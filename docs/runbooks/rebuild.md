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

Assume commands are run from the repository root. Select the target host first:

```bash
host=gl702zc # Or: host=desktop
```

The flake exports `gl702zc` and `desktop`; the old `nixos` alias is obsolete.
Desktop validation requires its real hardware artifacts.

## Format and evaluate

```bash
nix fmt
nix flake check --no-build
```

`nix fmt` uses the formatter declared by the flake. The check evaluates flake outputs without realizing the complete NixOS closure.

## Validate/build without activation

```bash
sudo nixos-rebuild build --flake ".#${host}"
```

Use this to prove that evaluation and realization succeed without changing the running system profile.

Use `"path:.#${host}"` while new source files are untracked and must be included
without staging them.

## Activate temporarily

```bash
sudo nixos-rebuild test --flake ".#${host}"
```

This activates the new configuration for the current boot but does not make it the boot default.
It can restart stateful services and run database migrations; it is not a safe
substitute for a non-activating build.

## Activate and make default

```bash
sudo nixos-rebuild switch --flake ".#${host}"
```

## Input updates

`flake.lock` is the reproducibility boundary. Review lockfile changes when updating inputs; do not treat an input update as equivalent to an ordinary rebuild.

## Related

- [[runbooks/private-server|Private Server Runbook]] — GL702ZC-specific deployment prerequisites and checks.
- [[system/architecture|System Architecture]]
- [[decisions/0002-stable-plus-unstable|ADR 0002 - Stable Plus Unstable Package Sets]]
