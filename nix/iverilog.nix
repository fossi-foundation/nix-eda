# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
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
  pkgs,
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
  addBinToPathHook,
  version ? "13.0",
  rev ? null,
  sha256 ? "sha256-SfODx7K3UrDHMoKCbMFpxo4t9j9vG1oWF0RFS3dSUm4=",
}:
stdenv.mkDerivation {
  pname = "iverilog";
  inherit version;

  src = fetchFromGitHub {
    owner = "steveicarus";
    repo = "iverilog";
    rev = if rev == null then "v${lib.replaceStrings [ "." ] [ "_" ] version}" else rev;
    inherit sha256;
  };

  nativeBuildInputs = [
    autoconf
    bison
    flex
    gperf
  ];

  env = {
    CC_FOR_BUILD = "${lib.getExe' buildPackages.stdenv.cc "cc"}";
    CXX_FOR_BUILD = "${lib.getExe' buildPackages.stdenv.cc "cc++"}";
  }
  // lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    NIX_CFLAGS_COMPILE = "-Wno-error=implicit-function-declaration";
  };

  buildInputs = [
    bzip2
    ncurses
    readline
    zlib
  ];

  preConfigure = "sh autoconf.sh";

  enableParallelBuilding = true;

  # NOTE(jleightcap): the `make check` target only runs a "Hello, World"-esque sanity check.
  # the tests in the doInstallCheck phase run a full regression test suite.
  # however, these tests currently fail upstream on aarch64
  # (see https://github.com/steveicarus/iverilog/issues/917)
  # so disable the full suite for now.
  doCheck = pkgs.stdenv.hostPlatform.system != "x86_64-darwin";
  doInstallCheck = !stdenv.hostPlatform.isAarch64;

  nativeInstallCheckInputs = [
    perl
    (python3.withPackages (
      pp: with pp; [
        docopt
      ]
    ))
    addBinToPathHook
  ];

  installCheckPhase = ''
    runHook preInstallCheck

    # PLI1 is not enabled in the build (ENABLE_PLI1=no), so skip PLI1 VPI tests
    # which would fail at runtime with "Failed - running vvp".
    sh .github/test.sh no-pli1

    runHook postInstallCheck
  '';

  meta = with lib; {
    description = "Icarus Verilog compiler";
    homepage = "https://steveicarus.github.io/iverilog";
    downloadPage = "https://github.com/steveicarus/iverilog";
    license = with licenses; [
      gpl2Plus
      lgpl21Plus
    ];
    platforms = platforms.all;

    # TODO: for now allow on all platforms
    # until I find out how to properly disable it

    #badPlatforms = [
    #  # Several tests fail with:
    #  # ==> Failed - running iverilog.
    #  "x86_64-darwin"
    #];
  };
}
