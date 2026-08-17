---
title: Steam and Proton
description: Steam module integration, Proton policy, Protontricks, GameMode, MangoHud, controllers, and optional Gamescope.
tags:
  - gaming
  - steam
  - proton
  - gamemode
  - mangohud
type: software
status: active
date: 2026-08-17
source-files:
  - modules/gaming.nix
  - home/gaming.nix
---

# Steam and Proton

Steam is enabled through the NixOS `programs.steam` module, not installed as a plain package. The module provides the Steam FHS/bubblewrap environment, graphics integration, `steam-run`, controller rules, `uinput`, and 32-bit audio support.

## Declarative configuration

The effective policy in `modules/gaming.nix` is:

```nix
programs.steam = {
  enable = true;
  protontricks.enable = true;
  extraCompatPackages = [ pkgs.proton-ge-bin ];
};
```

GE-Proton is supplied through `extraCompatPackages` because the package's `steamcompattool` output is designed for Steam's compatibility-tool path. Its normal package output intentionally tells users not to install it as a regular global executable.

No firewall exceptions are opened for Remote Play, local network transfers, or a dedicated server. Those Steam features remain client-configurable but may require the corresponding module firewall option. The extest bridge and Gamescope login session remain disabled; enable them only for a demonstrated use.

## Proton selection policy

Use one compatibility tool per game and change it only for a reason:

1. Leave Steam's compatibility override disabled and use Valve's title-specific default.
2. Select current Valve Proton Stable if an explicit version is useful.
3. Try Proton Experimental for a known newer fix.
4. Select GE-Proton for a game that specifically benefits from its patches or codecs.

GE-Proton is available, not globally forced. After the first rebuild, fully exit and restart Steam if it does not appear under a game's **Properties -> Compatibility** selector.

Valve describes Proton as a Steam tool and recommends the builds provided by the Steam client for normal users. UMU, rather than direct `proton` invocation, is the supported architecture here for non-Steam Windows games.

## Native versus Windows builds

Run a maintained native Steam build normally. If an old Linux port has stale libraries, missing updates, or game-specific defects, select **Force the use of a specific Steam Play compatibility tool** to install and run the Windows depot through Proton. This is a per-title workaround, not a policy that Windows builds are always better.

## Protontricks

Protontricks applies Winetricks verbs or launches tools inside one Steam game's Proton prefix:

```bash
protontricks -l
protontricks -s "GAME NAME"
protontricks APPID VERB
protontricks --gui
```

Launch the game once before using Protontricks so Steam creates its prefix. Apply only a title-specific, documented verb. Protontricks makes persistent prefix changes; it should not be a routine way to replace Proton's DXVK/VKD3D or install broad dependency collections. Back up saves before invasive changes.

## GameMode

The NixOS GameMode module is enabled with no custom settings and `enableRenice = false`. Upstream defaults still request the `performance` CPU governor while active, BE/0 I/O priority, screensaver inhibition, and temporary split-lock mitigation changes. Membership in the `gamemode` group permits those standard privileged helpers. GameMode should restore the prior governor and kernel setting after the last client exits.

This deliberately avoids `CAP_SYS_NICE`, process renicing, GPU performance-level controls, GPU clock offsets, custom scripts, and overclocking. The GPU optimization block remains disabled by default.

For a Steam title that does not request GameMode itself, use:

```text
gamemoderun %command%
```

For a direct native executable:

```bash
gamemoderun ./game
```

GameMode does not replace the existing NBFC fan policy. Validate temperatures and restoration of the normal power state, especially while the GPU stability investigation remains open.

## MangoHud

Home Manager installs MangoHud with a diagnostic layout but does not enable it session-wide. Opt in per title:

```text
mangohud %command%
```

Combine it with GameMode in this order:

```text
mangohud gamemoderun %command%
```

The wrapper works with Vulkan and OpenGL. `MANGOHUD=1 %command%` is a Vulkan-only alternative. The configured overlay shows FPS, frame time, CPU/GPU load and temperature, RAM/VRAM, architecture, Vulkan driver, Wine/Proton version, and GameMode state.

