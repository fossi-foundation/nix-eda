# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
{
  lib,
  gtkwave,
  fetchurl,
  version ? "3.3.128",
  sha256 ? "sha256-gX4Zf8GAj4qsNUPCwvloPLATaMkRkrjq5a9YBw7x0fg=",
}:
gtkwave.overrideAttrs (
  attrs': attrs: {
    inherit version;
    src = fetchurl {
      url = "mirror://sourceforge/gtkwave/gtkwave-gtk3-${attrs'.version}.tar.gz";
      inherit sha256;
    };

    # disable judy because of bounds checking issue on newer
    # platforms
    configureFlags = (lib.strings.filter (x: x != "--enable-judy") attrs.configureFlags) ++ [
      "--disable-judy"
    ];
  }
)
