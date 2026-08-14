---
title: Julia
description: Julia installation and project-package boundary.
tags:
  - software
  - science
  - julia
type: software
status: accepted
date: 2026-08-14
source-files:
  - home/engsci.nix
---

# Julia

## Current configuration

```nix
pkgs.julia-bin
```

The binary package is used so the Julia runtime follows the upstream-provided binary while still being installed through Nix.

## Julia packages

Prefer Julia's project mechanism (`Project.toml` / `Manifest.toml`) for Julia ecosystem packages unless a concrete Nix integration requirement appears.

Nix remains responsible for the runtime and host/system dependencies.

## Related

- [[Project Environments]]
- [[Scientific Software]]
- [[Cantor]]
