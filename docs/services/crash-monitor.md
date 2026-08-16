---
title: Crash Monitor
description: Custom systemd diagnostics that continuously and periodically capture evidence for hard system crashes and suspend failures.
tags:
  - systemd
  - diagnostics
  - crash
  - journald
type: service
status: active
date: 2026-08-15
source-files:
  - modules/crash-monitor.nix
---

# Crash Monitor

## Purpose

Hard freezes, GPU failures, suspend/resume hangs, and abrupt power events can
destroy the most useful in-memory evidence.

`modules/crash-monitor.nix` increases log persistence and captures high-signal
state before and after failures.

Logs live under:

```text
/var/log/crash-monitor/
```

The monitor is diagnostic infrastructure. It is intentionally more aggressive
about logging and syncing than a normal long-term configuration.

## Components

### Continuous kernel recorder

`crash-monitor-kmsg.service` runs:

```text
dmesg --follow --decode --ctime
```

and creates one file per kernel boot ID:

```text
kmsg-<hyphenated-boot-id>.log
```

The service restarts automatically if the recorder process exits.

This provides a second persistent copy of kernel `printk` traffic in addition
to journald.

### Periodic state snapshot

`crash-monitor-snapshot.timer` runs every 30 seconds after an initial
30-second delay.

The most recent state is stored atomically per boot:

```text
state-<hyphenated-boot-id>-last.txt
```

Using the boot ID is important: the first snapshot after a reboot must not
overwrite the last snapshot from the failed boot.

Captured information includes:

- timestamp;
- uptime and load;
- kernel command line;
- CPU, I/O, and memory PSI data;
- `/proc/meminfo`;
- process state;
- tasks in uninterruptible D state;
- interrupts;
- AMDGPU module parameters;
- AMDGPU runtime/power state;
- AMDGPU debugfs PM information;
- AMDGPU fence information;
- selected GPU PCIe state;
- selected NVMe PCIe state;
- recent kernel warnings and errors.

The snapshot is deliberately replaced within a boot rather than accumulated
indefinitely. The desired artifact is the state closest to the failure.

### Previous-boot archive

`crash-monitor-archive-previous.service` runs once after boot.

It archives the preceding boot's:

```text
previous-<boot-id>-full.log
previous-<boot-id>-kernel.log
previous-<boot-id>-focus.log
previous-<boot-id>-last-x.log
```

It also copies pstore data where available:

```text
previous-<boot-id>-pstore/
previous-<boot-id>-live-pstore/
```

The service is `Type=oneshot`, so after successful completion it normally
appears as:

```text
inactive (dead)
```

with an exit status of `0/SUCCESS`.

Top-level diagnostic files older than the configured retention period are
pruned.

## Journald configuration

The module enables persistent journal storage.

During crash investigation it lowers the journal sync interval to reduce the
amount of recent journal data that can be lost in an abrupt failure.

It also raises the journald rate-limit burst so a short kernel/driver error
storm is less likely to be suppressed.

Journal disk usage is bounded.

These settings are intended for active debugging rather than necessarily for
the final long-term system configuration.

## Kernel diagnostics

The module enlarges the kernel printk ring buffer.

It also enables hung-task detection with a 30-second threshold without forcing
a panic or automatic reboot.

The intent is to preserve traces from tasks stuck in uninterruptible sleep
while keeping the machine alive long enough for diagnostic data to be written
when possible.

## Evidence successfully captured so far

The monitor has successfully preserved:

- a deep/ACPI-S3 suspend followed by AMDGPU UVD resume failure;
- SDMA fence stalls after the GPU resume failure;
- Niri DRM/page-flip failures downstream of the GPU failure;
- an s2idle attempt whose kernel log stopped at `PM: suspend entry (s2idle)`;
- per-boot pre-failure process/GPU/PCIe state;
- historical EFI pstore records containing AMDGPU/UVD/SMU7 failures.

This confirms that the monitor is functioning and materially improves the
investigation compared with manual `dmesg -wT` sessions.

## Current PM debugging

Additional suspend diagnostics may be enabled manually through:

```text
/sys/power/pm_test
/sys/power/pm_print_times
/sys/power/pm_debug_messages
/sys/power/mem_sleep
```

These are runtime kernel controls and are not part of the crash-monitor
service itself.

The current experiment uses:

```text
mem_sleep         = s2idle
pm_test           = devices
pm_print_times    = 1
pm_debug_messages = 1
```

The `devices` test exercises process freezing plus device suspend/resume
without entering the final hardware sleep state.

See [[runbooks/crash-monitor|Crash Monitor Runbook]] for the exact procedure.

## Known limitations

No local systemd service can guarantee capture of the final cause of every
hard lockup.

A failure may stop:

- userspace scheduling;
- filesystem progress;
- the block layer;
- the kernel logging path;
- the PCIe fabric;
- or the CPU itself

before the final diagnostic message reaches persistent storage.

Pstore can retain information across some failures, but availability and
coverage depend on firmware/platform support.

If local persistence remains insufficient, remote kernel logging such as
netconsole over a suitable network interface may be required.

## Known logging-noise issue

A previous NBFC error storm produced a very large number of warning messages.
Because the focused journal currently includes broad warning matching, this
caused unusually large `previous-*-focus.log` files.

The correct future improvement is to make the focused filter more selective
while retaining the complete journal separately.

## Related

- [[Crash Investigation]]
- [[runbooks/crash-monitor|Crash Monitor Runbook]]
