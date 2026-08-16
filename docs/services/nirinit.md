---
title: Nirinit
description: Niri session persistence service, restoration behavior, Flatpak launch mapping, and operational guidance.
tags:
  - service
  - niri
  - session
  - flatpak
type: service
status: active
date: 2026-08-16
source-files:
  - flake.nix
  - modules/nirinit.nix
  - dotfiles/niri/config.kdl
---

# Nirinit

[nirinit](https://github.com/amaanq/nirinit) records open Niri windows and attempts to restore them in the next graphical session. It is used here to recover the practical workspace layout after login without making application startup part of the Niri KDL configuration.

The repository pins nirinit v0.2.2 through `flake.lock`, imports its upstream NixOS module, and keeps local settings in `modules/nirinit.nix`.

## Niri integration

The upstream module creates a systemd user service tied to `graphical-session.target`. The normal Niri session starts that target, so no `spawn-at-startup` entry is added to `config.kdl`. Starting a second copy from Niri would risk restoring every saved application twice.

Nirinit communicates with Niri through its IPC socket. It does not rewrite the Niri configuration.

## State and restoration

Persistent state is stored at:

```text
$XDG_DATA_HOME/nirinit/session.json
```

This is normally `~/.local/share/nirinit/session.json`. The service snapshots open windows every five minutes and performs a final save when it stops cleanly.

At startup, nirinit reads the saved session, launches each recorded command, waits for a window with the saved `app_id`, and then restores its output, workspace, width, and height. It does not preserve exact tiling order, floating/fullscreen state, tabs, titles, or focus. Multiple windows sharing one app ID may be matched imperfectly.

If no state file exists, nirinit records the current session rather than launching applications immediately.

## Flatpak launch mapping

Nirinit normally treats a window's `app_id` as its executable name. That does not work for Flatpak applications, and nirinit accepts only one executable token rather than a shell command with arguments.

NormCap therefore has this mapping:

```text
com.github.dynobo.normcap -> /run/current-system/sw/bin/nirinit-launch-normcap
```

The wrapper runs `flatpak run --system com.github.dynobo.normcap`. The same Flathub application and desktop ID is used by the declarative inventory, Niri shortcut, and floating-window rule. After the first installation, confirm the runtime ID with `niri msg windows`; if NormCap reports a different value, update the nirinit mapping and Niri rule together.

No mappings are declared for LibreOffice, JASP, jamovi, or GIMP yet. Their actual Niri runtime app IDs should first be observed with `niri msg windows`; LibreOffice can expose component-specific IDs, and guessing mappings could restore the wrong command. Until a verified mapping is added and a new snapshot is saved, nirinit cannot reliably relaunch those Flatpaks.

## Troubleshooting

Check the user service and current Niri IDs:

```bash
systemctl --user status nirinit.service
journalctl --user -u nirinit.service -b
niri msg windows
jq . "${XDG_DATA_HOME:-$HOME/.local/share}/nirinit/session.json"
```

Important caveats:

- restart the service cautiously while applications are open, because startup restoration can create duplicates;
- launch mappings are resolved when a snapshot is saved, so changing a mapping does not rewrite an old session immediately;
- a partial graphical-session teardown can leave an incomplete snapshot;
- configuration errors are reported in the user journal.

If the state is stale or broken, stop the service and remove `session.json`; the next start creates a fresh snapshot.

## Disable or remove

Set `services.nirinit.enable = false` or remove `modules/nirinit.nix` from the imports, then rebuild. If nirinit is no longer wanted anywhere, also remove its upstream module and flake input.

NixOS does not delete user state automatically. Remove it separately only if the saved session is no longer needed:

```bash
rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/nirinit"
```

## Related

- [[Flatpak]]
- [[system/architecture|System Architecture]]
- [[runbooks/rebuild|Rebuild Runbook]]
