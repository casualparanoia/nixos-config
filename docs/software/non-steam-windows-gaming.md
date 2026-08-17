---
title: Non-Steam Windows Gaming
description: Roles and runtime boundaries for UMU, Heroic, Lutris, Bottles, Faugus, and direct Wine.
tags:
  - gaming
  - wine
  - proton
  - umu
  - flatpak
type: software
status: active
date: 2026-08-17
source-files:
  - home/gaming.nix
---

# Non-Steam Windows Gaming

Non-Steam Windows games should still run inside a purpose-built compatibility environment. Calling a Proton script directly omits assumptions that Steam normally supplies; globally combining Wine, DXVK, VKD3D, and random libraries creates an unmaintainable shared runtime.

## Tool boundaries

| Tool | Installed | Primary role | Runtime behavior |
|---|---|---|---|
| UMU Launcher | Stable Nixpkgs 1.4.0 | Direct standalone Proton launch | Nixpkgs wraps it in a multiarch Steam runtime environment; UMU manages Proton and pressure-vessel behavior. |
| Heroic | Stable Nixpkgs 2.22.0 | GOG, Epic, Amazon, and imported games | Nixpkgs wraps Heroic in a Steam-style runtime and includes UMU on supported Linux systems. Its supported `extraPkgs` hook adds GameMode. |
| Lutris | Stable Nixpkgs 0.5.22 | Complex installers, launchers, community scripts, unusual runners | Nixpkgs provides a broad multilib FHS environment; its `extraPkgs` hook adds GameMode and embedded Steam support is disabled. Do not wrap it in `steam-run`. |
| Bottles | No; optional Flathub declaration | Isolated Wine environments and Windows applications | Upstream's most tested distribution, but its broad default permissions require review before installation. |
| Faugus | No | Optional lightweight UMU GUI | Redundant with direct UMU plus Lutris in the current setup. |
| Raw Wine/Winetricks | No | Manual debugging or intentionally hand-built prefixes | Must not become the runner for launcher-owned games. |

## UMU Launcher

