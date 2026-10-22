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

secret_names="$(nix eval --json --file secrets/secrets.nix \
  --apply 'secrets: builtins.attrNames secrets')"
jq -e 'all(.[]; startswith("infrastructure/wireguard-") | not)' \
  <<<"$secret_names" >/dev/null

if rg -n -i 'wireguard|10\.0\.0\.|10\.0\.1\.|172\.236\.148\.68|\bshannon\b|\bfeynman\b' \
  flake.nix \
  hosts/einstein \
  hosts/newton \
  modules/linux/default.nix; then
  exit 1
fi

echo "Retired network boundary: PASS"
