# Installation Guide

Setting up nix-eda differs slightly based on whether you already have Nix or
not.

## I don't have Nix

```{warning}
Do not under any circumstances install Nix using your OS's package manager.

If you ran `sudo apt-get install nix`, follow this guide to uninstall Nix:

https://nix.dev/manual/nix/2.21/installation/uninstall#multi-user
```

Nix is available for systemd-based Linux (including Ubuntu, Debian, Fedora,
etc), macOS, and the Windows Subsystem for Linux with Nix enabled.

To install Nix, just run this command:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm --extra-conf "
    extra-substituters = https://nix-cache.fossi-foundation.org
    extra-trusted-public-keys = nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs=
"
```

And that's it. If you restart your terminal, you should have the Nix command
available.

To test whether the nix-eda cache has been set up correctly, run:

```bash
nix run github:fossi-foundation/nix-eda#yosys -- -V
```

If it prints the Yosys version without attempting to build Yosys first, you
have successfully set up nix-eda.

## I already have Nix

### In most cases…

You will need to update your Nix configuration to point to the FOSSi Foundation
Nix Cache, and also enable the allegedly experimental Nix commands and Flakes
features.

You can do this by typing:

```bash
sudo nano /etc/nix/nix.conf
```

and adding the following lines:

```ini
extra-experimental-features = nix-command flakes
extra-substituters = https://nix-cache.fossi-foundation.org
extra-trusted-public-keys = nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs=
```

Afterwards, you need to run `sudo pkill nix-daemon` so Nix picks up the new
settings.

To test, run the following:

```bash
nix run github:fossi-foundation/nix-eda#yosys -- -V
```

If it prints the Yosys version without attempting to build Yosys first, you
have successfully set up nix-eda.

### NixOS, or macOS with [nix-darwin](https://github.com/lnl7/nix-darwin)

You will need to update your Nix configuration to point to the FOSSi Foundation
Nix Cache, and also enable the allegedly experimental Nix commands and Flakes
features.

You can do that by adding these statements to your OS's derivation:

```nix
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://nix-cache.fossi-foundation.org"
      ];
      trusted-public-keys = [
        "nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs="
      ];
    };
  };
}
```

To test, run the following:

```bash
nix run github:fossi-foundation/nix-eda#yosys -- -V
```

If it prints the Yosys version without attempting to build Yosys first, you
have successfully set up nix-eda.
