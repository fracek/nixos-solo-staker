{ config, inputs, pkgs, ... }:
{
  imports = [
    ./security.nix
    ./users.nix
    inputs.srvos.nixosModules.server
  ];

  # users in trusted group are trusted by the nix-daemon
  nix.settings.trusted-users = [ "@trusted" ];
  users.groups.trusted = { };
}
