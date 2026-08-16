---
title: ADR 0002 - Stable Plus Unstable Package Sets
description: Decision to keep NixOS 26.05 as the default package set and selectively consume nixos-unstable.
tags:
  - adr
  - nixpkgs
  - flakes
  - unstable
type: decision
status: accepted
date: 2026-08-14
source-files:
  - flake.nix
---

# ADR 0002 - Stable Plus Unstable Package Sets

## Context

Some applications need newer versions than the stable NixOS release provides, while moving the entire system to unstable would increase churn and make unrelated packages change together.

## Decision

Use `nixos-26.05` as the default `nixpkgs` input and import a second `nixos-unstable` input as `pkgsUnstable`. Select unstable packages explicitly where there is a concrete reason.

The flake passes `pkgsUnstable` into both NixOS modules and Home Manager modules.

## Consequences

- most of the machine follows the stable release;
- selected applications can track unstable independently;
- the store may contain more than one version of some dependencies;
- dependency-sensitive ecosystems should be kept internally consistent when practical.

A current example is [[openEMS]] being selected from unstable alongside unstable [[Octave]].

## Related

- [[system/architecture|System Architecture]]
- [[Package Source Policy]]
