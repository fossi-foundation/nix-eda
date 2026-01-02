# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  patchelfUnstable,
  insert-dylib,
  darwin,
  zlib,
  python3,
  libgnat-bin,
  data ? (builtins.fromTOML (builtins.readFile ./ghdl-bin.toml)),
}:
let
  version = data.version;
  system-data = data."${stdenv.hostPlatform.system}";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "ghdl-bin";
  inherit version;

  src = fetchurl {
    url = "https://github.com/ghdl/ghdl/releases/download/v${finalAttrs.version}/ghdl-${system-data.backend}-${finalAttrs.version}-${system-data.platform_double}.tar.gz";
    inherit (system-data) sha256;
  };

  buildInputs = [
    zlib
  ]
  ++ lib.optionals (stdenv.hostPlatform.isLinux) [
    libgnat-bin
  ];

  nativeBuildInputs =
    lib.optionals (!stdenv.hostPlatform.isDarwin) [
      patchelfUnstable
    ]
    ++ lib.optionals (stdenv.hostPlatform.isDarwin) [
      (python3.withPackages (ps: [
        ps.lief
        ps.click
      ]))
      darwin.autoSignDarwinBinariesHook
    ];

  buildPhase = "true";

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r bin $out/bin
    cp -r include $out/include
    cp -r lib $out/lib
    runHook postInstall
  '';

  fixupPhase = ''
    runHook preFixup
  ''
  + lib.optionalString (stdenv.isLinux) ''
    $CC \
      -shared \
      -D GHDL_PREFIX=\"$out/lib/ghdl\" \
      -o $out/lib/set_ghdl_pfx.so \
      ${./supporting/ghdl-bin/set_ghdl_pfx.c}
    patchelf\
      --replace-needed libgnat-13.so ${libgnat-bin}/lib/libgnat-13.so \
      --replace-needed libc.so.6 ${stdenv.cc.libc}/lib/libc.so.6 \
      --replace-needed libm.so.6 ${stdenv.cc.libc}/lib/libm.so.6 \
      --add-needed $out/lib/set_ghdl_pfx.so \
      $out/lib/*.so 
    patchelf\
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --replace-needed libgnat-13.so ${libgnat-bin}/lib/libgnat-13.so \
      --replace-needed libc.so.6 ${stdenv.cc.libc}/lib/libc.so.6 \
      --replace-needed libm.so.6 ${stdenv.cc.libc}/lib/libm.so.6 \
      $out/bin/ghdl
  ''
  +
    # autoPatchelfHook handles fixup on linux
    lib.optionalString (stdenv.isDarwin) ''
      $CC \
        -dynamiclib -install_name $out/lib/set_ghdl_pfx.dylib \
        -D GHDL_PREFIX=\"$out/lib/ghdl\" \
        -o $out/lib/set_ghdl_pfx.dylib \
        ${./supporting/ghdl-bin/set_ghdl_pfx.c}
      python3 ${./supporting/lief_inject_dylib.py} \
        --inject $out/lib/set_ghdl_pfx.dylib \
        --inplace $out/lib/libghdl-*.dylib
      install_name_tool \
        -change /usr/lib/libc++.1.dylib ${stdenv.cc.libcxx}/lib/libc++.1.dylib \
        -change /usr/lib/libz.1.dylib ${zlib}/lib/libz.1.dylib \
        $out/bin/ghdl1-llvm
    ''
  + ''
    runHook postFixup
  '';

  meta = {
    description = "VHDL 2008/93/87 simulator (from official binaries)";
    homepage = "https://github.com/ghdl/ghdl";
    license = lib.licenses.gpl2Plus;
    mainProgram = "ghdl";
    platforms = lib.lists.remove "version" (builtins.attrNames data);
  };
})
