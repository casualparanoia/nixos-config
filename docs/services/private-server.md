---
title: GL702ZC Private Server
description: Host-local private HTTP services, shared photo storage, and unattended workstation operation.
type: service
status: experimental
tags:
  - gl702zc
  - self-hosting
  - media
  - networking
source-files:
  - hosts/gl702zc/default.nix
  - hosts/gl702zc/server.nix
  - hosts/gl702zc/media.nix
  - hosts/gl702zc/personal-services.nix
---

# GL702ZC Private Server

GL702ZC combines the existing graphical workstation profile with an unattended
private home server. Three host-local files own the additional responsibilities:
`server.nix` handles connectivity, ingress, search and availability; `media.nix`
handles shared storage and photo applications; `personal-services.nix` contains
the small monitoring, notification, dashboard, bookmark and feed-reader layer.
There is no shared server profile.

Immich and NetBird were operational before this cleanup. Caddy, PhotoPrism,
SearXNG and the declarative network/power changes require deliberate activation
after the [[runbooks/private-server|Private Server Runbook]] prerequisites.
Building a generation does not change the running services.

## Private access topology

```text
private client -- NetBird/wt0 ----------> Caddy HTTP :80
desktop ------- optional enp6s0 ------->     |
                                           +-- immich.home.arpa ----> 127.0.0.1:2283
                                           +-- photoprism.home.arpa -> 127.0.0.1:2342
                                           +-- search.home.arpa ----> 127.0.0.1:8888
                                           +-- status.home.arpa ----> 127.0.0.1:8081
                                           +-- notify.home.arpa ----> 127.0.0.1:2586
                                           +-- dashboard.home.arpa -> 127.0.0.1:8082
                                           +-- bookmarks.home.arpa -> 127.0.0.1:9090
                                           +-- rss.home.arpa -------> PHP-FPM socket
```

NetBird is the normal access path, including when Ethernet is unplugged.
The private `home.arpa` names resolve to the GL702ZC NetBird address,
`100.72.185.137`. Wi-Fi (`wlp7s0`) supplies Internet access through DHCP; its
changing LAN address is not a service dependency.

Caddy is the only HTTP ingress. Each site has an explicit `http://` scheme,
so these names do not trigger automatic TLS or HTTPS redirects. HTTP over
NetBird uses its encrypted transport. HTTP sent directly over Ethernet is
unencrypted on that dedicated cable; rsync still uses OpenSSH encryption.

The NixOS firewall admits TCP 80 on `wt0` and the dedicated `enp6s0` only.
It does not open HTTP globally on Wi-Fi, nor any application backend port.
Caddy can listen on wildcard addresses without depending on NetBird's startup
order; the firewall supplies the interface boundary. NetBird's own peer policies
remain an additional external access-control layer. Caddy routes by hostname,
not by an IP-only URL. No direct-only DNS alias is required.

NetBird runs headless with its explicit unstable package override. Normal
OpenSSH-over-NetBird provides shell access; NetBird's separate SSH server is not
enabled. The workstation's existing OpenSSH exposure and password-authentication
policy remain in force.

## Optional direct Ethernet

NetworkManager's `ensureProfiles` creates `gl702zc-direct` on `enp6s0`:
`10.42.0.2/24`, no gateway, no DNS, IPv4 `never-default`, and IPv6 disabled.
The desktop end must independently use `10.42.0.1/24` without gateway or DNS.
The link must remain dedicated to the desktop, since HTTP is permitted there.

Recent measurements were about **111 MB/s** on direct 1 GbE, **11 MB/s** through
NetBird P2P over Wi-Fi, and **14–15 MB/s** over raw Wi-Fi SSH. These are
observations, not throughput guarantees. The cable is an optional transfer
optimization and does not replace Wi-Fi's default route or change private DNS.

The earlier `Wired connection 1` profile was ad-hoc NetworkManager state. The
runbook explains retiring it after the declarative profile becomes available.
Samba's Wi-Fi transfer experiment has been removed from the host configuration;
direct Ethernet plus rsync is the supported workflow.

## Storage and ownership

