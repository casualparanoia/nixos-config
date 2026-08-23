# ~/nixos-config/modules/hardware-tools.nix
{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.pciutils
    pkgs.usbutils
    pkgs.lm_sensors
    pkgs.lsof
    pkgs.psmisc
  ];
}
