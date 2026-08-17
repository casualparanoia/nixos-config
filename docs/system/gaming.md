---
title: Gaming Architecture
description: System design and decision model for native Linux, Steam, Proton, non-Steam Windows, and foreign-binary games.
tags:
  - gaming
  - architecture
  - steam
  - wine
  - amdgpu
type: architecture
status: active
date: 2026-08-17
aliases:
  - Gaming
source-files:
  - modules/gaming.nix
  - home/gaming.nix
---

# Gaming Architecture

The gaming setup separates host graphics and hardware integration from game launchers and from each game's mutable runtime state. The configuration declares stable Mesa/RADV, both graphics architectures, Steam integration, GameMode, diagnostics, and selected launchers. Steam, Heroic, Lutris, and UMU remain responsible for their own runners and prefixes; Bottles is a documented optional alternative.

## Decision table

| Situation | Preferred mechanism | Reason |
|---|---|---|
| Steam native Linux game | [[software/steam|Steam]] | Steam supplies the title and its expected Linux runtime. |
| Steam Windows game | Steam plus Valve Proton | This is Proton's primary supported environment. |
| Broken or abandoned native Steam port | Force the Windows build through Proton | The Windows build is sometimes newer or better tested. |
| GOG, Epic, or Amazon game | [[software/non-steam-windows-gaming|Heroic]] | Focused store integration, downloads, updates, cloud saves, and UMU support. |
| Simple standalone Windows game | UMU | Low-level Proton launch outside Steam with the Steam Linux Runtime. |
| Complex installer, launcher, or unusual runner | Lutris | Per-game installer scripts and broad runner configuration. |
| Manually isolated Windows environment | Bottles | Explicit bottle/prefix management in upstream's preferred Flatpak distribution. |
| Raw Wine experiment | Optional system Wine | Only when a launcher-managed environment is the wrong abstraction. |
| Native game available in Nixpkgs | Nix package | Reproducible dependencies and NixOS-compatible ELF paths. |
| Arbitrary proprietary Linux binary | Proper package or `steam-run` | NixOS does not expose a conventional global FHS library tree. |
| Authorized Steamworks interoperability fixture | Per-game [[software/gbe-fork|gbe_fork]] files | The emulator is test data layered onto one writable game copy, not a system runtime. |

See [[runbooks/non-steam-game|Run a Non-Steam Game]] for procedures rather than just tool selection.

## Declared layers

These layers are present in the built configuration and become available after `nixos-rebuild switch` and a fresh login. They are not claims about the currently running generation.

Before the new module files are committed, use the explicit path flake so Git does not exclude untracked files:

```bash
sudo nixos-rebuild switch --flake path:.#nixos
```

After the files are tracked, the repository's normal `.#nixos` form is equivalent. A fresh login is required for `gamemode` group membership.

