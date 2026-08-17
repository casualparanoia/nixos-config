---
title: System Architecture
description: High-level architecture of the NixOS flake, modules, Home Manager, and external integrations.
tags:
  - nixos
  - architecture
  - flakes
type: architecture
status: accepted
date: 2026-08-17
source-files:
  - flake.nix
  - configuration.nix
  - home/home.nix
  - modules/flatpak.nix
  - modules/gaming.nix
  - home/gaming.nix
  - modules/logitech-mouse.nix
  - modules/nirinit.nix
---

# System Architecture

## Top-level model

The machine is configured by a flake with stable Nixpkgs as the primary package set, an explicitly selected unstable set, and pinned specialist inputs:

```text
nixpkgs             -> nixos-26.05 (default/stable package set)
nixpkgs-unstable    -> nixos-unstable (selectively imported as pkgsUnstable)
home-manager        -> release-26.05, following stable nixpkgs
antigravity-nix     -> dedicated, lockfile-pinned Antigravity package
nirinit             -> v0.2.2 Niri session service, following stable nixpkgs
nix-flatpak         -> v0.7.0 declarative Flatpak NixOS module
nix-index-database  -> command-not-found database, following stable nixpkgs
helium              -> browser package, following stable nixpkgs
vicinae             -> launcher Home Manager module and package
```

`pkgsUnstable` is imported once in `flake.nix` and passed through `specialArgs` to NixOS modules and `extraSpecialArgs` to Home Manager modules. This allows explicit package-by-package selection without changing the entire system to unstable.

Home Manager, Helium, Antigravity, nirinit, and nix-index follow the primary Nixpkgs input where their interfaces permit it. `nix-flatpak` has no Nixpkgs input. Vicinae retains the package inputs defined by its upstream flake.

See [[decisions/0002-stable-plus-unstable|ADR 0002 - Stable Plus Unstable Package Sets]].

## NixOS layer

`configuration.nix` imports machine/system modules including:

- hardware tuning and workarounds;
- [[Logitech Mouse Tools]] and their device-access rules;
- Niri;
- [[Nirinit]] session persistence;
- desktop/session integration;
- [[system/gaming|gaming graphics, Steam, and runtime integration]];
- declarative [[Flatpak]] applications;
- appearance;
- DankMaterialShell;
- system packages;
- [[services/crash-monitor|Crash Monitor]];
- AdGuard Home.

System-level packages are intentionally kept relatively small. User-facing applications generally belong to Home Manager unless they need system integration.

## Home Manager layer

`home/home.nix` imports user modules for appearance, applications, dotfiles, Niri settings, MIME associations, CLI tools, desktop applications, screenshots, downloads, development tooling, engineering/scientific software, and gaming launchers/instrumentation.

The scientific package set currently lives in `home/engsci.nix`.
Reusable programming tools live in `home/development.nix`; project dependencies remain project-local.
Gaming launchers and opt-in MangoHud configuration live in `home/gaming.nix`; host graphics, Steam, GameMode, and diagnostics live in `modules/gaming.nix`.

## Local packages

Packages unavailable or unsuitable in Nixpkgs can live under `packages/` and be imported with `pkgs.callPackage`. Current examples are [[AB Download Manager]] and the prebuilt OpenLogi package documented in [[Logitech Mouse Tools]].

## Reproducibility

`flake.lock` pins the exact revisions of stable Nixpkgs, unstable Nixpkgs, Home Manager, and other flake inputs. Updating an input is therefore a deliberate repository change rather than an implicit package-manager state change.

## Related

- [[Package Source Policy]]
- [[Project Environments]]
- [[Documentation System]]
- [[runbooks/rebuild|Rebuild Runbook]]
