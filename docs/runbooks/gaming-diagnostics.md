---
title: Gaming Diagnostics
description: Repeatable checks for AMD graphics, 32-bit Vulkan/OpenGL, Steam, Proton, UMU, launchers, GameMode, MangoHud, and controllers.
tags:
  - gaming
  - runbook
  - diagnostics
  - vulkan
  - amdgpu
type: runbook
status: active
date: 2026-08-17
source-files:
  - modules/gaming.nix
  - home/gaming.nix
---

# Gaming Diagnostics

Remove unrelated launch options and reproduce the smallest failure first. Record the game, distribution source, selected runner/version, whether it is native or Windows, and whether the failure is a game exit, compositor problem, GPU reset, or whole-machine freeze.

## Effective configuration

```bash
nix eval --json 'path:.#nixosConfigurations.nixos.config.hardware.graphics'
nix eval 'path:.#nixosConfigurations.nixos.config.programs.steam.enable'
nix eval 'path:.#nixosConfigurations.nixos.config.programs.gamemode.enable'
```

Expected graphics state after activation includes both `enable` and `enable32Bit` set to `true`.

## Kernel driver and GPU

```bash
lspci -nnk -d 1002:
journalctl -b -k --grep='amdgpu|drm'
```

The RX 580 should use the kernel `amdgpu` driver. A GPU reset, ring timeout, page fault, or recovery sequence in the kernel log is not an ordinary Proton crash; preserve it for [[Crash Investigation]].

## 64-bit Vulkan

```bash
vulkaninfo --summary
```

Look for the RX 580 and values equivalent to:

```text
AMD Radeon RX 580 Series
RADV POLARIS10
driverName = radv
```

Mesa may also enumerate a software device such as llvmpipe. That alone is not a failure; confirm the hardware device is present and selected by the game. AMDVLK should not appear because it is not installed.

## 64-bit OpenGL and Wayland EGL

For XWayland/GLX:

```bash
glxinfo -B
```

For native Wayland EGL:

```bash
eglinfo -B -p wayland -a gl
```

Expected renderer text includes RadeonSI/Polaris and hardware acceleration. `glxinfo` and `eglinfo` come from `mesa-demos`; there is no separate `glxinfo` Nix package in this pinned package set.

## 32-bit graphics

The 64-bit diagnostic binaries do not prove the i686 driver path. After activating the gaming configuration, verify the driver tree exists:

```bash
test -d /run/opengl-driver-32 && echo "32-bit driver tree present"
```

Then run genuine i686 tools from this flake's pinned package set:

```bash
nix shell 'path:.#nixosConfigurations.nixos.pkgs.pkgsi686Linux.vulkan-tools' \
  --command vulkaninfo --summary
```

```bash
nix shell 'path:.#nixosConfigurations.nixos.pkgs.pkgsi686Linux.mesa-demos' \
  --command glxinfo -B
```

The 32-bit output should still identify RADV/RadeonSI on the RX 580. Before this configuration is activated, these commands are expected to fail because the running system has no `/run/opengl-driver-32` tree.

## Steam client

Start Steam from a terminal with its developer console enabled:

```bash
steam -dev -console
```

Inspect client/runtime logs under:

```text
~/.local/share/Steam/logs/
```

Confirm the game is using the intended native/Proton path and remove all launch options before introducing GameMode, MangoHud, Gamescope, or compatibility variables.

If GE-Proton is missing after a rebuild, fully exit every Steam process and restart Steam. Do not install `proton-ge-bin` manually into a second location until the declarative compatibility-tool path has been checked.

## Per-game Proton log

Set this for one Steam game:

```text
PROTON_LOG=1 %command%
```

Valve Proton writes:

```text
~/steam-APPID.log
```

Remove the launch option after collecting the log. For controlled composition with instrumentation:

```text
PROTON_LOG=1 mangohud gamemoderun %command%
```

If the combined command behaves differently, return to `PROTON_LOG=1 %command%` and add one wrapper at a time. A GE-Proton-only failure belongs in the GE issue tracker, not Valve Proton's tracker.

Useful Protontricks discovery commands are:

```bash
protontricks -l
protontricks -s "GAME NAME"
```

Do not apply a verb merely as a diagnostic probe; it mutates the prefix.

## UMU

Repeat the exact game launch with launcher debug output:

