---
title: Crash Investigation
description: Ongoing investigation of runtime hard freezes, black-screen events, and suspend/resume failures on this laptop.
tags:
  - hardware
  - crash
  - amdgpu
  - suspend
  - pcie
  - nvme
  - diagnostics
type: investigation
status: investigating
date: 2026-08-15
source-files:
  - modules/crash-monitor.nix
  - modules/hardware-tuning.nix
---

# Crash Investigation

## Scope

The laptop has experienced multiple classes of hard failure:

1. spontaneous runtime freezes/black screens while normally using Niri/DMS;
2. abrupt/unlogged termination followed by reboot;
3. black-screen failures during suspend/resume;
4. occasional fan-max behavior during or after failures.

These symptoms must not be assumed to have one common cause.

The fan-max behavior is also not a reliable root-cause indicator. It occurred
before NBFC was installed, and ASUS hwmon fan-control modes can independently
cause full-speed fan operation.

## Hardware context

Relevant hardware includes:

- AMD Ryzen platform;
- AMD Polaris 10 / Ellesmere discrete GPU using `amdgpu`;
- Crucial P3 1 TB NVMe (`CT1000P3SSD8`);
- ASUS firmware/EC fan control;
- no laptop battery installed.

Historical behavior predating the current NixOS configuration included
unreliable suspend/resume and occasional failure to detect the SSD until a
cold AC power cycle.

## Crash-monitor infrastructure

The primary evidence collection mechanism is [[Crash Monitor]].

It preserves:

- continuous kernel messages;
- periodic per-boot system/GPU state;
- previous-boot full and kernel journals;
- focused GPU/IOMMU/PCIe/NVMe/error logs;
- `last -x`;
- pstore data when available.

`rasdaemon` is enabled.

`amdgpu.gpu_recovery=1` has been enabled as a diagnostic parameter.

## Established findings

### NVMe APST

NVMe APST was explicitly disabled using:

```text
nvme_core.default_ps_max_latency_us=0
```

The controller confirmed APST was disabled.

Crashes still occurred.

Therefore NVMe APST is currently a weak explanation for the failures. This
test did not establish that the NVMe subsystem is unrelated to all failures,
only that disabling APST did not prevent them.

The NVMe SMART data observed during the investigation showed:

- no critical warning;
- no media errors;
- successful short self-tests;
- a large historical unsafe-shutdown count.

The unsafe-shutdown count is evidence of past abrupt power events, not proof
that the NVMe caused them.

### GPU PCIe/runtime power management

The discrete Polaris GPU reported:

```text
power/control        = on
power/runtime_status = active
```

AMDGPU initialization also reported:

```text
Runtime PM not available
```

The GPU PCIe link supported ASPM L1 but its effective link state showed:

```text
LnkCtl: ASPM Disabled
```

Therefore GPU runtime suspend and GPU-link ASPM are not currently strong
candidates for the observed failures.

### Runtime crash evidence

At least one runtime boot ended abruptly with no orderly shutdown sequence.

The final persisted messages before that failure did not contain a clear
AMDGPU, NVMe, PCIe, watchdog, panic, or kernel-oops cause.

On a following warm boot, AMDGPU showed serious initialization trouble,
including a KIQ ring timeout and KCQ failure. This proves that the GPU was in
a bad state after that event, but does not prove that the GPU initiated the
preceding crash.

Spontaneous runtime crashes remain unresolved and are an active investigation
separate from suspend/resume testing.

## Suspend/resume findings

### Deep / ACPI S3 failure

The machine supports:

```text
s2idle [deep]
```

where brackets indicate the selected mode.

A captured `deep` suspend entered ACPI S3 successfully and subsequently woke.

During device resume, the Polaris GPU failed to return to a usable state.

The captured sequence included:

```text
ACPI: PM: Waking up from system sleep state S3
...
amdgpu: last message was failed ret is 65535
...
ring uvd test failed (-110)
resume of IP block <uvd_v6_0> failed -110
amdgpu_device_ip_resume failed (-110)
PM: dpm_run_callback(): pci_pm_resume returns -110
PM: failed to resume async: error -110
```

Afterward, repeated SDMA fence fallback timeouts occurred.

Niri subsequently failed DRM page-flip commits. Therefore for this event,
Niri was downstream of the kernel/GPU resume failure rather than its cause.

The effective failure sequence was approximately:

```text
ACPI S3 wake
    -> device resume
    -> Polaris/SMU/UVD resume failure
    -> UVD ring timeout
    -> AMDGPU PCI resume failure
    -> SDMA remains wedged
    -> DRM unusable
    -> Niri cannot present frames
    -> black screen
```

### Historical pstore evidence

Older EFI pstore records contain another AMDGPU failure involving the same
general subsystem.

The records include an AMDGPU probe timeout followed by a kernel NULL pointer
dereference in the UVD/SMU7 power-gating path:

```text
smu7_powergate_uvd
pp_set_powergating_by_smu
amdgpu_dpm_set_powergating_by_smu
amdgpu_dpm_enable_uvd
```

This makes Polaris UVD/SMU/power-management behavior a significant suspect,
although it still does not prove that all runtime crashes have the same cause.

### s2idle test

A later test manually selected:

