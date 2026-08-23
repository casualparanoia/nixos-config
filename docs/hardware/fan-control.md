---
title: Fan Control
description: NBFC-based CPU/GPU fan control derived from the Asus ROG GL702ZC profile.
tags:
  - hardware
  - fan-control
  - nbfc
  - asus
  - workaround
type: hardware
status: experimental
date: 2026-08-14
source-files:
  - hosts/gl702zc/fan-control.nix
---

# Fan Control

## Purpose

The laptop's standard Linux ASUS interface exposes fan RPM monitoring and limited automatic/full-speed control, but does not expose the intermediate fan-speed control available through the machine's embedded controller.

NBFC-Linux is therefore used to control the CPU and GPU fans directly through the embedded controller.

The configuration is based on NBFC's existing **Asus ROG GL702ZC** profile rather than defining the machine's EC registers from scratch.

## Hardware control path

The effective control path is:

```text
NBFC-Linux
    ↓
ec_sys
    ↓
embedded controller
    ↓
CPU / GPU fan control registers
    ↓
physical fans
```

The standard ASUS hwmon interface remains useful for observing physical fan RPM:

```text
/sys/class/hwmon/.../fan1_input
/sys/class/hwmon/.../fan2_input
```

but the useful stepped fan control is performed through NBFC and the embedded controller.

## NBFC package

NBFC-Linux is provided through the unstable package set:

```nix
pkgsUnstable.nbfc-linux
```

The package itself is installed via `environment.systemPackages` directly in:

```text
hosts/gl702zc/fan-control.nix
```

The machine-specific configuration and service are also defined in:

```text
hosts/gl702zc/fan-control.nix
```

## Embedded-controller backend

NBFC uses the Linux `ec_sys` embedded-controller backend.

The kernel module is loaded declaratively:

```nix
boot.kernelModules = [ "ec_sys" ];
```

NBFC requires write access to the EC, so `ec_sys` must be loaded with:

```text
write_support=1
```

This is configured through:

```nix
boot.extraModprobeConfig = ''
  options ec_sys write_support=1
'';
```

The runtime state can be checked with:

```bash
cat /sys/module/ec_sys/parameters/write_support
```

Expected result:

```text
Y
```

### Failure mode without write support

When `ec_sys` was initially loaded without the option above, the value was:

```text
N
```

NBFC could discover the EC backend but failed when attempting EC access, repeatedly reporting:

```text
/sys/kernel/debug/ec/ec0/io: Invalid argument
```

and terminating with:

```text
status=3/NOTIMPLEMENTED
```

Reloading the module with:

```bash
sudo modprobe -r ec_sys
sudo modprobe ec_sys write_support=1
```

resolved the problem during testing.

The declarative `boot.extraModprobeConfig` setting exists so the correct parameter is applied automatically after future boots.

## Base hardware profile

The custom profile is generated from NBFC-Linux's existing:

```text
Asus ROG GL702ZC
```

configuration.

Rather than duplicating the complete profile and its machine-specific EC behavior, Nix transforms only the automatic fan thresholds with `jq`.

Conceptually:

```text
upstream GL702ZC profile
        ↓
       jq
        ↓
custom temperature thresholds
        ↓
Nix store model configuration
```

This preserves NBFC's known GL702ZC fan register configuration and other profile-specific behavior while allowing the local thermal policy to remain declarative.

## Fan speed resolution

The GL702ZC EC exposes eight fan-speed steps.

NBFC reports:

```text
Fan Speed Steps : 8
```

The effective fan levels are therefore spaced by:

\[
\frac{100\%}{8}=12.5\%
\]

giving the useful stepped states:

```text
0%
12.5%
25%
37.5%
50%
62.5%
75%
87.5%
100%
```

There are eight intervals and nine possible endpoint states when 0% is included.

Arbitrary requested percentages are quantized to the nearest supported EC state.

For example:

```bash
nbfc set -s 10
```

produced:

```text
Target Fan Speed  : 10.00
Current Fan Speed : 12.50
Fan Speed Steps   : 8
```

This confirms that the underlying control is stepped rather than continuously variable.

## Manual control validation

The GL702ZC profile has been tested with actual EC writes.

A manual 50% request:

```bash
nbfc set -s 50
```

produced approximately:

```text
CPU fan: 3400 RPM
GPU fan: 3400 RPM
```

NBFC reported:

```text
Current Fan Speed : 50.00
Target Fan Speed  : 50.00
```

A manual 75% request:

```bash
nbfc set -s 75
```

produced approximately:

```text
CPU fan: 4300 RPM
GPU fan: 4400 RPM
```

