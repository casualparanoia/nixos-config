---
title: Xyce
description: SPICE-compatible high-performance circuit simulator in the engineering stack.
tags:
  - software
  - ee
  - circuit-simulation
  - spice
type: software
status: accepted
date: 2026-08-14
source-files:
  - home/engsci.nix
---

# Xyce

## Current configuration

```nix
pkgs.xyce
```

Xyce is installed as a standalone simulator alongside the broader EDA/scientific stack. No MPI customization has been introduced; keep the default package until a real large-scale simulation workload justifies extra complexity.

## Related

- [[Qucs-S]]
- [[ngspice]]
- [[Scientific Software]]
