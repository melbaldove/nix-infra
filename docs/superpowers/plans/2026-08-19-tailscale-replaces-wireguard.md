# Tailscale Replaces WireGuard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let Turing use OpenSSH to reach Einstein and Eisenhower through Tailscale from any local network, then remove the old WireGuard configuration and retire Shannon and Feynman from the repositories.

**Architecture:** Tailscale supplies private IP connectivity and MagicDNS. OpenSSH continues to authenticate Turing with its existing Ed25519 key. Einstein runs the NixOS Tailscale service, Eisenhower runs the system nix-darwin Tailscale daemon, and Turing keeps the standalone Mac application.

**Tech Stack:** NixOS, nix-darwin, Home Manager, Tailscale, OpenSSH, Bash evaluation tests, deploy-rs configuration, agenix

**Spec:** `docs/superpowers/specs/2026-08-19-tailscale-replaces-wireguard-design.md`

## Global Constraints

- Work in `/Users/melbournebaldove/nix-infra` and `/Users/melbournebaldove/.dotfiles` on their existing `main` checkouts.
- Do not create a branch or worktree.
- Preserve the existing uncommitted `.dotfiles/claude/settings.json` change.
- Restore each repository's tracked `result` symlink after a build and before a commit.
- Keep Tailscale SSH disabled. Use normal OpenSSH.
- Do not add tags, OAuth credentials, reusable auth keys, subnet routes, or exit nodes.
- Keep LAN SSH available on Einstein and Eisenhower.
- Do not print secret values or private keys.
- Do not change `hy_staging_wg0`, `hy_prod_wg0`, Proton VPN, or the WireGuard Mac application that manages the Hey You tunnels.
- Do not change, stop, or delete the Shannon and Feynman provider resources. Melbourne will decommission both resources manually.
- Distinguish repository builds, live host checks, and cloud-provider evidence in the final report.

---

### Task 1: Configure Eisenhower and Turing for Tailscale OpenSSH

**Files:**
- Modify: `/Users/melbournebaldove/.dotfiles/hosts/eisenhower/tests/eval-test.sh`
- Modify: `/Users/melbournebaldove/.dotfiles/hosts/eisenhower/default.nix`
- Modify: `/Users/melbournebaldove/.dotfiles/users/melbournebaldove/core.nix`

**Interfaces:**
- Consumes: Turing public key `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvRFinX32oEn1D4pBUmAZdmk+LofsuMG9rpmv87U0at melbournebaldove@Turing.local`
- Produces: boot-time `com.tailscale.tailscaled`, macOS OpenSSH, and SSH aliases that resolve through `tail141ab8.ts.net`

- [ ] **Step 1: Protect the unrelated `.dotfiles` change**

Run:

```bash
cd /Users/melbournebaldove/.dotfiles
git status --short --branch
shasum -a 256 claude/settings.json > /tmp/tailscale-dotfiles-protected.sha256
```

Expected: `main` is 32 commits ahead of `origin/main`, and only `claude/settings.json` has an existing modification.

- [ ] **Step 2: Add failing Eisenhower and SSH-alias assertions**

Append these checks before the final success message in `hosts/eisenhower/tests/eval-test.sh`:

```bash
test "$(nix eval --json .#darwinConfigurations.eisenhower.config.services.tailscale.enable)" = true
test "$(nix eval --json .#darwinConfigurations.eisenhower.config.services.openssh.enable)" = true

tailscale_job="$(nix eval --json \
  .#darwinConfigurations.eisenhower.config.launchd.daemons.tailscaled.serviceConfig)"
jq -e '.Label == "com.tailscale.tailscaled" and .RunAtLoad == true' \
  <<<"$tailscale_job" >/dev/null

authorized_keys="$(nix eval --json \
  .#darwinConfigurations.eisenhower.config.users.users.melbournebaldove.openssh.authorizedKeys.keys)"
jq -e --arg key 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvRFinX32oEn1D4pBUmAZdmk+LofsuMG9rpmv87U0at melbournebaldove@Turing.local' \
  'index($key) != null' <<<"$authorized_keys" >/dev/null

test "$(nix eval --raw \
  .#darwinConfigurations.turing.config.home-manager.users.melbournebaldove.programs.ssh.matchBlocks.einstein.hostname)" = \
  einstein.tail141ab8.ts.net
test "$(nix eval --raw \
  .#darwinConfigurations.turing.config.home-manager.users.melbournebaldove.programs.ssh.matchBlocks.eisenhower.hostname)" = \
  eisenhower.tail141ab8.ts.net
```

