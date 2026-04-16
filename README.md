# nix-infra

NixOS infrastructure configuration for all servers. Managed declaratively with Nix flakes, deployed via [deploy-rs](https://github.com/serokell/deploy-rs), secrets encrypted with [agenix](https://github.com/ryantm/agenix).

## Hosts

| Host | Role |
|------|------|
| **shannon** | Application server (haeru services) |
| **einstein** | Application server (haeru amplify), deployment hub |
| **feynman** | General-purpose server (disko-provisioned) |
| **newton** | NextDesk services *(currently disabled)* |

## Structure

```
hosts/          # Per-host NixOS configurations
modules/
  shared/       # Core system, SSH keys, Promtail, node-exporter
  infrastructure/  # Grafana, Loki, Alertmanager, Restic backups, GitHub runner
  networking/   # WireGuard server & gateway
  personal/     # Media server
  linux/        # Linux-specific defaults, agenix setup
secrets/        # agenix-encrypted secrets
docs/           # Provisioning guides
```

## Key Dependencies

- **nixpkgs** (unstable) — base packages
- **deploy-rs** — push-based deployment
- **agenix** — secret management
- **home-manager** — user environment configs
- **disko** — declarative disk partitioning
- **dotfiles** — personal user configs ([melbaldove/dotfiles](https://github.com/melbaldove/dotfiles))
- **haeru** / **nextdesk-services** — application service modules (private)

## Deployment

Deploy from einstein via deploy-rs:

```bash
ssh einstein
cd /path/to/nix-infra
git pull
nix run github:serokell/deploy-rs -- .#<hostname>
```

## Secrets

Secrets are managed with agenix. See [AGENTS.md](AGENTS.md) for detailed instructions on creating and managing encrypted secrets.
