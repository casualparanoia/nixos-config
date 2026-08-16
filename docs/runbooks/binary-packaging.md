---
title: Binary Packaging Runbook
description: Operational procedure for inspecting and packaging a prebuilt Linux archive for NixOS.
tags:
  - runbook
  - nix
  - packaging
  - elf
type: runbook
status: active
date: 2026-08-16
source-files:
  - scripts/nix-binary-inspect
---

# Binary Packaging Runbook

## Inspect an upstream archive

From the repository root:

```bash
scripts/nix-binary-inspect URL
```

The script currently:

1. prefetches the archive through Nix;
2. prints a `fetchurl`-compatible hash;
3. extracts tar/zip archives and Debian packages;
4. prints Debian package metadata when applicable;
5. discovers ELF files;
6. reads their `DT_NEEDED` dependencies;
7. filters libraries already bundled by the application;
8. can query `nix-locate` for providers;
9. can verify candidates against the package set of this flake.

Debian inspection requires `dpkg-deb`, supplied by the Nixpkgs `dpkg` package in the development baseline.

Useful options include:

```bash
scripts/nix-binary-inspect --no-locate URL
scripts/nix-binary-inspect --no-verify URL
scripts/nix-binary-inspect --keep URL
```

## Build the package iteratively

After creating a derivation:

- build it before adding speculative dependencies;
- use the actual `autoPatchelfHook`/runtime failures to identify missing pieces;
- keep wrappers narrow rather than exporting broad global library paths;
- re-run inspection when upstream substantially changes its bundle.

## Related

- [[Foreign Binary Packaging]]
- [[AB Download Manager]]
- [[Logitech Mouse Tools]]