Earlier forced full-speed testing through the ASUS hwmon interface produced physical fan speeds around:

```text
5800–5900 RPM
```

The monotonic RPM response confirms that NBFC is controlling the correct GL702ZC EC fan states.

## Automatic control

Automatic NBFC control is enabled with:

```bash
nbfc set --auto
```

Manual commands such as:

```bash
nbfc set -s 50
```

disable automatic control for the affected fans until automatic mode is restored.

The current automatic state can be checked with:

```bash
nbfc status -a
```

A working automatic configuration should report:

```text
Auto Control Enabled : true
```

for both CPU and GPU.

## Temperature sources

The generated `/etc/nbfc/nbfc.json` assigns independent temperature sources to the two fans.

### CPU fan

Fan 0 uses:

```text
@CPU
```

with:

```text
TemperatureAlgorithmType = Max
```

On this machine the group currently resolves to:

```text
k10temp
```

Therefore the CPU fan is controlled from the CPU temperature reported by the Ryzen thermal sensor.

### GPU fan

Fan 1 uses:

```text
@GPU
```

with:

```text
TemperatureAlgorithmType = Max
```

On this machine the group currently resolves to:

```text
amdgpu
```

Therefore the GPU fan follows the discrete AMD GPU temperature rather than the CPU temperature.

This separation is important because CPU and GPU thermal loads can differ substantially.

## AMDGPU startup ordering

During an early boot test, NBFC started before the `amdgpu` hwmon sensor had appeared.

At that point NBFC discovered:

```text
nvme
k10temp
acpitz
```

but not:

```text
amdgpu
```

Since the GPU fan is explicitly configured to use `@GPU`, the service now waits for an hwmon device whose `name` is:

```text
amdgpu
```

before starting NBFC.

The wait script checks:

```text
/sys/class/hwmon/hwmon*/name
```

rather than relying on a fixed number such as `hwmon6`, because hwmon numbering is not stable between boots.

The current timeout is approximately 30 seconds.

If `amdgpu` does not appear within that period, the pre-start check fails and systemd can retry the NBFC service according to its restart policy.

## Current automatic curve

CPU and GPU currently use the same temperature-to-speed curve, but each fan uses its own temperature source.

| Rising temperature | Target fan speed |
|---:|---:|
| ≤ 45 °C | 12.5% |
| > 45 °C | 25% |
| > 50 °C | 37.5% |
| > 55 °C | 50% |
| > 65 °C | 62.5% |
| > 72 °C | 75% |
| > 78 °C | 87.5% |
| > 84 °C | 100% |

The model also contains a final 100% threshold at:

```text
90 °C
```

to keep the threshold table consistent with the configured critical temperature.

## Hysteresis

The configuration uses separate rising and falling temperature thresholds.

This prevents rapid fan-speed oscillation near a boundary.

For example, a fan can increase to a higher state when temperature rises beyond an `UpThreshold` but will not immediately drop again when the temperature falls by a fraction of a degree.

A simplified example is:

```text
temperature rises:
54 °C → 37.5%
56 °C → 50%

temperature falls:
54 °C → remain at 50%
51 °C → remain at 50%
49 °C → return to 37.5%
```

The exact down-threshold values are encoded in the generated NBFC model.

## Critical temperature

The custom model uses:

```text
CriticalTemperature       = 90 °C
CriticalTemperatureOffset = 5 °C
```

The critical-temperature mechanism is separate from the normal stepped curve.

It provides an emergency maximum-cooling state if the configured critical temperature is reached.

The 5 °C offset introduces hysteresis for leaving critical mode.

## Current observed automatic behavior

Automatic operation has been verified after the EC write issue was fixed.

One observed state was:

```text
CPU:
Temperature          : 72.43 °C
Current Fan Speed    : 75.00%
Target Fan Speed     : 75.00%
Auto Control Enabled : true

GPU:
Temperature          : 68.08 °C
Current Fan Speed    : 62.50%
Target Fan Speed     : 62.50%
Auto Control Enabled : true
```

This is consistent with the configured curve and demonstrates that the CPU and GPU fans are independently following their respective sensors.

## Minimum fan speed

The automatic curve deliberately begins at:

```text
12.5%
```

rather than:

```text
0%
```

NBFC therefore emits a validation warning similar to:

```text
No threshold with FanSpeed == 0 found
```

This is currently intentional.

The configuration does not allow the automatic controller to stop either fan completely.

The warning should not be removed merely by introducing an artificial 0% state unless fan-stop behavior is explicitly tested and judged desirable.

## systemd service

NBFC runs as:

```text
nbfc_service.service
```

