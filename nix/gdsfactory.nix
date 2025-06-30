# Copyright 2025 nix-eda Contributors
#
# Adapted from efabless/nix-eda
#
# Copyright 2024 Efabless Corporation
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
}: let
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

    nativeCheckInputs = [pytestCheckHook];

    doCheck = true;

    meta = {
      description = "python library to design chips (Photonics, Analog, Quantum, MEMs, ...), objects for 3D printing or PCBs.";
      homepage = "https://gdsfactory.github.io/gdsfactory/";
      license = [lib.licenses.mit];
      platforms = lib.platforms.unix;
      mainProgram = "gf";
    };
  };
in
  self
