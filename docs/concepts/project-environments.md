---
title: Project Environments
description: Policy for keeping project-specific scientific toolchains and language packages out of the global machine generation.
tags:
  - nix
  - devshell
  - reproducibility
  - science
type: concept
status: accepted
date: 2026-08-16
aliases:
  - Scientific Project Environments
---

# Project Environments

The persistent Home Manager environment may contain broadly useful applications, editor services, debuggers, and baseline toolchains. Project-specific language packages, compiler versions, and scientific dependencies should move to project environments when they become substantial or fragile.

Typical structure:

```text
project/
├── flake.nix
├── flake.lock
└── project-specific files
```

with:

```bash
nix develop
```

## Motivation

This avoids making every system rebuild depend on every historical project's package graph.

Examples:

- [[Octave]] Forge package sets;
- [[R]] + native geospatial/statistical dependencies;
- [[Python Scientific Environments]];
- project compilers and build tools.

Ordinary Python projects use the global Nix-managed interpreter with `uv` and do not require a Nix flake. Add a `devShell` when native libraries, special compilers, accelerators, external system packages, or stronger Nix-level reproducibility are required; `uv` can continue to manage the Python dependency graph inside that shell.

[[Julia]] may primarily use Julia's own project/manifest mechanism while Nix supplies the runtime and external host dependencies.

## Related

- [[Package Source Policy]]
- [[decisions/0003-octave-package-management|ADR 0003 - Octave Package Management]]
