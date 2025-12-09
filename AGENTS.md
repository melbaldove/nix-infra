# nix-infra Agent Handbook

## Secrets Management with agenix

### Creating a new secret programmatically

The standard `agenix -e` command requires an interactive editor. To create secrets non-interactively (e.g., from Claude Code), use `age` directly:

```bash
# 1. First, add the secret entry to secrets/secrets.nix with the appropriate public keys
#    Example: "infrastructure/my-secret.age".publicKeys = [ user hostname ];

# 2. Write the secret content to a temporary file
echo "my-secret-value" > /tmp/secret-content.txt

# 3. Extract the public keys from secrets.nix and encrypt directly with age
nix-shell -p age --run 'cd secrets && age -e \
  -R <(grep -E "turing|hostname" secrets.nix | grep -oE "ssh-ed25519 [A-Za-z0-9+/=]+") \
  -o infrastructure/my-secret.age \
  /tmp/secret-content.txt'

# 4. Verify the encryption worked
cd secrets && nix run github:ryantm/agenix -- -d infrastructure/my-secret.age
```

### Why this works

- `agenix -e` uses `$EDITOR` which doesn't work well non-interactively due to stdin/sandbox issues
- Using `age` directly with `-R` (recipients file) bypasses the editor entirely
- The `grep` extracts ssh-ed25519 public keys from secrets.nix for the specified hosts
- Always verify with `agenix -d` to confirm the secret decrypts correctly

### Adding a new host's secret

1. Get the host's SSH public key: `ssh-keyscan -t ed25519 hostname | grep ed25519`
2. Add the key to `secrets/secrets.nix` in the `let` block
3. Add the secret entry with appropriate public keys
4. Encrypt using the method above
5. Reference in the host's NixOS config via `age.secrets.<name>.file`

## Deployment

Deploy to hosts using deploy-rs from einstein:

```bash
ssh einstein
cd /path/to/nix-infra
git pull
nix run github:serokell/deploy-rs -- .#hostname
```
