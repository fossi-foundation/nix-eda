# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
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
  yosys,
  clang18Stdenv, # Need C++20
  fetchGitHubSnapshot,
  cmake,
  fmt,
  jq,
  rev ? "d4053e825408a25dc2c065cd430b4cc5e71b1b6c",
  rev-date ? "2025-12-08",
  hash ? "sha256-lSulYjGoW3ngRwKgQg8KdzWanrMos/w2NeqpFr+kkI4=",
}:
clang18Stdenv.mkDerivation {
  name = "yosys-slang";
  version = rev-date;
  dylibs = [ "slang" ];

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

  nativeBuildInputs = [
    cmake
    jq
  ]; # ninja doesn't work, cba to debug why
  buildInputs = [
    yosys
    yosys.python3-env
    fmt
  ];

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
    license = [ lib.licenses.mit ];
    homepage = "https://github.com/povik/yosys-slang";
    platforms = lib.platforms.all;
  };
}
