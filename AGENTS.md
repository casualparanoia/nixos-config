
# Repository Instructions

This repository is the declarative NixOS/Home Manager configuration for
multiple personal machines.

Prefer correctness, explicitness, and preserving known-working hardware
behavior over abstraction.

## Architecture

- `hosts/` contains physical-machine-specific configuration.
- `profiles/` composes reusable machine roles such as the workstation.
- `modules/` contains reusable NixOS capabilities.
- `home/` contains reusable Home Manager capabilities.
- `packages/` contains local package definitions.
- `shells/` contains development shells.
- `scripts/` contains operational/bootstrap tooling.
- `docs/` is the system of record for architecture, hardware quirks,
  operational procedures, and design decisions.

Read `docs/system/architecture.md` before making architectural changes.

## Hosts

### GL702ZC

`hosts/gl702zc/` describes the existing ASUS ROG GL702ZC installation.

Its hardware workarounds are deliberate and known to be machine-specific.
Do not generalize them into shared modules without explicit justification.

Important areas include:

- NBFC / EC fan control
- AMDGPU hwmon mapping
- the `amdgpu_bl1` backlight workaround
- laptop-specific keyboard/udev handling
- laptop-specific TPM/kernel/power workarounds

The existing `hardware-configuration.nix` remains authoritative for this
host for now.

Do not convert the GL702ZC to Facter or Disko incidentally.

### Desktop

`hosts/desktop/` describes the new desktop.

The desktop uses:

- Disko for intended disk layout
- NixOS Facter for captured hardware discovery

Do not invent disk IDs, UUIDs, hardware facts, PCI IDs, or Facter data.

`facter.json` is generated explicitly, not during normal rebuilds.

## Disk and installation safety

Never run destructive Disko operations unless the user explicitly requests
installation/provisioning.

Normal:

    nixos-rebuild switch

must never repartition or format disks.

Do not put destructive provisioning logic in NixOS activation scripts.

The desktop contains a separate Windows disk. Never infer a target disk from
`/dev/nvme0n1`, `/dev/nvme1n1`, or enumeration order.

Installation must use an explicitly supplied stable `/dev/disk/by-id/...`
whole-disk path and verify it before destruction.

Do not execute `scripts/system install` during routine validation.

## Facter and public-repository safety

Do not regenerate Facter during normal rebuilds.

Before committing a generated `hosts/desktop/facter.json` to a public
repository, review it for persistent identifiers including serial numbers,
UUIDs, WWNs, MAC addresses, and asset tags.

Do not add secrets, password hashes, private keys, authentication tokens,
or generated credentials to the repository.

## Nix architecture

Keep imports explicit.

Do not introduce flake-parts, `.mod.nix` auto-discovery, Hjem, custom flake
registries, or similar framework machinery unless explicitly requested.

A small abstraction is justified only when it removes real duplication.

## Package policy

- `pkgs` = stable nixos-26.05 package set
- `pkgsUnstable` = nixos-unstable
- For the operating system: `stable = normal`
- For explicitly selected user packages: `unstable = normal`, `stable = exception`
- NixOS remains stable.
- Home Manager remains release-26.05.
- Ordinary explicitly selected applications/tools normally use `pkgsUnstable`.
- Stable explicit application selections are exceptions.
- System/module defaults remain stable unless intentionally overridden.

Preserve the stable/unstable package-source policy. Do not silently migrate
packages between package sets during unrelated changes.

Preserve `my.dotfiles.mode` semantics.

## Package organization

Prefer capability/domain modules over catch-all package lists.

Do not create one module per application.

Machine-specific packages belong to the relevant host, not common package
sets.

## Editing hardware workarounds

Read the corresponding file under `docs/hardware/` before changing a
hardware workaround.

Preserve comments that explain observed hardware behavior and empirical
constants.

Do not replace measured/workaround values with guessed "cleaner" values.

## Validation

Prefer non-activating validation first.

When Nix is available:

    nix flake check
    sudo nixos-rebuild build --flake .#gl702zc

During the migration, also verify:

    sudo nixos-rebuild build --flake .#nixos

Do not run `nixos-rebuild switch` unless explicitly requested.

The desktop should only be treated as fully evaluable once its required real
hardware artifacts exist.

Never claim a Nix build/check succeeded when Nix was unavailable.

## Version control

Git is the repository's version-control system.

Inspection commands such as `git status`, `git diff`, and `git grep` are
fine.

Do not commit, push, force-push, rewrite history, create public repositories,
or publish generated hardware data unless explicitly requested.

Before presenting completed changes:

- inspect `git status`
- inspect the relevant diff
- check for stale paths after file moves
- report validation actually performed

Do not confuse staged content with newer unstaged modifications.

## Generated and lock files

- Never hand-edit `flake.lock`; update it using Nix tooling.
- Treat generated hardware data such as `facter.json` separately from ordinary source.
- Do not assume generated files are safe to publish merely because they contain no credentials.

## File moves

When moving or deleting configuration files, search `docs/`, `README.md`, and
the rest of the tracked repository for stale path references before considering
the change complete.
