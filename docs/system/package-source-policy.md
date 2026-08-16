---
title: Package Source Policy
description: Preferred order and decision criteria for installing software on this NixOS system.
tags:
  - nixos
  - packages
  - flatpak
  - policy
type: architecture
status: accepted
date: 2026-08-16
---

# Package Source Policy

Nix/Nixpkgs remains the primary source for the operating system, services, development and CLI tools, toolchains, and infrastructure. The installation method is still chosen per program; selected GUI applications may use another source when it is demonstrably a better fit.

## Preferred options

1. Stable Nixpkgs when sufficiently current and functional.
2. `nixpkgs-unstable` when the stable package is materially behind or lacks a needed fix.
3. Project-local Nix environments for toolchains and language ecosystems that should not be coupled to the machine generation.
4. Flatpak for selected self-contained GUI applications when upstream support, update cadence, dependency isolation, or portal integration makes it materially preferable and sandbox constraints are acceptable.
5. A dedicated upstream or community flake when it provides materially better maintenance and can be pinned in `flake.lock`.
6. A local Nix derivation from upstream source or generic Linux binaries when Nixpkgs is unsuitable.

Home Manager and NixOS modules are configuration layers, not independent package sources.

## Source packaging preference

When maintaining a local Nix package, prefer roughly:

```text
manageable upstream source
    > generic upstream Linux binary
    > AppImage
    > distro-specific DEB/RPM
```

This is not an absolute rule; upstream support and maintenance cost matter more than ideology.

## Toolchains versus applications

A useful boundary is:

- Nix manages shared executables, baseline toolchains, and system dependencies.
- A language-native project manager may manage project packages when it has strong lockfile semantics and works cleanly on NixOS.
- Python uses the Nix-managed interpreter and `uv`; ordinary projects need no Nix flake, while native/system requirements belong in a `devShell`.

See [[Project Environments]], [[Octave]], [[Julia]], [[R]], and [[Python Scientific Environments]].

## Flatpak

Flatpak is a deliberate exception for selected GUI applications, not a default whenever Flathub has a package. Effective access is determined by permissions and portals; inspect applications that need project files, host tools, devices, or compilers.

See [[Flatpak]].
