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
  ghdl',
  # always pick the revision closest to ghdl.version's release date
  # recall: ghdl.version is synced with the one in nixpkgs
  rev ? "07a30ed39fb6a078f1bf7e9e88ce9ed712380ec2",
  rev-date ? "2026-01-11",
  sha256 ? "sha256-LETpUfpIezSxD4A9VYA/OvgN3aZd1YivPe2w973X3nk=",
}:
yosys.stdenv.mkDerivation {
  __structuredAttrs = true; # because of space in makeFlags

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
    ghdl'
  ];

  makeFlags = [
    "VER_HASH=${rev}"
    "CFLAGS=-Wno-error=unused -O2"
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
    yosys -m $PWD/ghdl.so -p "ghdl testsuite/examples/dff/dff.vhdl -e dff; hierarchy"
    runHook postcheck
  '';

  meta = {
    description = "VHDL synthesis (based on GHDL and Yosys)";
    homepage = "http://ghdl.github.io/ghdl/using/Synthesis.html";
    license = lib.licenses.gpl3Plus;
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };
}
