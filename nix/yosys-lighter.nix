# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
# Copyright (c) 2023 UmbraLogic Technologies LLC
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
  fetchFromGitHub,
  yosys,
  python3,
  rev ? "b8e7d4ece5d6e22ab62c03eead761c736dbcaf3c",
  rev-date ? "2023-09-29",
  sha256 ? "sha256-gftQwWrq7KVVQXfb/SThOvbEJK0DoPpiQ3f3X1thBiQ=",
}:
yosys.stdenv.mkDerivation (finalAttrs: {
  pname = "yosys-lighter";
  version = rev-date;

  dylibs = [ "lighter" ];

  src = fetchFromGitHub {
    owner = "aucohl";
    repo = "lighter";
    inherit rev;
    inherit sha256;
  };

  buildInputs = [
    yosys
    python3
  ];

  buildPhase = ''
    ${yosys}/bin/yosys-config --build lighter.so src/clock_gating_plugin.cc
  '';

  installPhase = ''
    mkdir -p $out/share/yosys/plugins
    cp lighter.so $out/share/yosys/plugins

    mkdir -p $out/bin
    cat << HD > $out/bin/lighter_files
    #!/bin/sh
    if [ "\$1" = "" ]; then
      echo "Usage: \$0 <scl>" >> /dev/stderr
      exit 1
    fi
    find $out/share/lighter_maps/\$1 -type f
    HD
    chmod +x $out/bin/lighter_files

    mkdir -p $out/share/lighter_maps
    cp -r platform/* $out/share/lighter_maps
    rm -rf $out/share/lighter_maps/**/*.lib
    rm -rf $out/share/lighter_maps/**/*_blackbox.v
  '';

  makeWrapperArgs = [
    "--prefix PATH : ${lib.makeBinPath finalAttrs.buildInputs}"
  ];

  meta = with lib; {
    description = "An automatic clock gating utility.";
    homepage = "https://github.com/AUCOHL/Lighter";
    license = licenses.asl20;
    platforms = platforms.all;
  };
})
