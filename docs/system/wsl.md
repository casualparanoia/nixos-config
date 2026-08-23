---
title: NixOS-WSL Recovery & Build Environment
description: Instructions for building, managing, and maintaining the NixOS-WSL host.
tags:
  - wsl
  - maintenance
  - runbook
type: runbook
status: accepted
date: 2026-08-23
source-files:
  - hosts/wsl/default.nix
  - home/wsl.nix
---

# NixOS-WSL Recovery Environment

The NixOS-WSL distribution running on the Windows desktop provides a conservative, CLI-focused environment. It is intentionally decoupled from the complex graphical `workstation.nix` profile to ensure it remains a reliable recovery and evaluation context.

Its primary purposes are:
- Repository maintenance (Git operations)
- Fast local Nix evaluation without booting a physical machine
- Autonomous AI coding agent execution
- Debugging Nix configurations

## Updating the configuration

Because the WSL instance is treated as a normal flake output, you update it by building and booting the `wsl` configuration.

Do not use `nixos-rebuild switch`. The WSL environment requires explicit restarting to properly apply many system-level changes (like default user transitions).

1. Build and configure the new generation:
   ```bash
   sudo nixos-rebuild boot --flake .#wsl
   ```

2. Exit the WSL instance gracefully.

3. From Windows (PowerShell), terminate the distro:
   ```powershell
   wsl -t NixOS
   ```

4. Start it and exit immediately as root so WSL applies the initialization logic:
   ```powershell
   wsl -d NixOS --user root exit
   ```

5. Terminate it one more time to ensure all processes stop cleanly:
   ```powershell
   wsl -t NixOS
   ```

6. Start it normally to drop into the updated system:
   ```powershell
   wsl -d NixOS
   ```

## User migration

If the WSL instance was installed with the stock `nixos` user, the very first rebuild to the `wsl` flake output (which specifies `wsl.defaultUser = "casua";`) will transition your login to `casua`. Following the exact 6-step restart sequence above is mandatory to complete this transition safely.
