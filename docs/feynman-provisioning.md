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
- [x] Configure deploy-rs with VPN IP (10.0.1.3)
- [x] Verify deployment from einstein works
- [x] Document agenix programmatic encryption (AGENTS.md)
- [x] Restrict SSH to VPN only (disable public SSH)

## Phase 4: Haeru Services (TODO)

### 4.1 Secrets Configuration
- [ ] Create prod/ secrets subdirectory
- [ ] Update secrets.nix with feynman and prod entries
- [ ] Generate self-created credentials (DB password, JWT secret, etc.)
- [ ] Create prod secret files with placeholders
- [ ] Fill in external API keys (see Manual Tasks below)

### 4.2 Service Deployment
- [ ] Enable haeru-services NixOS module
- [ ] Enable haeru-observability NixOS module
- [ ] Set up PostgreSQL
- [ ] Set up Redis
- [ ] Set up RabbitMQ
- [ ] Set up Memgraph
- [ ] Deploy platform services
- [ ] Deploy brain services
- [ ] Configure Promtail for log shipping to Shannon
- [ ] Verify services via observability dashboard

## Manual Tasks (User)

These require manual creation in external services:

### AWS S3
- [ ] Create S3 bucket: `haeru-prod-bucket` in us-east-1
- [ ] Create IAM user with S3 access, get `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- [ ] Set up CloudFront CDN for `cdn.haeru.app`

### AI/ML API Keys
- [ ] Groq API key: https://console.groq.com
- [ ] OpenAI API key: https://platform.openai.com
- [ ] OpenRouter API key: https://openrouter.ai
- [ ] FAL API key: https://fal.ai
- [ ] ZAI API key

### Firebase (new prod project recommended)
- [ ] Create Firebase project for production
- [ ] Enable Authentication
- [ ] Generate service account JSON
- [ ] Note: `GOOGLE_SERVER_CLIENT_ID` and `GOOGLE_CLIENT_ID_*` come from Google Cloud Console OAuth

### RevenueCat
- [ ] Create prod app in RevenueCat dashboard
- [ ] Get `REVENUECAT_SECRET_API_KEY`
- [ ] Get `REVENUECAT_WEBHOOK_AUTH_HEADER_VALUE`

### Google OAuth (for Console)
- [ ] Create OAuth 2.0 credentials in Google Cloud Console
- [ ] Get `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` for console app

## Server Details

- **Hostname:** feynman
- **Public IP:** 5.161.56.109
- **VPN IP:** 10.0.1.3 (wg-startup network)
- **Provider:** Hetzner Cloud
- **Location:** Ashburn, VA (us-east)
- **SSH Host Key:** `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLE89lhPvY7ZDVzLTVq2ZhVD8ypeVz8zXS8ZCYSk9SP`
