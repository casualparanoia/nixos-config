---
title: Python Scientific Environments
description: Deferred strategy for Python scientific projects using uv, Nix devShells, or a combination.
tags:
  - software
  - python
  - science
  - uv
  - devshell
type: software
status: deferred
date: 2026-08-14
---

# Python Scientific Environments

A global scientific Python environment is deliberately deferred.

The intended direction is project-level isolation using either:

- `uv` for Python dependency/environment management;
- Nix `devShell`s for reproducible system/toolchain dependencies;
- a hybrid model where Nix supplies native/system dependencies and `uv` manages Python packages.

Avoid putting a giant NumPy/SciPy/Pandas/Matplotlib/ML environment into normal Home Manager until there is a clear shared-use case.

## Related

- [[Project Environments]]
- [[GNU Radio]]
- [[Scientific Software]]
