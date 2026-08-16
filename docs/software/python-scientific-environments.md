---
title: Python Scientific Environments
description: Python and uv policy for ordinary projects, scientific dependencies, and hybrid Nix development environments.
tags:
  - software
  - python
  - science
  - uv
  - devshell
type: software
status: accepted
date: 2026-08-16
source-files:
  - home/development.nix
---

# Python Scientific Environments

Nix provides a globally available Python interpreter and `uv`. `uv` is the default manager for project dependencies and virtual environments; the global Home Manager environment deliberately contains no NumPy, SciPy, Pandas, Matplotlib, Jupyter, machine-learning framework, or similar scientific package collection.

The baseline also includes Ruff for formatting and linting and `ty` for type analysis. Both are installed as Nix packages rather than into a global Python environment. Helix discovers their language servers from `PATH`; individual projects may still pin different versions through `uv`.

## Ordinary projects

An ordinary Python project does not need a Nix flake merely because it uses Python:

```bash
uv init
uv add numpy pandas matplotlib
uv run python
```

The dependency graph and virtual environment belong to the project. Prefer the Nix-managed interpreter when it satisfies the project rather than making interpreters downloaded by `uv` the machine-wide foundation.

## Projects with native dependencies

Use a Nix `devShell` when a project needs system libraries, special compilers, CUDA/ROCm, external tools, or stronger Nix-level environment reproducibility. Nix and `uv` can be combined:

```bash
nix develop
uv sync
```

In that model, Nix normally provides the native/system substrate and Python interpreter while `uv` manages Python dependencies. Project-specific Python tools may also be pinned through `uv` when reproducibility requires it.

## Boundary

- Nix owns the persistent interpreter, `uv`, and shared editor tooling.
- `uv` owns normal project dependency graphs and virtual environments.
- Nix `devShell`s own exceptional native and system requirements.
- No global scientific Python environment is maintained.

## Related

- [[Project Environments]]
- [[software/gnuradio|GNU Radio]]
- [[Scientific Software]]
