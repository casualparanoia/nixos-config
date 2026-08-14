---
title: Cantor
description: KDE mathematical worksheet frontend; installation route and backend integration remain undecided.
tags:
  - software
  - kde
  - notebook
  - mathematics
  - flatpak
type: software
status: undecided
date: 2026-08-14
source-files:
  - home/engsci.nix
---

# Cantor

Cantor is a worksheet/notebook frontend for external mathematical engines rather than a replacement for those engines.

Potential backends include systems such as [[Octave]], [[R]], [[Julia]], and [[SageMath]], but packaging determines whether the frontend can actually discover and execute them.

## Current repository state

```nix
# pkgs.kdePackages.cantor
```

## Nix versus Flatpak

The Nix package is more naturally integrated with the NixOS host, but R/Julia backend discovery needs actual testing.

The Flatpak is more isolated and should **not** be assumed to see host executables in `/nix/store`. Installing both is technically possible, but there is no reason to do so until there is a concrete test plan.

## Decision criteria

- Does the Nix package find Octave/Sage/R/Julia?
- Can backend paths be configured cleanly when auto-detection fails?
- Does Cantor add useful workflow beyond native application GUIs and future notebooks?

## Related

- [[Flatpak]]
- [[Octave]]
- [[R]]
- [[Julia]]
- [[SageMath]]
