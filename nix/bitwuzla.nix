# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
# Copyright (c) 2023 UmbraLogic Technologies LLC
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
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
{
  stdenv,
  fetchFromGitHub,
  lib,
  python3,
  cmake,
  lingeling,
  btor2tools,
  symfpu,
  gtest,
  gmp,
  cadical,
  minisat,
  picosat,
  cryptominisat,
  zlib,
  pkg-config,
  rev ? "3bc0f9f1aca04afabe1aff53dd0937924618b2ad",
  rev-date ? "2022-10-03",
  sha256 ? "sha256-UXZERl7Nedwex/oUrcf6/GkDSgOQ537WDYm117RfvWo=",
  # "*** internal error in 'lglib.c': watcher stack overflow" on aarch64-linux
  withLingeling ? !stdenv.hostPlatform.isAarch64,
}:
stdenv.mkDerivation (self: {
  pname = "bitwuzla";
  version = "unstable-${rev-date}";

  src = fetchFromGitHub {
    owner = "bitwuzla";
    repo = "bitwuzla";
    inherit rev;
    inherit sha256;
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];
  buildInputs = [
    cadical
    cryptominisat
    picosat
    minisat
    btor2tools
    symfpu
    gmp
    zlib
  ] ++ lib.optional withLingeling lingeling;

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DPicoSAT_INCLUDE_DIR=${lib.getDev picosat}/include/picosat"
    "-DBtor2Tools_INCLUDE_DIR=${lib.getDev btor2tools}/include/btor2parser"
    "-DBtor2Tools_LIBRARIES=${lib.getLib btor2tools}/lib/libbtor2parser${stdenv.hostPlatform.extensions.sharedLibrary}"
  ] ++ lib.optional self.doCheck "-DTESTING=YES";

  checkInputs = [
    python3
    gtest
  ];
  doCheck = false; # they take freaking forever
  preCheck =
    let
      var = if stdenv.isDarwin then "DYLD_LIBRARY_PATH" else "LD_LIBRARY_PATH";
    in
    ''
      export ${var}=$(readlink -f lib)
      patchShebangs ..
    '';

  meta = {
    description = "A SMT solver for fixed-size bit-vectors, floating-point arithmetic, arrays, and uninterpreted functions";
    homepage = "https://bitwuzla.github.io";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
