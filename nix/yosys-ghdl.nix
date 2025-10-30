# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
# Copyright (c) 2023 UmbraLogic Technologies LLC
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
  ghdl,
  pkg-config,
  rev ? "c9b05e481423c55ffcbb856fd5296701f670808c",
  rev-date ? "2022-01-11",
  sha256 ? "sha256-tT2+DXUtbJIBzBUBcyG2sz+3G+dTkciLVIczcRPr0Jw=",
}:
yosys.stdenv.mkDerivation {
  pname = "yosys-ghdl";
  version = rev-date;

  dylibs = [ "ghdl" ];

  src = fetchFromGitHub {
    owner = "ghdl";
    repo = "ghdl-yosys-plugin";
    inherit rev;
    inherit sha256;
  };

  buildInputs = [
    yosys
    python3
    ghdl
  ];

  nativeBuildInputs = [
    pkg-config
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/yosys/plugins
    cp ghdl.so $out/share/yosys/plugins/ghdl.so
    runHook postInstall
  '';

  doCheck = true;

  checkPhase = ''
    runHook preCheck
    yosys -p "plugin -i $PWD/ghdl.so; ghdl testsuite/examples/dff/dff.vhdl -e dff; hierarchy"
    runHook postcheck
  '';

  meta = {
    description = "VHDL synthesis (based on GHDL and Yosys)";
    homepage = "http://ghdl.github.io/ghdl/using/Synthesis.html";
    license = lib.licenses.gpl3Plus;
    inherit (ghdl.meta) platforms;
  };
}
