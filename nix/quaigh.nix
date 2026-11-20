# SPDX-License-Identifier: MIT
# Copyright (c) 2026 nix-eda Contributors
{
  lib,
  fetchFromGitHub,
  rustPlatform,
  kissat,
  bzip2,
  libclang,
  rev ? "5b47ca63608d516efc3f225758635df689be70c5",
  rev-date ? "2026-02-02",
  hash ? "sha256-dcGI2FVd0SyrN5RaZXc5VrYY37pKtb/pZhNSV7MtNGE=",
  cargoHash ? "sha256-f8Ay9SgPPZWIY8NjwjSJRWFKWer8KaHxeclD+jGblss=",
}:
rustPlatform.buildRustPackage {
  pname = "quaigh";
  version = rev-date;

  src = fetchFromGitHub {
    owner = "coloquinte";
    repo = "quaigh";
    inherit rev;
    inherit hash;
  };

  env.LIBCLANG_PATH = "${lib.getLib libclang}/lib";

  buildInputs = [
    kissat
    bzip2
    libclang
  ];

  inherit cargoHash;

  meta = {
    description = "Logic simplification and analysis tools";
    homepage = "https://github.com/coloquinte/quaigh";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "quaigh";
    platforms = lib.platforms.all;
  };
}
