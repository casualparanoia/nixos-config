---
title: R
description: R runtime choice and unresolved package-management strategy.
tags:
  - software
  - science
  - statistics
  - r
  - nixpkgs-unstable
type: software
status: experimental
date: 2026-08-14
source-files:
  - home/engsci.nix
---

# R

## Current configuration

```nix
pkgsUnstable.R
```

At the time this page was created, the selected unstable package was R 4.6.1.

## Unresolved choice

The runtime source is decided, but the package ecosystem is not.

Two serious models remain:

1. Nix-managed `rWrapper` / `rPackages` for a declarative package set.
2. Per-project `renv`, with Nix/devShell providing R, compilers, and external native libraries.

Do not expand the global R package set until this boundary is chosen from actual project requirements.

## Related

- [[Project Environments]]
- [[Cantor]]
- [[Scientific Software]]
