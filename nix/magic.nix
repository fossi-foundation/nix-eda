# SPDX-License-Identifier: MIT
# Copyright (c) 2025-2026 fossi-foundation/nix-eda contributors
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
  fetchGitHubSnapshot,
  libX11,
  m4,
  ncurses,
  tcl,
  tk-x11,
  cairo,
  python3,
  gnused,
  darwin,
  autoconf269,
  automake,
  version ? "8.3.669",
  rev ? null,
  sha256 ? "sha256-8XNM0GEu5IJn2ssDgVxIGUvSZHTyP9Bk63XbXA8sSRQ=",
}:
clangStdenv.mkDerivation {
  pname = "magic-vlsi";
  inherit version;

  src = fetchGitHubSnapshot {
    owner = "RTimothyEdwards";
    repo = "magic";
    rev = if rev == null then version else rev;
    hash = sha256;
  };

  nativeBuildInputs = [
    python3
    gnused
    # autoconf and automake are just to ease development, there's a configure
    # checked into magic source control
    autoconf269
    automake
    m4
  ]
  ++ lib.optionals clangStdenv.isDarwin [ darwin.autoSignDarwinBinariesHook ];

  buildInputs = [
    libX11
    ncurses
    tcl
    tk-x11
    cairo
  ];

  preConfigure = ''
    # nix shebang fix
    patchShebangs ./scripts

    # "Precompute" git rev-parse HEAD
    substituteInPlace ./scripts/defs.mak.in\
      --replace-fail '$(shell git rev-parse HEAD)' $(cat .gitcommit)
  '';

  configureFlags = [
    "--with-tcl=${tcl}"
    "--with-tk=${tk-x11}"
  ];

  NIX_CFLAGS_COMPILE = "-std=gnu99 -Wno-deprecated-non-prototype -Wno-implicit-function-declaration -Wno-parentheses -Wno-macro-redefined";

  fixupPhase = ''
    sed -i "13iexport CAD_ROOT='$out/lib'" $out/bin/magic
    patchShebangs $out/bin/magic
  '';

  meta = {
    mainProgram = "magic";
    description = "VLSI layout tool written in Tcl";
    homepage = "http://opencircuitdesign.com/magic/";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
