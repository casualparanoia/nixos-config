---
title: Run a Non-Steam Game
description: Procedures for standalone Windows installers, executables, and native Linux game binaries.
tags:
  - gaming
  - runbook
  - umu
  - wine
  - linux
type: runbook
status: active
date: 2026-08-17
source-files:
  - home/gaming.nix
---

# Run a Non-Steam Game

Start by identifying the executable format and distribution source. Do not choose Wine merely because a download is not from Steam.

```bash
file "/path/to/download"
```

## Choose the owner

| Download | Use |
|---|---|
| GOG, Epic, or Amazon library item | Heroic |
| Windows `.exe` with a simple installer or portable directory | UMU |
| Windows title with a multi-stage/community installer or special runner needs | Lutris |
| Windows application needing a named isolated environment | Bottles |
| Native Linux ELF binary | Nix package or `steam-run` |
| Native game already in Nixpkgs | Nix package |
| Authorized game directory with replacement DLL/`.so` files | Base runtime above plus [[runbooks/per-game-compatibility-layers|Per-Game Compatibility Layers]] |

One manager owns the game and prefix. Do not test the same writable prefix from several managers.

## Prepare writable directories

Use a user-owned game directory and a separate prefix when practical. The following is an example, not a mandatory global layout:

```text
~/Games/example/                 game files
~/Games/prefixes/example/        Windows compatibility prefix
~/Games/installers/example/      retained installer, optional
```

Never run an installer as root. Never install mutable game data into `/nix/store`.

## Already-prepared per-game layer

An authorized game directory that already contains or needs game-local DLL/`.so` replacements uses the same runtime selection as an unmodified game:

- Windows executable: UMU for a direct setup or Lutris for a managed/complex setup.
- Native Linux executable: direct Nix-compatible launch, `steam-run`, or a title-specific package.
- `gbe_fork`: the appropriate runtime plus the per-game API library and `steam_settings/`.

Do not copy the layer globally or into a runner installation. Use [[runbooks/per-game-compatibility-layers|Per-Game Compatibility Layers]] to preserve originals, inspect architecture, control DLL/SO loading, collect logs, and roll back cleanly.

## Standalone Windows game with UMU

For a portable executable:

```bash
WINEPREFIX="$HOME/Games/prefixes/example" \
  GAMEID=0 \
  umu-run "$HOME/Games/example/Game.exe"
```

For an installer, run the installer and final executable with the same prefix:

```bash
WINEPREFIX="$HOME/Games/prefixes/example" \
  GAMEID=0 \
  umu-run "$HOME/Games/installers/example/setup.exe"
```

Then locate the installed executable inside the prefix or the install directory selected in the installer and launch it with the same `WINEPREFIX`.

For one debug run:

```bash
UMU_LOG=debug \
  WINEPREFIX="$HOME/Games/prefixes/example" \
  GAMEID=0 \
  umu-run "$HOME/Games/example/Game.exe"
```

If the game exists in the [UMU database](https://github.com/Open-Wine-Components/umu-database), use its documented ID to obtain relevant protonfixes. Do not guess another title's ID.

UMU defaults to UMU-Proton. Change `PROTONPATH` only to test a specific known compatibility need. Back up the prefix and saves before changing runner families.

## Store game with Heroic

1. Sign into the required store in Heroic.
2. Select a user-writable library directory.
3. Install and launch once with Heroic's default UMU/runner choice.
4. Change runner, prefix, or environment settings only if the default fails.
5. Use the game's Heroic log view for the first failure report.

Do not redirect Heroic to a Lutris or Bottles prefix. Cloud-save support varies by store and game; verify a local save exists before destructive recovery.

## Complex game with Lutris

1. Prefer a maintained Lutris installer for the exact game/store version.
2. Review the install script and target directories before running it.
3. Keep the generated Lutris game entry as the owner of its prefix and runner.
4. Use per-game runner/system options rather than global environment overrides.
5. Restart with `lutris -d` to capture client and game-launch diagnostics.

Do not start Lutris under `steam-run`; its Nix package is already a multilib FHS environment.

## Optional isolated environment with Bottles

Bottles is not installed by default. First complete the permission review and declarative Flatpak step in [[software/non-steam-windows-gaming|Non-Steam Windows Gaming]]. Then:

1. Create one bottle for the application or closely related application set.
2. Choose a gaming or application environment based on the workload.
3. Install and run the executable from inside that bottle.
4. Grant only the host filesystem paths the Flatpak actually needs.
5. Export or back up important bottle state before runner changes.

Inspect current sandbox access with:

```bash
flatpak info --show-permissions com.usebottles.bottles
```

Do not reuse Steam, Heroic, Lutris, or UMU prefixes as Bottles bottles.

## Standalone native Linux game

Try the existing Steam runtime first for a conventional foreign binary:

```bash
cd "$HOME/Games/example"
steam-run ./example-game
```

If it fails, capture the actual missing interpreter/library behavior rather than globally adding libraries:

```bash
steam-run env LD_DEBUG=libs ./example-game
```

Package the title in Nix when its dependencies are stable enough to describe. See [[software/native-linux-games|Native Linux Games]] and [[runbooks/binary-packaging|Binary Packaging Runbook]].

## Add instrumentation one layer at a time

After the base game launches, test GameMode and MangoHud:

```bash
mangohud gamemoderun ./native-game
```

For Steam launch options:

```text
mangohud gamemoderun %command%
```

If behavior changes, remove both tools and re-add one at a time. Instrumentation is not part of the minimum compatibility path.

## Back up before recovery

Identify whether saves live in the game directory, prefix, launcher-specific state, or cloud synchronization. Back up the smallest complete set before:

- changing Proton/Wine runner families;
- running Winetricks/Protontricks verbs;
- deleting or recreating a prefix;
- moving a launcher-owned game between managers;
- adding per-game `gbe_fork` test files.

## Security checklist

- Verify the source and checksum/signature when the publisher provides one.
- Do not run launchers, games, or installers as root.
- Do not weaken device permissions or make game directories world-writable.
- Keep each untrusted executable's filesystem visibility as narrow as practical.
- Remember that Wine and Proton are compatibility layers, not malware sandboxes.

## Related

- [[system/gaming|Gaming Architecture]]
- [[software/non-steam-windows-gaming|Non-Steam Windows Gaming]]
- [[software/native-linux-games|Native Linux Games]]
- [[software/gbe-fork|gbe_fork]]
- [[runbooks/per-game-compatibility-layers|Per-Game Compatibility Layers]]
- [[runbooks/gaming-diagnostics|Gaming Diagnostics]]
