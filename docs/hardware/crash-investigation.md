---
title: Crash Investigation
description: Ongoing investigation of hard freezes, black-screen events, and abrupt failures on this laptop.
tags:
  - hardware
  - crash
  - amdgpu
  - nvme
  - diagnostics
type: investigation
status: investigating
date: 2026-08-14
source-files:
  - modules/crash-monitor.nix
  - modules/hardware-tuning.nix
---

# Crash Investigation

## Problem class

The machine has experienced hard failures including black-screen/freeze behavior. Some events have required forced power-off. The root cause is not yet established and should not be attributed to a single subsystem without evidence.

Possible areas already considered include GPU/AMDGPU behavior, NVMe/power behavior, suspend/resume interactions, watchdog/hung tasks, and fan-control interactions.

## Current diagnostics

The primary evidence collection mechanism is [[Crash Monitor]]. It preserves:

- continuous kernel messages;
- periodic system/GPU state;
- previous-boot journal data;
- focused GPU/IOMMU/PCIe/NVMe/error subsets;
- pstore data when available.

`rasdaemon` is enabled. `amdgpu.gpu_recovery=1` is currently present in kernel parameters.

## Investigation discipline

- Treat correlation with a recent configuration change as evidence to test, not proof of causation.
- Preserve exact boot IDs and timestamps when comparing evidence.
- Change one diagnostic/workaround variable at a time when possible.
- Document enabled and disabled test parameters so an old experiment is not mistaken for the current state.

## Related

- [[Crash Monitor]]
- [[Crash Monitor Runbook]]
- [[Fan Control]]
- [[Laptop]]
