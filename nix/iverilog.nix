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
# Code adapated from nixpkgs, original license follows
# ---
# Copyright (c) 2003-2025 Eelco Dolstra and the Nixpkgs/NixOS contributors
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
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  autoconf,
  bison,
  bzip2,
  flex,
  gperf,
  ncurses,
  perl,
  python3,
  readline,
  zlib,
  buildPackages,
  version ? "s20250103-60-gdb82380ce",
  rev ? "db82380cecf9943fcc397818e6899b7146442127",
  sha256 ? "sha256-0WA/SrHINtwv0UKX7Jjb8sjnXBfRIBoErK+MrdBwErg=",
}:
stdenv.mkDerivation {
  pname = "iverilog";
  inherit version;

  src = fetchFromGitHub {
    owner = "steveicarus";
    repo = "iverilog";
    rev =
      if rev == null
      then "v${lib.replaceStrings ["."] ["_"] version}"
      else rev;
    inherit sha256;
  };

  nativeBuildInputs = [
    autoconf
    bison
    flex
    gperf
  ];

  CC_FOR_BUILD = "${buildPackages.stdenv.cc}/bin/cc";
  CXX_FOR_BUILD = "${buildPackages.stdenv.cc}/bin/c++";

  patches = [
  ];

  buildInputs = [
    bzip2
    ncurses
    readline
    zlib
  ];

  preConfigure = "sh autoconf.sh";

  enableParallelBuilding = true;

  env = lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    NIX_CFLAGS_COMPILE = "-Wno-error=implicit-function-declaration";
  };

  # NOTE(jleightcap): the `make check` target only runs a "Hello, World"-esque sanity check.
  # the tests in the doInstallCheck phase run a full regression test suite.
  # however, these tests currently fail upstream on aarch64
  # (see https://github.com/steveicarus/iverilog/issues/917)
  # so disable the full suite for now.
  doCheck = true;
  doInstallCheck = !stdenv.hostPlatform.isAarch64;

  nativeInstallCheckInputs = [
    perl
    (python3.withPackages (
      pp:
        with pp; [
          docopt
        ]
    ))
  ];

  installCheckPhase = ''
    runHook preInstallCheck
    export PATH="$PATH:$out/bin"
    sh .github/test.sh
    runHook postInstallCheck
  '';

  meta = with lib; {
    description = "Icarus Verilog compiler";
    homepage = "https://steveicarus.github.io/iverilog";
    license = with licenses; [
      gpl2Plus
      lgpl21Plus
    ];
    platforms = platforms.all;
  };
}
