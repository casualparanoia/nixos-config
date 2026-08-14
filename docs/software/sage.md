---
title: SageMath
description: SageMath installation policy.
tags:
  - software
  - science
  - mathematics
  - cas
type: software
status: accepted
date: 2026-08-14
source-files:
  - home/engsci.nix
---

# SageMath

## Current configuration

```nix
pkgs.sage
```

SageMath is kept on stable Nixpkgs. Its dependency graph is large and integrated, so maintaining a custom package would have little value while the stable package is current enough for the intended use.

## Related

- [[Scientific Software]]
- [[Cantor]]