- [ ] **Step 3: Run the test and verify the expected failure**

Run:

```bash
bash hosts/eisenhower/tests/eval-test.sh
```

Expected: FAIL because `services.tailscale.enable` is not `true`.

- [ ] **Step 4: Add Eisenhower services and Turing's public key**

Add this block to `hosts/eisenhower/default.nix` after `security.pam.services.sudo_local.touchIdAuth = true;`:

```nix
  services = {
    tailscale.enable = true;
    openssh.enable = true;
  };

  users.users.melbournebaldove.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvRFinX32oEn1D4pBUmAZdmk+LofsuMG9rpmv87U0at melbournebaldove@Turing.local"
  ];
```

- [ ] **Step 5: Add Tailscale SSH destinations to Home Manager**

Add these blocks under `programs.ssh.matchBlocks` in `users/melbournebaldove/core.nix`:

```nix
        "einstein" = {
          hostname = "einstein.tail141ab8.ts.net";
          user = "melbournebaldove";
          identityFile = "~/.ssh/id_ed25519";
          identitiesOnly = true;
        };
        "eisenhower" = {
          hostname = "eisenhower.tail141ab8.ts.net";
          user = "melbournebaldove";
          identityFile = "~/.ssh/id_ed25519";
          identitiesOnly = true;
        };
```

- [ ] **Step 6: Run the Eisenhower tests**

Run:

```bash
bash hosts/eisenhower/tests/eval-test.sh
bash hosts/eisenhower/tests/wifi-watchdog-test.sh
```

Expected: both scripts print `PASS` and exit 0.

- [ ] **Step 7: Build both Darwin configurations without activation**

Run:

```bash
darwin-rebuild build --flake .#eisenhower
darwin-rebuild build --flake .#turing
git restore result
```

Expected: both commands exit 0.

- [ ] **Step 8: Confirm the unrelated file is unchanged and commit only this task**

Run:

```bash
shasum -a 256 -c /tmp/tailscale-dotfiles-protected.sha256
git diff --check
git add hosts/eisenhower/tests/eval-test.sh hosts/eisenhower/default.nix users/melbournebaldove/core.nix
git commit -m "feat: add Tailscale access to Eisenhower"
```

Expected: the checksum passes, and `claude/settings.json` is not staged.

---

### Task 2: Remove WireGuard from the declarative Darwin configuration

**Files:**
- Modify: `/Users/melbournebaldove/.dotfiles/hosts/eisenhower/tests/eval-test.sh`
- Modify: `/Users/melbournebaldove/.dotfiles/hosts/turing/default.nix`
- Modify: `/Users/melbournebaldove/.dotfiles/users/melbournebaldove/dev.nix`
- Modify: `/Users/melbournebaldove/.dotfiles/AGENTS.md`
- Modify: `/Users/melbournebaldove/.dotfiles/CLAUDE.md`
- Delete: `/Users/melbournebaldove/.dotfiles/modules/system/darwin/wireguard-client.nix`
- Delete: `/Users/melbournebaldove/.dotfiles/scripts/generate-wireguard-keys.sh`
- Delete: `/Users/melbournebaldove/.dotfiles/scripts/setup-wireguard-agenix-darwin.sh`
- Delete: `/Users/melbournebaldove/.dotfiles/scripts/test-vpn-connectivity.sh`

**Interfaces:**
- Consumes: working Tailscale configuration from Task 1
- Produces: Darwin configurations with no declarative WireGuard dependency

- [ ] **Step 1: Add a failing repository-boundary assertion**

Add this check before the success message in `hosts/eisenhower/tests/eval-test.sh`:

```bash
if rg -n -i 'wireguard|10\.0\.0\.|10\.0\.1\.|shannon|feynman' \
  hosts/turing \
  modules/system/darwin \
  users/melbournebaldove/dev.nix \
  scripts \
  AGENTS.md \
  CLAUDE.md; then
  exit 1
fi
```

- [ ] **Step 2: Run the test and verify the expected failure**

Run:

```bash
bash hosts/eisenhower/tests/eval-test.sh
```

Expected: FAIL and print current WireGuard or retired-host references.

- [ ] **Step 3: Remove the WireGuard import and package**

Remove this import from `hosts/turing/default.nix`:

```nix
    ../../modules/system/darwin/wireguard-client.nix
```

