---
title: NixOS Knowledge Base
description: Entry point for the configuration, decisions, workarounds, investigations, software policy, and operational notes for this NixOS installation.
tags:
  - nixos
  - index
  - knowledge-base
type: index
status: active
date: 2026-08-15
---

# NixOS Knowledge Base

This knowledge base records not only **what** the configuration does, but also **why**, what remains uncertain, and how to operate or remove non-obvious pieces.

> [!important]
> The Markdown files in `docs/` are the source of truth. Quartz, Obsidian, Kate, Helix, or any future viewer/editor are replaceable interfaces over these files.

## Current configuration architecture

- [[System Architecture]] — stable/unstable Nixpkgs, NixOS, Home Manager, local packages.
- [[Documentation System]] — documentation model, Quartz role, linking and metadata.
- [[Quartz Setup]] — how to render this `docs/` tree as a local searchable wiki.
- [[Package Source Policy]] — how software installation methods are chosen.
- [[Metadata Schema]] — page types, statuses, tags, and conventions.

## Hardware and machine-specific work

- [[Laptop]]
- [[AMD Backlight Workaround]] — active temporary brightness clamp.
- [[Fan Control]] — NBFC configuration and fan curves.
- [[Crash Investigation]] — unresolved freeze/black-screen investigation.
- [[Crash Monitor]] — diagnostic service implementation.

## Scientific / engineering software

See [[Scientific Software]] for the current matrix.

Implemented now:

- [[Octave]]
- [[Julia]]
- [[R]]
- [[SageMath]]
- [[Xyce]]
- [[KiCad]]
- [[openEMS]]
- [[GNU Radio]]

Deferred or undecided:

- [[Qucs-S]]
- [[ngspice]]
- [[qucsator-rf]]
- [[Cantor]]
- [[Scilab]]
- [[Python Scientific Environments]]

## Local packages and tooling

- [[AB Download Manager]]
- [[Antigravity]]
- [[Development Tooling]]
- [[Foreign Binary Packaging]]
- [[Binary Packaging Runbook]]

## Operations

- [[Rebuild Runbook]]
- [[Crash Monitor Runbook]]

## Architectural decisions

- [[ADR 0001 - Documentation Architecture]]
- [[ADR 0002 - Stable Plus Unstable Package Sets]]
- [[ADR 0003 - Octave Package Management]]

## Open work

See [[TODO]].
