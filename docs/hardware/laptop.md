---
title: Laptop
description: Index for machine-specific hardware assumptions, workarounds, and stability investigations.
tags:
  - hardware
  - laptop
type: hardware
status: active
date: 2026-08-14
---

# Laptop

This page is the anchor for configuration that should not be assumed portable to another machine.

## Machine-specific configuration

- [[AMD Backlight Workaround]]
- [[Fan Control]]
- [[Crash Investigation]]
- [[Crash Monitor]]

## Current kernel/hardware tuning represented in source

`modules/hardware-tuning.nix` currently includes, among other things:

- `amd_pstate=active`;
- native ACPI backlight handling;
- TPM module blacklisting and systemd TPM2 disablement;
- `amdgpu.gpu_recovery=1`;
- `rasdaemon`;
- ASUS daemon support from unstable;
- internal keyboard ignore/inhibit rule;
- the AMD backlight clamp;
- NBFC fan control through `ec_sys`.

Some entries are diagnostic or temporary. This page should not be treated as a recommendation for other machines.
