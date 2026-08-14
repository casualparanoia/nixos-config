---
title: ngspice
description: Deferred decision on persistent ngspice installation versus a future current-upstream local package.
tags:
  - software
  - ee
  - spice
  - circuit-simulation
  - deferred
type: software
status: deferred
date: 2026-08-14
source-files:
  - home/engsci.nix
---

# ngspice

## Current repository state

`pkgs.ngspice` is present but commented out in `home/engsci.nix`.

The stable Nixpkgs package is usable, but packaging a newer upstream version was discussed. That custom work is intentionally postponed until a newer feature is actually needed or the simulator is required directly.

Qucs-S and KiCad can each have their own integration concerns, so “ngspice exists somewhere in a dependency closure” is not identical to having a standalone `ngspice` command in the normal user environment.

## Related

- [[Qucs-S]]
- [[KiCad]]
- [[Xyce]]
- [[Scientific Software]]
