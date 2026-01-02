# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
{
  lib,
  stdenv,
  fetchurl,
  patchelfUnstable,
  python3,
  libgcc,
  gnat,
  zstd,
  data ? (builtins.fromTOML (builtins.readFile ./libgnat-bin.toml)),
}:
let
  version = data.version;
  system-data = data."${stdenv.hostPlatform.system}";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "libgnat-bin";
  inherit version;

  src = fetchurl {
    inherit (system-data) url sha256;
  };

  unpackPhase = ''
    runHook preUnpack
    ar x $src
    tar -xf data.tar.zst
    runHook postUnpack
  '';

  buildInputs = [
    libgcc
  ];

  nativeBuildInputs = [
    zstd
    patchelfUnstable
  ];

  buildPhase = "true";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    cp usr/lib/*/libgnat*.so $out/lib
    runHook postInstall
  '';

  fixupPhase = ''
    runHook preFixup
    patchelf \
      --replace-needed libc.so.6 ${stdenv.cc.libc}/lib/libc.so.6 \
      --replace-needed libm.so.6 ${stdenv.cc.libc}/lib/libm.so.6 \
      --replace-needed libgcc_s.so.1 ${libgcc}/lib/libgcc_s.so.1 \
      $out/lib/libgnat-13.so
    runHook postFixup
  '';

  meta = {
    description = "Runtime components for GNAT-build binaries (from Ubuntu binaries)";
    license = lib.licenses.gpl3Plus; # with runtime library exception
    platforms = lib.lists.remove "version" (builtins.attrNames data);
  };
})