| Path | Role |
| --- | --- |
| `/srv/media/stuff` | One physical originals archive, approximately 534 GiB at deployment |
| `/srv/incoming` | Completed and partial transfer staging |
| `/srv/immich` | Immich-managed uploads, thumbnails, encoded media and backups |
| `/var/lib/postgresql/17` | Stable module's Immich PostgreSQL database |
| `/var/cache/immich` | Immich ML model/cache state |
| `/var/lib/photoprism` | PhotoPrism SQLite index, configuration, sidecars, cache and backups |
| `/var/lib/gatus` | Gatus SQLite status history, bounded per endpoint |
| `/var/lib/ntfy-sh` | ntfy authentication and 72-hour text-message cache databases; attachments disabled |
| `/var/lib/glance` | Glance working/state directory; the dashboard configuration is declarative |
| `/var/lib/linkding` | linkding SQLite database, secret key, favicons and small preview assets |
| `/var/lib/freshrss` | FreshRSS configuration, per-user SQLite database, logs and feed cache |
| `/var/lib/caddy`, `/var/log/caddy` | Caddy state and access logs |
| `/run/searx/settings.yml` | Runtime SearXNG settings, including substituted secret; recreated by `searx-init` |
| `/var/lib/private-server-secrets` | Manually provisioned root-only secrets outside the Nix store |

The originals are not copied into PhotoPrism. Immich's external library points
to this same tree and is managed through its UI. Managed Immich uploads are
separate application state, not a second copy made for external-library indexing.

`casua` and `immich` belong to `media`. PhotoPrism retains its dynamic user but
uses the existing static `media` group as its primary group. Ingested directories
use **2770** and files **0660**, with group **media**. Host-level tmpfiles rules manage only the shared
`/srv/media` and `/srv/incoming` directories, non-recursively. The native Immich
module owns its `mediaLocation`; activation does not walk or repair the originals.
See [[runbooks/media-ingest|Media Transfer and Ingest]] for normalization and
postcondition checks.

**There is currently no complete independent backup of the originals archive.**
NixOS reproducibility, application databases, metadata exports and generated
previews are not backups of the original media. A backup plan must independently
cover the originals as well as application databases/state. SQLite lives under
PhotoPrism's state directory; no additional database server is deployed for the
comparison.

The new application databases are also operational state, not backups. Back up
Gatus only if history matters, and back up ntfy authentication, linkding and
FreshRSS state if those accounts/subscriptions must be recoverable. Keep the
external secret directory in a separate protected backup. Glance and smartd have
no important application database to preserve.

## Immich device access and managed albums/tags

