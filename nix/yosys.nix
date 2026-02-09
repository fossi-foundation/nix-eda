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
  symlinkJoin,
  clangStdenv,
  pkg-config,
  makeWrapper,
  python3,
  bison,
  flex,
  tcl,
  libedit,
  libbsd,
  libffi,
  zlib,
  fetchurl,
  fetchGitHubSnapshot,
  bash,
  version ? "0.62",
  rev ? null,
  sha256 ? "sha256-cxxcb3F7mIFT0BSfTJgFm9luO7ypcE9SZGq32pfqQqo=",
  darwin, # To fix codesigning issue for pyosys
  # For environments
  yosys,
  buildEnv,
  buildPythonEnvForInterpreter,
  makeBinaryWrapper,
}:
let
  yosys-python3-env = python3.withPackages (
    ps: with ps; [
      cxxheaderparser
      pybind11_3
      click
      setuptools
      wheel
    ]
  );
  site-packages = yosys-python3-env.sitePackages;
in
let
  self = clangStdenv.mkDerivation (finalAttrs: {
    pname = "yosys";
    inherit version;

    outputs = [
      "out"
      "python"
    ];

    src =
      if rev != null then
        fetchGitHubSnapshot {
          owner = "yosyshq";
          repo = "yosys";
          inherit rev;
          hash = sha256;
          add-gitcommit = true;
        }
      else
        fetchurl {
          url = "https://github.com/YosysHQ/yosys/releases/download/v${version}/yosys.tar.gz";
          inherit sha256;
        };

    nativeBuildInputs = [
      pkg-config
      bison
      flex
    ]
    ++ lib.optionals clangStdenv.isDarwin [ darwin.autoSignDarwinBinariesHook ];

    propagatedBuildInputs = [
      tcl
      libedit
      libbsd
      libffi
      zlib
    ];

    buildInputs = [
      yosys-python3-env
    ];

    passthru = {
      inherit python3;
      python3-env = yosys-python3-env;
      withPlugins =
        plugins:
        let
          paths = lib.closePropagation plugins;
          dylibs = lib.lists.flatten (map (n: n.dylibs) plugins);
        in
        let
          module_flags =
            with builtins;
            concatStringsSep " " (map (so: "--add-flags -m --add-flags ${so}") dylibs);
        in
        (symlinkJoin {
          pname = "${yosys.pname}-with-plugins";
          version = yosys.version;
          paths = paths ++ [ yosys ];
          nativeBuildInputs = [ makeWrapper ];
          postBuild = ''
            cat <<SCRIPT > $out/bin/with_yosys_plugin_env
            #!${bash}/bin/bash
            export YOSYS_PLUGIN_PATH='$out/share/yosys/plugins'
            exec "\$@"
            SCRIPT
            chmod +x $out/bin/with_yosys_plugin_env
            cp $out/bin/yosys $out/bin/yosys_with_plugins
            wrapProgram $out/bin/yosys \
              --suffix YOSYS_PLUGIN_PATH : $out/share/yosys/plugins
            wrapProgram $out/bin/yosys_with_plugins \
              --suffix YOSYS_PLUGIN_PATH : $out/share/yosys/plugins \
              ${module_flags}
          '';
          inherit (yosys) passthru;
          meta = {
            mainProgram = "yosys_with_plugins";
          };
        });
      withPythonPackages = buildPythonEnvForInterpreter {
        target = yosys;
        inherit lib;
        inherit buildEnv;
        inherit makeBinaryWrapper;
      };
    };

    unpackPhase = ''
      runHook preUnpack
      if [ -d ${finalAttrs.src} ]; then
        cp -r ${finalAttrs.src}/* ${finalAttrs.src}/.* .
        chmod u+w -R .
      else
        tar -xzC . -f ${finalAttrs.src}
      fi
      runHook postUnpack
    '';

    configurePhase = ''
      runHook preConfigure
      CC=clang CXX=clang++ make config-clang
      runHook postConfigure
    '';

    makeFlags = [
      "PRETTY=0"
      "PREFIX=${placeholder "out"}"
      "ENABLE_READLINE=0"
      "ENABLE_EDITLINE=1"
      "ENABLE_YOSYS=1"
      "ENABLE_PYOSYS=1"
      "PYTHON_DESTDIR=${placeholder "python"}/${site-packages}"
      "PYOSYS_USE_UV=0"
    ];

    postInstall = ''
      python3 ./setup.py dist_info -o $python/${site-packages}
    '';

    doCheck = false;
    enableParallelBuilding = true;

    meta = {
      description = "Yosys Open SYnthesis Suite";
      license = [ lib.licenses.mit ];
      homepage = "https://www.yosyshq.com/";
      platforms = lib.platforms.all;
    };
  });
in
self
