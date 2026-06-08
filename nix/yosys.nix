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
  cmake,
  ninja,
  bash,
  version ? "0.66",
  rev ? "cc9692caab049f5cfbf3f84c64a74d11b6e4e5dc",
  sha256 ? "sha256-p+l0ao+uLLOt467wTvvxKpBkUelz9WS1v/eh1/5EM8k=",
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
      build
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
          url = "https://github.com/YosysHQ/yosys/releases/download/v${version}/yosys-src.tar.gz";
          inherit sha256;
        };

    nativeBuildInputs = [
      pkg-config
      bison
      flex
      cmake
      ninja
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

    cmakeFlags = [
      "-DYOSYS_WITH_PYTHON:BOOL=ON"
      "-DYOSYS_INSTALL_PYTHON:BOOL=ON"
      "-DYOSYS_INSTALL_PYTHON_SITEDIR=${builtins.placeholder "python"}"
    ];

    doCheck = false;

    meta = {
      description = "Yosys Open SYnthesis Suite";
      license = [ lib.licenses.mit ];
      homepage = "https://www.yosyshq.com/";
      platforms = lib.platforms.all;
    };
  });
in
self
