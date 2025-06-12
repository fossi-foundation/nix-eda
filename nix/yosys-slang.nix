# Copyright 2025 The American University in Cairo
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
{
  lib,
  yosys,
  clang18Stdenv, # Need C++20
  fetchGitHubSnapshot,
  cmake,
  fmt,
  jq,
  rev ? "142641f2062a5eaa42d5bdf23982eb82b01fe76a",
  rev-date ? "2025-06-12",
  hash ? "sha256-BuG4k5vgWgrDYIprg95aCPeXjKBk378jSxyPom7Iw2M=",
}:
clang18Stdenv.mkDerivation {
  name = "yosys-slang";
  version = rev-date;

  src = fetchGitHubSnapshot {
    owner = "donn";
    repo = "yosys-slang";
    inherit rev;
    inherit hash;
  };

  cmakeFlags = [
    "-DYOSYS_CONFIG=${yosys}/bin/yosys-config"
    "-DFMT_INSTALL:BOOL=OFF"
  ];

  nativeBuildInputs = [cmake jq]; # ninja doesn't work, cba to debug why
  buildInputs = [yosys yosys.python3 fmt];

  patchPhase = ''
    runHook prePatch
    sed -iE \
      -e "/git_rev_parse(YOSYS_SLANG_REVISION/c\set(YOSYS_SLANG_REVISION ${rev})" \
      -e "/git_rev_parse(SLANG_REVISION/c\set(SLANG_REVISION $(cat .submodule_hashes.json | jq -r '."third_party/slang"'))" \
      src/CMakeLists.txt
    runHook postPatch
  '';

  doCheck = true;
  
  # Release, at least in Nix, is broken. Can't figure out why entirely.
  cmakeBuildType = "Debug";

  installPhase = ''
    runHook preBuild
    cd ../build
    mkdir -p $out/share/yosys/plugins
    cp slang.so $out/share/yosys/plugins
    runHook postBuild
  '';
}
