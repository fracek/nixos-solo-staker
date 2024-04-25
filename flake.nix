{
  description = "A bootable NixOS system for solo staking.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    agenix.url = "github:ryantm/agenix";
    ethereum.url = "github:nix-community/ethereum.nix";
  };

  outputs = { self, nixpkgs, flake-utils, ethereum, agenix }@inputs:
    let
      system = "x86_64-linux";
      overlays = [ agenix.overlays.default ];
      pkgs = import nixpkgs {
        inherit system overlays;
      };
    in
    {
      # expose all modules in ./modules.
      nixosModules = builtins.listToAttrs
        (map
          (x:
            {
              name = x;
              value = import (./modules + "/${x}");
            }
          )
          (builtins.attrNames (builtins.readDir ./modules)));

      # each directory in ./machines is a host.
      nixosConfigurations = builtins.listToAttrs
        (map
          (x:
            {
              name = x;
              value = nixpkgs.lib.nixosSystem {
                inherit pkgs system;
                # Make inputs and the flake itself accessible as module parameters.
                # Technically, adding the inputs is redundant as they can be also
                # accessed with flake-self.inputs.X, but adding them individually
                # allows to only pass what is needed to each module.
                specialArgs = { flake-self = self; } // inputs;
                modules = [
                  (./machines + "/${x}/configuration.nix")
                  { imports = builtins.attrValues self.nixosModules; }
                  agenix.nixosModules.default
                  "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
                ];
              };
            }
          )
          (builtins.attrNames (builtins.readDir ./machines)));
    } //
    (flake-utils.lib.eachDefaultSystem (system:
      {
        # format with `nix fmt`.
        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
      }
    ));
}
