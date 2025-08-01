# Copyright 2025 nix-eda Contributors
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
# Code adapated from nixpkgs, original license follows
# ---
# Copyright (c) 2003-2025 Eelco Dolstra and the Nixpkgs/NixOS contributors
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
{
  lib,
  stdenv,
  fetchFromGitHub,
  perl,
  flex,
  bison,
  python3,
  autoconf,
  which,
  help2man,
  makeWrapper,
  systemc,
  git,
  numactl,
  coreutils,
  gdb,
  glibcLocales,
  version ? "5.038",
  rev ? null,
  sha256 ? "sha256-uPGVE7y3zm+5ZydGjd1+/kIjW+a5u6d+YzjUSE4KnCY=",
}:

stdenv.mkDerivation rec {
  pname = "verilator";
  inherit version;

  # Verilator gets the version from this environment variable
  # if it can't do git describe while building.
  VERILATOR_SRC_VERSION = "v${version}";

  src = fetchFromGitHub {
    owner = "verilator";
    repo = "verilator";
    rev =
      if rev == null
      then "v${version}"
      else rev;
    inherit sha256;
  };

  enableParallelBuilding = true;
  buildInputs = [
    perl
    systemc
    (python3.withPackages (
      pp: with pp; [
        distro
      ]
    ))
    # ccache
  ];
  nativeBuildInputs = [
    makeWrapper
    flex
    bison
    autoconf
    help2man
    git
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    gdb
  ];

  nativeCheckInputs = [
    which
    coreutils
    # cmake
    python3
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    numactl
  ];

  doCheck = true;
  checkTarget = "test";

  preConfigure = "autoconf";

  postPatch = ''
    patchShebangs bin/* src/* nodist/* docs/bin/* examples/xml_py/* \
    test_regress/{driver.py,t/*.{pl,pf}} \
    test_regress/t/t_a1_first_cc.py \
    test_regress/t/t_a2_first_sc.py \
    ci/* ci/docker/run/* ci/docker/run/hooks/* ci/docker/buildenv/build.sh
    # verilator --gdbbt uses /bin/echo to test if gdb works.
    substituteInPlace bin/verilator --replace-fail "/bin/echo" "${coreutils}/bin/echo"
  '';
  # grep '^#!/' -R . | grep -v /nix/store | less
  # (in nix-shell after patchPhase)

  # This is needed to ensure that the check phase can find the verilator_bin_dbg.
  preCheck = ''
    export PATH=$PWD/bin:$PATH
  '';

  env = {
    SYSTEMC_INCLUDE = "${lib.getDev systemc}/include";
    SYSTEMC_LIBDIR = "${lib.getLib systemc}/lib";
  };

  postInstall = lib.optionalString stdenv.isLinux ''
    for x in $(ls $out/bin/verilator*); do
      wrapProgram "$x" --set LOCALE_ARCHIVE "${glibcLocales}/lib/locale/locale-archive"
    done
  '';

  meta = with lib; {
    description = "Fast and robust (System)Verilog simulator/compiler and linter";
    homepage = "https://www.veripool.org/verilator";
    license = with licenses; [
      lgpl3Only
      artistic2
    ];
    platforms = platforms.unix;
  };
}
