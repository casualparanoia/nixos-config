---
title: Scientific Software
description: Current engineering/scientific application matrix and unresolved package-source choices.
tags:
  - science
  - engineering
  - packages
  - index
type: index
status: active
date: 2026-08-14
source-files:
  - home/engsci.nix
---

# Scientific Software

`home/engsci.nix` is the current Home Manager module for global scientific/engineering applications.

## Current matrix

| Software | Current repository state | Intended source | Notes |
|---|---|---|---|
| [[Octave]] | enabled | unstable Nixpkgs | Forge packages deliberately excluded from global HM |
| [[Julia]] | enabled | stable Nixpkgs `julia-bin` | use Julia project environment for Julia packages |
| [[SageMath]] | enabled | stable Nixpkgs | integrated math/CAS stack |
| [[R]] | enabled | unstable Nixpkgs | package-management strategy still open |
| [[Xyce]] | enabled | stable Nixpkgs | SPICE-compatible simulator |
| [[KiCad]] | enabled | stable Nixpkgs | EDA/PCB suite |
| [[openEMS]] | enabled | unstable Nixpkgs | selected with unstable Octave ecosystem |
| [[GNU Radio]] | enabled | stable Nixpkgs | DSP/SDR framework |
| [[ngspice]] | commented out | undecided/deferred | Nixpkgs usable; newer custom package postponed |
| [[Qucs-S]] | commented out | undecided | Nixpkgs versus Flatpak/current upstream |
| [[qucsator-rf]] | commented out | undecided | Qucs-S can provide/use it without global PATH exposure |
| [[Cantor]] | commented out | undecided | backend integration needs testing |
| [[Scilab]] | absent | deferred | current Nixpkgs package is too old; revisit Flatpak/custom Nix later |
| [[Python Scientific Environments]] | absent | deferred | likely `uv`, Nix devShell, or both |

## Global-versus-project rule

Keep broadly useful applications globally available, but avoid coupling language package ecosystems to every Home Manager/NixOS rebuild.

See [[Project Environments]] and [[Package Source Policy]].
