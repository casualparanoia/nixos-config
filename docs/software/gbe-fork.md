---
title: gbe_fork
description: Authorized per-game Steamworks interoperability testing with gbe_fork on NixOS.
tags:
  - gaming
  - steamworks
  - interoperability
  - testing
type: software
status: deferred
date: 2026-08-17
---

# gbe_fork

[`gbe_fork`](https://github.com/Detanup01/gbe_fork) is not a gaming runtime and is not installed globally. It can be a per-game fixture for authorized interoperability, offline behavior, interface-version, callback, storage, or LAN testing after the game already has a working Windows or Linux runtime.

Use it only with software that may legally and contractually be modified and tested. It does not validate real Steam authentication, entitlements, matchmaking, anti-cheat, or production backend behavior. This page does not cover removing DRM or evading access controls.

The current non-prerelease upstream snapshot researched for this configuration is `release-2026_07_19`, commit `64bd1fcfef82d397cd4bdba49adc08f0c49da31c`. Upstream warns that this fork is incompatible with the original project and may be broken, so preserve original files and use a disposable test copy.

GitHub reports these SHA-256 asset digests:

| Asset | SHA-256 |
|---|---|
| `emu-linux-release.tar.bz2` | `382abe29f7e9e4febb2f73c9e2a3376e6aafd993266890d519f24bec8948d604` |
| `emu-win-release.7z` | `3ba855ef962205136a54fb32519a46362e0cc5b42fc2bb3667e4d21307d972e5` |
| `migrate_gse-linux.tar.bz2` | `1eada9e88abe0389fa5782dbde18f783e970ff34a4c9f423c475b9a081caa60b` |
| `migrate_gse-win.7z` | `78f7b5d978f8f0dff647a906797616d27b1c04a377e5aafad170715185acacdb` |

These are publisher-hosted integrity values, not an independent signature. Record the tag, commit, filename, and digest together.

## Current alternatives

| Project | Current status | Recommendation |
|---|---|---|
| `gbe_fork` | Active Windows/Linux x86/x64 Steam API and steamclient implementation; July 2026 release | Preferred broad binary-level baseline for authorized offline tests. Pin one reviewed release. |
| [`gse_fork`](https://github.com/alex47exe/gse_fork) | Active downstream of `gbe_fork`; release `2026_02_16`, later commits through June 2026 | Case-specific alternative when one of its documented changes fixes a tested problem. It is not independent and may lag `gbe_fork`. |
| [Original Goldberg](https://gitlab.com/Mr_Goldberg/goldberg_emulator) | Linux/Windows upstream lineage; last code activity in 2023 and last formal release in 2019 | Legacy reference, not the default for current Steamworks interfaces. |
| [GameNetworkingSockets](https://github.com/ValveSoftware/GameNetworkingSockets) | Maintained BSD-licensed Valve transport library for Windows/Linux/macOS | Best source-level choice when the application is owned and only networking transport must work without Steam. It is not a binary Steam API replacement. |
| [ColdAPI_Steam](https://github.com/Rat431/ColdAPI_Steam) | Windows-only, last release in 2020, no repository license | Legacy provenance for ColdClientLoader concepts; do not adopt as a current open-source baseline. |
| SmartSteamEmu | No verifiable maintained primary source, license, or native Linux support | Omit from this architecture. |

Tools that inject into or modify a live Steam client are a different and much riskier category: they are client-version-sensitive, touch real account/cloud state, and are not recommended for isolated offline testing. Steamworks.NET and Facepunch.Steamworks are maintained source wrappers around the real Steam API, not emulators.

## Layering model

Windows game:

```text
UMU / Lutris / another Windows-game runtime
`- writable test copy of the Windows game
   |- steam_api.dll or steam_api64.dll
   `- steam_settings/
```

Native Linux game:

```text
steam-run / title-specific Nix package
`- writable test copy of the native game
   |- libsteam_api.so
   `- steam_settings/
```

Do not add an extra `steam-run` around UMU or Lutris. Do not globally replace Steam libraries.

## Writable staging model

Leave the canonical installation untouched. Create an immutable baseline copy and a second disposable working copy:

```bash
source="$HOME/Games/authorized-source"
root="$HOME/Games/authorized-test"
baseline="$root/baseline"
work="$root/work"

mkdir -p -- "$baseline" "$work"
cp -a --no-preserve=ownership --reflink=auto -- "$source/." "$baseline/"
cp -a --no-preserve=ownership --reflink=auto -- "$baseline/." "$work/"
chmod -R a-w -- "$baseline"
chmod -R u+rwX,go-w -- "$work"
```

Record the original API-library hash before changing the working copy:

```bash
sha256sum -- "$baseline/path/to/steam_api64.dll"
```

Stop Steam, launchers, cloud synchronization, and game processes while staging. If a file in the copy is still a symlink into `/nix/store`, replace the symlink itself in the disposable tree rather than trying to modify its store target.

## Library placement

The application's architecture, not the host architecture, selects the release file:

| Target application | Release file |
|---|---|
| 32-bit Windows | `regular/x86/steam_api.dll` |
| 64-bit Windows | `regular/x64/steam_api64.dll` |
| 32-bit native Linux | `regular/x86/libsteam_api.so` |
| 64-bit native Linux | `regular/x64/libsteam_api.so` |

Upstream's model is to place the selected file where the original API library was loaded, retaining the expected filename. Keep the original library outside the test tree or under an unambiguous backup name. `steam_settings/` belongs beside the replacement library because the emulator derives settings from its own loaded location.

Never mutate a packaged game under `/nix/store`. Copy only the authorized test payload into a user-writable game directory first. Active settings, generated interfaces, portable saves, and loader state must also remain writable and outside the store.

## Interface generation

Some applications require `steam_interfaces.txt`:

1. Preserve the original `steam_api.dll`, `steam_api64.dll`, or `libsteam_api.so`.
2. Run `generate_interfaces` against that original library from a fresh writable staging directory.
3. Move the generated `steam_interfaces.txt` into the adjacent `steam_settings/` directory.

The current release actually contains `generate_interfaces_x64` and `generate_interfaces_x86` (with `.exe` on Windows), although one upstream readme still uses obsolete `_file` names. The suffix describes the helper process, not the input: the 64-bit helper scans either a 32-bit or 64-bit original library as bytes. It writes `steam_interfaces.txt` in its current working directory and truncates an existing file with that name.

The prebuilt Linux helpers expect conventional ELF interpreter/library paths. Run the 64-bit helper through the existing Steam FHS environment:

```bash
stage="$HOME/Games/gbe-interface-work"
generator="/path/to/gbe/release/tools/generate_interfaces/generate_interfaces_x64"
original="$HOME/Games/authorized-test/baseline/path/to/original/steam_api64.dll"

mkdir -p -- "$stage"
env -C "$stage" steam-run "$generator" "$original"
```

Inspect the generated file before placing it under the working copy's `steam_settings/`. A future source-built Nix package for this narrow helper would be more reproducible than the upstream FHS binary.

## Settings and helpers

The release includes `steam_settings.EXAMPLE`. Copy only the needed examples, remove `.EXAMPLE`, and do not enable every setting. A conservative regular-mode fixture is:

```text
directory containing the loaded replacement library/
|- steam_api.dll, steam_api64.dll, or libsteam_api.so
`- steam_settings/
   |- steam_interfaces.txt
   |- steam_appid.txt
   `- configs.user.ini        optional local-state isolation
```

The principal INI files are:

- `configs.main.ini` for emulator behavior;
- `configs.user.ini` for user/save behavior;
- `configs.app.ini` for application behavior;
- `configs.overlay.ini` for the optional experimental overlay.

Local settings override global settings. Native Linux global state defaults to `$XDG_DATA_HOME/GSE Saves/` or `~/.local/share/GSE Saves/`. For disposable local state, a minimal `configs.user.ini` can use:

```ini
[user::saves]
local_save_path=./gse-state
```

A relative `local_save_path` is relative to the emulator library and must not point into `/nix/store`. Use the authorized application's real ID in `steam_appid.txt`; this identifies the test target but does not provide authentication or entitlement.

`migrate_gse` is a separate release asset that converts older settings to the current INI model. It reads an explicit source directory and writes `steam_settings/` under its current working directory, potentially overwriting existing output. Run it from an empty work directory against an immutable backup, then diff and manually merge the generated files. It does not automatically preserve every image, sound, mod, JSON, or other non-converted asset.

The separate [`gbe_fork_tools`](https://github.com/Detanup01/gbe_fork_tools) repository now contains `generate_emu_config_old`; the current emulator archive does not contain the older `generate_emu_config` command still mentioned by some documentation. The companion can request real Steam credentials, read plaintext `my_login.txt`, and store refresh tokens. Do not use authenticated mode and never put credentials, tokens, its output, or backup directories in this repository or the Nix store. Prefer manual minimal settings and public metadata.

`lobby_connect_x86` and `lobby_connect_x64` discover emulator peers on a local network. On Linux they print connection arguments for manual use rather than selecting and launching the game as the generic upstream readme suggests. Use the helper only on a trusted test LAN, review peer-provided arguments, and do not expose discovery traffic publicly.

The experimental overlay is not part of the baseline. It hooks graphics APIs, works with relatively few Linux games, can conflict with MangoHud/other overlays, and can introduce crashes or frame-time problems. Start with `regular/` and add the overlay only as a separate controlled variable.

## ColdClientLoader and native loader

The current Windows fallback is under `steamclient_experimental/` and uses `steamclient_loader_x86.exe` or `steamclient_loader_x64.exe` plus `ColdClientLoader.ini`. The release readme's unsuffixed `steamclient_loader.exe` name is stale. Conceptually this mode keeps the application's original Steam API library and substitutes an emulated `steamclient` backend; `steam_interfaces.txt` is not required and settings belong beside the replacement `steamclient` libraries.

For an isolated Windows test, keep both supplied `steamclient.dll` and `steamclient64.dll`, the matching loader, and the included INI template in a dedicated directory inside the disposable test root. Configure only the authorized app ID, target executable, working directory, and client-library paths first. The loader must match the target process architecture when injection is involved. Leave persistence and arbitrary injection directories disabled unless a specific test requires them, and do not follow upstream's suggestion to run persistence mode as administrator.

This mode changes prefix registry state and can inject libraries into a suspended process. If it is required for legitimate testing, use a dedicated prefix, do not share that prefix with a real Steam session, do not run it as administrator, and verify restoration after interrupted runs. Upstream notes that GE-Proton under Lutris/UMU may require the per-game `PROTON_DISABLE_LSTEAMCLIENT=1` workaround for this specific mode; it is not a global Proton setting.

The native Linux analogue is `steamclient_loader.sh`. It temporarily moves `~/.steam/steam.pid` and both SDK `steamclient.so` paths, has no signal trap, and uses `eval` for loader configuration. The archive's `ldr_cmdline.EXAMPLE.txt` name also disagrees with the script's expected `ldr_cmd.txt`. Do not use untrusted loader files, do not run it concurrently with Steam, and inspect/restore `.orig` state after interruption. Upstream does not clearly specify which regular/experimental client pair should populate both loader architecture directories, so this remains an advanced, uncertain fallback rather than the normal native setup.

## Security boundary

- Verify the release tag and hashes before using binaries.
- Upstream Windows binaries use randomly generated self-signed certificates; never install those certificates.
- Keep LAN tests on trusted networks and do not expose listeners publicly.
- Do not store Steam credentials in Nix or in a shared test tree.
- Do not use the tooling to fabricate entitlements, bypass anti-cheat, access unauthorized services, or redistribute proprietary game files.

## Packaging decision

No package is added now. If repeated authorized use demonstrates a need, package only the native `generate_interfaces` helper from source and possibly `migrate_gse`. Do not create a package that automatically mutates game directories, deploys loaders, stores credentials, or globally replaces API libraries.

## Related

- [[system/gaming|Gaming Architecture]]
- [[software/non-steam-windows-gaming|Non-Steam Windows Gaming]]
- [[software/native-linux-games|Native Linux Games]]
- [[runbooks/non-steam-game|Run a Non-Steam Game]]
- [[runbooks/per-game-compatibility-layers|Per-Game Compatibility Layers]]

## Current sources

- [gbe_fork release 2026_07_19](https://github.com/Detanup01/gbe_fork/releases/tag/release-2026_07_19)
- [GitHub release API with asset digests](https://api.github.com/repos/Detanup01/gbe_fork/releases/tags/release-2026_07_19)
- [Release usage and settings](https://github.com/Detanup01/gbe_fork/blob/release-2026_07_19/post_build/README.release.md)
- [Interface generator documentation](https://github.com/Detanup01/gbe_fork/blob/release-2026_07_19/post_build/README.generate_interfaces.md)
- [Lobby helper documentation](https://github.com/Detanup01/gbe_fork/blob/release-2026_07_19/post_build/README.lobby_connect.md)
- [Experimental steamclient documentation](https://github.com/Detanup01/gbe_fork/blob/release-2026_07_19/post_build/README.experimental_steamclient.md)
- [Settings migration tool](https://github.com/Detanup01/gbe_fork/blob/release-2026_07_19/tools/migrate_gse/README.md)
- [gbe_fork companion tools](https://github.com/Detanup01/gbe_fork_tools)
- [gse_fork alternative](https://github.com/alex47exe/gse_fork)
- [Original Goldberg repository](https://gitlab.com/Mr_Goldberg/goldberg_emulator)
- [Valve GameNetworkingSockets](https://github.com/ValveSoftware/GameNetworkingSockets)
