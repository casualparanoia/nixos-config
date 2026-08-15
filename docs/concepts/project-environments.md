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
date: 2026-08-15
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

[[Julia]] may primarily use Julia's own project/manifest mechanism while Nix supplies the runtime and external host dependencies.

## Related

- [[Package Source Policy]]
- [[ADR 0003 - Octave Package Management]]
