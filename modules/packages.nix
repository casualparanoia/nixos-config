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
    pkgsUnstable.nbfc-linux


    pkgs.ripgrep
    pkgs.fd
  ];
}
