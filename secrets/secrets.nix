let
  # SSH public keys for each host
  turing = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvRFinX32oEn1D4pBUmAZdmk+LofsuMG9rpmv87U0at melbournebaldove@Turing.local";
  einstein = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbSfyESdV7Wr9zSHDbjLt2+/Fql3uEOEdxjhHvDDdmc";
  shannon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDS8buEp8SU2tKN/4ZNA8PLNiyJRKHwPoG1THgFx3lzT";
  newton = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJfIq1FgAcBRgqEom/w/WEIfBc81+CTUfdsAWvqZ72FU";

  # User keys (for managing secrets)
  user = turing; # Use turing's key for secret management
in
{
  # WireGuard private keys - each machine can only decrypt its own key
  "infrastructure/wireguard-einstein-private.age".publicKeys = [ user einstein ];
  "infrastructure/wireguard-shannon-private.age".publicKeys = [ user shannon ];
  "infrastructure/wireguard-shannon-startup-private.age".publicKeys = [ user shannon ];
  "infrastructure/wireguard-turing-private.age".publicKeys = [ user turing ];
  "infrastructure/wireguard-newton-private.age".publicKeys = [ user newton ];

  # Monitoring secrets
  "infrastructure/alertmanager-slack-nextdesk.age".publicKeys = [ user shannon ];
  "infrastructure/alertmanager-slack-haeru.age".publicKeys = [ user shannon ];
  
  # Backup secrets
  "infrastructure/restic-password.age".publicKeys = [ user newton shannon einstein ];
  
  # GitHub runner token for einstein
  "infrastructure/github-runner-token.age".publicKeys = [ user einstein ];
  
  # GitHub runner SSH key for einstein
  "infrastructure/github-runner-ssh-key.age".publicKeys = [ user einstein ];
}
