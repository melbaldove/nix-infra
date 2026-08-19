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

fail2ban_allowlist="$(nix eval --json \
  .#nixosConfigurations.einstein.config.services.fail2ban.ignoreIP)"
jq -e 'index("100.64.0.0/10") != null' <<<"$fail2ban_allowlist" >/dev/null
jq -e 'index("10.0.0.0/24") == null and index("10.0.1.0/24") == null' \
  <<<"$fail2ban_allowlist" >/dev/null

echo "Einstein Tailscale configuration: PASS"