Remove `wireguard-tools` from `users/melbournebaldove/dev.nix`.

- [ ] **Step 4: Delete the obsolete module and scripts**

Use `apply_patch` to delete the four files listed for deletion in this task. Keep `scripts/setup-darwin.sh`.

- [ ] **Step 5: Replace retired infrastructure notes**

In both `AGENTS.md` and `CLAUDE.md`, replace the stale structure comment, Linux deployment commands, Shannon service list, WireGuard network section, and monitoring section with this current text:

```markdown
hosts/         # Darwin host configs (turing, eisenhower)
modules/       # Shared Darwin system configs
users/         # User configs (melbournebaldove/)

Server configuration lives in `/Users/melbournebaldove/nix-infra`.

## Remote Access

- Tailscale supplies private connectivity between hosts.
- OpenSSH authenticates SSH sessions with the declared Ed25519 keys.
- `ssh einstein` and `ssh eisenhower` use their Tailscale MagicDNS names.
- LAN SSH remains available for local recovery.
```

- [ ] **Step 6: Run tests and build both hosts**

Run:

```bash
bash hosts/eisenhower/tests/eval-test.sh
bash hosts/eisenhower/tests/wifi-watchdog-test.sh
darwin-rebuild build --flake .#eisenhower
darwin-rebuild build --flake .#turing
git restore result
git diff --check
shasum -a 256 -c /tmp/tailscale-dotfiles-protected.sha256
```

Expected: all commands exit 0.

- [ ] **Step 7: Commit only the WireGuard cleanup**

Run:

```bash
git add hosts/eisenhower/tests/eval-test.sh hosts/turing/default.nix \
  users/melbournebaldove/dev.nix AGENTS.md CLAUDE.md \
  modules/system/darwin/wireguard-client.nix \
  scripts/generate-wireguard-keys.sh \
  scripts/setup-wireguard-agenix-darwin.sh \
  scripts/test-vpn-connectivity.sh
git commit -m "refactor: retire Darwin WireGuard configuration"
```

Expected: `claude/settings.json` remains modified and unstaged.

---

### Task 3: Move Einstein from WireGuard to Tailscale

**Files:**
- Create: `/Users/melbournebaldove/nix-infra/tests/einstein-tailscale-test.sh`
- Modify: `/Users/melbournebaldove/nix-infra/hosts/einstein/default.nix`

**Interfaces:**
- Consumes: NixOS Tailscale module from the pinned nixpkgs input
- Produces: Einstein Tailscale daemon, local-only Nix cache, and OpenClaw access through `tailscale0`

- [ ] **Step 1: Write the failing Einstein evaluation test**

Create `tests/einstein-tailscale-test.sh` with this content:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

test "$(nix eval --json .#nixosConfigurations.einstein.config.services.tailscale.enable)" = true
test "$(nix eval --json .#nixosConfigurations.einstein.config.services.tailscale.openFirewall)" = true

wireguard_interfaces="$(nix eval --json \
  .#nixosConfigurations.einstein.config.networking.wireguard.interfaces \
  --apply 'interfaces: builtins.attrNames interfaces')"
jq -e 'length == 0' <<<"$wireguard_interfaces" >/dev/null

test "$(nix eval --raw \
  .#nixosConfigurations.einstein.config.services.nix-serve.bindAddress)" = 127.0.0.1
test "$(nix eval --json \
  .#nixosConfigurations.einstein.config.services.nix-serve.openFirewall)" = false

tailscale_ports="$(nix eval --json \
  .#nixosConfigurations.einstein.config.networking.firewall.interfaces.tailscale0.allowedTCPPorts)"
jq -e 'index(18789) != null' <<<"$tailscale_ports" >/dev/null

nat_rules="$(nix eval --raw \
  .#nixosConfigurations.einstein.config.networking.firewall.extraCommands)"
grep -F -- '-i tailscale0 -p tcp --dport 18789' <<<"$nat_rules" >/dev/null

echo "Einstein Tailscale configuration: PASS"
```

Make the test executable:

```bash
chmod +x tests/einstein-tailscale-test.sh
```

- [ ] **Step 2: Run the test and verify the expected failure**

Run:

```bash
bash tests/einstein-tailscale-test.sh
```

Expected: FAIL because Tailscale is disabled.

- [ ] **Step 3: Replace Einstein's WireGuard import with Tailscale**

Remove these imports from `hosts/einstein/default.nix`:

```nix
    ../../modules/shared/promtail.nix
    ../../modules/networking/wireguard-gateway.nix
    ../../modules/shared/node-exporter.nix
