---
title: Crash Monitor Runbook
description: Steps to inspect, package, and interpret crash-monitor evidence after a failure.
tags:
  - runbook
  - crash
  - systemd
  - diagnostics
type: runbook
status: active
date: 2026-08-15
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

`crash-monitor-archive-previous.service` is a oneshot service. An
`inactive (dead)` state after a successful run is normal when its status shows:

```text
status=0/SUCCESS
```

## Inspect available evidence

```bash
sudo ls -lah /var/log/crash-monitor/
```

Important files include:

```text
kmsg-<hyphenated-boot-id>.log
state-<hyphenated-boot-id>-last.txt

previous-<boot-id>-kernel.log
previous-<boot-id>-focus.log
previous-<boot-id>-full.log
previous-<boot-id>-last-x.log

previous-<boot-id>-pstore/
previous-<boot-id>-live-pstore/
```

The state snapshot is stored per boot ID so that the next boot does not
overwrite the final pre-crash state from the failed boot.

## Identify the failed/previous boot

List boots:

```bash
journalctl --list-boots --no-pager
```

Normally the boot immediately before the current boot is `-1`.

Determine its boot ID automatically:

```bash
BOOT="$(
  journalctl --list-boots --no-pager |
  awk '$1 == "-1" { print $2; exit }'
)"

echo "$BOOT"
```

The kernel recorder uses the UUID with hyphens. Convert it:

```bash
KBOOT="$(
  printf '%s\n' "$BOOT" |
  sed -E 's/^(.{8})(.{4})(.{4})(.{4})(.{12})$/\1-\2-\3-\4-\5/'
)"

echo "$KBOOT"
```

Set the log directory:

```bash
DIR=/var/log/crash-monitor
```

Verify that the expected evidence exists:

```bash
sudo ls -lh \
  "$DIR/kmsg-$KBOOT.log" \
  "$DIR/state-$KBOOT-last.txt" \
  "$DIR/previous-$BOOT-full.log" \
  "$DIR/previous-$BOOT-kernel.log" \
  "$DIR/previous-$BOOT-focus.log" \
  "$DIR/previous-$BOOT-last-x.log"
```

## Package a failed boot

Avoid creating the archive directly as root inside `/tmp`, especially over an
existing user-owned file.

Instead, let privileged `tar` read the protected diagnostic files and let the
normal user shell create the output file:

```bash
sudo tar -C "$DIR" -czf - \
  "kmsg-$KBOOT.log" \
  "state-$KBOOT-last.txt" \
  "previous-$BOOT-full.log" \
  "previous-$BOOT-kernel.log" \
  "previous-$BOOT-focus.log" \
  "previous-$BOOT-last-x.log" \
  "previous-$BOOT-pstore" \
  "previous-$BOOT-live-pstore" \
  > "$HOME/crash-$BOOT.tar.gz"
```

Check it:

```bash
ls -lh "$HOME/crash-$BOOT.tar.gz"
```

If a pstore directory or state file does not exist for that boot, omit that
path from the `tar` command.

## Quick manual journal checks

The archive service should already preserve the previous boot, but direct
journal inspection is useful while validating the monitor:

```bash
journalctl -b -1 -k -o short-precise --no-pager
```

Focused kernel search:

```bash
journalctl -b -1 -k --no-pager |
grep -Ei \
'amdgpu|drm|gpu|ring|kiq|kcq|uvd|sdma|fence|timeout|reset|fault|hang|lockup|watchdog|iommu|amd.?iommu|amd-vi|ivrs|pcie|aer|nvme|mce|ras|BUG:|WARNING:|Call Trace|panic|oops'
```

## Suspend-debug procedure

Check supported sleep and PM-test modes:

```bash
cat /sys/power/mem_sleep
cat /sys/power/pm_test
```

For the current `s2idle` + device-callback test:

```bash
echo s2idle | sudo tee /sys/power/mem_sleep
echo devices | sudo tee /sys/power/pm_test

echo 1 | sudo tee /sys/power/pm_print_times
echo 1 | sudo tee /sys/power/pm_debug_messages
```

Verify:

```bash
cat /sys/power/mem_sleep
cat /sys/power/pm_test
cat /sys/power/pm_print_times
cat /sys/power/pm_debug_messages
```

Expected selections:

```text
[s2idle] deep
none core processors platform [devices] freezer
1
1
```

Run:

```bash
systemctl suspend
```

With `pm_test=devices`, the system should freeze processes, suspend devices,
wait roughly five seconds, resume devices, and thaw processes without entering
the final hardware sleep state.

Do not immediately press the power button when the display goes black. Give
the PM test time to complete and return automatically.

After a successful test, restore normal suspend operation:

```bash
echo none | sudo tee /sys/power/pm_test
```

Keep the PM timing/debug switches enabled while active suspend debugging
continues.

When finished:

```bash
echo 0 | sudo tee /sys/power/pm_print_times
echo 0 | sudo tee /sys/power/pm_debug_messages
```

If the machine hangs and must be rebooted, the manually configured PM sysfs
settings normally reset. Verify after reboot:

```bash
cat /sys/power/pm_test
cat /sys/power/pm_print_times
cat /sys/power/pm_debug_messages
cat /sys/power/mem_sleep
```

## Interpretation cautions

- Absence of pstore data does not prove there was no kernel or hardware failure.
- An abrupt loss can occur before the newest local writes reach persistent storage.
- The final warning in a journal may be a symptom rather than the initiating fault.
- A fully wedged kernel, GPU, PCIe path, or storage path can prevent diagnostics from progressing.
- A GPU failure observed only after a warm reboot proves the GPU was unhealthy after the preceding event, but does not by itself establish that the GPU initiated that event.
- Suspend/resume failures and spontaneous runtime crashes must be analyzed separately unless evidence links them.

## Known logging-noise issue

A previous NBFC error storm caused very large archived logs. In particular,
generic warning matching can make `previous-*-focus.log` much larger than
expected.

If this continues, narrow the focused-journal filter rather than reducing the
full-journal capture.

## Related

- [[services/crash-monitor|Crash Monitor]]
- [[Crash Investigation]]
