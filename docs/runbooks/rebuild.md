---
title: Rebuild Runbook
description: Normal flake-based commands and safety distinctions for evaluating and activating this NixOS configuration.
tags:
  - runbook
  - nixos
  - flakes
  - rebuild
type: runbook
status: active
date: 2026-08-15
---

# Rebuild Runbook

Assume commands are run from the repository root.

## Format and evaluate

```bash
nix fmt
nix flake check --no-build
```

`nix fmt` uses the formatter declared by the flake. The check evaluates flake outputs without realizing the complete NixOS closure.

## Validate/build without activation

```bash
sudo nixos-rebuild build --flake .#nixos
```

Use this to prove that evaluation and realization succeed without changing the running system profile.

## Activate temporarily

```bash
sudo nixos-rebuild test --flake .#nixos
```

This activates the new configuration for the current boot but does not make it the boot default.

## Activate and make default

```bash
sudo nixos-rebuild switch --flake .#nixos
```

## Input updates

`flake.lock` is the reproducibility boundary. Review lockfile changes when updating inputs; do not treat an input update as equivalent to an ordinary rebuild.

## Related

- [[system/architecture|System Architecture]]
- [[decisions/0002-stable-plus-unstable|ADR 0002 - Stable Plus Unstable Package Sets]]
