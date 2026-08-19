# Tailscale Replaces WireGuard Design

## Goal

Melbourne must be able to use OpenSSH from Turing to Einstein and Eisenhower when the computers are on different local networks. Tailscale will provide the private network. OpenSSH will continue to authenticate each SSH session.

The completed system will not depend on Shannon as a VPN hub. Shannon and Feynman will be removed because their data can be discarded. Jena and Lemuel will lose their old WireGuard access and will not join the tailnet as part of this work.

## Inspected State

This design uses these repository snapshots:

- `/Users/melbournebaldove/nix-infra` on `main` at `8fbd089c09541692eebb673c109d1882a1b1bb8d`.
- `/Users/melbournebaldove/.dotfiles` on `main` at `430e34faae162641318aa3b8f678a237e787e43f`.

The `.dotfiles` checkout is 32 commits ahead of `origin/main` and has an existing change in `claude/settings.json`. The migration must preserve that change. Work must stay on the existing `main` checkouts. The implementation must not create a branch or worktree.

At 2026-08-19 12:42 PST, Turing had address `192.168.50.233`. LAN SSH succeeded to Eisenhower at `192.168.50.140` and Einstein at `192.168.50.141`. Both hosts returned the expected hostname and operating system.

Turing runs the standalone Tailscale Mac application and is online in the current tailnet. Eisenhower has Homebrew Tailscale `1.96.4`, but its service is stopped. It has no Tailscale application, system extension, or active daemon. The old Eisenhower tailnet node was last seen on 2026-05-18.

## Target System

The remaining hosts are:

- Turing, which runs the standalone Tailscale Mac application.
- Einstein, which runs the NixOS `tailscaled` service and OpenSSH.
- Eisenhower, which runs the nix-darwin `tailscaled` service and OpenSSH.

Each remote host joins Melbourne's current tailnet through one user login. Device-key expiry will be disabled for Einstein and Eisenhower after enrollment. The design does not use tags, OAuth credentials, reusable auth keys, subnet routes, exit nodes, or Tailscale SSH.

Turing's SSH public key will remain the login credential. Einstein already declares that key. Eisenhower will declare the same key in its host configuration. Tailscale access rules must permit Turing to reach TCP port 22 on Einstein and Eisenhower.

LAN SSH remains available for local recovery. The normal remote path uses the host's Tailscale address and MagicDNS name.

## Migration Method

The migration will take place in one maintenance window while all remaining hosts are on the same LAN. It will use this order:

1. Add tests that describe the final network and host set.
2. Prepare the target configuration and the host-removal patch in both repositories.
3. Build the Einstein, Eisenhower, and Turing configurations without activating them.
4. Activate Einstein through LAN SSH and enroll it in Tailscale.
5. Activate Eisenhower through LAN SSH and enroll it in Tailscale.
6. Verify `tailscale ping` and normal OpenSSH from Turing to both Tailscale addresses.
7. Activate the WireGuard-free Turing configuration.
8. Remove Eisenhower's unused Homebrew Tailscale package after the Nix service works.
9. Remove the old offline Eisenhower identity from the tailnet after the replacement node works.
10. Remove Shannon, Feynman, and the WireGuard configuration from the repositories.
11. Build all remaining system configurations again.
12. Resolve the exact Shannon and Feynman cloud instances, show their identities, and delete them only after a final target check.

If Tailscale enrollment fails, the migration stops. LAN SSH remains the repair path. WireGuard and the cloud hosts stay in place until OpenSSH works over Tailscale to both hosts.

## `.dotfiles` Changes

Turing will stop importing `modules/system/darwin/wireguard-client.nix`. WireGuard packages and obsolete WireGuard setup or connectivity scripts will be removed. The Tailscale Mac application stays outside Nix because it is the appropriate interactive client for Turing.

Eisenhower will set `services.tailscale.enable = true` and will enable the nix-darwin OpenSSH service. Its user configuration will declare Turing's public key. The existing power and Wi-Fi recovery configuration will remain unchanged.

