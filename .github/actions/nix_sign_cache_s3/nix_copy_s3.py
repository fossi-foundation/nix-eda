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
import shlex
import sys
import tempfile
import subprocess
import logging
from pathlib import Path
from urllib.parse import urlparse
from urllib.error import HTTPError
from urllib.request import Request, urlopen
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


class NixPathInfoError(RuntimeError):
    def __init__(self, *args):
        super().__init__(*args)

    @classmethod
    def from_stderr(Self, stderr: io.TextIOWrapper):
        does_not_exist = re.compile(r"error: path '(\S+?)' does not exist in the store")
        unavailable = re.compile(r"Refusing to evaluate package '(\S+?)'")

        stderr_str = stderr.read()

        for line in stderr_str.splitlines():
            if dne_match := does_not_exist.search(line):
                return NixPathNotFound(dne_match[1])
            if unavailable_match := unavailable.search(line):
                return NixDerivationUnavailable(unavailable_match[1])

        return Self(f"unexpected error occurred:\n" + stderr_str)


class NixDerivationUnavailable(NixPathInfoError):
    def __init__(self, name):
        self.name = name
        super().__init__(
            f"derivation '{self.name}' is not available on the requested hostPlatform"
        )


class NixPathNotFound(NixPathInfoError):
    def __init__(self, path):
        self.path = path
        super().__init__(
            f"path '{self.path}' not found in nix store, likely failed to build"
        )


def nix_pathinfo_parse(
    *paths,
    recursive=True,
    encoding="utf8",
    eval_store: str | None = None,
    store: str | None = None,
):
    cmd = [
        "nix",
        "path-info",
        "--json",
        *(recursive * ("--recursive",)),
        *(("--eval-store", eval_store) if eval_store is not None else ()),
        *(("--store", store) if store is not None else ()),
        *paths,
    ]
    logging.info(f"\t\t> {shlex.join(cmd)}")
    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        encoding=encoding,
    )
    process.wait()
    if process.returncode:
        raise NixPathInfoError.from_stderr(process.stderr)
    return json.load(process.stdout)


def paths_from_path_info(path_info_raw: Any):
    if isinstance(path_info_raw, dict):  # nix (as of 2.31.2)
        return set(key for key in path_info_raw if path_info_raw[key] is not None)
    elif isinstance(path_info_raw, list):  # lix (as of 2.93.3)
        return set(entry["path"] for entry in path_info_raw if entry["valid"])
    else:
        logging.warning(
            f"nix path-info returned an unexpected result: {repr(json.dumps(path_info_raw))}…"
        )
        return None

def filter_store_paths_by_remote(
    *store_paths,
    remote="https://cache.nixos.org"
):
    remote = remote.rstrip("/")
    in_remote = []
    for path in store_paths:
        p = Path(path)
        name = p.name
        hash, _ = name.split("-", maxsplit=1)
        narinfo_path = f"{remote}/{hash}.narinfo"
        req = Request(narinfo_path)
        try:
            with urlopen(req) as res:
                if (res.getcode() // 100) == 2:
                    in_remote.append(path)
        except HTTPError:
            continue
    return in_remote


def main(text_args):
    args = argparse.ArgumentParser()
    args.add_argument(
        "-u",
        "--upstream-cache",
        help="Check if the paths exist in any of these upstream caches before attempting to upload to the S3 cache. If an element is the exact string 'TARGET_HTTPS', the final s3 cache is assumed accessible over HTTPS and also checked.",
        required=True,
        nargs="+",
        action="extend",
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

    s3_nix_url = args_parsed.to_s3_bucket
    if "://" not in s3_nix_url:
        s3_nix_url = f"s3://{s3_nix_url}"
    s3_nix_url = urlparse(s3_nix_url)._replace(scheme="s3")

    upstream_caches = []
    for cache in args_parsed.upstream_cache:
        if cache == "TARGET_HTTPS":
            upstream_caches.append(s3_nix_url._replace(scheme="https").geturl())
        else:
            upstream_caches.append(cache)

    for i, flake_output in enumerate(args_parsed.flake_outputs):
        logging.info(
            f"Processing {flake_output} ({i + 1}/{len(args_parsed.flake_outputs)})…"
        )

        # 0. List all paths that this flake output depends on, the "closure"
        try:
            closure_raw = nix_pathinfo_parse(flake_output)
        except (NixPathNotFound, NixDerivationUnavailable) as e:
            logging.warning(f"Skipping {flake_output}: {e}")
            continue

        closure = paths_from_path_info(closure_raw)
        if closure is None:
            continue

        # 1. Check which paths have already been queried in previous attempts
        #    to avoid hammering upstreams.
        paths_to_query: Set[str] = set()
        for path in closure:
            if path not in paths_queried:
                paths_to_query.add(path)

        # 2. Query any paths that have not already been queried
        if len(paths_to_query):
            logging.info("Checking for paths upstream…")
            for cache in upstream_caches:
                upstream_cache_paths = filter_store_paths_by_remote(
                    *paths_to_query,
                    remote=cache,
                )
                paths_in_upstream_caches.update(
                    {path: cache for path in upstream_cache_paths}
                )
            paths_queried |= paths_to_query

        # 3. Upload remaining paths from closure, if any, to our S3-based cache.
        difference = closure - set(paths_in_upstream_caches.keys())
        if len(difference):
            logging.info(
                "One or more paths not found in upstream caches and will be uploaded:"
            )
            for path in difference:
                logging.info(f"* {path}")
            # The way this is implemented is:
            # 0. copy the full closure with zstd compression to a temporary
            #    directory
            # 1. check which .narinfo and .nar.zstd files correspond to the
            #    missing paths in the directory, and add them to a "sync"
            #    list.
            # 2. Invoke aws s3 sync. Because --size-only is passed, any paths
            #    already in the cache will not be uploaded.
            # ---
            # Potential improvements:
            #
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
                        # despite its name, thats just a relative path to the
                        # .tar.zst
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
                            s3_nix_url._replace(query="").geturl(),
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
