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
  - hosts/gl702zc/personal-services.nix
---

# Private Server Runbook

Use this with [[services/private-server|GL702ZC Private Server]] and
[[runbooks/media-ingest|Media Transfer and Ingest]]. Configuration builds are
non-activating; service deployment and archive indexing are separate actions.

## Provision required secrets before activation

Create the private directory outside the repository and Nix store:

```bash
sudo install -d -o root -g root -m 0700 /var/lib/private-server-secrets
sudoedit /var/lib/private-server-secrets/photoprism-admin-password
sudoedit /var/lib/private-server-secrets/searx.env
sudoedit /var/lib/private-server-secrets/linkding.env
sudoedit /var/lib/private-server-secrets/freshrss-password
sudoedit /var/lib/private-server-secrets/ntfy.env
sudo chown root:root /var/lib/private-server-secrets/{photoprism-admin-password,searx.env,linkding.env,freshrss-password,ntfy.env}
sudo chmod 0600 /var/lib/private-server-secrets/{photoprism-admin-password,searx.env,linkding.env,freshrss-password,ntfy.env}
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

The linkding file is a systemd environment file with exactly this variable and
the chosen initial password as its value:

```text
LD_SUPERUSER_PASSWORD=replace-with-the-real-password
```

The username is declaratively fixed to `casua`. The value initializes a new
account; changing the file later does not rotate an existing account password.
The FreshRSS file contains only the chosen plaintext initial password, with no
variable name. It remains root-only: systemd reads the source and delivers a
read-only `freshrss-password` credential to `freshrss-config.service` under that
unit's private `/run/credentials` directory. The unprivileged `freshrss` service
identity does not read the source file directly. FreshRSS updates the `casua`
account from the delivered credential when its configuration unit runs, so keep
the source file synchronized with the intended login.

ntfy user and token provisioning is stateful and happens after its first
activation. Before that activation, create `ntfy.env` with two empty variables so
Gatus can validate and start without embedding a temporary credential:

```text
GATUS_NTFY_TOKEN=
SMARTD_NTFY_TOKEN=
```

Until real tokens replace those empty values, ntfy's deny-by-default policy
rejects alert publication. Do not reuse the linkding or FreshRSS passwords here.

Do **not** create `/var/lib/private-server-secrets/immich-api-key` before the
first activation of this configuration. Its absence is the safety gate that
prevents the persistent album/tag timer from performing the first mutation before
the operator reviews a dry-run. Provision it only in the ordered procedure
below.

When rotating SearXNG's key later, restart `searx-init.service` and then
`searx.service` so `/run/searx/settings.yml` is regenerated. Changing an external
file alone does not change the Nix derivation or reload it.

## Complete external NetBird/DNS state

In the NetBird control plane, manually:

1. Confirm the GL702ZC peer's unattended-server login/expiration policy. Avoid
   interactive expiry that would strand the machine.
2. Retain the private zone `home.arpa` and the working
   `immich.home.arpa -> 100.72.185.137` record.
3. Add `photoprism.home.arpa`, `search.home.arpa`, `status.home.arpa`,
   `notify.home.arpa`, `dashboard.home.arpa`, `bookmarks.home.arpa` and
   `rss.home.arpa`, all pointing at `100.72.185.137`, and distribute this private
   DNS configuration to the intended client group.
4. Confirm peer access policies permit the intended clients to reach TCP 80 and
   the existing OpenSSH service. Do not enable NetBird's separate SSH server.

These are cloud-managed settings, not fake NixOS options. GL702ZC's dynamic
Wi-Fi address must never be substituted into persistent private DNS records.
On Windows, AdGuard and ProtonVPN DNS handling previously interfered with the
private zone. Verify name resolution and routing independently; a successful
NetBird connection does not prove the Windows resolver uses its DNS policy.
Add these five corresponding AdGuard DNS rewrites on the desktop, each targeting
`100.72.185.137`: `status.home.arpa`, `notify.home.arpa`,
`dashboard.home.arpa`, `bookmarks.home.arpa` and `rss.home.arpa`. This is a
manual Windows-side step; NixOS does not manage it.

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
systemd-analyze verify result/etc/systemd/system/{immich-server,immich-album-sync,gatus,ntfy-sh,smartd,glance,linkding,linkding-setup,freshrss-config}.service
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

For Immich, expect `PrivateDevices=no` only on `immich-server.service` and a
single explicit `DeviceAllow=/dev/dri/renderD128`; the ML unit retains
`PrivateDevices=yes`. The album-sync service must have a credential load, the
secret-file condition and loopback-only IP policy.

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

Activate only during a deliberate deployment window after provisioning the
required startup secrets above. The Immich API-key file must still be absent.
This changes services and may run native module database migrations. Do not use
`nixos-rebuild test` as a harmless check of stateful services. The normal switch
removes the socket proxy and starts Caddy; if port 80 is busy afterward, inspect
the old `immich-http-proxy.socket`/service before restarting anything.

After reviewing the diff and a successful non-activating build, activate exactly
the reviewed working tree with:

```bash
sudo test ! -e /var/lib/private-server-secrets/immich-api-key
sudo nixos-rebuild switch --flake path:.#gl702zc
```

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

## Configure Immich video and album synchronization

After activation, first confirm the device sandbox, then use **Administration →
Settings → Video transcoding** in Immich 3.2.2:

1. Keep the offline/video-conversion transcoding policy **Disabled**. Do not
   resume or enqueue the existing video-conversion jobs.
2. Select **VAAPI**, enable accelerated decode, and select
   `/dev/dri/renderD128` when a device field is shown.
3. Under real-time HLS transcoding, enable real-time transcoding, select only
   **H.264**, and retain **480p**, **720p**, and **1080p**. Do not select HEVC or
   AV1 for this first test.
4. Save the settings, play one incompatible video at a forced lower quality,
   and inspect logs/GPU activity while playback is active:

```bash
systemctl show immich-server -p PrivateDevices -p DeviceAllow -p SupplementaryGroups
journalctl -fu immich-server
sudo nix shell path:.#nixosConfigurations.gl702zc.pkgs.radeontop -c radeontop
```

Look for an Immich FFmpeg command using `-hwaccel vaapi` and
`/dev/dri/renderD128`, plus non-zero GPU video-engine activity. Merely seeing a
successful video or CPU use does not prove VAAPI was selected. Stop playback and
confirm real-time segments do not accumulate unexpectedly; do not use a bulk job
as the test.

For the first album/tag synchronization, keep the API-key file absent during the
switch, then stop the timer before provisioning it:

```bash
sudo systemctl stop immich-album-sync.timer
```

In Immich, create a dedicated API key as the owner of the external library under
**Account settings → API keys**. Grant only `asset.read`, `album.read`,
`album.create`, `albumAsset.create`, `albumAsset.delete`, `tag.read`,
`tag.create` and `tag.asset`; these are the exact permissions advertised by the
installed 3.2.2 OpenAPI operations used by the synchronizer. `tag.update` and
`tag.delete` are neither needed nor granted. API keys act as their creating user,
so use the same user that owns the external library and the managed albums/tags.
Put the key alone, with no variable name or quotes, in the root-only external
file:

```bash
sudoedit /var/lib/private-server-secrets/immich-api-key
sudo chown root:root /var/lib/private-server-secrets/immich-api-key
sudo chmod 0600 /var/lib/private-server-secrets/immich-api-key
```

Preview first and inspect the complete counts and proposed deltas. Do not start
the oneshot until those results are approved:

```bash
sudo immich-album-sync --dry-run
```

After approval, apply once, inspect the resulting albums, tags and log, run a
second dry-run to confirm all four views are unchanged, and only then resume
automatic synchronization:

```bash
sudo systemctl start immich-album-sync.service
journalctl -u immich-album-sync.service -n 100 --no-pager
sudo immich-album-sync --dry-run
sudo systemctl start immich-album-sync.timer
systemctl list-timers immich-album-sync.timer
```

The first apply creates albums only when no same-name album exists. If an
unmarked `Instagram` or `Main Media` album already exists, the command fails and
does not adopt it; rename the unrelated album in the UI, preview again, and only
then apply. If no `Source` hierarchy exists, the first apply uses Immich's
hierarchical upsert to create exactly `Source/Instagram` and `Source/Main Media`.
An incomplete hierarchy, an extra `Source/*` tag, or an incorrect parent
relationship fails closed; resolve that conflict deliberately in the UI and
preview again. The exact three-node `Source` hierarchy is reserved to this
machine-managed classification and must not be manually repurposed. The
synchronizer changes only membership in its two leaf tags and preserves every
other tag on each asset.

For the existing album-only deployment, stop the timer and move the key out of
the unit's exact condition path **before switching to the tag-capable
generation**. This remains safe even if activation starts the persistent timer.
After the switch, stop the timer again, add only `tag.read`, `tag.create` and
`tag.asset` to the existing key in Immich, and restore the unchanged secret
file. Do not rotate or rewrite the key. Follow this ordered first-tag-run
procedure:

```bash
sudo systemctl stop immich-album-sync.timer
sudo mv /var/lib/private-server-secrets/immich-api-key \
  /var/lib/private-server-secrets/immich-api-key.disabled
sudo nixos-rebuild switch --flake path:.#gl702zc
sudo systemctl stop immich-album-sync.timer
# In Immich, add tag.read, tag.create and tag.asset to the existing key.
sudo mv /var/lib/private-server-secrets/immich-api-key.disabled \
  /var/lib/private-server-secrets/immich-api-key
sudo chown root:root /var/lib/private-server-secrets/immich-api-key
sudo chmod 0600 /var/lib/private-server-secrets/immich-api-key
sudo immich-album-sync --dry-run
# Inspect: album deltas should remain zero; tag additions should match 20,775 + 7,550.
sudo systemctl start immich-album-sync.service
journalctl -u immich-album-sync.service -n 100 --no-pager
sudo immich-album-sync --dry-run
# Inspect Source/Instagram and Source/Main Media in Immich Search, then:
sudo systemctl start immich-album-sync.timer
systemctl list-timers immich-album-sync.timer
```

Do not start the oneshot unless the first dry-run's path counts, zero album
deltas and proposed tag deltas are approved. The apply adds the correct managed
tag before removing the other managed tag from an asset. Membership requests
are capped at 100 assets because Immich updates tag metadata and emits tag events
per asset. The timer runs four times daily with jitter. API downtime causes that
run to fail without changing ingestion; the next timer run retries the complete
reconciliation. Run the oneshot manually after a large ingest when immediate
membership is useful.

## Provision ntfy access after first activation

The first activation creates `/var/lib/ntfy-sh` and starts ntfy with anonymous
access denied. The service uses `DynamicUser` with a systemd-managed, id-mapped
`StateDirectory`: `/var/lib/ntfy-sh` points at `private/ntfy-sh`, whose backing
ownership can appear as `nobody:nogroup` outside the service namespace. Ordinary
`sudo -u ntfy-sh` does not reproduce that filesystem view and cannot administer
the SQLite authentication database. Run every stateful ntfy CLI command in a
transient unit with the same identity and state-directory model:

```bash
ntfy_admin() {
  sudo systemd-run --wait --pty --collect \
    -p DynamicUser=yes \
    -p User=ntfy-sh \
    -p Group=ntfy-sh \
    -p StateDirectory=ntfy-sh \
    /run/current-system/sw/bin/ntfy "$@"
}

ntfy_admin user add --role=admin casua
ntfy_admin user add monitoring
ntfy_admin access monitoring server-alerts write-only
ntfy_admin token add --label=gatus monitoring
ntfy_admin token add --label=smartd monitoring
```

Choose strong, distinct passwords at the prompts. The two token commands print
different `tk_...` values. Put them into the matching variables in the existing
root-owned `ntfy.env`; never put them in Nix or commit them. Then load the Gatus
token and verify the ACL without sending a permanent test notification:

```bash
sudo systemctl restart gatus
ntfy_admin access monitoring
ntfy_admin token list monitoring
```

smartd reads its token file only when its notification helper runs, so token
rotation does not require restarting smartd. For rotation, create a distinctly
labeled replacement, update the matching variable in `ntfy.env`, restart Gatus
only when its token changes, verify the token list, and remove the old token only
after the replacement works:

```bash
# Use smartd-next instead when rotating SMARTD_NTFY_TOKEN.
ntfy_admin token add --label=gatus-next monitoring
sudoedit /var/lib/private-server-secrets/ntfy.env
sudo systemctl restart gatus
ntfy_admin token list monitoring
read -r -s -p "Token to remove: " TOKEN_TO_REMOVE; printf '\n'
ntfy_admin token remove monitoring "$TOKEN_TO_REMOVE"
unset TOKEN_TO_REMOVE
```

ntfy tokens inherit the publisher user's write-only `server-alerts` ACL; they
are not administrator tokens. Define `ntfy_admin` again in a new shell before
running later access, token-list or rotation commands.

After the first FreshRSS login, set a modest global article purge policy under
**Configuration → Archiving** (for example, a 90-day or per-feed article limit)
and preserve only deliberately starred articles. No subscriptions are imported
by this deployment. The configuration enables neither automatic SQLite exports
nor full-content retrieval extensions; any later export still needs independent
backup storage.

## Verify after deployment

On GL702ZC, inspect service state, listening sockets, and logs without starting
archive jobs:

```bash
systemctl status caddy immich-server immich-album-sync.timer gatus ntfy-sh smartd glance linkding linkding-setup freshrss-config phpfpm-freshrss
ss -lnt
curl --fail http://127.0.0.1:2283/api/server/ping
curl --fail --resolve immich.home.arpa:80:127.0.0.1 http://immich.home.arpa/api/server/ping
curl --fail --resolve photoprism.home.arpa:80:127.0.0.1 http://photoprism.home.arpa/
curl --fail --resolve notify.home.arpa:80:127.0.0.1 http://notify.home.arpa/v1/health
curl --fail --resolve bookmarks.home.arpa:80:127.0.0.1 http://bookmarks.home.arpa/health
curl --fail --resolve status.home.arpa:80:127.0.0.1 http://status.home.arpa/health
curl --fail --resolve dashboard.home.arpa:80:127.0.0.1 http://dashboard.home.arpa/
curl --fail --resolve rss.home.arpa:80:127.0.0.1 http://rss.home.arpa/
curl --fail --resolve search.home.arpa:80:127.0.0.1 http://search.home.arpa/
journalctl -u caddy -u immich-server -u immich-album-sync -u gatus -u ntfy-sh -u smartd -u glance -u linkding -u freshrss-config -n 100 --no-pager
netbird status
```

Expected TCP backends listen only on `127.0.0.1`: Immich `2283`, PhotoPrism
`2342`, SearXNG `8888`, Gatus `8081`, ntfy `2586`, Glance `8082`, and linkding
`9090`. FreshRSS uses `/run/phpfpm/freshrss.sock` rather than a backend TCP port.
Caddy listens on HTTP 80, with no automatic TLS/redirect. From a NetBird client,
verify all ordinary names with the cable unplugged.
From the desktop, test Caddy over Ethernet without changing DNS:

```bash
curl --fail --resolve immich.home.arpa:80:10.42.0.2 http://immich.home.arpa/api/server/ping
```

From a separate Wi-Fi LAN client, verify HTTP and backend connections are blocked
using the laptop's **observed** DHCP address. Curl from GL702ZC to its own Wi-Fi
address does not establish the ingress firewall boundary.

Inspect local state without touching the originals archive:

```bash
sudo du -sh /var/lib/{gatus,ntfy-sh,glance,linkding,freshrss}
sudo find /var/lib/ntfy-sh -maxdepth 2 -type f -printf '%p %s bytes\n'
sudo find /var/lib/linkding -maxdepth 2 -type f -printf '%p %s bytes\n'
sudo find /var/lib/freshrss -maxdepth 3 -type f -printf '%p %s bytes\n'
```

Gatus is bounded by result counts, ntfy keeps text for 72 hours and has no
attachment directory, linkding snapshot jobs are disabled, and Glance should
remain negligible. FreshRSS is the main variable-growth service; its SQLite
database/cache size follows the feed list and the user purge policy. These state
directories and the secret files need separate backups if their accounts or
history matter. They do not provide an independent backup of media originals.

Audit Immich state read-only before considering any storage action:

```bash
df -h /
sudo du -x -h --max-depth=1 /srv/immich | sort -h
sudo du -x -h --max-depth=2 /srv/immich | sort -h | tail -100
sudo find /srv/immich -xdev -type f -path '*/encoded-video/*' -printf '%s\n' \
  | awk '{ total += $1; count += 1 } END { printf "%d files, %.2f GiB\n", count, total / 1024^3 }'
```

The prior observation was roughly 8.9 GiB of encoded video from only 27
completed offline conversions, within about 16 GiB total Immich media state.
Those files are the first *potential* reclaim candidate only after correlating
them with current Immich database/API state and confirming they are obsolete.
Thumbnails, uploads, backups, profile data and ML cache have different roles.
Do not remove any of them, or any transcode/cache directory, merely because its
name looks generated; stop for approval with the measured breakdown.

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
- **NetBird unexpectedly relayed on Windows:** the desktop needed a
  process-scoped inbound UDP 49152–65535 firewall rule for
  `C:\Program Files\Netbird\netbird.exe`. That changed the observed connection
  from relayed (~4.5 MB/s) to P2P (~11 MB/s). Do not replace it with router port
  forwarding; compare `netbird status`, raw Wi-Fi SSH (~14–15 MB/s), and direct
  Ethernet (~111 MB/s) before blaming NixOS service routing.
