---
title: Native Linux Games
description: Runtime choices for Nixpkgs games, Steam Linux titles, and arbitrary proprietary Linux binaries on NixOS.
tags:
  - gaming
  - linux
  - fhs
  - steam-run
  - packaging
type: software
status: active
date: 2026-08-17
source-files:
  - modules/gaming.nix
---

# Native Linux Games

Native Linux games do not need Wine or Proton, but they still need a compatible Linux userspace. NixOS does not maintain the conventional global `/lib`, `/usr/lib`, and distribution-specific loader layout assumed by many binaries built for Ubuntu or similar systems.

## Game available in Nixpkgs

Prefer the Nix package when it is current and functional. A normal Nix package records dependencies, patches the ELF interpreter/RPATH where needed, installs desktop files, and makes runtime behavior reproducible.

Follow [[Package Source Policy]]: stable first, unstable only for a concrete fix, and local packaging only when Nixpkgs is unsuitable.

## Native Steam game

Run a maintained Linux build through [[software/steam|Steam]]. Steam supplies the title's expected Linux runtime. If an old native port is broken while the Windows version remains maintained, forcing the Windows depot through Proton can be the better per-game choice.

## Standalone Linux binary

Use this order:

1. Package the game properly in Nix when its dependencies and update process are understood.
2. Use `steam-run` for an ad hoc proprietary binary that expects a common Steam/FHS userspace.
3. Build a narrow title-specific FHS environment only when `steam-run` is unsuitable and packaging is not practical.
4. Use an upstream-supported Flatpak when its sandbox and file access fit the game.

Do not globally add random libraries, loader symlinks, or `LD_LIBRARY_PATH` entries until a downloaded binary happens to start. That hides dependencies and can break unrelated software.

## `steam-run`

The NixOS Steam module installs `steam-run`; no duplicate runtime package is declared. Run a foreign native executable with:

```bash
cd "$HOME/Games/example"
steam-run ./example-game
```

Pass arguments normally:

```bash
steam-run ./example-game --windowed
```

Inspect dynamic-loader decisions when troubleshooting:

```bash
steam-run env LD_DEBUG=libs ./example-game
```

`steam-run` supplies an FHS-like environment and common 64/32-bit game libraries. It does not:

- turn a Windows `.exe` into a Linux program;
- create a Wine/Proton prefix;
- guarantee every vendor-specific library or launcher works;
- make an untrusted binary safe.

Do not wrap packaged Heroic, Lutris, UMU, or Bottles in `steam-run`; those applications already own their runtime/container environment.

## Packaging versus an FHS environment

Package a game when repeatability, desktop integration, updates, or known native dependencies matter. Use a runtime environment when the binary is large, proprietary, self-updating, or too distribution-coupled to patch economically.

An AppImage is also a foreign Linux bundle. It may need FUSE or extraction and may still make assumptions about host graphics and portals. Treat it as a packaging format, not proof of NixOS compatibility.

The system-wide `nix-ld` compatibility feature may let some foreign executables start, but it is not a declaration of the game's full dependencies. Prefer a package or `steam-run` for a repeatable game setup.

## Per-game instrumentation

For a native Vulkan or OpenGL game:

```bash
mangohud gamemoderun ./example-game
```

For a foreign binary:

```bash
steam-run mangohud gamemoderun ./example-game
```

If the wrapper ordering fails for one title, remove all instrumentation, prove the base runtime works, and add one layer at a time.

## Wayland and X11

Niri provides on-demand XWayland support. Do not globally force a display backend. For one SDL2 game, compare:

```bash
SDL_VIDEODRIVER=wayland ./example-game
SDL_VIDEODRIVER=x11 ./example-game
```

SDL3 uses `SDL_VIDEO_DRIVER`. Use a per-game override only after identifying the game's SDL generation. Games with pointer-grab or fullscreen assumptions may need optional Gamescope as documented in [[software/steam|Steam and Proton]].

## `gbe_fork` layering

For authorized native Steamworks interoperability testing, `libsteam_api.so` and `steam_settings/` belong in a writable test copy of the game. The native game still needs a working packaged or `steam-run` runtime underneath; `gbe_fork` does not supply normal Linux libraries. See [[software/gbe-fork|gbe_fork]].

## Related

- [[system/gaming|Gaming Architecture]]
- [[software/steam|Steam and Proton]]
- [[runbooks/non-steam-game|Run a Non-Steam Game]]
- [[runbooks/gaming-diagnostics|Gaming Diagnostics]]
- [[Foreign Binary Packaging]]
- [[runbooks/binary-packaging|Binary Packaging Runbook]]

## Current sources

- [Official NixOS Steam page: FHS environment](https://wiki.nixos.org/wiki/Steam#FHS_environment_only)
- [Nixpkgs Steam runtime package](https://github.com/NixOS/nixpkgs/blob/70cc4559b10a6062b05ff1af17e0add065ccaed9/pkgs/by-name/st/steam/package.nix)
