---
title: Octave
description: Octave installation and Forge package-management policy.
tags:
  - software
  - science
  - octave
  - nixpkgs-unstable
type: software
status: accepted
date: 2026-08-14
source-files:
  - home/engsci.nix
---

# Octave

## Current configuration

```nix
pkgsUnstable.octaveFull
```

Octave is intentionally selected from unstable.

## Forge packages

A previous configuration used a large `octaveFull.withPackages` set. That caused the Nix derivation to build an Octave package environment by invoking Octave and made normal rebuilds depend on many Forge packages.

The current policy is therefore **not** to place a large Forge set in global Home Manager.

If Forge packages such as control/signal/communications/statistics are needed, create a separate project or named environment.

See [[decisions/0003-octave-package-management|ADR 0003 - Octave Package Management]].

## Related

- [[openEMS]]
- [[Scientific Software]]
- [[Project Environments]]
