# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
{
  verilator,
  fetchFromGitHub,
  version ? "5.042",
  rev ? null,
  sha256 ? "sha256-+hfqOt429Kv4rZXEMz4LxNgBULAt/ewWY7mnQt2zpVU=",
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
