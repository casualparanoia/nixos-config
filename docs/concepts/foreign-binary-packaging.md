---
title: Foreign Binary Packaging
description: Strategy for adapting upstream prebuilt Linux applications to NixOS.
tags:
  - nix
  - packaging
  - elf
  - autopatchelf
type: concept
status: accepted
date: 2026-08-14
source-files:
  - scripts/nix-binary-inspect
  - packages/ab-download-manager.nix
---

# Foreign Binary Packaging

When source builds are impractical but upstream provides a Linux binary archive, prefer a reproducible local Nix derivation over an imperative installation into the home directory.

## Typical process

1. Fetch the archive through Nix and record its fixed hash.
2. Extract it and inspect ELF executables/shared libraries.
3. Determine external `DT_NEEDED` libraries not bundled by upstream.
4. Map those libraries to Nixpkgs packages.
5. Use `autoPatchelfHook` where appropriate.
6. Wrap runtime environment variables only when the program requires them.
7. Install desktop files/icons if upstream layout does not integrate automatically.
8. Test in a clean build/run context.

`scripts/nix-binary-inspect` automates the early inspection steps and can query/verify candidate Nixpkgs providers.

## Related

- [[AB Download Manager]]
- [[Binary Packaging Runbook]]
- [[Scilab]]