MangoHud is diagnostic instrumentation, not a reason to globally inject preload variables into every process. See [[runbooks/gaming-diagnostics|Gaming Diagnostics]].

## Controllers

`programs.steam.enable` enables `hardware.steam-hardware`. That installs Valve/common-controller rules, loads `uinput`, and grants targeted session access. Bluetooth is already enabled elsewhere.

Use Steam Input per game. If a title sees duplicate devices or incorrect button prompts, compare that title with Steam Input enabled and disabled. Do not add a broad udev rule or join a broad input-device group without identifying a controller that the existing rules do not cover.

If Steam Input's keyboard/mouse emulation specifically cannot move the pointer under Wayland, the module has an optional bridge:

```nix
programs.steam.extest.enable = true;
```

It is not enabled preemptively because it adds another preload layer.

## `steam-run`

The Steam module installs its customized `steam-run` automatically. It runs a native Linux command in Steam's FHS-like runtime:

```bash
steam-run ./proprietary-linux-game
steam-run ./installer-or-tool --argument
```

It is not Wine and cannot execute Windows PE files by itself. See [[software/native-linux-games|Native Linux Games]].

## Optional Gamescope

Gamescope is not enabled globally. It is useful for fixed virtual resolutions, upscaling, frame-rate management, nested sessions, pointer confinement, and games that assume a stacking window manager. Niri currently recommends the SDL backend and forced cursor grab for problematic fullscreen games:

```text
gamescope -f -w 1920 -h 1080 -W 1920 -H 1080 --force-grab-cursor --backend sdl -- %command%
```

If a concrete game needs it, enable `programs.gamescope.enable = true` in `modules/gaming.nix` first. Do not enable the separate Steam Gamescope login session or `capSysNice` by default.

On Polaris/GFX8, Gamescope upstream documents possible corruption for native RadeonSI/OpenGL clients. Only after observing that problem, test the per-game `R600_DEBUG=nodcc` workaround. It can reduce performance and must not become a global variable. Normal Proton DXVK/VKD3D games use RADV rather than this OpenGL path.

When using Gamescope, normal MangoHud wrapping is unsupported; use Gamescope's MangoApp path:

```text
gamescope --mangoapp -- %command%
```

If the Steam client itself opens as a black window under Niri, first disable **GPU accelerated rendering in web views** through Steam's tray/settings interface and restart it. As a diagnostic alternative, test:

```bash
steam -system-composer
```

## State and recovery

Steam commonly stores state under `~/.local/share/Steam/`. Proton prefixes are normally under a library's `steamapps/compatdata/<APPID>/pfx`. Save files may live in that prefix, Steam Cloud, or a game-specific path.

Do not delete `compatdata` as a first troubleshooting step. Record the app ID and selected Proton version, collect a log, and back up saves first.

## Related

- [[system/gaming|Gaming Architecture]]
- [[software/non-steam-windows-gaming|Non-Steam Windows Gaming]]
- [[software/native-linux-games|Native Linux Games]]
- [[runbooks/gaming-diagnostics|Gaming Diagnostics]]

## Current sources

- [NixOS Steam module at the pinned revision](https://github.com/NixOS/nixpkgs/blob/70cc4559b10a6062b05ff1af17e0add065ccaed9/nixos/modules/programs/steam.nix)
- [Official NixOS Steam page](https://wiki.nixos.org/wiki/Steam)
- [Valve Proton README](https://github.com/ValveSoftware/Proton/blob/proton_11.0/README.md)
- [GameMode README](https://github.com/FeralInteractive/gamemode/blob/1.8.2/README.md)
- [MangoHud README](https://github.com/flightlessmango/MangoHud/blob/v0.8.3/README.md)
- [Niri application-specific gaming guidance](https://niri-wm.github.io/niri/Application-Issues.html#fullscreen-games)
