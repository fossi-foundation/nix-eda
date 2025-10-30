# Contributing Code
We'd love to accept your patches and contributions to this project. There are
just a couple of guidelines you need to follow.

## Testing and Code Standards
Please build tools on at least x86_64-linux before submitting them.

The CI will attempt to build them for the other three platforms: x86_64-darwin,
aarch64-linux and aarch64-darwin, but if you have the capacity to test those
builds yourselves, it will greatly speed up the PR process.

Nix code must be formatted using `nixfmt-tree`: just run `nix fmt .`

## Submissions
Make your changes and then submit them as a pull requests to the `main` branch.

Consult [GitHub Help](https://help.github.com/articles/about-pull-requests/) for
more information on using pull requests.

## Licensing and Copyright

Please note all code contributions must have the same license as nix-eda, i.e.,
the standard MIT license as published by the Open-Source Initiative (OSI.)

You, as the submitter of the patch, are responsible for your patch, regardless\
of where that change came from; whether you:

1. Wrote it yourself and are willing to release your changes under said license.
2. Acquired it from other libre software with compatible license terms
   (and of course the requisite copyright notices.)
3. Created using coding assistants, "Generative AI" software, or similar tools.

For significant changes, please add either your or your employer's information
to [Authors.md](./Authors.md).