```

Add this service block near the existing service declarations:

```nix
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
```

- [ ] **Step 4: Make the Einstein cache local-only**

Change the Nix cache configuration to:

```nix
  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    bindAddress = "127.0.0.1";
    port = 8081;
    openFirewall = false;
    secretKeyFile = config.age.secrets.nix-serve-cache.path;
  };

  nix.settings = {
    trusted-users = [ "root" "melbournebaldove" ];
    substituters = lib.mkAfter [ "http://127.0.0.1:8081" ];
    trusted-public-keys = lib.mkAfter [ "haeru-cache:m31dOHpFNZLXcN/Ts6luYMhDFvpqPjPBOkzioup9Q24=" ];
  };
```

Remove `monitoring.nodeExporter.listenAddress` and the retired Shannon or Feynman entries from `networking.extraHosts`.

- [ ] **Step 5: Move OpenClaw access to `tailscale0`**

Replace the WireGuard-specific block with:

```nix
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 18789 ];

  boot.kernel.sysctl."net.ipv4.conf.tailscale0.route_localnet" = 1;
  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -i tailscale0 -p tcp --dport 18789 -j DNAT --to-destination 127.0.0.1:18789
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t nat -D PREROUTING -i tailscale0 -p tcp --dport 18789 -j DNAT --to-destination 127.0.0.1:18789 2>/dev/null || true
  '';
```

- [ ] **Step 6: Run the Einstein test and evaluate the system closure**

Run:

```bash
bash tests/einstein-tailscale-test.sh
nix eval --raw .#nixosConfigurations.einstein.config.system.build.toplevel.drvPath
git diff --check
```

Expected: the test prints `PASS`, the evaluation prints one derivation path, and the diff check is clean.

- [ ] **Step 7: Commit Einstein's network replacement**

Run:

```bash
git add tests/einstein-tailscale-test.sh hosts/einstein/default.nix
git commit -m "feat: move Einstein access to Tailscale"
```

---

### Task 4: Retire Shannon, Feynman, and the remaining WireGuard code

**Files:**
- Create: `/Users/melbournebaldove/nix-infra/tests/retired-network-test.sh`
- Modify: `/Users/melbournebaldove/nix-infra/flake.nix`
- Modify: `/Users/melbournebaldove/nix-infra/hosts/newton/default.nix`
- Modify: `/Users/melbournebaldove/nix-infra/modules/infrastructure/github-runner.nix`
- Modify: `/Users/melbournebaldove/nix-infra/secrets/secrets.nix`
- Modify: `/Users/melbournebaldove/nix-infra/README.md`
- Delete: `/Users/melbournebaldove/nix-infra/hosts/shannon/default.nix`
- Delete: `/Users/melbournebaldove/nix-infra/hosts/shannon/hardware-configuration.nix`
- Delete: `/Users/melbournebaldove/nix-infra/hosts/feynman/default.nix`
- Delete: `/Users/melbournebaldove/nix-infra/hosts/feynman/disko-config.nix`
- Delete: `/Users/melbournebaldove/nix-infra/modules/networking/wireguard-server.nix`
- Delete: `/Users/melbournebaldove/nix-infra/modules/networking/wireguard-gateway.nix`
- Delete: `/Users/melbournebaldove/nix-infra/docs/feynman-provisioning.md`
- Delete: all six `/Users/melbournebaldove/nix-infra/secrets/infrastructure/wireguard-*.age` files

**Interfaces:**
- Consumes: working Einstein Tailscale configuration from Task 3
- Produces: one active NixOS host named Einstein and no active WireGuard network

- [ ] **Step 1: Write the failing retirement test**

Create `tests/retired-network-test.sh` with this content:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

nixos_hosts="$(nix eval --json .#nixosConfigurations \
  --apply 'outputs: builtins.attrNames outputs')"
jq -e '. == ["einstein"]' <<<"$nixos_hosts" >/dev/null

deploy_hosts="$(nix eval --json .#deploy.nodes \
  --apply 'outputs: builtins.attrNames outputs')"
jq -e '. == ["einstein"]' <<<"$deploy_hosts" >/dev/null

for retired_path in \
  hosts/shannon \
  hosts/feynman \
  modules/networking/wireguard-server.nix \
  modules/networking/wireguard-gateway.nix \
  docs/feynman-provisioning.md; do
  test ! -e "$retired_path"
done

if find secrets/infrastructure -maxdepth 1 -type f -name 'wireguard-*.age' | grep -q .; then
  exit 1
fi

if rg -n -i 'wireguard|10\.0\.0\.|10\.0\.1\.|172\.236\.148\.68|\bshannon\b|\bfeynman\b' \
  flake.nix \
  hosts/einstein \
  hosts/newton \
  modules/infrastructure/github-runner.nix; then
  exit 1
fi

echo "Retired network boundary: PASS"
```

