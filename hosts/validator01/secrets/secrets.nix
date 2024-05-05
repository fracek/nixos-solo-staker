let
  fra = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAIH585BI1nwwhzhoqHTUh2es8oNHKb2MzErN93hqiPI";
  users = [ fra ];

  host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM0nMxY1hOb+L6cIxoFfaA4g2OEOTQlkgVsyLf6Zj5HA";
in
{
  "tailscale.age".publicKeys = [ host ] ++ users;
  "password.age".publicKeys = [ host ] ++ users;
  "jwtsecret.age".publicKeys = [ host ] ++ users;
  "otel-env.age".publicKeys = [ host ] ++ users;
  "validator-env.age".publicKeys = [ host ] ++ users;
}
