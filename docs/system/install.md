# Physical Desktop Installation Runbook

This document describes the procedure for bootstrapping the NixOS configuration on the physical desktop.

## Preflight

1. **Boot Environment**:
   - Boot the NixOS live ISO in UEFI mode.
   - Verify UEFI mode is active:
     ```bash
     test -d /sys/firmware/efi/efivars && echo "UEFI boot confirmed" || echo "ERROR: Booted in Legacy BIOS mode"
     ```
   - Ensure Secure Boot is temporarily disabled in UEFI firmware.
   - **Warning (BitLocker)**: If the existing Windows disk has BitLocker or Device Encryption enabled, ensure the 48-digit recovery key is accessible before altering boot devices or UEFI settings.

2. **Verify Hardware & Storage**:
   - Verify network connectivity (`ping -c 3 nixos.org` or `curl -I https://nixos.org`).
   - Confirm the Windows Boot Manager entry exists in NVRAM:
     ```bash
     efibootmgr -v
     ```
   - Inspect physical devices, serials, and existing partitions:
     ```bash
     lsblk -o NAME,PATH,SIZE,MODEL,SERIAL,TYPE,FSTYPE,MOUNTPOINTS
     ```
   - Match the target drive's serial to its stable `/dev/disk/by-id/` path:
     ```bash
     ls -l /dev/disk/by-id/
     ```
     *Do not proceed with volatile names like `/dev/nvme0n1` or `/dev/sda`.*

3. **Prepare the Repository**:
   - Clone or copy this repository into the live environment:
     ```bash
     git clone <repo-url> ~/nixos-config
     cd ~/nixos-config
     ```
   - Inspect the Git working tree to verify the target commit:
     ```bash
     git status --short
     git log -n 1 --oneline
     ```

## Installation

The installer securely prepares the disk, evaluates the system (including dynamic hardware facts), and persists the installation source.

1. **Run Installer**:
   From the repository root, run:
   ```bash
   TARGET_DISK="/dev/disk/by-id/nvme-..." ./scripts/system install desktop
   ```
   *Note: The script requests `sudo` internally where required. Do not run the script itself as root.*

2. **Destructive Warning & Confirmation**:
   - The script will display the resolved disk hierarchy and source state.
   - It will ask for explicit confirmation requiring you to type the resolved device name.
   - *Note*: Windows remains on its separate physical disk. The installer only formats the explicitly supplied disk. The Windows EFI System Partition (ESP) is not part of this layout. NixOS has its own ESP.

3. **Password Generation**:
   - Provide the initial password for `casua`. It will be securely hashed with `mkpasswd` and copied.

4. **Reboot**:
   - Once `disko-install` completes, reboot.
   - *Boot Note*: UEFI NVRAM may prioritize the new NixOS bootloader. `systemd-boot` may not automatically detect Windows since Windows uses a separate ESP. If so, use the motherboard firmware boot menu (e.g. F11/F12) to select Windows when needed.

## First Boot & Post-Install

1. **Verify Checkout & Facter**:
   - Log in through the TTY.
   - Verify `/home/casua/nixos-config` exists and is owned by `casua`.
   - Verify `hosts/desktop/facter.json` was persisted correctly. **Do not blindly stage or commit it**.

2. **Network & DNS**:
   - Note: DNS resolution points to `127.0.0.1` due to AdGuard Home.
   - Start Niri using your normal session command.
   - Open a browser (by IP if necessary, e.g. `http://127.0.0.1:3000`) and complete the AdGuard first-run local setup. Normal DNS will work after this.

3. **Verify Functionality**:
   - Verify the graphics stack and Vulkan rendering.
   - Verify audio output (`wpctl status`).
   - Run `systemctl --failed` and `systemctl --user --failed` to ensure all services started correctly.
   - Verify Windows still boots via the firmware menu.
