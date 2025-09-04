{
  lib,
  system,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  patchelfUnstable,
  insert-dylib,
  darwin,
  zlib,
  python3,
  data ? (builtins.fromTOML (builtins.readFile ./ghdl-bin.toml)),
}: let
  version = data.version;
  system-data = data."${system}";
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
    ];

    nativeBuildInputs =
      lib.optionals (!stdenv.hostPlatform.isDarwin) [
        autoPatchelfHook
        patchelfUnstable
      ]
      ++ lib.optionals (stdenv.hostPlatform.isDarwin) [
        (python3.withPackages (ps: with ps; [lief click]))
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

    fixupPhase =
      lib.optionalString (!stdenv.isDarwin) "exit -1" # TODO
      + lib.optionalString (stdenv.isDarwin) ''
        runHook preFixup
        install_name_tool \
          -change /usr/lib/libc++.1.dylib ${stdenv.cc.libcxx}/lib/libc++.1.dylib \
          -change /usr/lib/libz.1.dylib ${zlib}/lib/libz.1.dylib \
          $out/bin/ghdl1-llvm
        clang \
          -x c\
          -dynamiclib \
          -D GHDL_PREFIX=\"$out/lib/ghdl\" \
          -o $out/lib/set_ghdl_pfx.dylib \
          -install_name $out/lib/set_ghdl_pfx.dylib \
          - <<'EOF'
          #include <stdlib.h>

          __attribute__((constructor))
          static void set_ghdl_pfx(void) {
              if (!getenv("GHDL_PREFIX")) {
                  setenv("GHDL_PREFIX", GHDL_PREFIX, 1);
              }
          }
        EOF
        python3 ${./supporting/lief_inject_dylib.py} \
          --inject $out/lib/set_ghdl_pfx.dylib \
          --inplace $out/lib/libghdl-*.dylib
        runHook postFixup
      '';

    meta = {
      description = "VHDL 2008/93/87 simulator";
      homepage = "https://github.com/ghdl/ghdl";
      license = lib.licenses.gpl2Plus;
      platforms = lib.lists.remove "version" (builtins.attrNames data);
      broken = !stdenv.isDarwin;
    };
  })
