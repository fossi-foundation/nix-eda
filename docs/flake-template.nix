# The nix-eda flake template
{
  inputs = {
    nix-eda.url = "github:fossi-foundation/nix-eda";

    # The following entries show how to incorporate other inputs without
    # having multiple nix-eda instances OR multiple nixpkgs instances.
    
    # To depend on another nix-eda-based flake:
    /* librelane = {
      url = "github:librelane/librelane";
      inputs.nix-eda.follows = "nix-eda";
    }; */
    
    # To depend on another nixpkgs-based flake:
    /* devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nix-eda/nixpkgs";
    }; */
  };

  outputs = {
    self,
    nix-eda,
    # don't forget to expose other inputs here if applicable…
    ...
  }: let
    nixpkgs = nix-eda.inputs.nixpkgs;
    lib = nixpkgs.lib;
  in {
    overlays = {
      default = lib.composeManyExtensions [
        (pkgs': pkgs: let
          callPackage = lib.callPackageWith pkgs';
        in {
            # Add binary derivations here
        })
        (
          nix-eda.composePythonOverlay (pkgs': pkgs: pypkgs': pypkgs: let
            callPythonPackage = lib.callPackageWith (pkgs' // pkgs'.python3.pkgs);
          in {
            # Add python package derivations here
          })
        )
      ];
    };

    legacyPackages = nix-eda.forAllSystems (
      system:
        import nix-eda.inputs.nixpkgs {
          inherit system;
          overlays = [nix-eda.overlays.default self.overlays.default];
        }
    );

    packages = nix-eda.forAllSystems (
      system: let
        pkgs = self.legacyPackages."${system}";
      in {
        # To be flakes-compatible, you also need to expose packages as follows:
        #   inherit (pkgs) mypackage;
        # And optionally, set a default package as well:
        #   default = pkgs.mypackage;
      }
    );

    devShells = nix-eda.forAllSystems (
      system: let
        pkgs = self.legacyPackages."${system}";
        callPackage = lib.callPackageWith pkgs;
      in {
      }
    );
  };
}
