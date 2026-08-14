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
date: 2026-08-14
---

# Package Source Policy

The installation method is chosen per program. There is no requirement that every application use the same distribution mechanism.

## Preferred options

1. Stable Nixpkgs when sufficiently current and functional.
2. `nixpkgs-unstable` when the stable package is materially behind or lacks a needed fix.
3. Project-local Nix environments for toolchains and language ecosystems that should not be coupled to the machine generation.
4. Flatpak for self-contained GUI applications when it gives a materially better/current package and sandbox constraints are acceptable.
5. A local Nix derivation from upstream source or generic Linux binaries when Nixpkgs is unsuitable.

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

- Nix manages executable/toolchain/system dependencies.
- A language-native project manager may manage project packages when it has strong lockfile semantics and works cleanly on NixOS.

See [[Project Environments]], [[Octave]], [[Julia]], [[R]], and [[Python Scientific Environments]].

## Flatpak

Flatpak does not inherently mean “cannot write outside the sandbox”. Effective access is determined by permissions and portals. Always inspect permissions for engineering applications that need project files, host tools, devices, or compilers.

See [[Flatpak]].
