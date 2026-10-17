# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
{
  verilator,
  fetchFromGitHub,
  version ? "5.052",
  rev ? null,
  sha256 ? "sha256-3xeodLkal/crtcB091lthUe/7/wC+sjAYRqNyl7/kv0=",
}:
verilator.overrideAttrs (
  attrs': attrs: {
    inherit version;
    src = fetchFromGitHub {
      owner = "verilator";
      repo = "verilator";
      rev = if rev == null then "v${version}" else rev;
      inherit sha256;
    };
    patches = [ ];
    postPatch = ''
      patchShebangs bin/* src/* nodist/* docs/bin/* examples/xml_py/* \
      test_regress/{driver.py,t/*.{pl,pf,py}} \
      ci/* ci/docker/run/* ci/docker/run/hooks/* ci/docker/buildenv/build.sh
    '';
  }
)
