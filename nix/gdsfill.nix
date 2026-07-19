# SPDX-License-Identifier: MIT
# Copyright (c) 2026 nix-eda Contributors
{
  lib,
  fetchFromGitHub,
  rustPlatform,
  cmake,
  version ? "0.1.8",
  rev ? null,
  sha256 ? "sha256-DG6QOB5MFRr+Rsr5wcrsQkSHYD9iubuA2LPcCGuAKpY=",
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

  cargoHash = "sha256-n4WJbeoH+M85Mv3sBeEpKdk+xv3fbL54PT0xlEV/voI=";

  nativeBuildInputs = [ cmake ];

  meta = {
    description = "Tool for inserting dummy metal fill into semiconductor layouts";
    homepage = "https://github.com/aesc-silicon/gdsfill";
    license = lib.licenses.lgpl21Plus;
    mainProgram = "gdsfill";
    platforms = lib.platforms.all;
  };
}
