{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./hardware.nix
    ./fan-control.nix
    ./backlight.nix
    ../../modules/crash-monitor.nix

    # Shared workstation profile
    ../../profiles/workstation.nix
  ];

  networking.hostName = "gl702zc";
}
