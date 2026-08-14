---
title: Crash Monitor Runbook
description: Steps to inspect the custom crash-monitor services and evidence after a failure.
tags:
  - runbook
  - crash
  - systemd
  - diagnostics
type: runbook
status: active
date: 2026-08-14
source-files:
  - modules/crash-monitor.nix
---

# Crash Monitor Runbook

## Check the collectors

```bash
systemctl status crash-monitor-kmsg --no-pager
systemctl status crash-monitor-snapshot.timer --no-pager
systemctl status crash-monitor-archive-previous --no-pager
```

## Inspect available evidence

```bash
sudo ls -lah /var/log/crash-monitor/
```

After a crash followed by reboot, prioritize files named for the previous boot ID:

```text
previous-<boot-id>-kernel.log
previous-<boot-id>-focus.log
previous-<boot-id>-full.log
previous-<boot-id>-last-x.log
```

Also inspect the preceding boot's last periodic snapshot and `kmsg-<boot-id>.log`.

## Useful journal checks

The archive service should already preserve the previous boot. `journalctl -b -1` remains useful when checking the archive mechanism itself.

## Interpretation cautions

- Absence of pstore data does not prove there was no kernel/hardware failure.
- An abrupt loss can truncate the newest writes despite aggressive syncing.
- The final warning in a log may be a symptom rather than the root cause.
- A fully wedged kernel/GPU/PCIe path may stop diagnostic progress before the true failure is recorded.

## Related

- [[Crash Monitor]]
- [[Crash Investigation]]
