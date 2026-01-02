# nix-eda Flake API

nix-eda can be considered an extension to the upstream nixpkgs with fixed or
updated versions of electronic design automation (EDA) tools.

True to its consideration, the way nix-eda works is by adding packages to
nix-eda in the form of a [Nix Overlay](https://nixos.wiki/wiki/Overlays), which
is exposed as `nix-eda.overlays.default`.

nix-eda uses the "experimental" Flakes feature in Nix to provide a structured
approach to listing, exposing, and consuming packages from Nix repositories.

## High-level description

nix-eda, and dependent flakes, operate as such:

1. The `default` overlay introduces new binary and python package derivations.
1. `legacyPackages` is instantiated as an import of its input `nixpkgs` flake
   with the `nix-eda.overlays.default` flake applied.
   * `nix-eda.overlays.default` is always expected to be included by dependents
     separately and should NOT be composed into the `overlays.default` of any
     dependents.
   * Conversely, if your flake has a hard dependency on anything other than
     nix-eda, we recommend baking it into your `overlays.default`.
1. To maintain compatibility with more standard flake structures, `packages`
   re-exports one or more derivations as flake outputs.
  
## Helper Functions

nix-eda provides a number of non-standard helper functions to help with the
creation of dependent Flakes, ranked by importance:

* `forAllSystems`: Calls a lambda N times with each Nix system double currently
  supported by nix-eda (e.g. `x86_64-linux`), and returns a set where the key is
  the Nix system double and the value is the result of evaluating the lambda.
  
  ```nix
  legacyPackages = self.forAllSystems (
    system:
    import nixpkgs {
      inherit system;
      overlays = [self.overlays.default];
    }
  );
  ```
* `composePythonOverlay`: Provides a slightly more ergonomic method of composing
  extensions for Python packages.
  
  ```nix
  self.composePythonOverlay (pkgs': pkgs: pypkgs': pypkgs: let
    callPythonPackage = lib.callPackageWith (pkgs' // pypkgs');
  in {
    gdsfactory = callPythonPackage ./nix/gdsfactory.nix {};
  })
  ```
* `createDockerImage`: Adapted from
  [nix/docker.nix](https://raw.githubusercontent.com/NixOS/nix/master/docker.nix)
  — creates a Docker image with one or more nix packages globally installed,
  with a number of customization options not present in the upstream version.
  * This allows nix-eda-dependent packages to also provide a container image for
    those who are unwilling or unable to install Nix.

## Template and Examples

A template flake.nix file can be found in
[flake-template.nix](./flake-template.nix).

Here are a number of example repos using nix-eda:

* [fossi-foundation/ciel](https://github.com/fossi-foundation/ciel)
* [librelane/librelane](https://github.com/librelane/librelane)
