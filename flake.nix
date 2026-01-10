# SPDX-License-Identifier: MIT
# Copyright (c) 2025 fossi-foundation/nix-eda contributors
# Copyright (c) 2024-2025 UmbraLogic Technologies LLC
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
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };
  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      lib = nixpkgs.lib;
    in
    {
      # Helper functions
      createDockerImage = import ./nix/create-docker.nix;
      composePythonOverlay = composable: pkgs': pkgs: {
        pythonPackagesExtensions = pkgs.pythonPackagesExtensions ++ [
          (composable pkgs' pkgs)
        ];
      };
      forAllSystems =
        fn:
        lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ] fn;

      # Common
      overlays = {
        default = lib.composeManyExtensions [
          (pkgs': pkgs: {
            buildPythonEnvForInterpreter = (import ./nix/build-python-env-for-interpreter.nix) lib;
            fetchGitHubSnapshot = lib.callPackageWith pkgs' ./nix/fetch_github_snapshot.nix { };
          })
          (self.composePythonOverlay (
            pkgs': pkgs: pypkgs': pypkgs:
            let
              callPythonPackage = lib.callPackageWith (pkgs' // pypkgs');
            in
            {
              pybind11_3 = callPythonPackage ./nix/pybind11_3.nix { };
              cocotb = callPythonPackage ./nix/cocotb.nix { };
              kfactory_1 = callPythonPackage ./nix/kfactory_1.nix { };
              gdsfactory = callPythonPackage ./nix/gdsfactory.nix { };
              gdstk = callPythonPackage ./nix/gdstk.nix { };
              tclint = callPythonPackage ./nix/tclint.nix { };
              antlr4_9-runtime = callPythonPackage ./nix/python3-antlr4-runtime.nix {
                antlr4 = pkgs'.antlr4_9;
              };
            }
          ))
          (
            pkgs': pkgs:
            let
              callPackage = lib.callPackageWith pkgs';
            in
            {
              # Dependencies
              ## Newer versions have worse performance with Yosys
              bitwuzla = callPackage ./nix/bitwuzla.nix { };

              ## Cairo X11 on Mac
              cairo = pkgs.cairo.override {
                x11Support = true;
              };

              ## slightly worse floating point errors cause ONE of the tests to fail
              ## on x86_64-darwin
              qrupdate = pkgs.qrupdate.overrideAttrs (
                self: super: {
                  doCheck = pkgs.stdenv.hostPlatform.system != "x86_64-darwin";
                }
              );

              ## repack ghdl binaries
              ## rationale: gnat is terribly broken in nixpkgs and i can't figure
              ##            out how to fix it.
              libgnat-bin = callPackage ./nix/libgnat-bin.nix { };
              ghdl-bin = callPackage ./nix/ghdl-bin.nix { };

              # Main
              magic = callPackage ./nix/magic.nix { };
              magic-vlsi = pkgs'.magic; # alias, there's a python package called magic
              netgen = callPackage ./nix/netgen.nix { };
              ngspice = callPackage ./nix/ngspice.nix { };
              klayout = callPackage ./nix/klayout.nix { };
              klayout-app = pkgs'.klayout; # alias, there's a python package called klayout (related) (thats also this)
              #
              iverilog = callPackage ./nix/iverilog.nix { };
              klayout-gdsfactory = callPackage ./nix/klayout-gdsfactory.nix { };
              tclFull = throw "'tclFull' has been removed starting nix-eda 6.0.0 – list [tcl tclPackages.tcllib tclPackages.tclx]";
              tk-x11 = callPackage ./nix/tk-x11.nix { };
              verilator = callPackage ./nix/verilator.nix { verilator = pkgs.verilator; };
              xschem = callPackage ./nix/xschem.nix { };
              xyce = callPackage ./nix/xyce.nix { };
              yosys = callPackage ./nix/yosys.nix { };
              yosys-sby = callPackage ./nix/yosys-sby.nix { };
              yosys-eqy = callPackage ./nix/yosys-eqy.nix { };
              yosys-lighter = callPackage ./nix/yosys-lighter.nix { };
              yosys-slang = callPackage ./nix/yosys-slang.nix { };
              yosys-ghdl = callPackage ./nix/yosys-ghdl.nix { };
            }
          )
          (self.composePythonOverlay (
            pkgs': pkgs: pypkgs': pypkgs:
            let
              callPythonPackage = lib.callPackageWith (pkgs' // pkgs'.python3.pkgs);
            in
            {
              pyosys = pypkgs'.toPythonModule (pkgs'.yosys.override { python3 = pypkgs'.python; }).python;
              klayout = pypkgs'.toPythonModule (pkgs'.klayout.override { python3 = pypkgs'.python; }).python;
            }
          ))
        ];
      };

      legacyPackages = self.forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        }
      );

      # Outputs
      formatter = self.forAllSystems (system: self.legacyPackages."${system}".nixfmt-tree);

      packages = self.forAllSystems (
        system:
        let
          pkgs = self.legacyPackages."${system}";
        in
        {
          yosysFull = pkgs.yosys.withPlugins (
            with pkgs;
            [
              yosys-sby
              yosys-eqy
              yosys-lighter
              yosys-slang
            ]
            ++ lib.optionals (lib.lists.any (el: el == system) pkgs.yosys-ghdl.meta.platforms) [ yosys-ghdl ]
          );
          inherit (pkgs)
            bitwuzla
            ghdl-bin
            iverilog
            klayout
            klayout-gdsfactory
            magic
            magic-vlsi
            netgen
            tk-x11
            verilator
            xschem
            xyce
            yosys
            yosys-sby
            yosys-eqy
            yosys-lighter
            yosys-slang
            yosys-ghdl
            ;
          inherit (pkgs.python3.pkgs)
            gdsfactory
            gdstk
            tclint
            cocotb
            ;
        }
      );
    };
}
