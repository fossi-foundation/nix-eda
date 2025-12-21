# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
# Copyright (c) 2024 UmbraLogic Technologies LLC
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
  fetchFromGitHub,
  buildPythonPackage,
  ply,
  schema,
  pathspec,
  importlib-metadata,
  pygls,
  setuptools,
  setuptools-scm,
  version ? "0.5.0",
  sha256 ? "sha256-FT0a0pYhpsr0xlehrg+QqyPqOaM0paU+iG0+Bx8tDrU=",
}:
let
  self = buildPythonPackage {
    pname = "tclint";
    inherit version;
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "nmoroze";
      repo = self.pname;
      rev = "v${self.version}";
      inherit sha256;
    };

    patchPhase = ''
      runHook prePatch
      sed -Ei 's/schema==[0-9.]+/schema==${schema.version}/' pyproject.toml
      sed -Ei 's/pathspec==[0-9.]+/pathspec==${pathspec.version}/' pyproject.toml
      sed -Ei 's/importlib-metadata==[0-9.]+/importlib-metadata==${importlib-metadata.version}/' pyproject.toml
      runHook postPatch
    '';

    nativeBuildInputs = [
      setuptools
      setuptools-scm
    ];

    propagatedBuildInputs = [
      ply
      schema
      pathspec
      importlib-metadata
      pygls
    ];
  };
in
self