```text
NixOS host
|- stable kernel + amdgpu
|- stable Mesa 26.1.5 + RADV/RadeonSI
|- 64-bit and 32-bit hardware.graphics
|- Steam module + Steam runtime + steam-run
|- GameMode daemon, without renice or GPU tuning
|- Vulkan/OpenGL/input diagnostics
|
Home Manager
|- Heroic 2.22.0, with GameMode available in its runtime
|- Lutris 0.5.22, without its redundant embedded Steam and with GameMode available
|- UMU Launcher 1.4.0
|- MangoHud 0.8.3, opt-in per launch
|
Optional Flatpak
`- Bottles, only after a permission review and explicit declaration
```

Steam 1.0.0.85, Protontricks 1.14.1, GE-Proton11-1, and GameMode 1.8.2 come from the pinned stable Nixpkgs input. Valve Proton itself remains managed by Steam.

The NixOS Steam module also installs its customized `steam-run` environment, enables Valve/common-controller udev rules, loads `uinput`, and ensures 32-bit PipeWire support. Those pieces are not duplicated manually.

## Graphics policy

The RX 580/Polaris stack remains deliberately ordinary:

- kernel `amdgpu` remains the kernel driver;
- stable Mesa provides RadeonSI for OpenGL and RADV for Vulkan;
- `hardware.graphics.enable` and `enable32Bit` are explicit;
- no AMDVLK, AMD proprietary driver, ROCm/OpenCL change, Mesa override, LLVM override, or kernel change is part of gaming;
- the existing `amdgpu.gpu_recovery=1`, fan control, and crash monitoring remain unchanged.

Steam also enables both graphics architectures internally, but the explicit declaration is intentional: non-Steam games must not conceptually depend on Steam to obtain 32-bit Vulkan/OpenGL support.

The machine is still under a stability investigation. Treat a game crash, compositor failure, and whole-machine GPU reset as different failure classes. Do not upgrade the complete graphics stack until a specific title or identified Mesa/kernel bug provides a reason. See [[Crash Investigation]] and [[runbooks/gaming-diagnostics|Gaming Diagnostics]].

## Runtime ownership

Each game has one runtime owner and one prefix owner:

| Owner | State it should manage |
|---|---|
| Steam | Steam library, `steamapps/compatdata/<APPID>`, Valve Proton selection |
| Heroic | Heroic library metadata, selected runner, and its per-game prefix |
| Lutris | Lutris game entry, installer result, selected runner, and prefix |
| UMU | Explicit game command, Proton selection, and `WINEPREFIX` |
| Bottles | One named bottle and applications installed inside it |

Do not point Heroic, Lutris, Bottles, raw Wine, and UMU at the same writable prefix. Runner changes mutate prefixes, and cross-manager ownership makes upgrades and recovery ambiguous. Back up saves before changing runner families or deleting a prefix; saves may be inside the prefix or elsewhere in the game directory.

## Package-source decisions

| Component | Source | Decision |
|---|---|---|
| Steam, GE-Proton, Protontricks, GameMode | Stable Nixpkgs | Current module-native integration; no unstable fix is required. |
| Heroic, Lutris, UMU, MangoHud | Stable Nixpkgs | Current enough and already wrapped for NixOS/FHS or multilib use. Heroic/Lutris use their supported `extraPkgs` hook for GameMode only. |
| Bottles | Not installed; prefer Flathub if selected | Upstream calls Flatpak its most supported and tested distribution, but its current manifest has broad device and UMU-directory access that must be reviewed first. |
| Faugus | Not installed | Useful UMU GUI, but redundant with direct UMU plus Lutris; pinned stable is 1.22.6 while upstream is 2.1.0. |
| Raw Wine and Winetricks | Not installed | Existing launchers own normal game runtimes; install only for a concrete manual-prefix need. |
| Gamescope | Not enabled | Useful for specific Niri/fullscreen/scaling problems, but adds another compositor and is not yet required. |
| `gbe_fork` | Not packaged | Per-game authorized test files, not a host runtime. A narrow helper package may be justified later. |

No gaming component currently uses `pkgsUnstable`. This follows [[Package Source Policy]] rather than selecting unstable solely for a higher version.

## Wayland and Niri

Niri starts `xwayland-satellite` on demand, so Steam, Proton, and X11 games do not need a global `DISPLAY` override. Native Wayland games can use Wayland directly. The existing Niri module sets `NIXOS_OZONE_WL=1`, which already biases Ozone/Electron applications such as Heroic toward Wayland; gaming adds no broader display override. For one process, `env -u NIXOS_OZONE_WL APPLICATION` removes that existing hint while testing. Do not globally force SDL, Wine, or Steam onto X11 or Wayland.

For one native SDL game, compare backends per launch:

```bash
SDL_VIDEODRIVER=wayland ./game
SDL_VIDEODRIVER=x11 ./game
```

SDL3 uses `SDL_VIDEO_DRIVER` instead. Games that mishandle fullscreen, pointer grabs, or assumptions from stacking X11 window managers may benefit from optional Gamescope; see [[software/steam|Steam and Proton]].

## Security and writable state

- Never run Steam, a game launcher, a Windows installer, Wine, Proton, or UMU as root.
- Treat arbitrary Windows and Linux executables as untrusted code with access to the files visible to their process or sandbox.
- Keep games and prefixes in user-writable locations. `/nix/store` is immutable and is not a game-data or prefix location.
- Flatpak isolation is permission-based, not absolute. Before declaring Bottles, review its manifest and effective permissions, including device access and access to UMU state directories.
- Do not make game directories or device files world-writable. Steam's hardware rules use targeted device matching and session access.
- Keep credentials, launcher tokens, Wine registry state, and generated settings out of Nix derivations because store paths are immutable and generally readable.

## Related

- [[software/steam|Steam and Proton]]
- [[software/non-steam-windows-gaming|Non-Steam Windows Gaming]]
- [[software/native-linux-games|Native Linux Games]]
- [[software/gbe-fork|gbe_fork]]
- [[runbooks/non-steam-game|Run a Non-Steam Game]]
- [[runbooks/per-game-compatibility-layers|Per-Game Compatibility Layers]]
- [[runbooks/gaming-diagnostics|Gaming Diagnostics]]
- [[Flatpak]]
- [[Package Source Policy]]

## Current sources

- [Official NixOS Gaming category](https://wiki.nixos.org/wiki/Category:Gaming)
- [Official NixOS Steam page](https://wiki.nixos.org/wiki/Steam)
- [Official NixOS AMD GPU page](https://wiki.nixos.org/wiki/AMD_GPU)
- [Valve Proton](https://github.com/ValveSoftware/Proton)
- [UMU Launcher](https://github.com/Open-Wine-Components/umu-launcher)
