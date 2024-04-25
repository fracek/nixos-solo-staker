{ nixpkgs, pkgs, ... }:
{
  age.secrets.hashedPassword.file = ./secrets/hashedPassword.age;

  validator = {
    base.enable = true;
  };

  system.stateVersion = "23.11";
}
