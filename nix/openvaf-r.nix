# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
{
  lib,
  rustPlatform,
  clangStdenv,
  llvm_21,
  clang,
  python3,
  rustfmt,
  fetchFromGitHub,
  version ? "24.0.1",
  rev ? null,
  sha256 ? "sha256-qIxvO+M32A8WlPSQ0WqZHfwiR9MmcBs0nbbfhQoqKLs=",
}:
(rustPlatform.buildRustPackage.override { stdenv = clangStdenv; }) {
  pname = "openvaf-r";
  inherit version;

  src = fetchFromGitHub {
    owner = "OpenVAF";
    repo = "OpenVAF-Reloaded";
    rev = if rev == null then "v${version}mob" else rev;
    inherit sha256;
    # submodules are required for tests and fetchGitHubSnapshot doesn't appear
    # to select the right commit. to be fixed?
    fetchSubmodules = true;
  };

  cargoHash = "sha256-+jvaiBCmjd3RrlES+Sc1SskEMOtO1ykOdInMTH/Gazo=";

  postPatch = ''
    # nix wrapper not compatible with --target flag
    sed -Ei.bak \
      -e 's@let compiler =.+@let compiler = "${clang.cc}/bin/clang";@' \
      openvaf/target/build.rs
    # nix wrapper not compatible with --target flag + actually may end up
    # escaping the sandbox and using a non-Nix clang on macOS
    substituteInPlace openvaf/osdi/build.rs \
      --replace-fail "{clang_path}" "${clang.cc}/bin/clang"
    # would have to get it in PATH otherwise
    substituteInPlace sourcegen/src/lib.rs\
      --replace-fail "rustfmt --config-path" "${rustfmt}/bin/rustfmt --config-path"
  '';

  nativeBuildInputs = [
    llvm_21 # make llvm-config available
  ];

  buildInputs = [
    llvm_21 # make libllvm linkable
    python3 # for pyo3
    rustfmt
  ];

  PYO3_PYTHON = "${python3}/bin/python3";

  cargoBuildFlags = [
    "--verbose"
    "--features=llvm21"
  ];
  cargoTestFlags = [
    "--verbose"
    "--features=llvm21"
  ];

  meta = {
    description = "OpenVAF Verilog-A compiler revived by community";
    homepage = "https://openvaf.semimod.de/";
    license = lib.licenses.gpl3;
    platforms = with lib.platforms; darwin ++ linux;
  };
}
