# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
# Copyright (c) 2023 UmbraLogic Technologies LLC
# Copyright (c) 2003-2024 Eelco Dolstra and the Nixpkgs/NixOS contributors
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
  fetchFromGitHub,
  python3,
  boolector,
  z3,
  yices,
  version ? "0.59",
  sha256 ? "sha256-WNJ390nN2+vjWGIc842e/5CX2wKI/cyo+NnuCfbHSbQ=",
}:
yosys.stdenv.mkDerivation (finalAttrs: {
  pname = "yosys-sby";
  inherit version;
  dylibs = [ ];

  src = fetchFromGitHub {
    owner = "yosyshq";
    repo = "sby";
    rev = "v${version}";
    inherit sha256;
  };

  buildPhase = "";

  makeFlags = [
    "YOSYS_CONFIG=${yosys}/bin/yosys-config"
    "PREFIX=${placeholder "out"}"
  ];

  buildInputs = [
    yosys

    yosys.python3-env
    # solvers
    boolector
    z3
    yices
  ];

  patchPhase = ''
    runHook prePatch
    sed -i.bak "s@#!/usr/bin/env python3@#!${yosys.python3-env}/bin/python3@" sbysrc/sby.py
    sed -i.bak "s@\"/usr/bin/env\", @@" sbysrc/sby_core.py
    runHook postPatch
  '';

  doCheck = false; # it just takes forever man
  checkPhase = ''
    make test SBY_MAIN=$src/sbysrc/sby.py
  '';

  makeWrapperArgs = [
    "--prefix PATH : ${lib.makeBinPath finalAttrs.buildInputs}"
  ];

  meta = with lib; {
    description = "SymbiYosys (sby) -- Front-end for Yosys-based formal verification flows";
    homepage = "https://github.com/YosysHQ/sby";
    mainProgram = "sby";
    license = licenses.mit;
    platforms = platforms.all;
  };
})
