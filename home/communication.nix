{ pkgs, ... }:

{
  home.packages = [
    # VPN
    pkgs.proton-vpn

    # Mail
    pkgs.thunderbird

    # Communication
    pkgs.signal-desktop
  ];
}
