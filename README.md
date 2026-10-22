# nix-infra

NixOS infrastructure configuration for all servers. Managed declaratively with Nix flakes, deployed via [deploy-rs](https://github.com/serokell/deploy-rs), secrets encrypted with [agenix](https://github.com/ryantm/agenix).

## Hosts

| Host | Role |
|------|------|
| **einstein** | Application server and deployment hub |
| **newton** | NextDesk services *(currently disabled)* |

## Structure

```text
hosts/             # Per-host NixOS configurations
modules/
  shared/          # Core system and SSH keys
  infrastructure/  # Reusable service modules
  personal/        # Media server
  linux/           # Linux defaults and agenix setup
secrets/           # agenix-encrypted secrets
docs/              # Design and implementation records
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
