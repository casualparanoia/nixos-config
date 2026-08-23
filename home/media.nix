{ pkgs, pkgsUnstable, ... }:

{
  home.packages = [
    # Media and image viewers
    pkgs.kdePackages.gwenview
    pkgs.imv
    pkgsUnstable.spotify
    pkgs.deezer-desktop
    pkgsUnstable.calibre

    # Video
    pkgsUnstable.haruna
    pkgs.mpv
    pkgs.vlc
    pkgs.mediainfo
    pkgs.ffmpeg
    pkgs.exiftool
  ];
}
