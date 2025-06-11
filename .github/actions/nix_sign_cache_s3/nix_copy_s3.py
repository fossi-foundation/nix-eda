# Written for fossi-foundation/nix-eda
#
# Copyright (c) 2025 Mohamed Gaber
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
"""
Nix S3 Copy Script
---

While ``nix copy`` does support s3 buckets, it does *not* allow you to exclude
files found in any upstream caches, which would typically include
https://cachix.nixos.org: See https://github.com/NixOS/nix/issues/13333.

This script is intended as a stop-gap measure until this is implemented.

This script requires Python 3.8+ and the AWS CLI to be installed (with
credentials configured in the environment.)
"""
import io
import os
import re
import json
import argparse
import sys
import tempfile
import subprocess
import logging
from typing import Any, List, Dict, Set

ws_rx = re.compile(r"\s+")

logging.basicConfig(
    format="%(asctime)s %(levelname)-8s %(message)s",
    level=logging.INFO,
    datefmt="%Y-%m-%d %H:%M:%S",
)


def parse_narinfo(file: io.TextIOWrapper):
    result: Dict[str, Any] = {}
    for line_raw in file:
        key_raw, value_raw = line_raw.strip().split(":", maxsplit=1)
        key = key_raw.strip()
        value = value_raw.strip()
        if key in ["StorePath", "URL", "Compression", "FileHash", "NarHash", "Deriver"]:
            pass  # strings
        elif key in ["FileSize", "NarSize"]:
            value = int(value)
        elif key in ["References", "Sig"]:
            value = ws_rx.split(value)
        else:
            logging.warning(
                f"Error while parsing narinfo file: Unexpected key {key} -- ignoring"
            )
            continue
        result[key] = value
    return result


def check_json_out(args: List[str], **kwargs):
    if "encoding" not in kwargs:
        kwargs["encoding"] = "utf8"
    out_str = subprocess.check_output(args, **kwargs)
    return json.loads(out_str)


def main(text_args):
    args = argparse.ArgumentParser()
    args.add_argument(
        "-u",
        "--upstream-cache",
        help="Check this upstream cache before uploading to the supplementary S3 bucket-based cache.",
        required=True,
    )
    args.add_argument(
        "-t",
        "--to-s3-bucket",
        help="The S3 bucket to upload to. The AWS CLI will be used, so make sure your environment is configured properly.",
        required=True,
    )
    args.add_argument(
        "-s",
        "--verify-signature-key",
        help="The public key used to sign the store paths in question. If a store path is not signed with this key, this script will exit with an error code.",
        required=True,
    )
    args.add_argument("flake_outputs", nargs="+")
    args_parsed = args.parse_args(text_args)

    paths_queried: Set[str] = set()
    paths_in_upstream_caches: Dict[str, str] = {}

    for i, flake_output in enumerate(args_parsed.flake_outputs):
        logging.info(
            f"Processing {flake_output} ({i + 1}/{len(args_parsed.flake_outputs)})…"
        )

        # 0. List all paths that this flake output depends on.
        try:
            local_store_path_dict: Dict[str, Any] = check_json_out(
                ["nix", "path-info", "--recursive", "--json", flake_output],
                stderr=subprocess.PIPE,
            )
        except subprocess.CalledProcessError as e:
            if "is not valid" in e.stderr:
                logging.warning(f"Failed to get store paths for {flake_output} -- assuming broken, skipping…")
                continue
            else:
                raise e from None

        closure: Set[str] = set(local_store_path_dict.keys())

        # 1. Check which paths have already been queried upstream, and
        # which need to be queried.
        paths_to_query: Set[str] = set()
        for path in closure:
            if path not in paths_queried:
                paths_to_query.add(path)
                paths_queried.add(path)

        # 2. Query paths that need to be queried against upstream.
        if len(paths_to_query):
            logging.info("Checking for paths upstream…")
            upstream_cache_paths_dict = check_json_out(
                [
                    "nix",
                    "path-info",
                    "--json",
                    "--eval-store",
                    "",
                    "--store",
                    args_parsed.upstream_cache,
                    *paths_to_query,
                ],
                stderr=subprocess.PIPE,
            )

            # 2a. Update list of paths known to be upstream
            #
            #    We store which cache for the probability of supporting multiple
            #    caches in the future. Don't count on it though.
            paths_in_upstream_caches.update(
                {
                    k: args_parsed.upstream_cache
                    for k in upstream_cache_paths_dict
                    if upstream_cache_paths_dict[k] != None
                }
            )

        # 3. Upload remaining paths from closure, if any, to our S3-based cache.
        difference = closure - set(paths_in_upstream_caches.keys())
        if len(difference):
            logging.info(
                f"One or more paths not found in upstream cache and will be uploaded:"
            )
            for path in difference:
                logging.info(f"* {path}")
            # The way this is implemented is:
            # 0. copy the full closure with zstd compression to a temporary
            #    directory
            # 1. check which .narinfo and .nar.zstd files correspond to the
            #    missing cache in the directory, and add them to a "sync"
            #    list.
            # 2. Invoke aws s3 sync. Because --size-only is passed, any paths
            #    already in the cache will not be uploaded.
            # ---
            # Potential improvements:
            #
            # * Query cache to verify the paths don't already exist there
            #   to save time on nix copy
            # * Only nix copy paths that we care about uploading -- blocked on
            #    https://github.com/NixOS/nix/issues/12835
            with tempfile.TemporaryDirectory(prefix="nix-eda-copy-uncache") as temp_dir:
                d = os.path.abspath(os.path.realpath(temp_dir))
                sync_include_args: List[str] = []
                logging.info("Copying closure…")
                subprocess.check_call(
                    [
                        "nix",
                        "copy",
                        "--to",
                        f"file://{d}?compression=zstd",
                        flake_output,
                    ],
                )
                for missing_store_path in difference:
                    # Verify non-recursively that it is signed with our key
                    try:
                        logging.info(f"Verifying {missing_store_path}…")
                        subprocess.check_call(
                            [
                                "nix",
                                "store",
                                "verify",
                                "--trusted-public-keys",
                                args_parsed.verify_signature_key,
                                missing_store_path,
                            ],
                            stderr=subprocess.PIPE,
                        )
                    except subprocess.CalledProcessError as e:
                        logging.warning(
                            f"Skipping {missing_store_path}: not signed with {args_parsed.verify_signature_key}: {e.stderr}"
                        )
                        continue
                    nix_hash, _ = os.path.basename(missing_store_path).split(
                        "-", maxsplit=1
                    )
                    narinfo_path = f"{d}/{nix_hash}.narinfo"
                    with open(narinfo_path) as f:
                        narinfo = parse_narinfo(f)
                    sync_include_args += [
                        "--include",
                        os.path.basename(narinfo_path),
                        "--include",
                        narinfo["URL"],
                    ]
                if len(sync_include_args):
                    logging.info("Uploading…")
                    subprocess.check_call(
                        [
                            "aws",
                            "s3",
                            "sync",
                            d,
                            f"s3://{args_parsed.to_s3_bucket}",
                            "--size-only",
                            "--exclude",
                            "*",
                            *sync_include_args,
                        ]
                    )
        else:
            logging.info("All paths already exist in upstream caches.")


if __name__ == "__main__":
    main(sys.argv[1:])
