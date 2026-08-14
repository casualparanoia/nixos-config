---
title: AB Download Manager
description: Local Nix derivation for the upstream prebuilt AB Download Manager Linux archive.
tags:
  - software
  - custom-package
  - binary-packaging
  - downloads
type: software
status: active
date: 2026-08-14
source-files:
  - packages/ab-download-manager.nix
  - home/downloads.nix
---

# AB Download Manager

## Current implementation

AB Download Manager is packaged locally rather than installed imperatively.

`home/downloads.nix` imports it with:

```nix
pkgs.callPackage ../packages/ab-download-manager.nix { }
```

The derivation currently packages upstream version `1.10.1` from its Linux x86-64 tarball.

## Packaging strategy

The package:

- fetches the upstream archive with a fixed hash;
- uses `autoPatchelfHook`;
- declares required runtime libraries;
- installs the unpacked program under `$out/opt/ABDownloadManager`;
- creates a wrapped executable under `$out/bin`;
- supplies `fontconfig` through `LD_LIBRARY_PATH` for a runtime lookup requirement;
- creates a desktop entry and application icon link.

## Why this is documented

Binary repackaging can keep working for months and then fail after an upstream release because bundled libraries, ELF dependencies, layout, or startup behavior changed. The update path should therefore be reproducible rather than rediscovered.

## Updating

See [[Binary Packaging Runbook]] and [[Foreign Binary Packaging]].