```bash
UMU_LOG=debug \
  WINEPREFIX="$HOME/Games/prefixes/example" \
  GAMEID=0 \
  umu-run "$HOME/Games/example/Game.exe"
```

Record the effective prefix, game ID, Proton selection, executable path, and whether UMU downloaded or updated a runtime. Do not compare an UMU failure against a different manager using the same prefix.

## Heroic, Lutris, and Bottles

Heroic:

- open the per-game log after the failed launch;
- start `heroic` from a terminal for client-level output;
- record the selected Wine/Proton runner and prefix.

Lutris:

```bash
lutris -d
```

Use the failed game's **Show logs** action as well. Record the runner, prefix, and any command prefix/environment overrides.

Bottles, only if the optional Flatpak has been deliberately installed:

```bash
flatpak run com.usebottles.bottles
```

Run it from a terminal to retain Flatpak/client output and use the bottle's logs/debugger for Wine details. Check sandbox permissions if the executable or game directory is invisible:

```bash
flatpak info --show-permissions com.usebottles.bottles
```

## GameMode

Start a fresh login session after activation so the new `gamemode` group membership is effective, then run the upstream self-test:

```bash
gamemoded -t
```

Query status:

```bash
gamemoded -s
systemctl --user status gamemoded.service
```

For an observable request:

```bash
gamemoderun sleep 30
```

While it runs, query `gamemoded -s` in another terminal. Check the user journal afterward:

```bash
journalctl --user -u gamemoded.service -b
```

The default test includes the temporary `performance` CPU governor, I/O priority, screensaver inhibition, and split-lock mitigation paths. Confirm that the previous governor/state is restored afterward. This configuration intentionally disables renice capability and defines no GPU tuning; do not enable renice, GPU clocks, AMD performance levels, or overclocking merely to improve an unmeasured result.

## MangoHud

Smoke-test Vulkan overlay injection:

```bash
mangohud vkcube
```

Smoke-test OpenGL injection:

```bash
mangohud glxgears
```

`glxgears` is an overlay-path check, not a benchmark. In a real title, use MangoHud to confirm the renderer, `radv`, process architecture, GPU/CPU load, VRAM, temperature, FPS, and frame-time behavior.

Normal MangoHud wrapping is unsupported around Gamescope. If optional Gamescope is enabled, use:

```text
gamescope --mangoapp -- %command%
```

## Niri, XWayland, and fullscreen

```bash
journalctl --user-unit=niri -b
niri msg outputs
niri msg windows
```

Steam and many games will use on-demand xwayland-satellite. Do not manually set a global `DISPLAY`. For a native SDL game only, compare a per-game Wayland/X11 override as described in [[software/native-linux-games|Native Linux Games]].

If one game mishandles fullscreen or pointer grabs, first use Niri's fullscreen action. Consider optional Gamescope only after reproducing the issue without MangoHud and GameMode.

For a black Steam client window, use the recovery documented in [[software/steam|Steam and Proton]] before changing graphics drivers.

## Controllers

The Steam module supplies targeted controller rules and `uinput`. Identify devices before adding anything:

```bash
lsusb
ls -l /dev/uinput /dev/hidraw* /dev/input/event*
udevadm monitor --udev --property
evtest
```

Use `evtest` on the identified event device and Steam's **Settings -> Controller** input test. Compare Steam Input enabled and disabled for the specific game. Add a new udev rule only when a known vendor/product is absent from existing rules; never use `MODE="0666"` as a generic fix.

## Escalation record

Capture these before changing the host stack:

- game and app/store ID;
- native, Valve Proton, Proton Experimental, GE-Proton, UMU-Proton, or Wine runner version;
- kernel and Mesa versions;
- `vulkaninfo --summary` renderer/driver;
- 32-bit test result when relevant;
- minimal launch options;
- launcher/Proton log;
- kernel `amdgpu` messages and whether the compositor/system survived;
- MangoHud frame time, load, VRAM, and temperatures when the game runs long enough.

Do not upgrade Mesa, LLVM, the kernel, or the complete unstable graphics stack without linking the change to a specific reproduced issue.

## Related

- [[system/gaming|Gaming Architecture]]
- [[software/steam|Steam and Proton]]
- [[software/non-steam-windows-gaming|Non-Steam Windows Gaming]]
- [[software/native-linux-games|Native Linux Games]]
- [[Crash Investigation]]
- [[services/crash-monitor|Crash Monitor]]
