{ config, lib, ... }:
let
  userLib = import ./lib.nix { inherit lib; };
in
{
  users.users.fra = {
    openssh.authorizedKeys.keyFiles = [ ./keys/fra-danix ];
    hashedPasswordFile = config.age.secrets.password.path;

    useDefaultShell = true;
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "trusted"
    ];
    uid = userLib.mkUid "micc";
  };
}
