{ pkgs, pkgsUnstable, ... }:

{
  home.packages = [
    # Image
    pkgsUnstable.kdePackages.gwenview
    pkgsUnstable.imv

    # Audio
    pkgsUnstable.spotify
    pkgsUnstable.deezer-desktop
    pkgsUnstable.calibre

    # Video
    pkgsUnstable.haruna
    pkgsUnstable.mpv
    pkgsUnstable.vlc
    pkgsUnstable.mediainfo
    pkgsUnstable.ffmpeg
    pkgsUnstable.exiftool
  ];
}
