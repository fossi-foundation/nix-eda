# Copyright 2025 nix-eda Contributors
#
# Adapted from efabless/nix-eda
#
# Copyright 2024 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  };
  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    lib = nixpkgs.lib;
  in {
    # Helper functions
    createDockerImage = import ./nix/create-docker.nix;
    composePythonOverlay = composable: pkgs': pkgs: {
      pythonPackagesExtensions =
        pkgs.pythonPackagesExtensions
        ++ [
          (composable pkgs' pkgs)
        ];
    };
    flakesToOverlay = flakes: (
      lib.composeManyExtensions (builtins.map
        (flake: _: pkgs: flake.packages."${pkgs.stdenv.system}")
        flakes)
    );
    forAllSystems = fn:
      lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ]
      fn;

    # Common
    overlays = {
      default = lib.composeManyExtensions [
        (
          pkgs': pkgs: {
            buildPythonEnvForInterpreter = (import ./nix/build-python-env-for-interpreter.nix) lib;
            fetchGitHubSnapshot = lib.callPackageWith pkgs' ./nix/fetch_github_snapshot.nix {};
          }
        )
        (
          self.composePythonOverlay (pkgs': pkgs: pypkgs': pypkgs: let
            callPythonPackage = lib.callPackageWith (pkgs' // pypkgs');
          in {
            kfactory = pypkgs.kfactory.overrideAttrs (attrs': attrs: {
              version = "1.9.3";
              src = pypkgs'.fetchPypi {
                inherit (attrs') pname version;
                sha256 = "sha256-1HC+Ip+BbjbyjuYjF44DOLOglndvibd+grdAYzoLfHQ=";
              };
            });
            pyglet = callPythonPackage ./nix/pyglet.nix {};
            gdsfactory = callPythonPackage ./nix/gdsfactory.nix {};
            gdstk = callPythonPackage ./nix/gdstk.nix {};
            tclint = callPythonPackage ./nix/tclint.nix {};
            antlr4_9-runtime = callPythonPackage ./nix/python3-antlr4-runtime.nix {
              antlr4 = pkgs'.antlr4_9;
            };
          })
        )
        (pkgs': pkgs: let
          callPackage = lib.callPackageWith pkgs';
        in {
          # Dependencies
          ## Newer versions have worse performance with Yosys
          bitwuzla = callPackage ./nix/bitwuzla.nix {};

          ## Cairo X11 on Mac
          cairo = pkgs.cairo.override {
            x11Support = true;
          };

          ## slightly worse floating point errors cause ONE of the tests to fail
          ## on x86_64-darwin
          qrupdate = pkgs.qrupdate.overrideAttrs (self: super: {
            doCheck = pkgs.system != "x86_64-darwin";
          });

          # Main
          magic = callPackage ./nix/magic.nix {};
          magic-vlsi = pkgs'.magic; # alias, there's a python package called magic
          netgen = callPackage ./nix/netgen.nix {};
          ngspice = callPackage ./nix/ngspice.nix {};
          klayout = callPackage ./nix/klayout.nix {};
          klayout-app = pkgs'.klayout; # alias, there's a python package called klayout (related) (thats also this)
          #
          klayout-gdsfactory = callPackage ./nix/klayout-gdsfactory.nix {};
          tclFull = callPackage ./nix/tclFull.nix {};
          tk-x11 = callPackage ./nix/tk-x11.nix {};
          verilator = callPackage ./nix/verilator.nix {};
          xschem = callPackage ./nix/xschem.nix {};
          xyce = callPackage ./nix/xyce.nix {};
          yosys = callPackage ./nix/yosys.nix {};
          yosys-sby = callPackage ./nix/yosys-sby.nix {};
          yosys-eqy = callPackage ./nix/yosys-eqy.nix {};
          yosys-lighter = callPackage ./nix/yosys-lighter.nix {};
          yosys-slang = callPackage ./nix/yosys-slang.nix {};
          yosys-ghdl = callPackage ./nix/yosys-ghdl.nix {};
        })
        (
          self.composePythonOverlay (
            pkgs': pkgs: pypkgs': pypkgs: let
              callPythonPackage = lib.callPackageWith (pkgs' // pkgs'.python3.pkgs);
            in {
              pyosys = pypkgs'.toPythonModule (pkgs'.yosys.override {python3 = pypkgs'.python;}).python;
              klayout = pypkgs'.toPythonModule (pkgs'.klayout.override {python3 = pypkgs'.python;}).python;
            }
          )
        )
      ];
    };

    legacyPackages = self.forAllSystems (
      system:
        import nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
        }
    );

    # Outputs
    formatter = self.forAllSystems (
      system: self.legacyPackages."${system}".alejandra
    );

    packages = self.forAllSystems (
      system: let
        pkgs = self.legacyPackages."${system}";
      in
        {
          yosysFull = pkgs.yosys.withPlugins (with pkgs;
            [
              yosys-sby
              yosys-eqy
              yosys-lighter
              yosys-slang
            ]
            ++ lib.optionals (lib.lists.any (el: el == system) yosys-ghdl.meta.platforms) [yosys-ghdl]);
          inherit (pkgs) magic magic-vlsi netgen klayout klayout-gdsfactory tclFull tk-x11 verilator xschem ngspice bitwuzla yosys yosys-sby yosys-eqy yosys-lighter yosys-slang;
          inherit (pkgs.python3.pkgs) gdsfactory gdstk tclint;
        }
        // lib.optionalAttrs self.legacyPackages."${system}".stdenv.hostPlatform.isLinux {
          inherit (pkgs) xyce;
        }
        // lib.optionalAttrs self.legacyPackages."${system}".stdenv.hostPlatform.isx86_64 {
          inherit (pkgs) yosys-ghdl;
        }
    );
  };
}
