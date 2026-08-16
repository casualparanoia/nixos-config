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
date: 2026-08-16
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

The primary evidence collection mechanism is [[services/crash-monitor|Crash Monitor]].

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

### Device-callback PM test

A subsequent test used `s2idle` with `pm_test=devices`. This test does not
enter the final hardware sleep state, but it does exercise device suspend and
resume callbacks.

The Polaris GPU failed during both phases. Suspend reported:

```text
Failed to force to switch arbf0
[disable_dpm_tasks] Failed to disable DPM
suspend of IP block <powerplay> failed -22
```

The automatic device resume then reported:

```text
atombios stuck in loop for more than 20secs
amdgpu asic init failed
SMU load firmware failed
amdgpu_device_ip_resume failed (-22)
PM: failed to resume async: error -22
```

The AMDGPU resume callback took approximately 56.7 seconds. A state snapshot
afterward found the GPU PCI configuration space returning an unknown header
type of `7f`, AMDGPU power/debug interfaces returning `EBUSY`, and an invalid
UVD fence value.

The NVMe device callbacks completed successfully and no NVMe, block-I/O,
filesystem, or active AER fault was logged during the test. The later failure
of firmware to detect the SSD until an AC power cycle remains relevant as a
platform power-state symptom, but the evidence does not identify NVMe as the
initiator of this suspend failure.

This test establishes that the suspend black screen can be triggered entirely
within device power-management callbacks. It does not require entering real
s2idle, and it strengthens Polaris PowerPlay/SMU/UVD power management as the
primary suspend suspect.

### Power-gating-disabled device-callback test

The device-callback test was repeated with `amdgpu.pg_mask=0` effective. This
changed the suspend phase: AMDGPU suspended successfully in approximately 115
milliseconds instead of reporting the earlier PowerPlay suspend failure.

It did not fix resume. The same ATOMBIOS and SMU initialization path failed,
and the AMDGPU resume callback returned `-22` after approximately 53.2 seconds.
The failed GPU then caused:

- repeated SDMA, GFX, and KIQ ring timeouts;
- unsuccessful GPU recovery attempts;
- ATOMBIOS and display-link command timeouts;
- kernel warnings in `amdgpu_irq_put`;
- DRM, TTM, compositor, and `systemd-logind` tasks blocked in D state.

The `systemd-logind` stack was blocked in
`amdgpu_dpm_display_configuration_change`. A later `sudo sync` invocation
recorded the sudo command but never opened its PAM session while logind was
wedged. Therefore that command does not establish an NVMe or filesystem sync
failure; it likely never reached `sync`.

The NVMe callbacks again completed successfully, in approximately 17
milliseconds for suspend and 50 milliseconds for resume, with no NVMe,
block-I/O, or filesystem error. Disabling AMDGPU power gating is therefore
insufficient, although its effect on the suspend phase further localizes the
problem to broader Polaris power-management and resume behavior.

### DPM-disabled runtime failure

The next boot selected `amdgpu.dpm=0`, but the machine failed spontaneously
before the planned device-callback test was run. There was no suspend request
on that boot.

Disabling DPM also removed the AMDGPU hwmon sensor required by NBFC. NBFC never
started and retried 147 times while waiting for that sensor. The resulting fan
behavior was therefore uncontrolled by NBFC and included high fan speed.

The boot ended abruptly about 10 seconds after a successful periodic state
snapshot. At that point the load and pressure metrics were low, memory was
available, no task was in D state, every AMDGPU ring's emitted fence matched its
last signaled fence, and the GPU and NVMe PCIe configuration spaces remained
readable. There were no thermal-event or machine-check interrupts. `rasdaemon`
later reported no memory, PCIe AER, disk, or MCE errors.

The persisted journal contains no panic, watchdog reset, AMDGPU timeout, NVMe
error, filesystem error, thermal-critical event, or orderly shutdown sequence
at the end. The NBFC retry loop consumed only approximately 2.4 CPU seconds per
38-second attempt and did not create system pressure, making it an unlikely
direct crash mechanism. This does not prove that disabling DPM caused the
spontaneous failure, but it makes `amdgpu.dpm=0` operationally unsuitable on
this system and it cannot be treated as a completed suspend test.

### Power-delivery observations

The laptop is intentionally operating without an installed battery, as already
recorded in the hardware context above. There is therefore no battery buffer
for a short AC-adapter, DC-jack, or motherboard input-power transient.
The firmware nevertheless exposes `BAT0` as present. Its voltage, energy, and
power attributes are unreadable, it reports `Not charging`, and an earlier
`upowerd` instance reported that no valid battery voltage was available. This
may be only stale firmware/EC behavior for the absent pack; it is not proof of
a battery-controller fault.

The installed adapter is correctly rated at 19.5 V and 16.9 A, approximately
330 W. ASUS documentation lists 280 W and 330 W supplies depending on the
GL702ZC SKU, while a reviewed Ryzen 7 1700/RX 580 configuration shipped with a
330 W supply. ASUS documents simultaneous adapter and battery delivery under
heavy load for some gaming notebooks, but no model-specific source found so
far establishes that the GL702ZC requires a battery for idle operation.

The observed runtime failures are not uniform. They include a display-only
black screen where SSH can remain available, whole-system freezes requiring a
power-button hold, and occasional automatic reboots. Instant loss of all power
has not been observed. Therefore an abrupt journal end does not by itself prove
AC loss: it may be the result of a hard kernel/platform hang followed by a
manual power cycle. This weakens a simple adapter-dropout explanation, although
GPU or motherboard power-rail faults remain possible.

The model's ArchWiki page independently reports full-speed fans and an
unresponsive system after long idle, with no established fix and possible
motherboard power-control failure. It also reports first-generation Ryzen MCE
failures, but no MCE has been captured on this machine and `rasdaemon` currently
reports no MCE records. The exact idle/fan symptom is therefore corroborated by
an owner report, while its proposed hardware cause remains unproven.

These runtime failures remain separate from the reproducible Polaris
suspend/resume defect. The next isolation should distinguish display/GPU loss
from a whole-platform hang before changing another kernel parameter.

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

Active suspend testing is paused. The final DPM-disabled snapshot has been
inspected, the baseline generation is active again, and both experimental
parameters have been removed:

```text
amdgpu.pg_mask=0
amdgpu.dpm=0
```

Do not run another suspend test while hardware power delivery is being
isolated. A later suspend experiment must still change only one variable.

The commands below document the device-callback procedure for a later test;
they are not currently an instruction to run it.

Runtime configuration:

```bash
sudo sh -c '
  printf "%s\n" s2idle > /sys/power/mem_sleep
  printf "%s\n" devices > /sys/power/pm_test
  printf "%s\n" 1 > /sys/power/pm_print_times
  printf "%s\n" 1 > /sys/power/pm_debug_messages
'
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
sudo sh -c 'printf "%s\n" none > /sys/power/pm_test'
```

The PM timing/debug switches may remain enabled while suspend debugging
continues. Disable them afterward with:

```bash
sudo sh -c '
  printf "%s\n" 0 > /sys/power/pm_print_times
  printf "%s\n" 0 > /sys/power/pm_debug_messages
'
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

Do not select another kernel workaround while hardware power delivery is being
isolated.

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

- [[services/crash-monitor|Crash Monitor]]
- [[runbooks/crash-monitor|Crash Monitor Runbook]]
- [[Fan Control]]
- [[Laptop]]
