# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
{
  verilator,
  fetchFromGitHub,
  version ? "5.046",
  rev ? null,
  sha256 ? "sha256-dfZzbQrw/14dFvWnkmCDElwsGm6GdFstNAURujvEIb8=",
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
