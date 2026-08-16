---
title: Logitech Mouse Tools
description: OpenLogi and Mouser installation, device permissions, runtime ownership, and switching procedure.
tags:
  - software
  - hardware
  - logitech
  - mouse
  - hid
type: software
status: active
date: 2026-08-16
source-files:
  - modules/logitech-mouse.nix
  - packages/openlogi.nix
---

# Logitech Mouse Tools

Two local Logitech HID++ managers are installed for evaluation. OpenLogi is the primary manager and starts automatically; Mouser is an on-demand fallback. They may coexist as packages and share compatible udev access rules, but they must not control the same receiver or device simultaneously.

## OpenLogi

[OpenLogi](https://github.com/AprilNEA/OpenLogi) 0.7.1 is packaged locally from its published x86-64 Debian package. This avoids compiling the large Rust/GPUI workspace during a system build while retaining fixed-source hashing and normal NixOS integration.

The upstream flake and module were evaluated but are not retained: their package builds and tests the full source workspace, which expanded this system build by hundreds of derivations. The local derivation uses the official release payload instead and introduces no additional flake input.

The local package and module:

- installs the CLI, GUI, overlay, and agent;
- installs udev rules for `hidraw`, `uinput`, and relevant input-event devices;
- starts `openlogi-agent.service` with the graphical session;
- restarts the agent on failure.

The `.deb` payload is extracted with `dpkg-deb`, its ELF binaries are patched with `autoPatchelfHook`, and the dynamically loaded OpenGL, Wayland, and Vulkan paths are added explicitly. The original desktop entry, icon, licenses, and udev rules are retained.

Configuration is stored in `~/.config/openlogi/config.toml`. The GUI keeps rotating backups beside that file. Do not enable OpenLogi's in-application launch-at-login option: the declarative NixOS user unit already owns startup, while the GUI option can create a shadowing unit under `~/.config/systemd/user/`.

Useful checks:

```bash
systemctl --user status openlogi-agent.service
openlogi list
openlogi-gui
```

OpenLogi's normal device configuration works under Niri. Linux per-application profile switching currently depends on X11/XWayland window identification and should not be expected to identify every native Wayland application.

## Mouser

[Mouser](https://github.com/TomBadash/Mouser) 3.7.3 comes from `nixpkgs-unstable`. It is installed system-wide with its udev package so the active user can access the required Logitech HID++, input-event, and `uinput` devices. Mouser does not have a declarative service here and must not have its in-application autostart enabled while OpenLogi starts automatically.

To test Mouser without competing for the device:

```bash
systemctl --user stop openlogi-agent.service
mouser
```

After closing Mouser:

```bash
systemctl --user start openlogi-agent.service
```

## Disable or remove

Remove the OpenLogi package, udev entry, and user service from `modules/logitech-mouse.nix` to disable it. Remove `pkgsUnstable.mouser` from both `environment.systemPackages` and `services.udev.packages` to remove Mouser and its device-access rules.

User configuration under `~/.config/openlogi/` and any Mouser-created autostart/configuration files are not deleted automatically.

## Updating OpenLogi

When upstream publishes a new `.deb`, inspect it before changing the version and hash:

```bash
scripts/nix-binary-inspect OPENLOGI_DEB_URL
```

Confirm the payload layout, linked libraries, desktop entry, and udev rules before rebuilding. See [[runbooks/binary-packaging|Binary Packaging Runbook]].

## Related

- [[system/architecture|System Architecture]]
- [[Package Source Policy]]
- [[runbooks/rebuild|Rebuild Runbook]]
