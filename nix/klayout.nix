# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
# Copyright (c) 2023 UmbraLogic Technologies LLC
# Copyright (c) 2003-2023 Eelco Dolstra and the Nixpkgs/NixOS contributors
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
{
  lib,
  clangStdenv,
  fetchFromGitHub,
  qt6,
  qt6Packages,
  which,
  perl,
  python3,
  ruby,
  gnused,
  curl,
  gcc,
  libgit2,
  libpng,
  fetchurl,
  buildEnv,
  makeBinaryWrapper,
  darwin,
  # Python environments
  klayout,
  buildPythonEnvForInterpreter,
  version ? "0.30.13",
  sha256 ? "sha256-/m6Tf3f0xQ1yUAMS9Dmma19FYKtofLxEacOBS727Dsk=",
}:
clangStdenv.mkDerivation (finalAttrs: {
  pname = "klayout";
  inherit version;

  outputs = [
    "out"
    "python"
  ];

  src = fetchurl {
    url = "https://github.com/KLayout/klayout/archive/refs/tags/v${version}.tar.gz";
    inherit sha256;
  };

  patches = [
    ./patches/klayout/abspath.patch
  ];

  postPatch = ''
    substituteInPlace src/klayout.pri --replace "-Wno-reserved-user-defined-literal" ""
    patchShebangs .
  '';

  nativeBuildInputs = [
    which
    perl
    (python3.withPackages (ps: with ps; [ setuptools ]))
    ruby
    gnused
    qt6.wrapQtAppsHook
  ]
  ++ lib.optionals clangStdenv.hostPlatform.isDarwin [ darwin.autoSignDarwinBinariesHook ];

  buildInputs = with qt6Packages; [
    qtbase
    qtmultimedia
    qttools
    qt5compat
    curl
    gcc
    libgit2
    libpng
  ];

  propagatedBuildInputs = [
    ruby
  ];

  configurePhase = ''
    runHook preConfigure
  ''
  + (lib.strings.optionalString clangStdenv.hostPlatform.isDarwin ''
    export MAC_LIBGIT2_INC="${libgit2}/include"
    export MAC_LIBGIT2_LIB="${libgit2}/lib"
    export LDFLAGS="-headerpad_max_install_names"
  '')
  + ''
    python3 ./setup.py egg_info
    ./build.sh\
      -prefix $out/lib\
      -with-qtbinding\
      -python "${lib.getExe python3}"\
      -ruby "${lib.getExe ruby}"\
      -qmake "${lib.getBin qt6Packages.qtbase}/bin/qmake"\
      -expert\
      -verbose\
      -dry-run
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    make -j$NIX_BUILD_CORES -C build-release PREFIX=$out
    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/bin
    make -C build-release install
    cp -r src/pymod/distutils_src/klayout.egg-info $out/lib/pymod/klayout-${version}.dist-info

    mkdir -p $python/${python3.sitePackages}
    ln -s $out/lib/pymod/klayout $python/${python3.sitePackages}/klayout
    ln -s $out/lib/pymod/pya $python/${python3.sitePackages}/pya
    ln -s $out/lib/pymod/klayout*.dist-info $python/${python3.sitePackages}/
  ''
  + (
    if clangStdenv.hostPlatform.isDarwin then
      ''
        cp $out/lib/klayout.app/Contents/MacOS/klayout $out/bin/
      ''
    else
      ''
        cp $out/lib/klayout $out/bin/
      ''
  );

  # The automatic Qt wrapper overrides makeWrapperArgs
  preFixup = lib.strings.optionalString clangStdenv.hostPlatform.isDarwin ''
    python3 ${./supporting/klayout/patch_binaries.py} $out/lib $out/lib/pymod/klayout $out/bin/klayout
  '';

  passthru = {
    inherit python3;

    withPythonPackages = buildPythonEnvForInterpreter {
      target = klayout;
      inherit lib;
      inherit buildEnv;
      inherit makeBinaryWrapper;
    };
  };

  meta = {
    description = "High performance layout viewer and editor with support for GDS and OASIS";
    license = with lib.licenses; [ gpl3Plus ];
    homepage = "https://www.klayout.de/";
    changelog = "https://www.klayout.de/development.html#${version}";
    platforms = with lib; platforms.linux ++ platforms.darwin;
  };
})