```bash
echo s2idle | sudo tee /sys/power/mem_sleep
```

The resulting failed boot ended at:

```text
PM: suspend entry (s2idle)
```

with no persisted `PM: suspend exit`, AMDGPU UVD timeout, or normal resume
sequence afterward.

Therefore switching from `deep` to `s2idle` did not by itself make suspend
reliable.

The s2idle failure is not identical to the captured S3 failure. In the s2idle
case, logging stopped before a resume sequence was captured.

A per-boot state snapshot roughly 20 seconds before that test showed:

- no significant CPU, memory, or I/O pressure;
- AMDGPU active;
- GPU idle;
- UVD and VCE powered down;
- AMDGPU fence counters caught up;
- one DRM worker temporarily in D state at
  `drm_atomic_helper_wait_for_flip_done`.

The D-state observation is interesting but not yet evidence of a persistent
hang because the snapshot does not show how long the task had been waiting.

## IOMMU observations

AMD-Vi / IOMMU messages have appeared during boot and around resume.

At least some `INVALID_DEVICE_REQUEST` messages also appear during ordinary
boot, so the presence of `IOMMU`, `AMD-Vi`, or `IVRS` text alone must not be
treated as the root cause.

IOMMU behavior remains relevant because it participates in the PCIe/device
environment, but no causal IOMMU failure has yet been established.

## Fan-control observations

The ASUS hwmon interface uses standard fan-control mode meanings:

```text
pwm*_enable = 0   full speed / fan control disabled
pwm*_enable = 1   manual
pwm*_enable = 2   automatic
```

Therefore:

```bash
echo 0 | sudo tee "$H/pwm1_enable"
echo 0 | sudo tee "$H/pwm2_enable"
```

can directly cause full-speed fans, while:

```bash
echo 2 | sudo tee "$H/pwm1_enable"
echo 2 | sudo tee "$H/pwm2_enable"
```

returns the fans to automatic firmware control.

NBFC can therefore explain some fan-state behavior, but it cannot explain the
entire crash history because fan-max failures occurred before NBFC was
installed.

During one captured S3/AMDGPU failure, NBFC subsequently lost its GPU
temperature source after AMDGPU had already failed. This makes NBFC a
downstream symptom in that event rather than the initiating failure.

## Current suspend diagnostic

The current experiment uses the kernel PM test facility.

Runtime configuration:

```bash
echo s2idle | sudo tee /sys/power/mem_sleep
echo devices | sudo tee /sys/power/pm_test

echo 1 | sudo tee /sys/power/pm_print_times
echo 1 | sudo tee /sys/power/pm_debug_messages
```

Expected state:

```text
/sys/power/mem_sleep:
[s2idle] deep

/sys/power/pm_test:
none core processors platform [devices] freezer
```

The `devices` PM test freezes processes, suspends devices, waits a few
seconds, resumes devices, and thaws processes without entering the final
hardware sleep state.

Run the test with:

```bash
systemctl suspend
```

If the test succeeds, restore normal suspend operation:

```bash
echo none | sudo tee /sys/power/pm_test
```

The PM timing/debug switches may remain enabled while suspend debugging
continues. Disable them afterward with:

```bash
echo 0 | sudo tee /sys/power/pm_print_times
echo 0 | sudo tee /sys/power/pm_debug_messages
```

These sysfs settings are runtime state and normally reset on reboot unless
made persistent through kernel parameters or another service.

After a crash/reboot, verify rather than assuming:

```bash
cat /sys/power/pm_test
cat /sys/power/pm_print_times
cat /sys/power/pm_debug_messages
cat /sys/power/mem_sleep
```

## Interpretation of the PM test

If `pm_test=devices` itself hangs, the problem can occur while devices are
being suspended or resumed and does not require the machine to enter the
actual hardware sleep state.

If `pm_test=devices` succeeds repeatedly but a real s2idle transition hangs,
the failure is likely deeper in the real sleep/wakeup transition.

Do not progress to `platform`, `processors`, or `core` until the result of the
`devices` test has been collected and interpreted.

## Potential later tests

Do not enable these simultaneously.

Possible future experiments, depending on evidence:

```text
amdgpu.pg_mask=0
```

This disables AMDGPU power gating and is relevant because historical pstore
evidence includes `smu7_powergate_uvd`.

A broader later experiment would be:

```text
amdgpu.dpm=0
```

which disables dynamic power management and is therefore more invasive.

Other possible diagnostic mechanisms include:

- `pm_trace` for suspend/resume device fingerprinting;
- remote kernel logging/netconsole when local persistence is insufficient;
- PCIe upstream/root-port inspection;
- hardware power-delivery isolation.

## Investigation discipline

- Separate spontaneous runtime crashes from suspend/resume failures.
- Do not infer root cause from the final log line alone.
- Treat post-crash GPU failures as evidence of GPU state, not automatically
  proof that the GPU initiated the crash.
- Preserve exact boot IDs and timestamps.
- Change one diagnostic/workaround variable at a time where possible.
- Record both requested configuration and effective hardware state.
- Keep temporary diagnostic parameters documented.
- Prefer captured evidence over symptom-based guesses.

## Related

- [[Crash Monitor]]
- [[Crash Monitor Runbook]]
- [[Fan Control]]
- [[Laptop]]
