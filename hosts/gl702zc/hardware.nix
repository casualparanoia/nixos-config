{ pkgs, pkgsUnstable, ... }:

{
  # 1. Power Profiles Daemon
  services.power-profiles-daemon.enable = true;

  hardware.rasdaemon.enable = true;

  # 2. AMD Ryzen CPU Power Driver & laptop specific kernel parameters
  boot.kernelParams = [
    "amd_pstate=active"
    "acpi_backlight=native"
    #"i8042.nokbd" #DISABLE INTERNAL KEYBOARD
    #TPM DISABLE
    "modprobe.blacklist=tpm_crb,tpm_tis,tpm_tis_core,tpm"
    #nvme test
    #	"nvme_core.default_ps_max_latency_us=0"
    "amdgpu.gpu_recovery=1"
  ];

  # option to support certain USB WLAN and WWAN adapters.
  hardware.usb-modeswitch.enable = true;

  # TPM DISABLE workaround for this laptop
  systemd.tpm2.enable = false;
  boot.initrd.systemd.tpm2.enable = false;

  # DISABLE INTERNAL KEYBOARD for this laptop
  services.udev.extraRules = ''
    ACTION=="add|change",ATTRS{name}=="Asus Keyboard", ENV{LIBINPUT_IGNORE_DEVICE}="1",ATTR{inhibited}="1"
  '';
}
