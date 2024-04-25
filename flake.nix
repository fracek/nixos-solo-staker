{
  description = "A bootable NixOS system for solo staking.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    agenix.url = "github:ryantm/agenix";
    ethereum.url = "github:nix-community/ethereum.nix";
    srvos.url = "github:nix-community/srvos";
  };

  outputs = { self, nixpkgs, flake-utils, ethereum, agenix, ... }@inputs:
    let
      nixosSystem = args: nixpkgs.lib.nixosSystem ({ specialArgs = { inherit inputs; }; } // args);
      system = "x86_64-linux";
      overlays = [ agenix.overlays.default ethereum.overlays.default ];
      pkgs = import nixpkgs {
        inherit system overlays;
      };
    in
    {
      nixosModules = {
        common = ./modules/common;
      };

      nixosConfigurations = {
        validator01 = nixosSystem {
          inherit pkgs;
          modules = [ ./hosts/validator01/configuration.nix ];
        };
      };
    } //
    (flake-utils.lib.eachDefaultSystem (system:
      {
        # format with `nix fmt`.
        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
      }
    ));
}
