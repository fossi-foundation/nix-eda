# SPDX-License-Identifier: MIT
# Copyright (c) 2026 fossi-foundation/nix-eda contributors
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

# Modified for nix-eda based on https://github.com/NixOS/nixpkgs/pull/478061
# while removing docs/mpi/test support to further save compute time and space
# (and my own sanity.)
{
  stdenv,
  fetchFromGitHub,
  fetchgit,
  fetchpatch,
  applyPatches,
  lib,
  bison,
  blas,
  cmake,
  flex,
  fftw,
  gfortran,
  lapack,
  libtool_2,
  suitesparse,
  trilinos,
  version ? "7.10.0",
  hash ? "sha256-FDvbk8ICxAetm8QNCvnXiLlq+Yem8KkHCJWb/HgJrec=",
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xyce";
  inherit version;

  src = fetchFromGitHub {
    owner = "Xyce";
    repo = "Xyce";
    rev = "Release-${version}";
    inherit hash;
  };

  patches = [
    # fix clang build issue
    (fetchpatch {
      url = "https://github.com/Xyce/Xyce/commit/f321f7eb1c59d29fe98054ec02567976aca43120.patch";
      hash = "sha256-VXKMNERrTYciOtb63sIVT36SVsx2scmSWpFE5zaDcX8=";
    })
  ];

  nativeBuildInputs = [
    cmake
    gfortran
    libtool_2
  ];

  buildInputs = [
    bison
    blas
    flex
    fftw
    lapack
    suitesparse
    trilinos
  ];

  meta = {
    description = "High-performance analog circuit simulator";
    longDescription = ''
      Xyce is a SPICE-compatible, high-performance analog circuit simulator,
      capable of solving extremely large circuit problems by supporting
      large-scale parallel computing platforms.
    '';
    homepage = "https://xyce.sandia.gov";
    license = lib.licenses.gpl3;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
})
