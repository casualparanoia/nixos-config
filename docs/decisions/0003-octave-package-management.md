---
title: ADR 0003 - Octave Package Management
description: Decision to install Octave globally without a large octave.withPackages Forge environment.
tags:
  - adr
  - octave
  - science
  - reproducibility
type: decision
status: accepted
date: 2026-08-14
source-files:
  - home/engsci.nix
---

# ADR 0003 - Octave Package Management

## Context

A previous configuration used `octaveFull.withPackages` with a large set of Octave Forge packages. Nix constructs such an environment by invoking Octave during the derivation build to install the selected packages. This made normal configuration rebuilds depend on a broad and sometimes fragile Forge package graph.

## Decision

Install the Octave application globally as:

```nix
pkgsUnstable.octaveFull
```

Do **not** place a large `octave.withPackages` environment in the normal Home Manager generation.

When Forge packages are required, they should be built locally using the `shells/octave-pkg.nix` development shell, which provides the necessary system libraries and compilers, so failures in optional Octave packages cannot block unrelated NixOS/Home Manager rebuilds.

## Consequences

### Positive

- normal machine rebuilds are less coupled to Forge packages;
- the global package graph is smaller;
- different projects can use different Octave package sets.

### Negative

- engineering projects that need Forge packages require an explicit environment;
- package setup is no longer “everything globally available”.

## Related

- [[Octave]]
- [[Project Environments]]
- [[Scientific Software]]