[UMU](https://github.com/Open-Wine-Components/umu-launcher) makes Proton and protonfixes available outside Steam while preserving the Steam Linux Runtime/container model. It is preferable to invoking Proton directly because it establishes the runtime, Proton verb, prefix, and known-game fix environment in a standardized way.

A minimal isolated launch is:

```bash
WINEPREFIX="$HOME/Games/prefixes/example" \
  GAMEID=0 \
  umu-run "$HOME/Games/example/Game.exe"
```

The directory layout is an example, not a global requirement. Use one prefix per game or tightly related launcher environment. If `WINEPREFIX` is omitted, UMU defaults beneath `$HOME/Games/umu/`; explicitly naming it makes backups and ownership clearer.

If `PROTONPATH` is omitted, UMU obtains/uses UMU-Proton. It can also accept a full Proton directory, a version name, or the `GE-Proton` codename. Steam's declarative GE-Proton path is guaranteed inside Steam; it is not a reason to set a global `PROTONPATH` for every UMU game.

Useful per-launch variables are:

| Variable | Purpose |
|---|---|
| `WINEPREFIX` | Writable compatibility prefix for this game. |
| `GAMEID` | UMU database ID or an arbitrary value; a known ID can select protonfixes. |
| `STORE` | Store identifier such as `gog`, `egs`, `amazon`, or `itchio`. |
| `PROTONPATH` | Explicit Proton directory/version/codename when not using default UMU-Proton. |
| `UMU_LOG=debug` | Verbose launcher diagnostics for one invocation. |

UMU also accepts a TOML file:

```toml
[umu]
prefix = "/home/casua/Games/prefixes/example"
proton = "/home/casua/.local/share/Steam/compatibilitytools.d/GE-Proton11-1"
exe = "/home/casua/Games/example/Game.exe"
game_id = "0"
store = "gog"
launch_args = ["-windowed"]
```

```bash
umu-run --config example.toml
```

The Proton path is illustrative and must point to a real compatibility-tool directory. Do not commit user-specific launcher tokens or mutable prefixes into this repository.

Windows save/config data may be in the game directory or inside the prefix under paths corresponding to `AppData`, `Documents`, or `Saved Games`. Consult the game rather than assuming the prefix is disposable.

## Heroic

Use Heroic for GOG, Epic Games Store, and Amazon Games libraries. It handles authentication, downloads, updates, cloud saves where supported, imported games, runner selection, and UMU integration.

Keep each title's prefix and runner owned by Heroic. Do not open the same prefix as a Lutris game or Bottles bottle. Heroic's Nix package already supplies a runtime wrapper and UMU; the only override adds `gamemode` through the wrapper's supported `extraPkgs` interface so Heroic's GameMode option can reach the system daemon. Adding a second broad Wine environment would duplicate and obscure that integration.

For troubleshooting, open the game's log in Heroic after a failed launch. Starting `heroic` from a terminal also captures client-level output.

## Lutris

Use Lutris when a title needs a community installer, multiple setup stages, a non-store launcher, an emulator, unusual environment variables, or more manual runner control than Heroic provides.

The Nixpkgs package is already a large multilib FHS environment. Its supported `extraPkgs` interface adds GameMode, which Lutris can request for a game. The package's `steamSupport` override is disabled because Steam is owned by the NixOS module; this avoids embedding a second plain Steam that would not carry the declarative GE-Proton path. Run `lutris` directly, not through `steam-run`, UMU, or another FHS wrapper. Let each Lutris game entry own its runner and prefix.

Useful diagnostic launch:

```bash
lutris -d
```

User data is normally under `~/.local/share/lutris/`, including game YAML, runner configuration, and the library database. Prefixes and installed games may be elsewhere according to each game entry.

## Bottles

Bottles is not installed by default. Upstream identifies Flatpak as its most supported and tested release, so Flathub is the preferred source if an isolated bottle becomes necessary. Use it for a named Windows application or manually managed environment, not as an extra layer around Steam, Heroic, Lutris, or UMU.

The current Flathub manifest grants broad device access and writable access to UMU directories including `~/Games/umu` and `~/.local/share/umu`. That weakens isolation and can cross the one-owner prefix boundary. Review the current manifest and effective permissions before adding this ID to `modules/flatpak.nix`:

```nix
services.flatpak.packages = [
  "com.usebottles.bottles"
];
```

Its Flatpak data is normally under:

```text
~/.var/app/com.usebottles.bottles/data/bottles/
```

After installation, inspect effective sandbox permissions before granting more access:

```bash
flatpak info --show-permissions com.usebottles.bottles
```

Prefer a narrow game-directory grant over broad host or home access. Run the GUI normally, or inspect named bottles with:

```bash
flatpak run --command=bottles-cli com.usebottles.bottles list bottles
```

Do not attempt to make Bottles reuse a Steam `compatdata` prefix.

## Faugus

Faugus is a lightweight GUI centered on UMU and is a good alternative for users who want a simpler standalone-game interface. It is not installed because direct UMU already supplies the low-level path and Lutris supplies the configurable GUI path. The pinned stable package is 1.22.6, unstable is 2.0.6, and upstream is 2.1.0; a channel switch still would not reach current upstream and is not justified by an identified need.

If workflow experience shows that Lutris is excessive for simple UMU entries, reconsider Faugus as a replacement, not another default launcher.

## Raw Wine and Winetricks

NixOS 26.05 provides the current WoW64 architecture as `wineWow64Packages`; the older `wineWowPackages` family is deprecated. A future explicit manual-prefix setup would normally start with:

```nix
home.packages = with pkgs; [
  wineWow64Packages.stableFull
  winetricks
];
```

That is intentionally absent now. Raw Wine is appropriate for compatibility testing, non-game Windows software, or a game deliberately managed without Proton/UMU/Lutris/Bottles. It must not silently become the Wine executable used inside another launcher's prefix.

## Related

- [[system/gaming|Gaming Architecture]]
- [[runbooks/non-steam-game|Run a Non-Steam Game]]
- [[runbooks/gaming-diagnostics|Gaming Diagnostics]]
- [[software/gbe-fork|gbe_fork]]
- [[Flatpak]]

## Current sources

- [UMU Launcher 1.4.0 manual](https://github.com/Open-Wine-Components/umu-launcher/blob/1.4.0/docs/umu.1.scd)
- [UMU Launcher 1.4.0 configuration format](https://github.com/Open-Wine-Components/umu-launcher/blob/1.4.0/docs/umu.5.scd)
- [Heroic Games Launcher](https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher)
- [Official NixOS Heroic page](https://wiki.nixos.org/wiki/Heroic_Games_Launcher)
- [Lutris 0.5.22](https://github.com/lutris/lutris/tree/v0.5.22)
- [Faugus Launcher](https://github.com/Faugus/faugus-launcher)
- [Bottles installation guidance](https://docs.usebottles.com/getting-started/installation)
- [Flathub Bottles manifest](https://github.com/flathub/com.usebottles.bottles)
- [Official NixOS Wine page](https://wiki.nixos.org/wiki/Wine)
