# SPDX-License-Identifier: MIT
# Copyright (c) 2026 fossi-foundation/nix-eda contributors
# Copyright (c) 2003-2026 Eelco Dolstra and the Nixpkgs/NixOS contributors
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
  stdenv,
  clangStdenv,
  fetchFromGitHub,
  bzip2,
  fetchurl,
  glib,
  gperf,
  gtk3,
  gtk-mac-integration,
  judy,
  pkg-config,
  tcl,
  tk,
  wrapGAppsHook3,
  xz,
  desktopToDarwinBundle,
  version ? "3.3.127",
  rev ? null,
  sha256 ? "sha256-h4SESGTjeD8vtLiLFSkIlnBVQfysQvxWp4E5nS1wu4Y=",
}:
stdenv.mkDerivation {
  pname = "gtkwave";
  inherit version;

  #src = fetchFromGitHub {
  #  owner = "gtkwave";
  #  repo = "gtkwave";
  #  rev = if rev == null then version else rev;
  #  inherit sha256;
  #};

  src = fetchurl {
    url = "mirror://sourceforge/gtkwave/gtkwave-gtk3-${version}.tar.gz";
    sha256 = "sha256-8Z2i20Oye7zGaXJYQ0UZRaaMOkziMlYuNB1vY7gLVeQ=";
  };

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook3
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    desktopToDarwinBundle
  ];
  buildInputs = [
    bzip2
    glib
    gperf
    gtk3
    judy
    tcl
    tk
    xz
  ]
  ++ lib.optional stdenv.hostPlatform.isDarwin gtk-mac-integration;

  configureFlags = [
    "--with-tcl=${tcl}/lib"
    "--with-tk=${tk}/lib"
    "--enable-judy"
    "--enable-gtk3"
  ];

  hardeningDisable = ["all"];

  postFixup = lib.optionalString stdenv.hostPlatform.isDarwin ''
    mv $out/bin/.gtkwave-wrapped $out/Applications/GTKWave.app/Contents/MacOS/.gtkwave-wrapped
    makeWrapper $out/Applications/GTKWave.app/Contents/MacOS/.gtkwave-wrapped $out/Applications/GTKWave.app/Contents/MacOS/GTKWave \
      --inherit-argv0 \
      "''${gappsWrapperArgs[@]}"
    ln -sf $out/Applications/GTKWave.app/Contents/MacOS/GTKWave $out/bin/gtkwave
  '';

  meta = {
    description = "VCD/Waveform viewer for Unix and Win32";
    homepage = "https://gtkwave.sourceforge.net";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
