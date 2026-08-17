---
title: Per-Game Compatibility Layers
description: Run authorized Windows DLL and native Linux shared-library layers from isolated writable game copies.
tags:
  - gaming
  - runbook
  - wine
  - elf
  - interoperability
type: runbook
status: active
date: 2026-08-17
---

# Per-Game Compatibility Layers

This runbook covers already-prepared, authorized per-game replacement or interoperability layers. These files sit above a working UMU/Lutris Windows runtime or native Linux/`steam-run` runtime. It does not cover obtaining modified game files, removing DRM, changing ownership checks, or bypassing anti-cheat.

## Core rules

- Keep the canonical installation and an original-file hash outside the working tree.
- Modify only a disposable, user-owned copy.
- Match every DLL or `.so` to the architecture of the process that loads it.
- Keep Wine prefixes, DLL overrides, `LD_LIBRARY_PATH`, and `LD_PRELOAD` per game.
- Prove the base game/runtime works before adding a replacement layer.
- Never modify a package under `/nix/store`.

## Prepare a test copy

```bash
source="$HOME/Games/authorized-source"
root="$HOME/Games/authorized-test"
baseline="$root/baseline"
game="$root/work"

mkdir -p -- "$baseline" "$game"
cp -a --no-preserve=ownership --reflink=auto -- "$source/." "$baseline/"
cp -a --no-preserve=ownership --reflink=auto -- "$baseline/." "$game/"
chmod -R a-w -- "$baseline"
chmod -R u+rwX,go-w -- "$game"
```

Hash the original and replacement files before changing the working copy:

```bash
sha256sum -- \
  "$baseline/path/to/original-library" \
  "/path/to/replacement-library"
```

If `readlink -f` shows that a copied file still resolves into `/nix/store`, replace that symlink inside the working tree rather than changing the store target.

## Windows PE architecture

Inspect the actual game executable and each DLL it will load:

```bash
exe="$game/bin/Game.exe"
dll="$game/bin/replacement.dll"

file -- "$exe" "$dll"
objdump -f -- "$exe"
objdump -f -- "$dll"
objdump -p -- "$exe" | rg 'DLL Name'
```

Interpretation:

| Result | Architecture |
|---|---|
| `PE32 ... Intel 80386` or `pei-i386` | 32-bit x86 |
| `PE32+ ... x86-64` or `pei-x86-64` | 64-bit x86-64 |

A 64-bit process cannot load a 32-bit DLL and vice versa. Inspect helper executables separately: a 64-bit launcher can start a 32-bit game. Static imports shown by `objdump` do not include every library loaded later with `LoadLibrary`.

## Windows DLL placement

Place a game-local DLL beside the executable that imports it, not merely at the installation root. If `Launcher.exe` starts `bin64/Game.exe`, a layer loaded by the game normally belongs beside `bin64/Game.exe`.

Preserve any documented renamed-original or subdirectory layout. Do not place replacement files in Proton, Wine, UMU, Lutris, or Nix store directories. `WINEDLLPATH` is not a game DLL path; Wine uses it for Wine builtins and Winelib applications.

## Test through UMU

Start without a DLL override so the log establishes normal load behavior:

```bash
game="$HOME/Games/authorized-test/work"
prefix="$HOME/Games/prefixes/authorized-test"
logs="$HOME/Games/logs/authorized-test"
exe="$game/bin/Game.exe"

mkdir -p -- "$prefix" "$logs"

env -C "$game" \
  WINEPREFIX="$prefix" \
  GAMEID=0 \
  UMU_LOG=debug \
  PROTON_LOG=1 \
  PROTON_LOG_DIR="$logs" \
  umu-run "$exe"
```

This keeps working directory, prefix, runtime logs, and game files explicit. The prefix isolates registry and Wine state; it is not a security sandbox and Windows programs can still access files visible to the Unix user.

Search the resulting Proton log for load decisions:

```bash
rg -i 'loaddll|err:module|not found|wrong architecture|bad exe' "$logs"
```

## Wine DLL overrides

Wine distinguishes native Windows DLLs from its builtin implementations:

| Override | Behavior |
|---|---|
| `n` | Native Windows DLL only |
| `b` | Wine builtin only |
| `n,b` | Native first, builtin fallback |
| `b,n` | Builtin first, native fallback |
| Empty value | Disable the named DLL |

A correctly placed non-system DLL often loads without an override. Add `WINEDLLOVERRIDES` only when the log proves Wine selected a builtin or the authorized layer explicitly requires one. For example:

```bash
env -C "$game" \
  WINEPREFIX="$prefix" \
  GAMEID=0 \
  WINEDLLOVERRIDES='dinput8=n,b' \
  PROTON_LOG=1 \
  PROTON_LOG_DIR="$logs" \
  umu-run "$exe"
```

Use the actual DLL basename without `.dll`. Avoid broad wildcard overrides, global session variables, core DLL overrides such as `ntdll`/`kernel32`, and two providers for the same basename. A game-local `dxgi.dll`, for example, can conflict with the runner's DXVK `dxgi.dll`.

Steam API replacement DLLs normally have no competing Wine builtin and should be tested without an override first.

## Configure the same layer in Lutris

