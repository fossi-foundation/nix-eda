# SPDX-License-Identifier: MIT
# Copyright (c) 2026 nix-eda Contributors
{
  lib,
  fetchFromGitHub,
  rustPlatform,
  cmake,
  version ? "0.1.11",
  rev ? null,
  sha256 ? "sha256-/oUzHXRQmxO8oonBqWNJOOWDckFEjoFqhHY/VNqb6U4=",
  cargoHash ? "sha256-svdhsuCmlsuiVyXfgveoRyBoCgoGZfkxrrK9D7dl8yM=",
}:
rustPlatform.buildRustPackage {
  pname = "gdsfill";
  inherit version;

  src = fetchFromGitHub {
    owner = "aesc-silicon";
    repo = "gdsfill";
    tag = if rev == null then "v${version}" else rev;
    hash = sha256;
  };

  inherit cargoHash;

  nativeBuildInputs = [ cmake ];

  meta = {
    description = "Tool for inserting dummy metal fill into semiconductor layouts";
    homepage = "https://github.com/aesc-silicon/gdsfill";
    license = lib.licenses.lgpl21Plus;
    mainProgram = "gdsfill";
    platforms = lib.platforms.all;
  };
}