Make the test executable:

```bash
chmod +x tests/retired-network-test.sh
```

- [ ] **Step 2: Run the test and verify the expected failure**

Run:

```bash
bash tests/retired-network-test.sh
```

Expected: FAIL because Shannon, Feynman, and WireGuard are still present.

- [ ] **Step 3: Remove retired outputs from `flake.nix`**

Delete the `nixosConfigurations.shannon` and `nixosConfigurations.feynman` blocks. Delete their `deploy.nodes` blocks. Remove the `wireguard-server` and `wireguard-gateway` exports. Keep Einstein, the disabled Newton comments, and reusable non-WireGuard module exports.

- [ ] **Step 4: Remove dormant WireGuard and Shannon monitoring from Newton**

From `hosts/newton/default.nix`, remove:

- The promtail and node-exporter imports.
- `networking.extraHosts` entries for Shannon and Einstein's old VPN address.
- The WireGuard secret and interface.
- Node exporter, cAdvisor, promtail overrides, and the `wg0` firewall block.
- The promtail Docker-group assignment.

Keep Newton disabled in `flake.nix`. Preserve its disk, restic, user, and application configuration.

- [ ] **Step 5: Remove retired GitHub runner host keys**

Keep only the two `github.com` keys in `modules/infrastructure/github-runner.nix`. Remove the Shannon, Feynman, `10.0.0.1`, and `10.0.1.3` lines and update the comment.

- [ ] **Step 6: Remove WireGuard secret declarations and files**

Delete the six WireGuard entries from `secrets/secrets.nix`. Keep the host public-key variables because non-WireGuard encrypted files still list Shannon as an existing recipient. Use `apply_patch` to delete each encrypted WireGuard file. Do not decrypt any secret.

- [ ] **Step 7: Delete retired host and module files**

Use `apply_patch` to delete the Shannon and Feynman host files, both WireGuard modules, and `docs/feynman-provisioning.md`.

- [ ] **Step 8: Update the repository overview**

Replace the host table and structure block in `README.md` with:

````markdown
## Hosts

| Host | Role |
|------|------|
| **einstein** | Application server, GitHub runner, and deployment hub |
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
````

- [ ] **Step 9: Run retirement and Einstein tests**

Run:

```bash
bash tests/retired-network-test.sh
bash tests/einstein-tailscale-test.sh
nix eval --raw .#nixosConfigurations.einstein.config.system.build.toplevel.drvPath
git diff --check
```

Expected: both tests print `PASS`, evaluation prints one derivation path, and the diff check is clean.

- [ ] **Step 10: Commit repository retirement**

Run:

```bash
git add tests/retired-network-test.sh flake.nix hosts modules/networking \
  modules/infrastructure/github-runner.nix secrets README.md docs/feynman-provisioning.md
git commit -m "refactor: retire WireGuard hosts and network"
```

---

### Task 5: Build and activate Einstein through LAN SSH

**Files:**
- Read: `/Users/melbournebaldove/nix-infra`
- Runtime target: `melbournebaldove@192.168.50.141`

**Interfaces:**
- Consumes: committed Einstein configuration from Tasks 3 and 4
- Produces: live NixOS `tailscaled`, active OpenSSH, and a new Einstein tailnet identity

- [ ] **Step 1: Recheck the LAN repair path and remote identity**

Run:

```bash
ping -c 2 192.168.50.141
ssh -o BatchMode=yes -o ConnectTimeout=5 192.168.50.141 \
  'hostname; whoami; uname -s; sudo -n true'
```

Expected: zero packet loss, then `einstein`, `melbournebaldove`, `Linux`, and exit 0.

- [ ] **Step 2: Stage the committed source without touching Einstein's existing checkout**

Run:

