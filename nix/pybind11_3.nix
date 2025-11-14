# SPDX-License-Identifier: MIT
# Copyright (c) 2025 nix-eda Contributors
{
  lib,
  fetchPypi,
  buildPythonPackage,
}:
buildPythonPackage rec {
  pname = "pybind11";
  version = "3.0.1";
  format = "wheel";

  src = fetchPypi {
    pname = "pybind11";
    inherit version;
    inherit format;
    dist = "py3";
    python = "py3";
    sha256 = "sha256-qo8KpuCpTTtkrfw49WDzPxXlib4hdeEDwKM8a85V7ok=";
  };
}
