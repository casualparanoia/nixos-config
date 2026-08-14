---
title: KiCad
description: PCB and schematic EDA suite in the engineering software stack.
tags:
  - software
  - ee
  - eda
  - pcb
type: software
status: accepted
date: 2026-08-14
source-files:
  - home/engsci.nix
---

# KiCad

## Current configuration

```nix
pkgs.kicad
```

KiCad is installed from stable Nixpkgs. It belongs in the persistent workstation environment rather than a project-only devShell because it is a general-purpose engineering application.

## Related

- [[ngspice]]
- [[Scientific Software]]
