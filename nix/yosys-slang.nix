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
{
  lib,
  yosys,
  clang18Stdenv, # Need C++20
  fetchGitHubSnapshot,
  cmake,
  fmt,
  jq,
  rev ? "76b83eb5b73ba871797e6db7bc5fed10af380be4",
  rev-date ? "2025-06-20",
  hash ? "sha256-XqBnrwH1C+oxfbIFFUS1s8Ujbcr1VDWHq8FVyL9iGOI=",
}:
clang18Stdenv.mkDerivation {
  name = "yosys-slang";
  version = rev-date;
  dylibs = ["slang"];

  src = fetchGitHubSnapshot {
    owner = "povik";
    repo = "yosys-slang";
    inherit rev;
    inherit hash;
  };

  cmakeFlags = [
    "-DYOSYS_CONFIG=${yosys}/bin/yosys-config"
    "-DFMT_INSTALL:BOOL=OFF"
  ];

  nativeBuildInputs = [cmake jq]; # ninja doesn't work, cba to debug why
  buildInputs = [yosys yosys.python3-env fmt];

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
  
  meta = {
    description = "SystemVerilog frontend for Yosys";
    license = [lib.licenses.mit];
    homepage = "https://github.com/povik/yosys-slang";
    platforms = lib.platforms.all;
  };
}
