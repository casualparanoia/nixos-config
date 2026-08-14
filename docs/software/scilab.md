---
title: Scilab
description: Deferred installation decision because the Nixpkgs package is substantially behind current upstream.
tags:
  - software
  - science
  - numerical
  - flatpak
  - custom-package
type: software
status: deferred
date: 2026-08-14
---

# Scilab

Scilab is intentionally **not installed yet**.

At the time of investigation, Nixpkgs carried an old Scilab generation while upstream and Flatpak were much newer. Two credible future paths remain:

1. test the current Flatpak as a self-contained GUI application;
2. create a local Nix package around the official upstream Linux binary archive, using the existing Nixpkgs binary-package derivation as a reference.

Do not spend maintenance effort on this until Scilab is actually needed.

## Related

- [[Flatpak]]
- [[Foreign Binary Packaging]]
- [[Scientific Software]]
