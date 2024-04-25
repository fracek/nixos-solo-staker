let
  t14s = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINNsv4+5x5zMaRzqyqJo1Jgepmhuly3j5/h+GzDxWSZ/ fra@t14s";
  systems = [ t14s ];
in
{
  "hashedPassword.age".publicKeys = [ ] ++ systems;
}
