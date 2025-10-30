# ❄️ nix-eda

![A terminal running a command to create a shell with the tool xschem installed, then invoking xschem](./screenshot.png)

A [flake](https://nixos.wiki/wiki/Flakes) containing a collection of Nix
derivations for EDA (Electronic Design Automation) utilities.

> nix-eda is not affiliated with the NixOS Foundation or any of its affiliates.

We compile and cache the tools for the following platforms:

| Platform | Nix System Name |
| - | - |
| Linux (x86_64) | `x86_64-linux` |
| Linux (aarch64) | `aarch64-linux` |
| macOS (x86_64) | `x86_64-darwin` |
| macOS (arm64) | `aarch64-darwin` |

## Tools Included
* [Magic](http://opencircuitdesign.com/magic)
* [Netgen](http://opencircuitdesign.com/netgen)
* [ngspice](https://ngspice.sourceforge.io)
* [KLayout](https://klayout.de)
    * (+ `.python3.pkgs.klayout` for Python module)
* [GDSFactory](https://github.com/gdsfactory/gdsfactory)
    * (+ `klayout-gdsfactory` as a shorthand for an environment with both installed)
* [Verilator](https://verilator.org)
* [Icarus Verilog](https://github.com/steveicarus/iverilog)
* [cocotb](https://www.cocotb.org/)
* [Xschem](https://xschem.sourceforge.io/stefan/index.html)
* [Xyce](https://github.com/xyce/xyce)
    * Linux only.
* [Yosys](https://github.com/YosysHQ/yosys)
    * (+ `python3.pkgs.pyosys` for Python module)
    * (+ some plugins that can be accessed programmatically)
    * (`yosysFull` for all plugins)
    
> [!NOTE]  
> As of the time of writing, if you're using KLayout andgdsfactory for sky130
> PCells, the versions of klayout and gdsfactory in nix-eda 5.0.0+ are 
> incompatible as the PCells are out-of-date.
>
> You can pull the latest working version, nix-eda 4.3.1, (based on NixOS 24.05) 
> as follows:
>
> `nix shell github:fossi-foundation/nix-eda/4.3.1#klayout-gdsfactory`

## Installation

See [docs/installation.md](./docs/installation.md).

## Usage

You may use any of the tools by creating a Terminal shell with the tool as
follows:

```sh
nix shell github:fossi-foundation/nix-eda#magic
```

Then you would be able to simply type `magic`.

You may also create a shell with multiple tools as follows:

```sh
nix shell github:fossi-foundation/nix-eda#{magic,xschem}
```

### Flake API

See [docs/flake_api.md](./docs/flake_api.md).

## ⚖️ License and Legal

nix-eda is available under the MIT license. See 'License'.

Binary cache is hosted by the FOSSi Foundation.

nix-eda is based on [nix-eda](https://github.com/efabless/nix-eda) by Efabless
Corporation, whose assets are currently owned by UmbraLogic Technologies LLC.
UmbraLogic has agreed to relicense all code under the MIT license to be
compatible with upstream nixpkgs, for which we are grateful.

```
Copyright (c) 2025 UmbraLogic Technologies LLC:

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
``` 
