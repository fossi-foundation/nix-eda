#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
# Copyright (c) 2021 UmbraLogic Technologies LLC
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Adapted from OpenLane Build Scripts
#
# https://github.com/The-OpenROAD-Project/OpenLane/blob/3c41826a8aaaf724e423593ddc7bea392e65277e/docker/utils.py
import ssl
import json
import re
import os
import pathlib
import shutil
import sys
import tarfile
import tempfile
import urllib.parse
from typing import Optional

try:
    import click
    import httpx
except ImportError:
    print(
        "python packages click and httpx are required -- pip3 install click httpx",
        file=sys.stderr,
    )
    exit(-1)


class GitHubSession(httpx.Client):
    def __init__(
        self,
        *,
        follow_redirects: bool = True,
        github_token: Optional[str] = None,
        ssl_context=None,
        **kwargs,
    ):
        if ssl_context is None:
            try:
                import truststore

                ssl_context = truststore.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
            except ImportError:
                pass

        try:
            super().__init__(
                follow_redirects=follow_redirects,
                verify=ssl_context,
                **kwargs,
            )
        except ValueError as e:
            if "Unknown scheme for proxy URL" in e.args[0] and "socks://" in e.args[0]:
                print(
                    f"Invalid SOCKS proxy: download_github_snapshot only supports http://, https:// and socks5:// schemes: {e.args[0]}",
                    file=sys.stderr,
                )
                exit(-1)
            else:
                raise e from None
        github_token = github_token or os.getenv("GITHUB_TOKEN", "").strip()
        self.github_token = github_token

        raw_headers = {
            "User-Agent": type(self).get_user_agent(),
        }
        if github_token != "":
            print("Setting non-empty token from daemon's environment environment…")
            raw_headers["Authorization"] = f"Bearer {github_token}"
        self.headers = httpx.Headers(raw_headers)

    @classmethod
    def get_user_agent(Self) -> str:
        return f"nix-eda"


github_client = GitHubSession()
download_cache = {}


def download_tarball(repo_url: str, commit: str) -> str:
    repo_path = urllib.parse.urlsplit(repo_url).path.strip("/")
    tarball_url = f"https://api.github.com/repos/{repo_path}/tarball/{commit}"
    print(f"Downloading tarball from {tarball_url}…")

    response = github_client.get(tarball_url)
    response.raise_for_status()

    tmp_dir = tempfile.mkdtemp()
    tarball_path = os.path.join(tmp_dir, "repo.tar.gz")

    with open(tarball_path, "wb") as f:
        f.write(response.content)

    return tarball_path


def extract_tarball(tarball_path: str, extract_to: str):
    print(f"Extracting to {extract_to}")
    shutil.rmtree(extract_to, ignore_errors=True)
    pathlib.Path(extract_to).mkdir(parents=True, exist_ok=True)

    with tarfile.open(tarball_path, "r:gz") as tar:
        for member in tar.getmembers():
            stripped = "/".join(member.name.split("/")[1:])
            if not stripped:
                continue
            member.name = stripped
            tar.extract(member, path=extract_to, filter="tar")


def fetch_tarball_and_submodules(
    repo_url,
    commit,
    base_path=None,
    filter=".",
    add_gitcommit=False,
):
    if base_path is None:
        base_path = urllib.parse.urlsplit(repo_url).path.split("/")[-1]
    key = (repo_url, commit)

    if key not in download_cache:
        tarball_path = download_tarball(repo_url, commit)
        download_cache[key] = tarball_path
    else:
        tarball_path = download_cache[key]
        print(f"Using cached tarball for {repo_url}@{commit}")

    extract_tarball(tarball_path, base_path)

    # Fetch tree from GitHub API
    repo_path = urllib.parse.urlsplit(repo_url).path.strip("/")
    tree_url = (
        f"https://api.github.com/repos/{repo_path}/git/trees/{commit}?recursive=1"
    )
    print(f"Fetching tree from {tree_url}")

    tree_resp = github_client.get(tree_url)
    tree_resp.raise_for_status()
    tree_data = tree_resp.json()

    if add_gitcommit:
        with open(os.path.join(base_path, ".gitcommit"), "w") as f:
            f.write(tree_data["sha"])

    submodules = {
        item["path"]: item["sha"]
        for item in tree_data.get("tree", [])
        if item["type"] == "commit"
    }

    # Fetch and parse .gitmodules
    gitmodules_url = (
        f"https://raw.githubusercontent.com/{repo_path}/{commit}/.gitmodules"
    )
    print(f"Fetching .gitmodules from {gitmodules_url}")

    gm_resp = github_client.get(gitmodules_url)
    if gm_resp.status_code != 200:
        print(f"No .gitmodules found for {repo_url}.")
        return
    gitmodules = gm_resp.text

    section_rx = re.compile(r'\[\s*submodule\s+"(.+?)"\s*\]')
    kv_rx = re.compile(r"\s*(\w+)\s*=\s*(.+)")
    gitmodules_parsed = {}
    current = {}

    for line in gitmodules.splitlines():
        section = section_rx.match(line)
        if section:
            name = section.group(1)
            gitmodules_parsed[name] = {}
            current = gitmodules_parsed[name]
        else:
            kv = kv_rx.match(line)
            if kv:
                current[kv.group(1)] = kv.group(2)

    filter_rx = re.compile(filter)

    for name, sub in gitmodules_parsed.items():
        path = sub.get("path")
        if not path or not filter_rx.match(path):
            print(f"Skipping submodule {name} at {path}…")
            continue

        sha = submodules.get(path)
        if not sha:
            print(f"No commit SHA found for {name}, skipping…")
            continue

        url = sub.get("url")
        if url.startswith(("./", "../")):
            url = urllib.parse.urljoin(repo_url + "/", url)
        if url.endswith(".git"):
            url = url[:-4]

        sub_path = os.path.join(base_path, path)
        print(f"Fetching submodule {name} at {path}…")
        fetch_tarball_and_submodules(
            repo_url=url,
            commit=sha,
            base_path=sub_path,
            filter=filter,
            add_gitcommit=add_gitcommit,
        )

    with open(
        os.path.join(base_path, ".submodule_hashes.json"),
        "w",
        encoding="utf8",
    ) as f:
        json.dump(submodules, sort_keys=True, fp=f)

    print(f"Finished {base_path}.")


@click.command()
@click.option(
    "--out-dir",
    default=None,
    help="The directory to download to. If omitted, will be equal to the name of the repository (CWD).",
)
@click.option(
    "--filter",
    default=".",
    help="Regex to match submodule paths. Submodules that are not matched will be excluded.",
)
@click.option(
    "--add-gitcommit",
    default=False,
    is_flag=True,
    help="Adds a .gitcommit file containing the commit sha256 of each resolved tree",
)
@click.argument("repo_url")
@click.argument("commit")
def main(repo_url, commit, out_dir, filter, add_gitcommit):
    """
    Downloads a snapshot of a GitHub repo, i.e. with all GitHub-based submodules
    recursively downloaded.

    Currently does not work for repositories with private or externally hosted
    submodules.
    """
    global github_client
    fetch_tarball_and_submodules(
        repo_url=repo_url,
        commit=commit,
        base_path=out_dir,
        filter=filter,
        add_gitcommit=add_gitcommit,
    )


if __name__ == "__main__":
    main()
