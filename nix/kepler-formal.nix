# SPDX-License-Identifier: MIT
# Copyright (c) 2026 nix-eda Contributors
# Partially adapted from https://github.com/ngi-nix/forge
# Copyright (c) 2026 Ivan Mincik
{
  lib,
  fetchGitHubSnapshot,
  stdenv,
  python3,
  spdlog,
  zlib,
  boost,
  capnproto,
  onetbb,
  fmt,
  tomlplusplus,
  pkg-config,
  cmake,
  flex,
  bison,
  ctestCheckHook,
  rev-date ? "2026-07-14",
  rev ? "23ae50f5777f44d6a348264abd5f87f32d025330",
  hash ? "sha256-tD9pbr/9iKejV3eTZcpvPAi7MnJd6K3AX0RTz94pBdI=",
}:
stdenv.mkDerivation {
  pname = "kepler-formal";
  version = "0-unstable-${rev-date}";

  src = fetchGitHubSnapshot {
    owner = "keplertech";
    repo = "kepler-formal";
    inherit rev;
    inherit hash;
  };

  postPatch = ''
    substituteInPlace ./thirdparty/naja/thirdparty/slang/external/CMakeLists.txt \
      --replace-fail "FIND_PACKAGE_ARGS 12.2" "FIND_PACKAGE_ARGS ${fmt.version}"
  '';

  nativeBuildInputs = [
    flex
    bison
    cmake
    pkg-config
    ctestCheckHook
  ];

  buildInputs = [
    boost
    capnproto
    onetbb
    python3
    spdlog
    zlib
    fmt
    tomlplusplus
  ];

  cmakeFlags = [
    "-DFMT_INSTALL:BOOL=OFF"
  ];

  doCheck = true;

  meta = {
    description = "equivalence checking tool for digital designs";
    license = [ lib.licenses.mit ];
    platforms = lib.platforms.all;
  };
}
