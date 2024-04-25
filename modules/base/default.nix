{ config, lib, pkgs, flake-self, nixpkgs, ethereum, ... }:
with lib;
let
  cfg = config.validator.base;
in
{
  options.validator.base = {
    enable = mkEnableOption "the base validator module";
  };

  config = mkIf cfg.enable {
    # Disable root login
    users.users.root.hashedPassword = "!";

    users.users.validator = {
      home = "/home/validator";
      createHome = true;
      isNormalUser = true;
      shell = pkgs.bash;
      extraGroups = [ "wheel" "networkmanager" "dialout" "libvirtd" ];
      passwordFile = config.age.secrets.hashedPassword.path;
    };

    # Set timezone and language.
    time.timeZone = "UTC";
    i18n.defaultLocale = "en_GB.UTF-8";

    environment.systemPackages = with pkgs; [
      age
      agenix
      curl
      git
      neovim
      tmux
      jq
    ];

    # Enable the OpenSSH server.
    services.openssh = {
      enable = true;
      ports = [
        9119
      ];
      openFirewall = true;
    };

    # Set the $NIX_PATH entry for nixpkgs. This is necessary in
    # this setup with flakes, otherwise commands like `nix-shell
    # -p pkgs.htop` will keep using an old version of nixpkgs.
    # With this entry in $NIX_PATH it is possible (and
    # recommended) to remove the `nixos` channel for both users
    # and root e.g. `nix-channel --remove nixos`. `nix-channel
    # --list` should be empty for all users afterwards
    nix.nixPath = [ "nixpkgs=${nixpkgs}" ];

    # Let 'nixos-version --json' know the Git revision of this flake.
    system.configurationRevision =
      lib.mkIf (flake-self ? rev) flake-self.rev;

    nix.registry = {
      nixpkgs.flake = nixpkgs;
      ethereum.flake = ethereum;
    };

    nix = {
      # Enable flakes
      package = pkgs.nixFlakes;
      extraOptions = ''
        experimental-features = nix-command flakes impure-derivations ca-derivations
      '';

      settings = {
        # Save space by hardlinking store files
        auto-optimise-store = true;
        # Users allowed to run nix
        allowed-users = [ "root" "validator" ];
      };

      # Clean up old generations after 30 days
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };
  };
}
