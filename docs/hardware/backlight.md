---
title: AMD Backlight Workaround
description: Temporary clamp for the amdgpu_bl1 brightness interface wrapping or dropping to zero near its reported maximum.
tags:
  - hardware
  - amdgpu
  - backlight
  - workaround
  - systemd
type: hardware
status: active-workaround
date: 2026-08-14
source-files:
  - hosts/gl702zc/backlight.nix
---

# AMD Backlight Workaround

## Observed behavior

The native backlight interface is exposed as:

```text
/sys/class/backlight/amdgpu_bl1
```

On this machine, requested brightness values near the reported top of the range behave incorrectly. The current configuration treats **65512** as the maximum safe requested value; values above that point can cause `actual_brightness` to wrap/drop to zero.

## Current mitigation

`hosts/gl702zc/backlight.nix` defines a shell script that:

1. checks whether `/sys/class/backlight/amdgpu_bl1/brightness` exists;
2. reads the requested brightness;
3. writes `65512` when the requested value is greater than the safe limit.

The script is triggered in two ways:

- a udev `change` rule for `amdgpu_bl1`;
- `amdgpu-backlight-clamp.service` after the systemd backlight restore service during boot.

The kernel parameter uses:

```text
acpi_backlight=native
```

## Why this exists

Using the native backlight interface makes the backlight visible to normal Wayland/desktop tooling, but exposes the broken maximum region on this hardware/kernel combination. The clamp preserves native integration while preventing the problematic top range.

## Removal criterion

Remove this workaround only after the native interface can be moved through its full reported range without the wrap/drop behavior, including after reboot and systemd brightness restoration.

## Verification

After kernel/driver changes, verify both requested and actual values rather than relying only on the desktop slider.

## Related

- [[Laptop]]
- [[Fan Control]]
- [[Crash Investigation]]
