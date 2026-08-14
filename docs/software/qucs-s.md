---
title: Qucs-S
description: Pending choice between the older Nixpkgs Qucs-S integration and the current Flatpak release.
tags:
  - software
  - ee
  - circuit-simulation
  - flatpak
  - undecided
type: software
status: undecided
date: 2026-08-14
source-files:
  - home/engsci.nix
---

# Qucs-S

## Current repository state

The Nix package is present but commented out in `home/engsci.nix`:

```nix
# pkgs.qucs-s
```

No permanent installation method has been selected.

## Observed options on 2026-08-14

### Nixpkgs

The available Nixpkgs package was behind current upstream. Its main advantage is native host integration, including its configured simulator-kernel environment.

### Flatpak

The Flatpak tracked the current Qucs-S release more closely and bundled its own ngspice. Its sandbox/permissions make host simulator integration a separate concern.

### Local Nix package

Updating the existing Nixpkgs derivation is possible, but deliberately deferred until the simpler options have been tested.

## Decision criteria

Test before deciding:

- current-version functionality;
- project file access;
- ngspice behavior;
- [[qucsator-rf]] availability;
- [[Xyce]] integration;
- launcher/MIME ergonomics;
- maintenance burden.

## Related

- [[Flatpak]]
- [[ngspice]]
- [[qucsator-rf]]
- [[Xyce]]
- [[Scientific Software]]
