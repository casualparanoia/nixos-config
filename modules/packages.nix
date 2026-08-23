# ~/nixos-config/modules/packages.nix
{ pkgs, pkgsUnstable, ... }:

{
  environment.systemPackages = [
    pkgs.file
    pkgs.pciutils
    pkgs.usbutils
    pkgs.psmisc
    pkgs.lsof
    pkgs.lm_sensors
    pkgs.ripgrep
    pkgs.fd
  ];
}
