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
#
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
  symlinkJoin,
  clangStdenv,
  pkg-config,
  cmake,
  makeWrapper,
  boost,
  python3,
  bison,
  flex,
  tcl,
  libedit,
  libbsd,
  libffi,
  zlib,
  fetchurl,
  bash,
  version ? "0.54",
  sha256 ? "sha256-meKlZh6ZiiPHwQCvS7Y667lvE9XWgIaual8c6SDpeDw=",
  darwin, # To fix codesigning issue for pyosys
  # For environments
  yosys,
  buildEnv,
  buildPythonEnvForInterpreter,
  makeBinaryWrapper,
}: let
  boost-python = boost.override {
    python = python3;
    enablePython = true;
  };
  yosys-python3-env = python3.withPackages (ps: with ps; [click setuptools wheel]);
  site-packages = yosys-python3-env.sitePackages;
in let
  self = clangStdenv.mkDerivation (finalAttrs: {
    pname = "yosys";
    inherit version;

    outputs = ["out" "python"];

    src = fetchurl {
      url = "https://github.com/YosysHQ/yosys/releases/download/v${version}/yosys.tar.gz";
      inherit sha256;
    };

    unpackPhase = ''
      tar -xzvC . -f ${finalAttrs.src}
    '';

    nativeBuildInputs = [
      pkg-config
      bison
      flex
    ] ++ lib.optionals clangStdenv.isDarwin [darwin.autoSignDarwinBinariesHook];

    propagatedBuildInputs = [
      tcl
      libedit
      libbsd
      libffi
      zlib
      boost-python
    ];

    buildInputs = [
      yosys-python3-env
    ];

    passthru = {
      inherit python3;
      python3-env = yosys-python3-env;
      withPlugins = plugins: let
        paths = lib.closePropagation plugins;
        dylibs = lib.lists.flatten (map (n: n.dylibs) plugins);
      in let
        module_flags = with builtins;
          concatStringsSep " "
          (map (so: "--add-flags -m --add-flags ${so}") dylibs);
      in (symlinkJoin {
        pname = "${yosys.pname}-with-plugins";
        version = yosys.version;
        paths = paths ++ [yosys];
        nativeBuildInputs = [makeWrapper];
        postBuild = ''
          cat <<SCRIPT > $out/bin/with_yosys_plugin_env
          #!${bash}/bin/bash
          export NIX_YOSYS_PLUGIN_DIRS='$out/share/yosys/plugins'
          exec "\$@"
          SCRIPT
          chmod +x $out/bin/with_yosys_plugin_env
          cp $out/bin/yosys $out/bin/yosys_with_plugins
          wrapProgram $out/bin/yosys \
            --set NIX_YOSYS_PLUGIN_DIRS $out/share/yosys/plugins
          wrapProgram $out/bin/yosys_with_plugins \
            --set NIX_YOSYS_PLUGIN_DIRS $out/share/yosys/plugins \
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

    makeFlags = [
      "PRETTY=0"
      "PREFIX=${placeholder "out"}"
      "ENABLE_READLINE=0"
      "ENABLE_EDITLINE=1"
      "ENABLE_YOSYS=1"
      "ENABLE_PYOSYS=1"
      "PYTHON_DESTDIR=${placeholder "python"}/${site-packages}"
      "BOOST_PYTHON_LIB=${boost-python}/lib/libboost_${python3.pythonAttr}${clangStdenv.hostPlatform.extensions.sharedLibrary}"
    ];

    patches = [
      ./patches/yosys/plugin-search-dirs.patch
    ];

    postPatch = ''
      substituteInPlace ./Makefile \
        --replace 'echo UNKNOWN' 'echo ${version}'

      chmod +x ./misc/yosys-config.in
      set -x
    '';

    postInstall = ''
      python3 ./setup.py dist_info -o $python/${site-packages}
    '';

    doCheck = false;
    enableParallelBuilding = true;

    meta = with lib; {
      description = "Yosys Open SYnthesis Suite";
      license = with licenses; [mit];
      homepage = "https://www.yosyshq.com/";
      platforms = platforms.all;
    };
  });
in
  self
