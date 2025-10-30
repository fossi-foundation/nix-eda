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
  fetchPypi,
  setuptools,
  setuptools_scm,
  # Tools
  klayout,
  # Python
  matplotlib,
  numpy,
  rich,
  flit-core,
  orjson,
  pandas,
  pydantic,
  pydantic-settings,
  pydantic-extra-types,
  pyyaml,
  qrcode,
  scipy,
  shapely,
  toolz,
  types-pyyaml,
  typer,
  watchdog,
  freetype-py,
  mapbox-earcut,
  networkx,
  ipykernel,
  attrs,
  jinja2,
  graphviz,
  rectangle-packer,
  rectpack,
  kfactory,
  trimesh,
  pyglet,
  pytestCheckHook,
  scikit-image,
  # Metadata
  version ? "9.9.1",
  sha256 ? "sha256-rL/9clBJq/z7PyKKArGuAx2xtxce/3N3oPMIOiZA3VU=",
}:
let
  self = buildPythonPackage {
    pname = "gdsfactory";
    format = "pyproject";
    inherit version;

    src = fetchPypi {
      inherit (self) pname version;
      inherit sha256;
    };

    buildInputs = [
      flit-core
    ];

    propagatedBuildInputs = [
      matplotlib
      numpy
      orjson
      pandas
      pydantic
      pydantic-settings
      pydantic-extra-types
      pyyaml
      qrcode
      rectpack
      rich
      scipy
      shapely
      toolz
      types-pyyaml
      typer
      kfactory
      watchdog
      freetype-py
      mapbox-earcut
      networkx
      scikit-image
      trimesh
      ipykernel
      attrs
      jinja2
      graphviz
      pyglet
    ];

    nativeCheckInputs = [ pytestCheckHook ];

    doCheck = true;

    meta = {
      description = "python library to design chips (Photonics, Analog, Quantum, MEMs, ...), objects for 3D printing or PCBs.";
      homepage = "https://gdsfactory.github.io/gdsfactory/";
      license = [ lib.licenses.mit ];
      platforms = lib.platforms.unix;
      mainProgram = "gf";
    };
  };
in
self