The Immich server receives only `/dev/dri/renderD128` through the native module's
device allow-list. The module must set `PrivateDevices=no` so the render node is
visible; the nonempty `DeviceAllow` list gives the unit a closed device policy
that permits this node (and systemd's standard pseudo-devices), not all DRM
devices. The render node is currently mode 0666, so adding `immich` to `video` or
`render` would not add useful access and is intentionally avoided. VAAPI
selection and real-time HLS policy remain UI-managed; offline video conversion
must remain disabled.

Immich 3.2.2 has static albums and an official workflow system. Workflows can
match full paths and add assets on an event, but they cannot reconcile removals,
provide the exact Main Media complement, or reliably backfill all existing
assets. `scripts/immich-album-sync.py` therefore uses the versioned official API
to maintain two ordinary albums and two hierarchical tags without changing
asset visibility or files:

- **Instagram** / **Source/Instagram** is every active external-library asset
  whose original path begins with `/srv/media/stuff/instagram/`;
- **Main Media** / **Source/Main Media** is every active external-library asset
  whose original path begins with `/srv/media/stuff/`, except that Instagram
  subtree.

The albums provide collection and slideshow views. The tags expose the same
classification as a composable Immich Search filter. `Source` and its two exact
children are reserved to this machine-managed classification and must not be
manually renamed, reparented, extended or repurposed.

The trailing-slash boundary means `instagram-old` remains Main Media. A non-null
Immich library ID excludes Immich-owned uploads even if a path were surprising.
The synchronizer explicitly admits `timeline` and `archive` visibility. Internal
`hidden` components, locked assets and soft-deleted trash are excluded; restored
assets rejoin the desired set naturally, and stacked assets are included
individually.
The synchronizer scans the desired universe once, cursor-paginates membership
searches, computes set deltas, batches only needed changes, and completes all
additions before removals. Album changes use batches of 500. Tag changes use
conservative batches of 100 because Immich 3.2.2 refreshes tag metadata and
emits an event for each successfully changed asset. It never deletes, archives,
unarchives, favorites, renames or writes an asset, and it modifies only the two
managed tag memberships; every unrelated/manual tag is preserved. An exact
description marker establishes album ownership; an unmarked same-name album
causes a safe failure instead of being adopted.

Tags have no description marker in Immich 3.2.2, so ownership is fail-closed:
an absent `Source` namespace may be created by the stable hierarchical upsert,
and an already-complete hierarchy containing exactly `Source`,
`Source/Instagram` and `Source/Main Media` is treated as the reserved managed
namespace. A partial tree, extra `Source/*` child, duplicate, or incorrect
parent relationship aborts the run before membership mutation. The synchronizer
never calls tag update or deletion endpoints.
The API key is a root-owned external systemd credential. A four-times-daily timer
is skipped when that file is absent and later runs naturally catch ongoing
indexing.

## PhotoPrism originals boundary

PhotoPrism uses application read-only mode and disables WebDAV. Its service has
`ProtectSystem=strict`, a read-only bind mount of **all `/srv/media`**, and an
overridden `ReadWritePaths` containing only its own state directory. Binding the
parent read-only also protects the `stuff` directory entry. The stable module's
default writable-originals/import paths are deliberately replaced. Private
temporary space and the normal systemd state/runtime directories remain writable.

Thus group permissions allow reading the archive, while the service's mount
namespace denies creating, modifying, deleting or reorganizing originals. This
boundary applies to both the module's pre-start migrations and the main process.
Do not run PhotoPrism manually outside this sandbox against the archive; a plain
shell command does not inherit the service's mount restrictions.

The primary group is deliberate. An exact disposable transient-unit probe with
`DynamicUser=true`, `PrivateUsers=true` and `SupplementaryGroups=media` mapped
both the supplementary group and the fixture's host group to `nogroup`/65534
inside the user namespace. Although the collapsed IDs happened to permit reading,
they did not preserve a distinct media-group identity. Repeating the probe with
`Group=media` preserved GID 987 as `media` and read the representative 0750/0640
fixture successfully. The primary-group design therefore retains `PrivateUsers`
hardening without relying on namespace-collapsed supplementary groups.

The stable module emits an empty trailing `LoadCredential=` when the optional
database password is absent. In systemd this clears the preceding admin-password
credential. The host overrides that list with the single admin-password file;
this is a module workaround, not a change of application package source.

Automatic labels/classification, TensorFlow, face recognition, FFmpeg and normal
image/thumbnail quality defaults are retained. Indexing is an explicit operator
action, with no scheduled or WebDAV-triggered scanning. Use **indexing originals**,
not importing, to compare PhotoPrism with Immich.

## Transcoding and resource decisions

PhotoPrism retains FFmpeg for video metadata/previews and on-demand compatible
playback. The pinned application calls AVC conversion from its video API and
explicit conversion worker, not an automatic bulk transcode service configured
here. Do not schedule `photoprism convert` or bulk video conversion. On-demand
transcodes, thumbnails and sidecars still consume disk space; monitor the state
directory as the comparison grows. Image quality and recognition thresholds
have not been reduced to save space.

Immich video transcoding was stopped/disabled through the application after only
27 encoded videos consumed about 8.9 GiB with roughly 1500 jobs remaining. This is
operational application state, not an unsupported declarative Nix setting.
Preserve it when administering jobs.

Immich server/ML timeout increases are intentional for this laptop. ML has
`HOME=/tmp` within `PrivateTmp`: runtime testing showed repeated Gunicorn errors
at `/var/empty/.gunicorn` before this fix and successful creation of
`/tmp/.gunicorn/gunicorn.ctl` afterward.

## SearXNG and secrets

SearXNG uses the stable `services.searx` module's built-in HTTP mode for this small
private instance, bound to `127.0.0.1:8888`, with debug/public-instance/limiter
disabled. Neither uWSGI nor a SearXNG Redis/Valkey server is required. The module
substitutes `$SEARX_SECRET_KEY` from an external systemd environment file into a
mode-0600 runtime configuration. The secret itself is never in Nix source.

The built-in server logs queries to the journal; Caddy's default access logs
also include request URLs. Treat these as private operational data. Private
network access is the search instance's access boundary; it has no login screen.

## Lightweight personal services

Gatus checks the existing Caddy listener every five minutes through
`127.0.0.1:80` with the intended `Host` header. This tests both hostname routing
and each backend without depending on NetBird DNS from the server itself. The
checks cover Immich's ping response, PhotoPrism's login redirect, SearXNG, ntfy's
health API, linkding's health API, FreshRSS and Glance. SQLite retains at most
2016 results and 50 events per endpoint: about seven days at this interval, not
a long-term metrics archive.

Gatus publishes an alert after three consecutive failures and a recovery after
two consecutive successes. Its native ntfy provider posts to the local
`server-alerts` topic using a token from
`/var/lib/private-server-secrets/ntfy.env`. smartd monitors all locally detected
SMART/NVMe devices with `-a`, without scheduled self-tests. Its small `-M exec`
helper posts warnings to the same local topic with a separate token. Test
notifications are disabled in the persistent configuration.

ntfy listens only on `127.0.0.1:2586`. Its SQLite access database uses
deny-by-default authorization: `casua` is provisioned statefully as the human
administrator, while a `monitoring` user receives write-only access to
`server-alerts`. Account and token creation use the ntfy CLI after activation;
no password or token is declared in Nix. Text notifications remain cached for
72 hours. Upload attachments are disabled rather than receiving ntfy's default
multi-gigabyte attachment allowance.

Glance listens on `127.0.0.1:8082` and provides a front door to Immich,
PhotoPrism, SearXNG, Gatus, ntfy, linkding and FreshRSS. Its local server-stats
widget shows CPU, memory and root-filesystem usage directly, without a metrics
agent or time-series database.

linkding listens on `127.0.0.1:9090` and uses its native SQLite setup. The
initial `casua` superuser password comes from the external `linkding.env` file.
Background archive/snapshot tasks are disabled, so the state directory is
limited to the bookmark database, key, favicons and ordinary small previews.

FreshRSS uses its native Caddy/PHP-FPM integration over a local Unix socket,
form authentication, a `casua` default administrator and per-user SQLite state.
Systemd delivers its initial password from the root-only external
`freshrss-password` file to the unprivileged setup unit with `LoadCredential`.
No API, extensions, full-text helper service, database server or automatic
SQLite export is enabled. Configure the user's normal purge policy after first
login; starred articles and items still present in upstream feeds are
deliberately retained.

## Unattended power policy

GL702ZC has no useful battery. Logind ignores lid close (including external-power
and docked cases) and idle actions. Systemd disallows suspend, hibernation, hybrid
sleep and suspend-then-hibernate. The graphical workstation remains available.
NetworkManager disables Wi-Fi power saving only on this host for predictable
latency on a batteryless server/workstation. Measurements showed no throughput
improvement, so this is not a performance workaround or a shared default.
NixOS intentionally does not automatically restart logind on a configuration
change, because restarting it can disrupt sessions. Apply the effective lid
policy during a planned logind restart or reboot; see the runbook.

## Package boundary

NixOS modules, Caddy, PostgreSQL and other module-default infrastructure use
stable `nixos-26.05`; Home Manager follows `release-26.05`. Gatus, ntfy,
smartmontools and their helper tools use stable packages. Immich (including its
ML passthrough), PhotoPrism, SearXNG, Glance, linkding and FreshRSS explicitly use
`pkgsUnstable`. NetBird retains its intentional unstable infrastructure
exception. No input update or unstable module-set import is needed.

## Related and upstream references

- [[runbooks/private-server|Private Server Runbook]] — provisioning, verification and troubleshooting.
- [[runbooks/media-ingest|Media Transfer and Ingest]] — transfer and archive invariants.
- [[system/package-source-policy|Package Source Policy]].
- [PhotoPrism configuration options](https://docs.photoprism.app/getting-started/config-options/).
- [PhotoPrism originals indexing](https://docs.photoprism.app/user-guide/library/originals/).
- [SearXNG server settings](https://docs.searxng.org/admin/settings/settings_server.html).
