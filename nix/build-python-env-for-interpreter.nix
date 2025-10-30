# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
# Copyright (c) 2024 UmbraLogic Technologies LLC
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
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
lib:
lib.makeOverridable (
  {
    target,
    lib,
    buildEnv,
    makeBinaryWrapper,
    # extra opts
    extraOutputsToInstall ? [ ],
    postBuild ? "",
    ignoreCollisions ? false,
    permitUserSite ? false,
    # Wrap executables with the given argument.
    makeWrapperArgs ? [ ],
  }:
  pkglist:
  let
    extraLibs = pkglist target.python3.pkgs;
  in
  # Create an executable of something that embeds Python with additional
  # packages in its specific Python environment.
  let
    env =
      let
        python3 = target.python3;
        paths = (python3.pkgs.requiredPythonModules (extraLibs ++ [ python3 ])) ++ [ target ];
      in
      buildEnv {
        name = "${target.name}-${python3.name}-env";

        inherit paths;
        inherit ignoreCollisions;
        extraOutputsToInstall = [ "out" ] ++ extraOutputsToInstall;

        nativeBuildInputs = [ makeBinaryWrapper ];

        postBuild =
          ''
            rm -rf "$out/bin"
            mkdir -p "$out/bin"

            LIBPY_OLD=$out/lib/${python3.libPrefix}
            LIBPY_NEW=$(echo $LIBPY_OLD | sed -e 's@/python@/${target.name}-python@')
            mv $LIBPY_OLD $LIBPY_NEW

            path=${target}
            if [ -d "$path/bin" ]; then
              cd "$path/bin"
              for prg in *; do
                if [ -f "$prg" ]; then
                  rm -f "$out/bin/$prg"
                  if [ -x "$prg" ]; then
                    makeWrapper "$path/bin/$prg" "$out/bin/$prg"\
                      --set NIX_PYTHONPREFIX "$out"\
                      --set NIX_PYTHONPATH "$LIBPY_NEW/site-packages"\
                      ${lib.optionalString (!permitUserSite) ''--set PYTHONNOUSERSITE "true"''}\
                      ${lib.concatStringsSep " " makeWrapperArgs}
                  fi
                fi
              done
            fi
            ls $out/bin
          ''
          + postBuild;

        meta =
          {
            mainProgram = target.meta.mainProgram or target.pname or target.name;
            description = "Python environment for ${target.name}";
          }
          // lib.attrsets.filterAttrs (
            k: v:
            builtins.elem k [
              "license"
              "platforms"
              "broken"
            ]
          ) target.meta;

        passthru = python3.passthru // {
          interpreter = "${env}/bin/${python3.executable}";
          inherit python3;
          env = target.stdenv.mkDerivation {
            name = "interactive-${target.name}-${python3.name}-environment";
            nativeBuildInputs = [ env ];

            buildCommand = ''
              echo >&2 ""
              echo >&2 "*** Python 'env' attributes are intended for interactive nix-shell sessions, not for building! ***"
              echo >&2 ""
              exit 1
            '';
          };
        };
      };
  in
  env
)
