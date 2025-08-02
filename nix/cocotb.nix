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
  stdenv,
  # Metadata
  version ? "1.9.2",
  sha256 ? "sha256-7KCo7g2I1rfm8QDHRm3ZKloHwjDIICnJCF8KhaFdvqY=",
}:
let
  self = buildPythonPackage rec {
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

    buildInputs = [ setuptools ];
    propagatedBuildInputs = [ find-libpython ];

    postPatch = ''
      patchShebangs bin/*.py
    '';

    disabledTests = [
      # https://github.com/cocotb/cocotb/commit/425e1edb8e7133f4a891f2f87552aa2748cd8d2c#diff-4df986cbc2b1a3f22172caea94f959d8fcb4a128105979e6e99c68139469960cL33
      "test_cocotb"
      "test_cocotb_parallel"
    ];

    nativeCheckInputs = [
      cocotb-bus
      pytestCheckHook
      swig
      iverilog
      ghdl
    ];

    preCheck = ''
      export PATH=$out/bin:$PATH
      mv cocotb cocotb.hidden
    '';

    pythonImportsCheck = [ "cocotb" ];

    meta = {
      changelog = "https://github.com/cocotb/cocotb/releases/tag/v${version}";
      description = "Coroutine based cosimulation library for writing VHDL and Verilog testbenches in Python";
      mainProgram = "cocotb-config";
      homepage = "https://github.com/cocotb/cocotb";
      license = lib.licenses.bsd3;
      broken = stdenv.hostPlatform.isDarwin;
    };
  };
in
self