```bash
einstein_stage="$(ssh 192.168.50.141 'mktemp -d /tmp/tailscale-nix-infra.XXXXXX')"
case "$einstein_stage" in
  /tmp/tailscale-nix-infra.*) ;;
  *) exit 1 ;;
esac
git archive HEAD | ssh 192.168.50.141 "tar -x -C '$einstein_stage'"
```

Expected: `einstein_stage` is one new directory under `/tmp`, and the archive transfer exits 0.

- [ ] **Step 3: Build Einstein's full system on Einstein**

Run:

```bash
ssh 192.168.50.141 \
  "cd '$einstein_stage' && nix build .#nixosConfigurations.einstein.config.system.build.toplevel --no-link"
```

Expected: exit 0 with no evaluation or build failure.

- [ ] **Step 4: Activate the new NixOS generation**

Run:

```bash
ssh 192.168.50.141 \
  "cd '$einstein_stage' && sudo nixos-rebuild switch --flake .#einstein"
```

Expected: exit 0. The LAN SSH session remains available.

- [ ] **Step 5: Verify services before enrollment**

Run:

```bash
ssh 192.168.50.141 \
  'systemctl is-active sshd tailscaled; sudo tailscale status --json | jq -r .BackendState'
```

Expected: `active`, `active`, and either `NeedsLogin` or `Running`.

- [ ] **Step 6: Enroll Einstein**

Run:

```bash
ssh -t 192.168.50.141 'sudo tailscale up --hostname=einstein'
```

Expected: if authentication is required, the command prints one Tailscale login URL. Open that URL, sign in with the existing tailnet account, and wait for the command to complete. Do not create or store an auth key.

- [ ] **Step 7: Verify Einstein's tailnet state**

Run:

```bash
ssh 192.168.50.141 \
  'sudo tailscale status; sudo tailscale ip -4; systemctl is-active sshd tailscaled'
tailscale ping einstein
ssh -o HostName=einstein.tail141ab8.ts.net melbournebaldove@einstein hostname
```

Expected: Einstein has one `100.x` address, `tailscale ping` succeeds, both services are active, and OpenSSH prints `einstein`.

---

### Task 6: Build and activate Eisenhower through LAN SSH

**Files:**
- Read: `/Users/melbournebaldove/.dotfiles`
- Runtime target: `melbournebaldove@192.168.50.140`

**Interfaces:**
- Consumes: committed Darwin configuration from Tasks 1 and 2
- Produces: system `tailscaled`, Nix-managed OpenSSH, and a new Eisenhower tailnet identity

- [ ] **Step 1: Recheck Eisenhower and confirm the old Homebrew daemon is stopped**

Run:

```bash
ping -c 2 192.168.50.140
ssh -o BatchMode=yes -o ConnectTimeout=5 192.168.50.140 \
  'hostname; whoami; uname -s; sudo -n true; brew services info tailscale 2>/dev/null || true'
```

Expected: `eisenhower`, `melbournebaldove`, `Darwin`, successful passwordless sudo, and Homebrew Tailscale reports `Running: false`.

- [ ] **Step 2: Stage only the committed `.dotfiles` tree**

Run:

```bash
cd /Users/melbournebaldove/.dotfiles
shasum -a 256 -c /tmp/tailscale-dotfiles-protected.sha256
eisenhower_stage="$(ssh 192.168.50.140 'mktemp -d /tmp/tailscale-dotfiles.XXXXXX')"
case "$eisenhower_stage" in
  /tmp/tailscale-dotfiles.*) ;;
  *) exit 1 ;;
esac
git archive HEAD | ssh 192.168.50.140 "tar -x -C '$eisenhower_stage'"
```

Expected: the protected checksum passes and only committed files enter the staging directory.

- [ ] **Step 3: Build Eisenhower's full Darwin system**

Run:

```bash
ssh 192.168.50.140 \
  "cd '$eisenhower_stage' && darwin-rebuild build --flake .#eisenhower"
```

Expected: exit 0.

- [ ] **Step 4: Activate the new Darwin generation**

Run:

```bash
ssh 192.168.50.140 \
  "cd '$eisenhower_stage' && sudo darwin-rebuild switch --flake .#eisenhower"
```

Expected: exit 0 and LAN SSH remains available.

- [ ] **Step 5: Verify the system daemon and OpenSSH**

Run:

```bash
ssh 192.168.50.140 \
  'sudo launchctl print system/com.tailscale.tailscaled | head -40; \
   sudo launchctl print system/com.openssh.sshd | head -40; \
   sudo tailscale status --json 2>/dev/null | jq -r .BackendState || true'
```

