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
  libedit,
  libbsd,
  bitwuzla,
  zlib,
  yosys-sby,
  python3,
  makeBinaryWrapper,
  version ? "0.59",
  sha256 ? "sha256-dDDU3ld4e3CcqLzCwcV+AU2C8ZNFStRLpqlD3fIfdMw=",
}:
yosys.stdenv.mkDerivation (finalAttrs: {
  pname = "yosys-eqy";
  inherit version;

  dylibs = [
    "eqy_combine"
    "eqy_partition"
    "eqy_recode"
  ];

  src = fetchFromGitHub {
    owner = "yosyshq";
    repo = "eqy";
    rev = "v${version}";
    inherit sha256;
  };

  makeFlags = [
    "YOSYS_CONFIG=${yosys}/bin/yosys-config"
  ];

  nativeBuildInputs = [
    makeBinaryWrapper
  ];

  buildInputs = [
    yosys
    libedit
    libbsd
    bitwuzla
    zlib
    yosys-sby
    yosys.python3-env
  ];

  preConfigure = ''
    sed -i.bak "s@/usr/local@$out@" Makefile
    sed -i.bak "s@#!/usr/bin/env python3@#!${yosys.python3-env}/bin/python3@" src/eqy.py
    sed -i.bak "s@\"/usr/bin/env\", @@" src/eqy_job.py
  '';

  postInstall = ''
    cp examples/spm/formal_pdk_proc.py $out/bin/eqy.formal_pdk_proc
    chmod +x $out/bin/eqy.formal_pdk_proc
  '';

  checkPhase = ''
    runHook preCheck
    sed -i.bak "s@> /dev/null@@" tests/python/Makefile
    sed -i.bak "s/@//" tests/python/Makefile
    sed -i.bak "s@make -C /tmp/@make -C \$(TMPDIR)@" tests/python/Makefile
    make -C tests/python clean "EQY=${yosys.python3-env}/bin/python3 $PWD/src/eqy.py"
    make -C tests/python "EQY=${yosys.python3-env}/bin/python3 $PWD/src/eqy.py"
    runHook postCheck
  '';

  fixupPhase = ''
    runHook preFixup
    mv $out/bin/eqy $out/bin/.eqy-wrapped
    makeWrapper ${yosys.python3-env}/bin/python3 $out/bin/eqy\
      --add-flags "$out/bin/.eqy-wrapped"\
      --prefix PATH : ${lib.makeBinPath finalAttrs.buildInputs}
    runHook postFixup
  '';

  doCheck = true;

  meta = with lib; {
    description = "A front-end driver program for Yosys-based formal hardware verification flows.";
    homepage = "https://github.com/yosysHQ/eqy";
    mainProgram = "eqy";
    license = licenses.mit;
    platforms = platforms.all;
  };
})
