# Copyright 2025 nix-eda Contributors
#
# Adapted from efabless/nix-eda
#
# Copyright 2023 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# Code adapated from Nixpkgs, original license follows:
# ---
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
  libsForQt5,
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
  version ? "0.30.2",
  sha256 ? "sha256-jJnUVwcjqIZZFMYtJvRzGS1INrQ069Pi2vDekyif21M=",
  # Python environments
  klayout,
  buildPythonEnvForInterpreter,
}:
clangStdenv.mkDerivation {
  pname = "klayout";
  inherit version;

  outputs = ["out" "python"];

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
    (python3.withPackages (ps: with ps; [setuptools]))
    ruby
    gnused
    libsForQt5.wrapQtAppsHook
  ];

  buildInputs = with libsForQt5; [
    qtbase
    qtmultimedia
    qttools
    qtxmlpatterns
    curl
    gcc
    libgit2
    libpng
  ];

  propagatedBuildInputs = [
    ruby
  ];

  configurePhase =
    (lib.strings.optionalString clangStdenv.isDarwin ''
      export MAC_LIBGIT2_INC="${libgit2}/include"
      export MAC_LIBGIT2_LIB="${libgit2}/lib"
      export LDFLAGS="-headerpad_max_install_names"
    '')
    + ''
      python3 ./setup.py egg_info
      ./build.sh\
        -prefix $out/lib\
        -with-qtbinding\
        -python $(which python3)\
        -ruby $(which ruby)\
        -expert\
        -verbose\
        -dry-run
    '';

  buildPhase = ''
    echo "Using $NIX_BUILD_CORES threads…"
    make -j$NIX_BUILD_CORES -C build-release PREFIX=$out
  '';

  installPhase =
    ''
      mkdir -p $out/bin
      make -C build-release install
      cp -r src/pymod/distutils_src/klayout.egg-info $out/lib/pymod/klayout-${version}.dist-info

      mkdir -p $python/${python3.sitePackages}
      ln -s $out/lib/pymod/klayout $python/${python3.sitePackages}/klayout
      ln -s $out/lib/pymod/pya $python/${python3.sitePackages}/pya
      ln -s $out/lib/pymod/klayout*.dist-info $python/${python3.sitePackages}/
    ''
    + (
      if clangStdenv.isDarwin
      then ''
        cp $out/lib/klayout.app/Contents/MacOS/klayout $out/bin/
      ''
      else ''
        cp $out/lib/klayout $out/bin/
      ''
    );

  # The automatic Qt wrapper overrides makeWrapperArgs
  preFixup = lib.strings.optionalString clangStdenv.isDarwin ''
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

  meta = with lib; {
    description = "High performance layout viewer and editor with support for GDS and OASIS";
    license = with licenses; [gpl3Plus];
    homepage = "https://www.klayout.de/";
    changelog = "https://www.klayout.de/development.html#${version}";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
