# Contributing Code
We'd love to accept your patches and contributions to this project. There are
just a couple of guidelines you need to follow.

## Testing and Code Standards
Please build tools on at least x86_64-linux before submitting them.

The CI will attempt to build them for the other three platforms: x86_64-darwin,
aarch64-linux and aarch64-darwin, but if you have the capacity to test those
builds yourselves, it will greatly speed up the PR
process.

Nix code must be formatted using `alejandra`: `nix fmt .`

## Submissions
Make your changes and then submit them as a pull requests to the `main` branch.

Consult [GitHub Help](https://help.github.com/articles/about-pull-requests/) for
more information on using pull requests.

## Licensing and Copyright

Please add your name and email (and/or employer) to [Authors.md](./Authors.md).

We request that your changes be under the ISC/MIT License. 

We intend to eventually, when all Efabless Code is rewritten, relicense this
project under the ISC/MIT License in the hopes of upstreaming at least some of
these derivations to nixpkgs proper.
