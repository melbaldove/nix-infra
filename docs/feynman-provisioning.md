# Feynman Provisioning Plan

Feynman is the dedicated haeru production server on Hetzner Cloud.

## Phase 1: Base Infrastructure ✅

- [x] Provision Hetzner Cloud VPS (CCX13 - 2 vCPU, 8GB RAM, 80GB NVMe)
- [x] Deploy NixOS with nixos-anywhere
- [x] Configure UEFI boot with GRUB (efiInstallAsRemovable for Hetzner)
- [x] Set up disko for declarative disk partitioning (ESP + ext4 root)

## Phase 2: Networking ✅

- [x] Configure WireGuard VPN (wg-startup network, 10.0.1.3)
- [x] Add feynman as peer on Shannon's wg-startup
- [x] Encrypt WireGuard private key with agenix
- [x] Verify VPN connectivity to Shannon (10.0.1.1)

## Phase 3: Deployment Pipeline ✅

- [x] Add feynman to deploy.nodes in flake.nix
- [x] Configure deploy-rs with IP address (5.161.56.109)
- [x] Verify deployment from einstein works
- [x] Document agenix programmatic encryption (AGENTS.md)

## Phase 4: Haeru Services (TODO)

- [ ] Enable haeru-services NixOS module
- [ ] Enable haeru-observability NixOS module
- [ ] Configure haeru secrets (platform.env, brain.env, etc.)
- [ ] Set up PostgreSQL
- [ ] Set up Redis
- [ ] Set up RabbitMQ
- [ ] Set up Memgraph
- [ ] Deploy platform services
- [ ] Deploy brain services
- [ ] Configure Promtail for log shipping to Shannon
- [ ] Verify services via observability dashboard

## Server Details

- **Hostname:** feynman
- **Public IP:** 5.161.56.109
- **VPN IP:** 10.0.1.3 (wg-startup network)
- **Provider:** Hetzner Cloud
- **Location:** Ashburn, VA (us-east)
- **SSH Host Key:** `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLE89lhPvY7ZDVzLTVq2ZhVD8ypeVz8zXS8ZCYSk9SP`