Expected: both launchd jobs exist. Tailscale reports `NeedsLogin` or `Running`.

- [ ] **Step 6: Enroll Eisenhower**

Run:

```bash
ssh -t 192.168.50.140 'sudo tailscale up --hostname=eisenhower'
```

Expected: authenticate with the current tailnet account if a URL appears. Do not reuse the stopped Homebrew user's state file.

- [ ] **Step 7: Verify Eisenhower over Tailscale**

Run:

```bash
ssh 192.168.50.140 'sudo tailscale status; sudo tailscale ip -4'
eisenhower_tail_ip="$(ssh 192.168.50.140 'sudo tailscale ip -4' | head -1)"
case "$eisenhower_tail_ip" in 100.*) ;; *) exit 1 ;; esac
tailscale ping "$eisenhower_tail_ip"
ssh -o HostName="$eisenhower_tail_ip" melbournebaldove@eisenhower hostname
```

Expected: Eisenhower has one `100.x` address, the ping succeeds, and OpenSSH prints `eisenhower`. Use the address because the old offline node can temporarily cause a duplicate MagicDNS name.

- [ ] **Step 8: Remove the stopped Homebrew package and move its old state to Trash**

Run only after Step 7 passes:

```bash
ssh 192.168.50.140 'brew uninstall tailscale'
ssh 192.168.50.140 \
  'if test -d "$HOME/.local/share/tailscale"; then \
     mkdir -p "$HOME/.Trash"; \
     mv "$HOME/.local/share/tailscale" "$HOME/.Trash/tailscale-homebrew-state-20260819"; \
   fi'
```

Expected: the Nix daemon remains active because it runs from `/nix/store`; the old user state remains recoverable from Trash.

---

### Task 7: Activate Turing cleanup and verify the final network

**Files:**
- Runtime target: Turing
- Tailnet administration: current `melbournebaldove@gmail.com` tailnet

**Interfaces:**
- Consumes: working Einstein and Eisenhower tailnet nodes
- Produces: Turing with Tailscale-only private access and verified OpenSSH aliases

- [ ] **Step 1: Activate Turing's WireGuard-free Darwin configuration**

Run:

```bash
cd /Users/melbournebaldove/.dotfiles
sudo darwin-rebuild switch --flake .#turing
```

Expected: exit 0 and Tailscale remains online.

- [ ] **Step 2: Verify the retired personal tunnel without changing work VPNs**

Run:

```bash
scutil --nc list
test "$(scutil --nc status 'wg-personal' | head -1)" = Disconnected
test "$(scutil --nc status 'hy_staging_wg0' | head -1)" = Connected
tailscale status
```

Expected: `wg-personal` is disconnected, the active Hey You staging tunnel remains connected, and Tailscale reports `Running`. Do not infer tunnel ownership from a `10.0.0.0/16` route because the Hey You staging tunnel owns that route.

- [ ] **Step 3: Keep the WireGuard Mac application for Hey You access**

Do not stop or remove `/Applications/WireGuard.app`. It manages `hy_staging_wg0` and `hy_prod_wg0`, which are outside this migration. The retired personal dependency is removed by the repository changes and the disconnected `wg-personal` state.

- [ ] **Step 4: Verify both OpenSSH destinations through their Tailscale addresses**

Run:

```bash
einstein_tail_ip="$(ssh 192.168.50.141 'sudo tailscale ip -4' | head -1)"
eisenhower_tail_ip="$(ssh 192.168.50.140 'sudo tailscale ip -4' | head -1)"
case "$einstein_tail_ip" in 100.*) ;; *) exit 1 ;; esac
case "$eisenhower_tail_ip" in 100.*) ;; *) exit 1 ;; esac
tailscale ping "$einstein_tail_ip"
tailscale ping "$eisenhower_tail_ip"
route -n get "$einstein_tail_ip" | rg 'destination|interface'
route -n get "$eisenhower_tail_ip" | rg 'destination|interface'
ssh -o HostName="$einstein_tail_ip" melbournebaldove@einstein 'hostname; whoami'
ssh -o HostName="$eisenhower_tail_ip" melbournebaldove@eisenhower 'hostname; whoami'
```

Expected: both pings succeed, both routes use a Tailscale `utun` interface, and SSH prints `einstein` and `eisenhower`, each followed by `melbournebaldove`.

- [ ] **Step 5: Update tailnet device state with action-time confirmation**

