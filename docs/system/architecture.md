---
title: System Architecture
description: High-level architecture of the current NixOS flake and Home Manager configuration.
tags:
  - nixos
  - architecture
  - flakes
type: architecture
status: accepted
date: 2026-08-14
source-files:
  - flake.nix
  - configuration.nix
  - home/home.nix
---

# System Architecture

## Top-level model

The machine is configured by a flake with two Nixpkgs inputs:

```text
nixpkgs             -> nixos-26.05 (default/stable package set)
nixpkgs-unstable    -> nixos-unstable (selectively imported as pkgsUnstable)
home-manager        -> release-26.05, following stable nixpkgs
```

`pkgsUnstable` is imported once in `flake.nix` and passed through `specialArgs` to NixOS modules and `extraSpecialArgs` to Home Manager modules. This allows explicit package-by-package selection without changing the entire system to unstable.

See [[ADR 0002 - Stable Plus Unstable Package Sets]].

## NixOS layer

`configuration.nix` imports machine/system modules including:

- hardware tuning and workarounds;
- Niri;
- desktop/session integration;
- appearance;
- DankMaterialShell;
- system packages;
- [[Crash Monitor]];
- AdGuard Home.

System-level packages are intentionally kept relatively small. User-facing applications generally belong to Home Manager unless they need system integration.

## Home Manager layer

`home/home.nix` imports user modules for appearance, applications, dotfiles, Niri settings, MIME associations, CLI tools, desktop applications, screenshots, downloads, and engineering/scientific software.

The scientific package set currently lives in `home/engsci.nix`.

## Local packages

Packages unavailable or unsuitable in Nixpkgs can live under `packages/` and be imported with `pkgs.callPackage`. The current example is [[AB Download Manager]].

## Reproducibility

`flake.lock` pins the exact revisions of stable Nixpkgs, unstable Nixpkgs, Home Manager, and other flake inputs. Updating an input is therefore a deliberate repository change rather than an implicit package-manager state change.

## Related

- [[Package Source Policy]]
- [[Project Environments]]
- [[Documentation System]]
- [[Rebuild Runbook]]
