# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
{
  verilator,
  fetchFromGitHub,
  version ? "5.044",
  rev ? null,
  sha256 ? "sha256-z3jYNzhnZ+OocDAbmsRBWHNNPXLLvExKK1TLDi9JzPQ=",
}:
verilator.overrideAttrs (
  attrs': attrs: {
    inherit version;
    src = fetchFromGitHub {
      owner = "verilator";
      repo = "verilator";
      rev = if rev == null then "v${version}" else rev;
      inherit sha256;
    };
    patches = [ ];
  }
)
