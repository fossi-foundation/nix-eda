# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
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
  rustPlatform,
  fetchFromGitHub,
  version ? "24.0.1",
  rev ? null,
  sha256 ? "sha256-wZMZpg4X7yRVssGv8U6dupawTtzs7CLbYhaMBlxxBKo=",
}:
rustPlatform.buildRustPackage {
  pname = "openvaf-r";
  inherit version;

  src = fetchFromGitHub {
    owner = "OpenVAF";
    repo = "OpenVAF-Reloaded";
    rev = if rev == null then "v${version}mob" else rev;
    inherit sha256;
  };

  cargoHash = "sha256-+jvaiBCmjd3RrlES+Sc1SskEMOtO1ykOdInMTH/Gazo=";

  meta = with lib; {
    description = "OpenVAF Verilog-A compiler revived by community";
    homepage = "https://openvaf.semimod.de/";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
