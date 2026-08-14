---
title: Crash Monitor
description: Custom systemd diagnostics that continuously and periodically capture evidence for hard system crashes.
tags:
  - systemd
  - diagnostics
  - crash
  - journald
type: service
status: active
date: 2026-08-14
source-files:
  - modules/crash-monitor.nix
---

# Crash Monitor

## Purpose

Hard freezes and abrupt power losses can destroy the most useful in-memory evidence. `modules/crash-monitor.nix` increases persistence and captures high-signal state before and after failures.

Logs live under:

```text
/var/log/crash-monitor/
```

## Components

### Continuous kernel recorder

`crash-monitor-kmsg.service` runs `dmesg --follow --decode --ctime` and writes one log per boot ID:

```text
kmsg-<boot-id>.log
```

It restarts automatically on failure.

### Periodic snapshot

`crash-monitor-snapshot.timer` runs every 30 seconds after the initial 30-second delay. The snapshot is overwritten atomically per boot because the goal is to retain the most recent pre-failure state, not an unbounded history.

Captured data includes:

- uptime/load;
- kernel command line;
- PSI pressure data;
- memory;
- processes and D-state tasks;
- interrupts;
- AMDGPU module parameters;
- AMDGPU power/debugfs state and fences;
- selected GPU/NVMe PCIe state;
- recent kernel warnings/errors.

### Previous-boot archive

`crash-monitor-archive-previous.service` runs after boot and archives the previous boot's:

- full journal;
- kernel journal;
- high-signal filtered journal;
- `last -x` history;
- systemd pstore and live pstore data when present.

Old top-level diagnostic files are pruned after 14 days.

## Journald changes

The module enables persistent journal storage, lowers the sync interval to 5 seconds while debugging, raises the rate-limit burst for potential error storms, and bounds journal disk consumption.

## Kernel diagnostics

The module increases the printk buffer and enables hung-task warnings at 30 seconds without forcing panic/reboot.

## Related

- [[Crash Investigation]]
- [[Crash Monitor Runbook]]
