# Copyright 2023 Efabless Corporation
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
  fetchFromGitHub,
  python3,
  boolector,
  z3,
  yices,
  version ? "0.54",
  sha256 ? "sha256-onVeK23KgCodEoaUtfh3R0MraaXuoNuQ2BAX5k4RNis=",
}:
yosys.stdenv.mkDerivation (finalAttrs: {
  pname = "yosys-sby";
  inherit version;
  dylibs = [];

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
