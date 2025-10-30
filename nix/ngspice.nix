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
  fetchurl,
  flex,
  bison,
  fftw,
  withNgshared ? true,
  xorg,
  autoconf269,
  automake,
  libtool,
  readline,
  llvmPackages,
  version ? "44",
  sha256 ? "sha256-OGXROrRPHwH2jHrA4HFphORdzlqG0SZgPCbY3zAWHps=",
}:
clangStdenv.mkDerivation {
  pname = "ngspice";
  inherit version;

  src = fetchurl {
    url = "mirror://sourceforge/ngspice/ngspice-${version}.tar.gz";
    inherit sha256;
  };

  nativeBuildInputs = [
    flex
    bison
    autoconf269
    automake
    libtool
  ];

  buildInputs = [
    fftw
    xorg.libXaw
    xorg.libXext
    readline
    llvmPackages.openmp
  ];

  configureFlags = [
    "--with-x"
    "--enable-xspice"
    "--enable-cider"
    "--enable-predictor"
    "--enable-osdi"
    "--enable-klu"
    "--with-readline=${readline.dev}"
    "--enable-openmp"
  ];

  # This adds a dummy cpp file to ngspice_SOURCES, which forces automake to use
  # CXXLD as `-lstdc++` doesn't work on macOS -- feel free to replace this with
  # a more proper solution.
  preConfigure = ''
    set -x
    echo "" > src/dummy.cpp
    sed -i "s@\tngspice.c@\tngspice.c \\\\\n\tdummy.cpp@" ./src/Makefile.am
    autoreconf -i
    set +x
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "The Next Generation Spice (Electronic Circuit Simulator)";
    homepage = "http://ngspice.sourceforge.net";
    license = with licenses; [
      bsd3
      gpl2Plus
      lgpl2Plus
    ]; # See https://sourceforge.net/p/ngspice/ngspice/ci/master/tree/COPYING
    platforms = platforms.linux ++ platforms.darwin;
  };
}
