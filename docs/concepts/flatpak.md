---
title: Flatpak
description: Policy, declarative inventory, and operational caveats for selected Flatpak applications.
tags:
  - flatpak
  - sandbox
  - packages
  - policy
type: concept
status: accepted
date: 2026-08-16
source-files:
  - modules/flatpak.nix
  - dotfiles/niri/config.kdl
---

# Flatpak

Nix remains the primary source for the operating system, services, development tools, command-line software, and infrastructure. Flatpak is used selectively for self-contained GUI applications when upstream support, update cadence, dependency isolation, or portal integration makes it the better fit. Availability on Flathub alone is not a reason to prefer Flatpak.

`nix-flatpak` manages the system Flathub remote and application inventory in `modules/flatpak.nix`. The input is pinned in `flake.lock`.

## Managed applications

| Application | Application ID | Source | Why Flatpak | Sandbox and desktop caveats | Niri / nirinit integration |
|---|---|---|---|---|---|
| NormCap | `com.github.dynobo.normcap` | Flathub | Current, self-contained OCR capture with screenshot-portal integration | Uses the screenshot portal and has Pictures access; portal behavior is part of the capture flow | `Mod+Shift+T` launches it, its window floats, and nirinit maps its app ID to an explicit Flatpak wrapper |
| LibreOffice | `org.libreoffice.LibreOffice` | Flathub | Upstream-supported desktop bundle with isolated office dependencies and timely updates | Broad host-file access; fonts, printing, portals, and MIME integration should be checked after major updates | No special rule or restoration mapping |
| JASP | `org.jaspstats.JASP` | Flathub | Self-contained statistical application with its own tested runtime stack | Home-directory access; its bundled statistical runtime is separate from host R/Python environments | No special rule or restoration mapping |
| jamovi | `org.jamovi.jamovi` | Flathub | Self-contained statistical desktop application with a current distribution path | Currently relies on X11 and therefore Niri's Xwayland support; has home-directory access | No special rule or restoration mapping |
| GIMP | `org.gimp.GIMP` | Flathub | Current, self-contained graphics stack without coupling its dependency set to NixOS | Broad host-file and device access; portals and plugins may behave differently from host packages | No special rule or restoration mapping |

The IDs above were checked against current Flathub metadata. None of these applications is also installed from Nixpkgs.

## Declarative behavior

Applications are installed system-wide. Existing system installations with the same IDs are adopted rather than duplicated; user-scope Flatpaks are separate and are not managed by this NixOS module.

A fresh installation is a substantial network and disk operation because it downloads the applications and their runtimes; JASP alone reports a multi-gigabyte installed size.

The configuration deliberately uses conservative reconciliation:

- `uninstallUnmanaged = false` preserves applications and remotes that were never managed by this declaration;
- `uninstallUnused = false` avoids broad runtime cleanup;
- `update.onActivation = false` keeps network updates out of `nixos-rebuild`;
- a weekly systemd timer updates the declared applications.

Removing a previously managed application from `services.flatpak.packages` requests its removal on a later activation. Flatpak state is mutable rather than Nix-generational, so a NixOS rollback may install or remove applications to match the rolled-back declaration instead of restoring a store snapshot.

## Disable or remove

Disabling or removing nix-flatpak does not itself uninstall applications already stored under `/var/lib/flatpak`. For declarative removal, first empty `services.flatpak.packages` and rebuild while the module remains enabled. After the managed applications are gone, remove `modules/flatpak.nix`, its upstream module, and the flake input if Flatpak management is no longer wanted.

Unused runtimes remain because `uninstallUnused = false`. Review and remove them manually only when desired:

```bash
flatpak list --system --runtime
flatpak uninstall --system --unused
```

## Important model

“Sandboxed” does **not** mean “cannot access or modify normal files”. Effective access depends on static permissions and dynamic portals.

Before relying on a Flatpak for engineering or scientific work, inspect:

```bash
flatpak info --show-permissions APP_ID
```

Pay particular attention to:

- `home` / host filesystem access;
- document portal behavior;
- device/USB access;
- network access;
- ability to invoke external host tools;
- whether needed simulation/compiler/runtime dependencies are bundled inside the Flatpak.

## Good fit

Flatpak is attractive for a largely self-contained GUI when it has a strong upstream-supported package, benefits from isolated dependencies, and does not need deep host-toolchain integration.

## Poorer fit

It is less attractive for language/toolchain environments that need host compilers, arbitrary native libraries, external commands, or hardware devices.

## Related

- [[Package Source Policy]]
- [[Nirinit]]
- [[Qucs-S]]
- [[Cantor]]
- [[Scilab]]
