---
title: TODO
description: Open work and unresolved configuration decisions.
tags:
  - todo
  - index
type: index
status: active
date: 2026-08-16
---

# TODO

## Documentation system

- [ ] Decide whether to use Obsidian as an optional editor in addition to Kate/Helix.
- [ ] Review the metadata schema after the first few weeks of use; avoid adding fields without a demonstrated need.
- [ ] Add links from relevant `.nix` files to their corresponding documentation pages.

## Scientific software

- [ ] [[Qucs-S]]: compare Nixpkgs and Flatpak behavior before choosing a permanent installation path.
- [ ] [[ngspice]]: keep custom/current-upstream packaging deferred until there is a concrete need.
- [ ] [[Scilab]]: later evaluate current Flatpak versus a custom Nix package based on the upstream binary archive.
- [ ] [[Cantor]]: test whether the Nix package can use the desired installed backends; do not assume the Flatpak can see host Nix executables.
- [ ] [[qucsator-rf]]: decide whether it needs to be exposed directly on the normal shell `PATH`.
- [ ] [[R]]: decide between Nix-managed `rWrapper` package sets and per-project `renv`.
- [ ] [[Octave]]: create an isolated engineering/project environment if Forge packages are needed.

## Hardware / stability

- [ ] [[hardware/backlight|AMD Backlight Workaround]]: determine the root cause of brightness wrap/drop above the safe request value.
- [ ] [[Fan Control]]: continue validating automatic fan behavior under sustained CPU/GPU load.
- [ ] [[Crash Investigation]]: continue collecting evidence until the black-screen/freeze root cause is isolated.
- [ ] Review disabled/test kernel parameters before permanently enabling additional workarounds.

## Packaging

- [ ] [[AB Download Manager]]: document/update procedure when the upstream version changes.
- [ ] [[Foreign Binary Packaging]]: extend `scripts/nix-binary-inspect` only when a real package exposes a missing capability.
