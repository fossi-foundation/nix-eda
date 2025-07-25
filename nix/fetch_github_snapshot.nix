# Copyright 2025 nix-eda Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Code adapated from Nixpkgs, original license follows:
# ---
# Copyright (c) 2003-2023 Eelco Dolstra and the Nixpkgs/NixOS contributors
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
{
  lib,
  stdenvNoCC,
  python3,
  preferLocalBuild ? true,
}: {
  owner,
  repo,
  rev,
  hash,
}:
stdenvNoCC.mkDerivation {
  name = "github-${repo}-${rev}-snapshot";
  nativeBuildInputs = [
    (python3.withPackages (ps: with ps; [click httpx truststore]))
  ];
  phases = ["installPhase"];
  installPhase = ''
    python3 ${./supporting/download_github_snapshot.py} \
      --out-dir $out \
      https://github.com/${owner}/${repo} \
      ${rev}
  '';
  impureEnvVars =
    lib.fetchers.proxyImpureEnvVars
    ++ [
      "GITHUB_TOKEN"
    ];
  outputHash = hash;
  outputHashAlgo =
    if hash == ""
    then "sha256"
    else null;
  outputHashMode = "recursive";
  inherit preferLocalBuild;
}
