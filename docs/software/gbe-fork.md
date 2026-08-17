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

The current non-prerelease upstream snapshot researched for this configuration is `release-2026_07_19`. Upstream warns that this fork is incompatible with the original project and may be broken, so preserve original files and use a disposable test copy.

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
2. Run the matching `generate_interfaces` helper against that original library.
3. Move the generated `steam_interfaces.txt` into the adjacent `steam_settings/` directory.

The current release actually contains `generate_interfaces_x64` and `generate_interfaces_x86` (with `.exe` on Windows), although one upstream readme still uses older `_file` names. The prebuilt Linux helpers expect conventional ELF interpreter paths and are not clean standalone NixOS binaries. A future source-built Nix package for this narrow helper would be more reproducible than relying on `nix-ld`.

## Settings and helpers

The release includes `steam_settings.EXAMPLE`. Copy only the needed examples, remove `.EXAMPLE`, and do not enable every setting. The principal files are:

- `configs.main.ini` for emulator behavior;
- `configs.user.ini` for user/save behavior;
- `configs.app.ini` for application behavior;
- `configs.overlay.ini` for the optional experimental overlay.

Local settings override global settings. Native Linux global state defaults to `$XDG_DATA_HOME/GSE Saves/` or `~/.local/share/GSE Saves/`. A `local_save_path` is relative to the emulator library when configured relatively; it must not point into `/nix/store`.

`migrate_gse` converts older settings to the current INI model. Run migrations only on a backup. The older `generate_emu_config_old` tooling is maintained separately and can request Steam credentials; never put credentials or `my_login.txt` in this repository, a derivation, or the Nix store.

## ColdClientLoader and native loader

The current Windows fallback is under `steamclient_experimental/` and uses `steamclient_loader_x86.exe` or `steamclient_loader_x64.exe` plus `ColdClientLoader.ini`. Conceptually it keeps the application's original Steam API library and substitutes an emulated `steamclient` backend.

This mode changes prefix registry state and can inject libraries into a suspended process. If it is required for legitimate testing, use a dedicated prefix, do not share that prefix with a real Steam session, do not run it as administrator, and verify restoration after interrupted runs. Upstream notes that GE-Proton under Lutris/UMU may require the per-game `PROTON_DISABLE_LSTEAMCLIENT=1` workaround for this specific mode; it is not a global Proton setting.

The native Linux analogue is `steamclient_loader.sh`. It temporarily replaces Steam SDK client paths and uses `eval` for loader configuration. Do not use untrusted loader files, do not run it concurrently with Steam, and inspect state after interruption. It should not become a default transparent wrapper.

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

## Current sources

- [gbe_fork release 2026_07_19](https://github.com/Detanup01/gbe_fork/releases/tag/release-2026_07_19)
- [Release usage and settings](https://github.com/Detanup01/gbe_fork/blob/release-2026_07_19/post_build/README.release.md)
- [Interface generator documentation](https://github.com/Detanup01/gbe_fork/blob/release-2026_07_19/post_build/README.generate_interfaces.md)
- [Experimental steamclient documentation](https://github.com/Detanup01/gbe_fork/blob/release-2026_07_19/post_build/README.experimental_steamclient.md)
- [Settings migration tool](https://github.com/Detanup01/gbe_fork/blob/release-2026_07_19/tools/migrate_gse/README.md)