The service:

- starts as part of `multi-user.target`;
- waits for the AMDGPU hwmon device;
- uses the `ec_sys` backend;
- reads `/etc/nbfc/nbfc.json`;
- automatically restarts after failures.

The configured restart delay is:

```text
5 seconds
```

The service can be inspected with:

```bash
systemctl status nbfc_service --no-pager
```

and its boot log with:

```bash
journalctl -b -u nbfc_service --no-pager -o cat
```

## Useful commands

Show complete NBFC state:

```bash
nbfc status -a
```

Restore automatic control:

```bash
nbfc set --auto
```

Set a temporary manual speed:

```bash
nbfc set -s 50
```

Check physical temperatures and fan RPM:

```bash
sensors
```

Monitor continuously:

```bash
watch -n 1 sensors
```

Check the EC write permission:

```bash
cat /sys/module/ec_sys/parameters/write_support
```

Expected:

```text
Y
```

Check whether the service is running:

```bash
systemctl is-active nbfc_service
```

Check the relevant NBFC startup messages:

```bash
journalctl -b -u nbfc_service --no-pager -o cat \
  | rg 'Fan #|amdgpu|Invalid argument|ERROR'
```

A healthy startup should contain lines equivalent to:

```text
Fan #0 (CPU) uses "k10temp" ... (Max)
Fan #1 (GPU) uses "amdgpu" ... (Max)
```

and should not contain repeated:

```text
/sys/kernel/debug/ec/ec0/io: Invalid argument
```

## Rebuild workflow

Changes to the declarative fan configuration are applied with:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

A successful switch should stop the old NBFC service, activate the new configuration, and start the new service again.

The latest configuration switch successfully restarted `nbfc_service`.

## Reboot validation still required

The current configuration has successfully been activated with `nixos-rebuild switch`.

However, `ec_sys` had already been manually reloaded with:

```text
write_support=Y
```

before that switch.

A future cold reboot is therefore still required to prove that the complete declarative boot path works.

After reboot, verify:

```bash
cat /sys/module/ec_sys/parameters/write_support
```

Expected:

```text
Y
```

Then:

```bash
systemctl is-active nbfc_service
```

Expected:

```text
active
```

Then:

```bash
nbfc status -a
```

Both fans should report:

```text
Auto Control Enabled : true
```

Finally:

```bash
journalctl -b -u nbfc_service --no-pager -o cat \
  | rg 'Fan #|amdgpu|Invalid argument|ERROR'
```

The expected sensor assignments are:

```text
CPU → k10temp
GPU → amdgpu
```

with no EC `Invalid argument` failures.

## Current validation status

The following behavior has been verified:

- NBFC-Linux 0.5.2 recognizes the Asus ROG GL702ZC profile.
- The `ec_sys` backend can access the machine's embedded controller.
- EC writes work when `write_support=1`.
- CPU and GPU fan control registers respond correctly.
- Both fan states can be read through NBFC.
- The machine exposes eight fan-speed steps.
- Arbitrary percentage requests are quantized to 12.5% steps.
- Manual 50% control produces intermediate physical RPM.
- Manual 75% control produces higher physical RPM.
- Full-speed operation reaches approximately 5800–5900 RPM.
- Automatic NBFC control works.
- CPU temperature control resolves to `k10temp`.
- GPU temperature control resolves to `amdgpu`.
- CPU and GPU fans operate independently from their respective temperatures.
- A declarative NixOS configuration switch successfully restarts the NBFC service.

Still to be verified:

- automatic `ec_sys write_support=1` after a cold boot;
- early-boot AMDGPU hwmon waiting;
- sustained CPU-only thermal behavior;
- sustained GPU-only thermal behavior;
- sustained combined CPU/GPU thermal behavior;
- whether the current custom curve provides the desired noise/temperature trade-off.

## Important caveat

NBFC writes directly to the machine's embedded controller.

Incorrect EC configuration can cause undesirable fan behavior and, in the worst case, inadequate cooling.

The underlying GL702ZC register configuration is therefore inherited from NBFC's existing machine-specific profile rather than recreated manually.

Only the thermal policy is overridden locally.

Curve changes should be tested under controlled workloads while monitoring:

```text
CPU temperature
GPU temperature
CPU fan RPM
GPU fan RPM
NBFC target fan speed
NBFC current fan speed
```

The current control mechanism is functional, but the chosen automatic temperature curve should still be treated as experimental machine-specific tuning until sustained load testing is completed.

## Related

- [[Laptop]]
- [[Crash Investigation]]
- [[hardware/backlight|AMD Backlight Workaround]]
