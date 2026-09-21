---
title: Private Server Runbook
description: Provision external state and verify the GL702ZC private services without confusing builds with activation.
type: runbook
status: experimental
tags:
  - self-hosting
  - gl702zc
  - operations
source-files:
  - hosts/gl702zc/server.nix
  - hosts/gl702zc/media.nix
---

# Private Server Runbook

Use this with [[services/private-server|GL702ZC Private Server]] and
[[runbooks/media-ingest|Media Transfer and Ingest]]. Configuration builds are
non-activating; service deployment and archive indexing are separate actions.

## Provision secrets before activation

Create the private directory outside the repository and Nix store:

```bash
sudo install -d -o root -g root -m 0700 /var/lib/private-server-secrets
sudoedit /var/lib/private-server-secrets/photoprism-admin-password
sudoedit /var/lib/private-server-secrets/searx.env
sudo chown root:root /var/lib/private-server-secrets/photoprism-admin-password /var/lib/private-server-secrets/searx.env
sudo chmod 0600 /var/lib/private-server-secrets/photoprism-admin-password /var/lib/private-server-secrets/searx.env
```

The PhotoPrism file contains only the chosen initial admin password (8–72
characters). Systemd loads it as a credential for the pre-start and main process.
It initializes the `admin` account; changing this file later is not a supported
substitute for changing an existing account's password in PhotoPrism.

The SearXNG file contains `SEARX_SECRET_KEY=` followed by a random hexadecimal
value, on one line, without spaces. Generate the value locally with
`openssl rand -hex 32`, then paste it into the file; never paste it into Nix.
Hex avoids quoting/JSON-escaping problems in the module's environment substitution.
These files are mandatory: missing credentials/environment files prevent startup.
Do not copy them into the repository to make a build pass.

When rotating SearXNG's key later, restart `searx-init.service` and then
`searx.service` so `/run/searx/settings.yml` is regenerated. Changing an external
file alone does not change the Nix derivation or reload it.

## Complete external NetBird/DNS state

In the NetBird control plane, manually:

1. Confirm the GL702ZC peer's unattended-server login/expiration policy. Avoid
   interactive expiry that would strand the machine.
2. Retain the private zone `home.arpa` and the working
   `immich.home.arpa -> 100.72.185.137` record.
3. Add `photoprism.home.arpa` and `search.home.arpa`, also pointing at
   `100.72.185.137`, and distribute this private DNS configuration to the intended
   client group.
4. Confirm peer access policies permit the intended clients to reach TCP 80 and
   the existing OpenSSH service. Do not enable NetBird's separate SSH server.

These are cloud-managed settings, not fake NixOS options. GL702ZC's dynamic
Wi-Fi address must never be substituted into persistent private DNS records.
On Windows, AdGuard and ProtonVPN DNS handling previously interfered with the
private zone. Verify name resolution and routing independently; a successful
NetBird connection does not prove the Windows resolver uses its DNS policy.

## Validate a generation

From the repository root:

```bash
nix flake check path:.
nixos-rebuild build --flake path:.#gl702zc
```

`path:.` explicitly includes new, untracked working-tree files without changing
the Git index. With all source files tracked, `.#gl702zc` is also suitable.
The removed legacy `.#nixos` alias is not an output in this working tree.
The `result` symlink is a built generation, not the running system.

Inspect generated ingress and units:

```bash
nix shell path:.#nixosConfigurations.gl702zc.pkgs.caddy -c caddy adapt --config result/etc/caddy/caddy_config --adapter caddyfile
systemd-analyze verify result/etc/systemd/system/photoprism.service result/etc/systemd/system/searx.service result/etc/systemd/system/searx-init.service
```

Caddy validation also opens log destinations; before activation,
`caddy validate` without root can fail solely because `/var/log/caddy` does not
yet exist. Do not mistake that for a routing/parser error.

For PhotoPrism, verify the unit has `BindReadOnlyPaths=/srv/media`,
`ProtectSystem=strict`, `ReadWritePaths=/var/lib/photoprism`,
`Group=media`, no `SupplementaryGroups=media`, and one nonempty `LoadCredential`
for the password.
There must be no trailing empty `LoadCredential=` clearing it. Inspection of a
built unit establishes intended sandbox configuration, not running enforcement.

### Validation evidence

During the 2026-09-20 cleanup, `nix flake check path:.` and the GL702ZC build
passed. The generated Immich server and ML units were byte-for-byte identical
to the running units. Package-path comparisons confirmed all intended stable/
unstable selections. The legacy `nixos` build failed because that output is absent;
no shared Nix module changed, so no desktop build was required.

All 31 ingest tests passed without root, including the actual group-change tests.
A disposable user systemd service using the same read-only-bind/strict-filesystem
boundary could read a fixture, received `EROFS` on create/modify/delete attempts,
and could write its state directory. Generated PhotoPrism units were inspected
separately; this was not a write probe against the archive or a test as the future
dynamic PhotoPrism user.

An exact privileged identity probe used a disposable group-`media` directory and
file with archive-representative 0750/0640 permissions. With `DynamicUser=true`,
`PrivateUsers=true`, and `SupplementaryGroups=media`, systemd mapped the
supplementary group and fixture group to `nogroup`/65534. With `Group=media`, the
dynamic user had primary GID 987 (`media`) and read the fixture successfully.
The generated service therefore uses the static primary group and retains both
`DynamicUser=true` and `PrivateUsers=true`.

PhotoPrism's module-equivalent migration command and HTTP startup succeeded with
temporary SQLite/originals paths and a dummy test password. SearXNG also returned
HTTP 200 with temporary settings. Caddy's generated configuration adapted and
validated with only log destinations redirected into temporary storage.
The deployed firewall, production credentials, service startup under the full
system sandbox, lid behavior and cable-absent client access remain post-activation
checks. The working Immich endpoint still returned `pong`; nothing was activated.

