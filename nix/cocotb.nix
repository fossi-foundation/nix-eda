# Copyright (c) 2025 nix-eda Contributors
#
# Adapted from nixpkgs
#
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
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  setuptools-scm,
  cocotb-bus,
  find-libpython,
  pytestCheckHook,
  swig,
  iverilog,
  ghdl,
  zlib,
  # Metadata
  version ? "2.0.0",
  sha256 ? "sha256-BpshczKA83ZeytGDrHEg6IAbI5FxciAUnzwE10hgPC0=",
}: let
  self = buildPythonPackage {
    pname = "cocotb";
    inherit version;
    format = "setuptools";

    # pypi source doesn't include tests
    src = fetchFromGitHub {
      owner = "cocotb";
      repo = "cocotb";
      tag = "v${version}";
      inherit sha256;
    };

    buildInputs = [setuptools zlib];
    propagatedBuildInputs = [find-libpython];

    postPatch = ''
      patchShebangs bin/*.py
    '';

    nativeCheckInputs = [
      cocotb-bus
      pytestCheckHook
      swig
      iverilog
      ghdl
    ];

    pythonImportsCheck = ["cocotb"];

    meta = {
      changelog = "https://github.com/cocotb/cocotb/releases/tag/v${version}";
      description = "Coroutine based cosimulation library for writing VHDL and Verilog testbenches in Python";
      mainProgram = "cocotb-config";
      homepage = "https://github.com/cocotb/cocotb";
      license = lib.licenses.bsd3;
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
    };
  };
in
  self
