# SPDX-License-Identifier: MIT
# Copyright (c) 2026 nix-eda Contributors
# Partially adapted from https://github.com/ngi-nix/forge
# Copyright (c) 2026 Ivan Mincik
{
  lib,
  fetchGitHubSnapshot,
  stdenv,
  python3,
  bash,
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
  autoPatchelfHook,
  ctestCheckHook,
  rev-date ? "2026-09-17",
  rev ? "0ce1f2ebd135d89cc3082725a9e38457f12d029c",
  hash ? "sha256-EcQXgZt501vjoDw0BaTjC0dnB6GPtuIG36xJj4mrhwM=",
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
    # This script generates some test scripts that harcode the shebang
    substituteInPlace ./test/sec/RunSecStrategiesRegressTests.sh \
      --replace-fail "#!/usr/bin/env bash" "#!${lib.getExe bash}"

    substituteInPlace ./thirdparty/naja/thirdparty/slang/external/CMakeLists.txt \
      --replace-fail "FIND_PACKAGE_ARGS 12.2" "FIND_PACKAGE_ARGS ${fmt.version}"
  '';

  nativeBuildInputs = [
    flex
    bison
    cmake
    pkg-config
    ctestCheckHook
    autoPatchelfHook
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

  # CMake copies naja.so beside the executable without rewriting its build
  # RPATH. Repair that module and the installed shared libraries together.
  preFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    # Remove build paths before stdenv checks them; autoPatchelfHook then finds
    # the installed libraries and writes the module's runtime search path.
    patchelf --remove-rpath "$out/bin/naja.so"
    addAutoPatchelfSearchPath "$out/lib"
  '' + lib.optionalString stdenv.hostPlatform.isDarwin ''
    # Use CMake's installed module, whose Mach-O library paths were rewritten.
    cp "$out/lib/python/naja/naja.so" "$out/bin/naja.so"
  '';

  meta = {
    description = "Formal equivalence checking tool for digital circuits";
    license = [ lib.licenses.asl20 ];
    mainProgram = "kepler-formal";
    platforms = lib.platforms.all;
  };
}