The Eisenhower evaluation test will check the `tailscaled` launch daemon, OpenSSH, and the authorized key. Repository documentation will describe Tailscale and the remaining hosts. It will not describe Shannon services or either WireGuard subnet.

## `nix-infra` Changes

Einstein will set `services.tailscale.enable = true` and open Tailscale's UDP port. Its existing OpenSSH service and Turing public key will remain.

The OpenClaw gateway will accept traffic on `tailscale0` instead of `wg0`. Its loopback forwarding rule will use `tailscale0`. No other service will become public as a result of the change.

Einstein's Nix cache has no remaining remote NixOS consumer. It will bind to loopback and will stop opening port 8081 on every interface. Einstein can continue to use the cache through `127.0.0.1`.

Promtail and node exporter currently depend on retired Shannon monitoring. Their Einstein imports and service-specific firewall rules will be removed. The GitHub runner and unrelated Einstein services will remain.

The NixOS configurations and deploy-rs nodes for Shannon and Feynman will be removed. Their host directories, known-host entries, and Feynman provisioning document will also be removed. The disabled Newton configuration will lose its WireGuard and Shannon references so that no dormant configuration keeps the old network.

WireGuard modules, flake exports, helper scripts, secret declarations, and encrypted WireGuard key files will be removed. Other encrypted secrets will remain unless they exist only for a retired service and are confirmed unused during implementation. Existing secrets must not be printed or decrypted into command output.

## Tailnet State

Einstein and Eisenhower will enroll as devices owned by Melbourne's user identity. Enrollment will use an interactive login URL or another one-use flow that does not store a reusable credential in either repository.

After each host is online, its device-key expiry will be disabled in the Tailscale administration interface. The old Eisenhower device entry will be removed only after the new node accepts OpenSSH. MagicDNS must resolve `einstein` and `eisenhower` to the new Tailscale nodes.

The tailnet will not manage SSH authentication. Standard Tailscale network policy will allow TCP port 22 from Turing to the two remote hosts. OpenSSH will verify Turing's key on each destination.

## Cloud Host Removal

Shannon and Feynman can be deleted with all data. The repository does not establish the current cloud-provider instance identity, so implementation must resolve each provider, account, instance identifier, hostname, and public address through read-only checks.

The deletion step must show the resolved targets before it changes provider state. It must not use a hostname or stored IP as the sole deletion selector. After deletion, the implementation will confirm that billing resources and instances no longer exist. The final report will state what was deleted and whether recovery is possible.

## Tests and Acceptance Criteria

Tests will first fail against the current configuration. They will then verify these properties:

- Einstein enables Tailscale and has no WireGuard interface.
- Eisenhower enables the system Tailscale daemon and OpenSSH.
- Turing does not import its WireGuard module.
- Shannon and Feynman are absent from NixOS configurations and deploy-rs.
- The remaining active configuration has no `10.0.0.0/24` or `10.0.1.0/24` dependency.
- The full Einstein, Eisenhower, and Turing system builds succeed.

Live acceptance requires all of these results:

- Turing reaches Einstein and Eisenhower with `tailscale ping`.
- The route to each `100.x` address uses Tailscale.
- `ssh einstein` and `ssh eisenhower` use OpenSSH and return the expected hostname and user.
- LAN SSH still works for local recovery.
- WireGuard interfaces and launch jobs are absent from the remaining hosts.
- The old Eisenhower tailnet identity is absent.
- Shannon and Feynman are absent from the provider account after the final approved deletion.

Repository builds do not prove live connectivity or provider deletion. The final report will keep build evidence, live host evidence, and provider evidence separate.

## Rollback

Before provider deletion, LAN SSH can activate the previous NixOS or nix-darwin generation on Einstein or Eisenhower. Turing can also return to its previous Darwin generation. The old WireGuard configuration remains recoverable from Git until the cloud hosts are deleted.

Provider deletion is the irreversible boundary. The process will not cross that boundary until Tailscale and OpenSSH work on both remaining remote hosts and the exact cloud targets have been verified.
