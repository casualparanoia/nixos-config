---
title: openEMS
description: Electromagnetic FDTD solver selected from unstable Nixpkgs.
tags:
  - software
  - ee
  - electromagnetics
  - fdtd
  - octave
  - nixpkgs-unstable
type: software
status: accepted
date: 2026-08-14
source-files:
  - home/engsci.nix
---

# openEMS

## Current configuration

```nix
pkgsUnstable.openems
```

The package is selected from unstable primarily to keep its Octave-side integration aligned with the unstable package set used for [[Octave]], even when the openEMS application version itself may match stable.

## Related

- [[Octave]]
- [[Scientific Software]]