## Activation and NetworkManager transition

Activate only during a deliberate deployment window after secret provisioning.
This changes services and may run native module database migrations. Do not use
`nixos-rebuild test` as a harmless check of stateful services. The normal switch
removes the socket proxy and starts Caddy; if port 80 is busy afterward, inspect
the old `immich-http-proxy.socket`/service before restarting anything.

The declarative Ethernet profile has higher autoconnect priority than the earlier
ad-hoc profile, but loading a profile does not replace an already active one.
After activation, from a local console or NetBird session **not carried over
Ethernet**, these commands change the live Ethernet connection and remove the
obsolete ad-hoc profile:

```bash
nmcli connection show
nmcli connection up gl702zc-direct
ip -brief address show enp6s0
ip route
nmcli connection show 'Wired connection 1'
```

After confirming `gl702zc-direct` works, remove only the inspected obsolete
profile (its UUID was observed on this machine, not inferred from hardware):

```bash
nmcli connection delete uuid 38401994-ddcc-379d-8008-b775bbd10b65
```

Expect `10.42.0.2/24`, a connected route for `10.42.0.0/24`, and the default route
still through Wi-Fi. The desktop end remains a manual client-side prerequisite.

NixOS avoids automatically restarting logind. Its changed lid/idle settings may
therefore wait until a planned reboot or explicit logind restart. A logind
restart can disrupt graphical sessions: schedule it, then verify the effective
policy before relying on closing the lid. A successful build alone proves
neither the live power behavior nor that the new profile is active.

## Verify after deployment

On GL702ZC, inspect service state, listening sockets, and logs without starting
archive jobs:

```bash
systemctl status caddy immich-server immich-machine-learning photoprism searx searx-init netbird
ss -lnt
curl --fail http://127.0.0.1:2283/api/server/ping
curl --fail --resolve immich.home.arpa:80:127.0.0.1 http://immich.home.arpa/api/server/ping
curl --fail --resolve photoprism.home.arpa:80:127.0.0.1 http://photoprism.home.arpa/
curl --fail --resolve search.home.arpa:80:127.0.0.1 http://search.home.arpa/
journalctl -u caddy -u photoprism -u searx -u searx-init -n 80 --no-pager
netbird status
```

Expected backends listen only on `127.0.0.1:2283`, `127.0.0.1:2342` and
`127.0.0.1:8888`. Caddy listens on HTTP 80, with no automatic TLS/redirect.
From a NetBird client, verify the three ordinary names with the cable unplugged.
From the desktop, test Caddy over Ethernet without changing DNS:

```bash
curl --fail --resolve immich.home.arpa:80:10.42.0.2 http://immich.home.arpa/api/server/ping
```

From a separate Wi-Fi LAN client, verify HTTP and backend connections are blocked
using the laptop's **observed** DHCP address. Curl from GL702ZC to its own Wi-Fi
address does not establish the ingress firewall boundary.

Inspect the running PhotoPrism namespace read-only, with no archive write probe:

```bash
systemctl show photoprism -p MainPID -p DynamicUser -p Group -p SupplementaryGroups -p BindReadOnlyPaths -p ReadWritePaths -p ProtectSystem -p LoadCredential
pid=$(systemctl show photoprism -p MainPID --value)
sudo nsenter -t "$pid" -m -- findmnt -T /srv/media/stuff -o TARGET,VFS-OPTIONS,FS-OPTIONS
sudo nsenter -t "$pid" -m -- findmnt -T /var/lib/photoprism -o TARGET,VFS-OPTIONS,FS-OPTIONS
```

Expect the originals' VFS mount options to contain `ro`, and state to remain `rw`.
Do not try creating/deleting files in the real originals to test this property.
Begin a small, deliberately selected PhotoPrism **index** comparison only after
deployment verification; avoid bulk conversion and importing.

## Troubleshooting evidence

- **Immich metadata/ffprobe permission errors:** same-filesystem moves preserved
  `casua:users`, denying the `immich` account access. After group/mode repair,
  stale metadata was repaired by metadata reprocessing. Diagnose with `id`,
  `namei -l` and `stat` before attributing failures to codecs or ML.
- **One MP4 metadata integer overflow:** an extremely high-precision video time
  base overflowed a PostgreSQL integer during Immich extraction. A stream-copy
  remux with a sane video track timescale repaired that specific file. This is
  historical evidence, not a reason for automatic remuxing or changes to originals
  during validation. Inspect `ffprobe` output and work on a disposable copy if a
  similar case recurs.
- **Repeated Facial Recognition “Missing” jobs:** valid embedded faces can remain
  unassigned to a person cluster. That does not by itself mean inference failed.
  Correlate actual worker errors and clustering state before reprocessing.
- **ML Gunicorn permission errors:** preserve `HOME=/tmp` and the extended worker
  timeout. Inspect `journalctl -u immich-machine-learning`; its `/tmp` is private
  to the service.
- **Caddy 502:** check the corresponding backend unit and secret provisioning.
  Distinguish DNS failures from routing with `curl --resolve`.
- **PhotoPrism write errors under originals:** the sandbox is intentional. Its
  cache/database/sidecar paths must stay under its writable state directory.
  Check any UI-written `options.yml`, which can override environment settings;
  never grant archive write access to make import/reorganization work.
- **Storage pressure:** compare `df -h` and read-only `du -sh` of the state
  directories. Preserve the Immich application's stopped/disabled video queue;
  do not restart it as a general repair step.
