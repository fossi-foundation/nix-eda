# SPDX-License-Identifier: MIT
# Copyright (c) 2026 nix-eda Contributors
# Partially adapted from https://github.com/ngi-nix/forge
# Copyright (c) 2026 Ivan Mincik
{
  lib,
  fetchGitHubSnapshot,
  clangStdenv,
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
  perl,
  autoPatchelfHook,
  darwin,
  ctestCheckHook,
  rev-date ? "2026-09-17",
  rev ? "0ce1f2ebd135d89cc3082725a9e38457f12d029c",
  hash ? "sha256-EcQXgZt501vjoDw0BaTjC0dnB6GPtuIG36xJj4mrhwM=",
}:
clangStdenv.mkDerivation {
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
    perl
    ctestCheckHook
  ]
  ++ lib.optionals clangStdenv.hostPlatform.isLinux [ autoPatchelfHook ]
  ++ lib.optionals clangStdenv.hostPlatform.isDarwin [ darwin.autoSignDarwinBinariesHook ];

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

  preFixup =
    # $out/bin/naja.so has invalid rpaths from the build process
    lib.optionalString clangStdenv.hostPlatform.isLinux ''
      patchelf --remove-rpath $out/bin/naja.so
      patchelf --set-rpath $out/lib $out/bin/naja.so
    ''
    + lib.optionalString clangStdenv.hostPlatform.isDarwin ''
      otool -l $out/bin/naja.so | perl -lne '$i = 3 if /LC_RPATH/; $i--; print /path (\S+)/ if $i == 0;' | xargs -n1 install_name_tool $out/bin/naja.so -delete_rpath
      install_name_tool -add_rpath $out/lib $out/bin/naja.so
    '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheckPhase
    echo "module mod1(input a, output b); assign b = ~a; endmodule" > ./mod_1.v
    echo "module mod2(input a, output b); assign b = a ^ 1'b1; endmodule" > ./mod_2.v
    $out/bin/kepler-formal -v sec -sv --design1 mod_1.v --design2 mod_2.v
    runHook postInstallCheckPhase
  '';

  meta = {
    description = "Formal equivalence checking tool for digital circuits";
    license = [ lib.licenses.asl20 ];
    mainProgram = "kepler-formal";
    platforms = lib.platforms.all;
  };
}
