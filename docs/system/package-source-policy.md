---
title: Package Source Policy
description: Package-set and source-selection policy for this NixOS configuration.
tags:
  - nixos
  - packages
  - unstable
  - flatpak
  - policy
type: architecture
status: accepted
date: 2026-08-23
---

# Package Source Policy

The system uses a stable NixOS base while explicitly selected user applications and tools normally track `nixpkgs-unstable`.

The core rule is:

```text
Operating system and module-selected infrastructure:
    stable = normal

Explicitly selected user packages:
    unstable = normal
    stable = exception
```

This keeps the operating system on the release branch while allowing user-facing software to update at the faster `nixos-unstable` cadence. It also avoids unnecessarily mixing stable and unstable application dependency graphs when many explicitly selected applications already come from unstable.

## Nixpkgs package sets

The repository exposes two package sets:

- `pkgs` is the stable `nixos-26.05` package set used by NixOS and Home Manager.
- `pkgsUnstable` is the `nixos-unstable` package set passed explicitly to modules that need it.

NixOS remains based on stable `nixpkgs`, and Home Manager remains on `release-26.05`.

Do not replace the global `pkgs` set with unstable and do not override NixOS module package defaults merely to make them newer.

## System packages and infrastructure

Stable `pkgs` is the normal source for operating-system infrastructure and packages selected as part of system integration, including areas such as:

- boot, filesystems, and core runtime infrastructure;
- networking and system services;
- NixOS module defaults;
- hardware support and host-critical service dependencies;
- login or recovery shells when they are part of account/system infrastructure;
- low-level diagnostic utilities when there is no concrete reason to prefer unstable.

A package being available in `nixpkgs-unstable` is not by itself a reason to override a stable NixOS module default.

## Explicit user applications and tools

Ordinary software explicitly selected for the user normally comes from `pkgsUnstable`.

This includes, when applicable:

- editors and terminal applications;
- browsers and communication applications;
- media, image, document, and file-management applications;
- user CLI and terminal-productivity tools;
- version-control clients and related utilities;
- language servers, formatters, linters, and editor-adjacent development tools;
- scientific and engineering applications;
- game launchers and other user-facing gaming utilities.

Home Manager program or service modules may implicitly select a package from stable `pkgs`. When an enabled module represents an ordinary user application and exposes a `package` option, set it explicitly to the corresponding `pkgsUnstable` package when practical.

A stable explicit user package is an exception. Keep one on stable only for a concrete reason such as a known regression, compatibility constraint, required version, unavailable/broken unstable package, or another tested operational requirement. Add a short comment when the reason is not obvious.

Package size or a large dependency graph is not, by itself, a reason to keep an explicit user package stable.

## Development toolchains

Toolchains are not automatically system infrastructure merely because they are compilers, runtimes, or build tools.

An explicitly installed development tool may use `pkgsUnstable` under the same default rule as other user software. Keep a toolchain on stable only when there is a concrete version, compatibility, reproducibility, or project requirement.

Project-specific toolchains and dependencies should still prefer isolated project environments when coupling them to the machine generation would be undesirable.

## Other package sources

Stable versus unstable Nixpkgs is only one source decision. Some software is intentionally sourced elsewhere.

A dedicated upstream or community flake is appropriate when it provides materially better maintenance, packaging, or integration and can be pinned in `flake.lock`.

Flatpak is appropriate for selected self-contained GUI applications when upstream support, update cadence, dependency isolation, or portal integration makes it materially preferable and the sandbox permissions are acceptable.

A local Nix derivation is appropriate when Nixpkgs or another maintained source is unsuitable.

Do not replace an intentionally selected external flake, Flatpak, or local package with a Nixpkgs package merely to make stable/unstable usage visually uniform.

Home Manager and NixOS modules are configuration layers, not independent package sources.

## Local package preference

When maintaining a local Nix package, prefer roughly:

```text
manageable upstream source
    > generic upstream Linux binary
    > AppImage
    > distro-specific DEB/RPM
```

This is not an absolute hierarchy. Upstream support, reproducibility, integration quality, and maintenance cost matter more than the packaging format itself.

## Project environments

Nix manages shared executables, baseline tools, and system dependencies. A language-native project manager may manage project dependencies when it has strong lockfile semantics and works cleanly on NixOS.

For example, Python uses the Nix-managed interpreter and `uv`; ordinary projects need no project flake solely for Python packages, while native/system requirements may justify a `devShell`.

See [[Project Environments]], [[Octave]], [[Julia]], [[R]], and [[Python Scientific Environments]].

## Flatpak

Flatpak is a deliberate source choice for selected GUI applications, not a default merely because a Flathub package exists. Effective access is determined by sandbox permissions and portals; inspect applications that need project files, host tools, devices, compilers, or broad filesystem access.

See [[Flatpak]].

## Maintenance rule

Do not silently migrate packages between stable, unstable, external flakes, Flatpak, or local derivations during unrelated work.

When changing a package source, preserve the reason in the surrounding configuration or documentation when the choice is exceptional or non-obvious.