Open the Tailscale Machines page. Resolve the new Einstein and Eisenhower rows by hostname and current `100.x` address. Immediately before each state-changing action, ask Melbourne for confirmation to:

- Disable key expiry for the new Einstein node.
- Disable key expiry for the new Eisenhower node.
- Delete only the old Eisenhower row whose last-seen time is 2026-05-18.

After confirmation, perform the three actions and reread the Machines page. If the new Eisenhower node has a numeric suffix because the old node used its name, run:

```bash
ssh 192.168.50.140 'sudo tailscale set --hostname=eisenhower'
```

Expected: the new nodes show key expiry disabled, only one Eisenhower identity remains, and its MagicDNS name is `eisenhower.tail141ab8.ts.net`.

- [ ] **Step 6: Verify MagicDNS aliases and LAN recovery separately**

Run:

```bash
tailscale ping einstein
tailscale ping eisenhower
ssh einstein 'hostname; whoami'
ssh eisenhower 'hostname; whoami'
ssh 192.168.50.141 'hostname; whoami'
ssh 192.168.50.140 'hostname; whoami'
```

Expected: the two MagicDNS pings and aliases work through Tailscale. Both LAN sessions also work.

- [ ] **Step 7: Run final repository verification**

Run:

```bash
cd /Users/melbournebaldove/nix-infra
bash tests/einstein-tailscale-test.sh
bash tests/retired-network-test.sh
nix eval --raw .#nixosConfigurations.einstein.config.system.build.toplevel.drvPath
git diff --check
git status --short --branch

cd /Users/melbournebaldove/.dotfiles
bash hosts/eisenhower/tests/eval-test.sh
bash hosts/eisenhower/tests/wifi-watchdog-test.sh
darwin-rebuild build --flake .#eisenhower
darwin-rebuild build --flake .#turing
git restore result
git diff --check
shasum -a 256 -c /tmp/tailscale-dotfiles-protected.sha256
git status --short --branch
```

Expected: all tests and builds exit 0. `nix-infra` is clean. `.dotfiles` contains only the original `claude/settings.json` modification.

---

### Task 8: Prepare the manual cloud-decommission handoff

**Files:**
- Read: `/Users/melbournebaldove/nix-infra/docs/feynman-provisioning.md` from Git history
- Read: `/Users/melbournebaldove/nix-infra/modules/networking/wireguard-gateway.nix` from Git history

**Interfaces:**
- Consumes: verified Tailscale replacement and retired repository configuration
- Produces: evidence for Melbourne's manual provider deletion

- [ ] **Step 1: Record Feynman's provider evidence**

Run:

```bash
git -C /Users/melbournebaldove/nix-infra show \
  8fbd089:docs/feynman-provisioning.md | \
  rg 'Provider|Public IP|Hostname'
whois 5.161.56.109 | rg -i 'netname|org-name|descr|origin' | head -20
```

Expected: repository evidence identifies Feynman at `5.161.56.109` on Hetzner Cloud, and public ownership data identifies Hetzner.

- [ ] **Step 2: Record Shannon's provider evidence**

Run:

```bash
git -C /Users/melbournebaldove/nix-infra show \
  8fbd089:modules/networking/wireguard-gateway.nix | \
  rg '172\.236\.148\.68'
whois 172.236.148.68 | rg -i 'NetName|OrgName|Country' | head -20
```

Expected: repository evidence identifies Shannon at `172.236.148.68`, and public ownership data identifies Akamai. Melbourne must confirm the matching Linode or Akamai Cloud instance in the correct account.

- [ ] **Step 3: Give Melbourne the manual deletion checklist**

Report these exact checks without opening a deletion flow:

```text
Feynman: Hetzner Cloud, hostname feynman, public IPv4 5.161.56.109.
Shannon: Akamai or Linode, hostname shannon, public IPv4 172.236.148.68.
For each provider: confirm account, instance ID, hostname, and public IPv4 before deletion.
All instance data can be discarded. Provider deletion is not recoverable unless the provider offers a separate snapshot.
```

- [ ] **Step 4: Report final evidence boundaries**

The final response must list:

- Repository commits and clean or preserved-dirty status.
- Full build and test results.
- Live Tailscale addresses, pings, OpenSSH results, and LAN recovery results.
- Tailnet state changes that were confirmed and completed.
- Feynman and Shannon provider evidence for Melbourne's manual decommission.
- A clear statement that no provider instance was changed or deleted.
