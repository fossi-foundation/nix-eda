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
  version ? "0.69",
  rev ? null,
  sha256 ? "sha256-aoNEKpkxzwQWS5kCM4GC/ozwdXDARSXylp6S1vEA1/g=",
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
      pybind11
      click
      setuptools
      wheel
      build
    ]
  );
in
let
  cmakeFlagsCommon =
    debug:
    [
      (lib.cmakeBool "YOSYS_WITHOUT_READLINE" true)
      (lib.cmakeBool "YOSYS_WITH_PYTHON" true)
      (lib.cmakeBool "YOSYS_INSTALL_PYTHON" true)
      (lib.cmakeFeature "YOSYS_INSTALL_PYTHON_SITEDIR" (builtins.placeholder "python"))
    ]
    ++ lib.optionals debug [ (lib.cmakeFeature "CMAKE_CXX_FLAGS" "-g -O0") ];
  join_flags = lib.strings.concatMapStrings (x: " \"${x}\" ");
  self = clangStdenv.mkDerivation (finalAttrs: {
    __structuredAttrs = true; # better serialization; enables spaces in cmakeFlags
    pname = "yosys";
    inherit version;

    outputs = [
      "out"
      "python"
    ];

    src = fetchGitHubSnapshot {
      owner = "yosyshq";
      repo = "yosys";
      rev = if rev == null then "v${version}" else "rev";
      hash = sha256;
    };

    postPatch = ''
      # default version code does way too much and I prefer +g<shortrev>
      # verisoning
      substituteInPlace cmake/YosysVersion.cmake \
        --replace-fail "yosys_extract_version" "yosys_extract_version_bk"
      cat <<'EOF' >> ./cmake/YosysVersion.cmake
      function(yosys_extract_version)
        include(YosysVersionData)
        set(YOSYS_VERSION_COMMIT "0")
        set(YOSYS_VERSION "${finalAttrs.version}${
          if rev == null then "" else "+g${lib.sources.shortRev rev}"
        }")
        file(READ "''${CMAKE_SOURCE_DIR}/.gitcommit" YOSYS_CHECKOUT_INFO)
        string(STRIP "''${YOSYS_CHECKOUT_INFO}" YOSYS_CHECKOUT_INFO)
        set(YOSYS_ORIGIN_INFO "")
        return(PROPAGATE
          YOSYS_VERSION_MAJOR
          YOSYS_VERSION_MINOR
          YOSYS_VERSION_COMMIT
          YOSYS_VERSION
          YOSYS_CHECKOUT_INFO
          YOSYS_ORIGIN_INFO
        )
      endfunction()
      EOF
    '';

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

    cmakeFlags = (cmakeFlagsCommon false) ++ [
      # tends to malfunction when you don't have git installed
      (lib.cmakeBool "YOSYS_SKIP_ABC_SUBMODULE_CHECK" true)
    ];

    doCheck = false;

    meta = {
      description = "Yosys Open SYnthesis Suite";
      license = [ lib.licenses.mit ];
      homepage = "https://www.yosyshq.com/";
      platforms = lib.platforms.all;
    };

    # Developer conveniences: these aliases/functions may be useful when
    # using this derivations development environment using `nix develop .#yosys`
    shellHook = ''
        alias ys-cmake-nix='cmake -DCMAKE_BUILD_TYPE=Release ${join_flags finalAttrs.cmakeFlags} -G Ninja'
        alias ys-cmake-debug='cmake -DCMAKE_BUILD_TYPE=Debug ${
          join_flags (
            cmakeFlagsCommon
              # debug:
              true
          )
        } -G Ninja'
        alias ys-cmake-release='cmake -DCMAKE_BUILD_TYPE=Release ${
          join_flags (
            cmakeFlagsCommon
              # debug:
              false
          )
        } -G Ninja'
        ys-mk-venv-wrapper() {
          if [ ! -f ./yosys ]; then
            return
          fi
          mkdir -p ./wrapped
          cat <<HD > ./wrapped/yosys
      #!${lib.getExe python3}
      import os
      import sys
      from pathlib import Path

      __here__ = Path(__file__).resolve().parent
      venv = __here__.parents[1] / "venv"
      env = os.environ.copy()
      env["PYTHONPATH"] = os.fspath(venv) + "/${python3.sitePackages}"
      exec = [__here__.parent / "yosys", "yosys"]
      if os.getenv("USE_LLDB") == "1":
        exec = ["lldb", "lldb", os.fspath(__here__.parent / "yosys"), "--"]
      os.execlpe(*exec, *sys.argv[1:], env)
      HD
          chmod +x ./wrapped/yosys
        }
    '';
  });
in
self