For a locally installed Windows game:

1. Add a locally installed game and select the Wine runner.
2. Set the executable to the actual game `.exe`.
3. Set its working directory explicitly to the executable directory.
4. Assign one unique writable Wine prefix.
5. Select one runner version and keep it fixed during diagnosis.
6. Add required DLL overrides under advanced **Runner options -> DLL overrides**.

Lutris' structured DLL override field is preferable to a raw global variable because Lutris merges it with runner-managed DXVK/VKD3D settings. When Lutris uses Proton/GE-Proton, version 0.5.22 launches it through UMU.

Use `lutris -d` and the per-game log button for diagnostics. Keep overrides in the game entry, not Home Manager session variables.

## Native Linux architecture

Inspect the executable and replacement library:

```bash
game="$HOME/Games/authorized-test/work"
exe="$game/bin/Game.x86_64"
so="$game/replacements/liblayer.so"

file -- "$exe" "$so"
readelf -hW "$exe" | rg 'Class:|Machine:|Type:'
readelf -hW "$so" | rg 'Class:|Machine:|Type:'
readelf -lW "$exe" | rg 'Requesting program interpreter'
readelf -dW "$exe" | rg 'NEEDED|RPATH|RUNPATH'
readelf -dW "$so" | rg 'NEEDED|SONAME|RPATH|RUNPATH'
patchelf --print-interpreter "$exe"
patchelf --print-needed "$exe"
patchelf --print-rpath "$exe"
patchelf --print-soname "$so"
```

An ELF64 x86-64 process needs ELF64 x86-64 libraries. A `.so` sitting beside an executable is not automatically selected unless the application uses `dlopen`, a runpath contains `$ORIGIN`, or a per-launch search path exposes it.

For a normal `DT_NEEDED` library name, glibc considers `DT_RPATH` when no `DT_RUNPATH` exists, then `LD_LIBRARY_PATH`, then `DT_RUNPATH`, the loader cache, and default paths. `DT_RUNPATH` applies only to direct dependencies. `$ORIGIN` expands to the directory containing the executable or shared object whose dynamic metadata contains it.

## Native per-launch search path

Use `LD_LIBRARY_PATH` when the executable already requests the library name and the replacement directory only needs to be searched first:

```bash
replacements="$game/replacements"

env -C "$game" \
  LD_LIBRARY_PATH="$replacements:$game/lib" \
  "$exe"
```

Use `LD_PRELOAD` only when the layer is explicitly an interposer intended to load before normal dependencies:

```bash
env -C "$game" \
  LD_PRELOAD="$replacements/liblayer.so" \
  "$exe"
```

`LD_PRELOAD` is inherited by child processes and a single-architecture preload can break a helper of another architecture. It is not a general fix for unresolved dependencies or incompatible symbol versions.

## Native loader diagnostics

```bash
logs="$HOME/Games/logs/authorized-native"
mkdir -p -- "$logs"

env -C "$game" \
  LD_DEBUG=libs,files \
  LD_DEBUG_OUTPUT="$logs/ld-debug" \
  "$exe"
```

Search the generated `ld-debug.PID` files:

```bash
rg -i 'search path|trying file|not found|error|liblayer' "$logs"
```

If the bare game expects a conventional Linux userspace, add the existing Steam FHS runtime without changing the per-game paths:

```bash
steam-run env -C "$game" \
  LD_LIBRARY_PATH="$replacements:$game/lib" \
  "$exe"
```

Use `steam-run` for ad hoc compatibility. Package a stable long-term setup in Nix so the interpreter, dependencies, and runpaths become reproducible. Manual `patchelf` experiments belong only in the disposable working copy; never embed an untracked current `/nix/store/...` path into a long-lived external file because garbage collection cannot see that reference.

## Restore and compare

When a test fails:

1. Save the exact command, runner version, logs, prefix path, and modified-file hashes.
2. Remove all MangoHud/GameMode/Gamescope layers and retry the compatibility layer alone.
3. Compare the working file against the read-only baseline.
4. Re-create the working tree and prefix before changing architecture, runner family, or replacement implementation.
5. Check save locations before deleting the prefix or emulator-local state.

## Related

- [[software/gbe-fork|gbe_fork]]
- [[runbooks/non-steam-game|Run a Non-Steam Game]]
- [[software/non-steam-windows-gaming|Non-Steam Windows Gaming]]
- [[software/native-linux-games|Native Linux Games]]
- [[runbooks/gaming-diagnostics|Gaming Diagnostics]]
- [[runbooks/binary-packaging|Binary Packaging Runbook]]

## Current sources

- [Wine runtime environment and DLL overrides](https://github.com/wine-mirror/wine/blob/master/tools/wine/wine.man.in)
- [Microsoft DLL search order](https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-search-order)
- [GNU C Library dynamic linker](https://sourceware.org/glibc/manual/latest/html_node/Dynamic-Linker.html)
- [GNU binutils readelf](https://sourceware.org/binutils/docs/binutils/readelf.html)
- [patchelf manual](https://github.com/NixOS/patchelf/blob/master/patchelf.1)
- [Nix store immutability](https://nix.dev/manual/nix/2.34/store/store-object#immutability)
