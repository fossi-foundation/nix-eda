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
  xorg,
  m4,
  ncurses,
  tcl,
  tcsh,
  tk-x11,
  cairo,
  python3,
  gnused,
  version ? "8.3.572",
  rev ? null,
  sha256 ? "sha256-hszQXuQprW2mz6Rr9fW0AGY7QO8BG3JEi5NUhFFF3OQ=",
}:
clangStdenv.mkDerivation {
  pname = "magic-vlsi";
  inherit version;

  src = fetchFromGitHub {
    owner = "RTimothyEdwards";
    repo = "magic";
    rev = if rev == null then version else rev;
    inherit sha256;
  };

  nativeBuildInputs = [
    python3
    gnused
  ];

  buildInputs = [
    xorg.libX11
    m4
    ncurses
    tcl
    tk-x11
    cairo
  ];

  configureFlags = [
    "--with-tcl=${tcl}"
    "--with-tk=${tk-x11}"
    "--disable-werror"
  ];

  NIX_CFLAGS_COMPILE = "-Wno-implicit-function-declaration -Wno-parentheses -Wno-macro-redefined";

  preConfigure = ''
    # nix shebang fix
    patchShebangs ./scripts

    # "Precompute" git rev-parse HEAD
    sed -i 's@`git rev-parse HEAD`@${version}@' ./scripts/defs.mak.in
  '';

  fixupPhase = ''
    sed -i "13iexport CAD_ROOT='$out/lib'" $out/bin/magic
    patchShebangs $out/bin/magic
  '';

  meta = with lib; {
    mainProgram = "magic";
    description = "VLSI layout tool written in Tcl";
    homepage = "http://opencircuitdesign.com/magic/";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
  };
}
