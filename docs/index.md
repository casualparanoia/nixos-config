---
title: NixOS Knowledge Base
description: Entry point for the configuration, decisions, workarounds, investigations, software policy, and operational notes for this NixOS installation.
tags:
  - nixos
  - index
  - knowledge-base
type: index
status: active
date: 2026-08-16
---

# NixOS Knowledge Base

This knowledge base records not only **what** the configuration does, but also **why**, what remains uncertain, and how to operate or remove non-obvious pieces.

> [!important]
> The Markdown files in `docs/` are the source of truth. Quartz, Obsidian, Kate, Helix, or any future viewer/editor are replaceable interfaces over these files.

## Current configuration architecture

- [[system/architecture|System Architecture]] — flake inputs, NixOS, Home Manager, services, and package layers.
- [[Documentation System]] — documentation model, Quartz role, linking and metadata.
- [[system/quartz|Quartz Setup]] — how to render this `docs/` tree as a local searchable wiki.
- [[Package Source Policy]] — how software installation methods are chosen.
- [[Metadata Schema]] — page types, statuses, tags, and conventions.

## Hardware and machine-specific work

- [[Laptop]]
- [[hardware/backlight|AMD Backlight Workaround]] — active temporary brightness clamp.
- [[Fan Control]] — NBFC configuration and fan curves.
- [[Crash Investigation]] — unresolved freeze/black-screen investigation.
- [[services/crash-monitor|Crash Monitor]] — diagnostic service implementation.

## Scientific / engineering software

See [[Scientific Software]] for the current matrix.

Implemented now:

- [[Octave]]
- [[Julia]]
- [[R]]
- [[software/sage|SageMath]]
- [[Xyce]]
- [[KiCad]]
- [[openEMS]]
- [[software/gnuradio|GNU Radio]]
- JASP and jamovi via [[Flatpak]]
- [[Python Scientific Environments]] — Nix-managed Python/uv baseline with project-local dependencies.

Deferred or undecided:

- [[Qucs-S]]
- [[ngspice]]
- [[qucsator-rf]]
- [[Cantor]]
- [[Scilab]]

## Packages, services, and tooling

- [[AB Download Manager]]
- [[Antigravity]]
- [[Development Tooling]]
- [[Flatpak]] — declarative Flathub inventory and application policy.
- [[Nirinit]] — Niri session persistence and restoration.
- [[Foreign Binary Packaging]]
- [[runbooks/binary-packaging|Binary Packaging Runbook]]

## Operations

- [[runbooks/rebuild|Rebuild Runbook]]
- [[runbooks/crash-monitor|Crash Monitor Runbook]]

## Architectural decisions

- [[decisions/0001-documentation-architecture|ADR 0001 - Documentation Architecture]]
- [[decisions/0002-stable-plus-unstable|ADR 0002 - Stable Plus Unstable Package Sets]]
- [[decisions/0003-octave-package-management|ADR 0003 - Octave Package Management]]

## Open work

See [[TODO]].
