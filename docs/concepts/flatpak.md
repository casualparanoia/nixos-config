---
title: Flatpak
description: Policy and caveats for using Flatpak alongside Nix on this workstation.
tags:
  - flatpak
  - sandbox
  - packages
  - policy
type: concept
status: accepted
date: 2026-08-14
---

# Flatpak

Flatpak is a valid parallel application distribution mechanism on this system. It does not conflict with Nix merely because both contain the same application; their package stores and application configuration are separate.

## Important model

“Sandboxed” does **not** mean “cannot access or modify normal files”. Effective access depends on static permissions and dynamic portals.

Before relying on a Flatpak for engineering/scientific work, inspect:

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

Flatpak is attractive for a largely self-contained GUI when Nixpkgs is badly outdated and the application does not need deep host-toolchain integration.

## Poorer fit

It is less attractive for language/toolchain environments that need host compilers, arbitrary native libraries, external commands, or hardware devices.

## Related

- [[Package Source Policy]]
- [[Qucs-S]]
- [[Cantor]]
- [[Scilab]]
