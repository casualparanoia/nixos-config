{ pkgs, pkgsUnstable, ... }:

{
  home.packages = [
    # VPN
    pkgsUnstable.proton-vpn

    # Mail
    pkgsUnstable.thunderbird

    # Communication
    pkgsUnstable.signal-desktop
  ];
}
