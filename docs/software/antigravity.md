---
title: Antigravity
description: Source and update policy for the Google Antigravity application.
tags:
  - software
  - development
  - ai
  - flakes
type: software
status: active
date: 2026-08-15
source-files:
  - flake.nix
  - home/packages.nix
---

# Antigravity

Antigravity is installed through the dedicated [`jacopone/antigravity-nix`](https://github.com/jacopone/antigravity-nix) flake rather than the older `antigravity-ide-fhs` package from `nixpkgs-unstable`.

The explicit `google-antigravity-ide` output preserves the existing IDE and `antigravity-ide` command while moving its updates to the dedicated flake. The pinned input currently packages IDE version 2.5.5. The flake's separate Antigravity 2.0 base application and CLI are not installed.

The input follows the system's stable Nixpkgs input and is pinned by `flake.lock`. Update it independently with:

```bash
nix flake update antigravity-nix
```

Antigravity is proprietary software, so the existing unfree-package allowance remains required.

## Related

- [[Development Tooling]]
- [[Package Source Policy]]
- [[Rebuild Runbook]]
