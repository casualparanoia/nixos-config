{ pkgs, pkgsUnstable, ... }:

{
  home.packages = [
    # File management
    pkgs.kdePackages.dolphin

    # Archive
    pkgs.kdePackages.ark
    pkgs._7zz
    pkgsUnstable.ouch
    pkgs.unzip
    pkgs.zip

    # Documents
    pkgs.kdePackages.okular

    # Dolphin/KDE integration
    pkgs.kdePackages.kservice
    pkgs.kdePackages.qtsvg
    pkgs.kdePackages.kio
    pkgs.kdePackages.kio-fuse
    pkgs.kdePackages.kio-extras
    pkgs.qt6Packages.qtstyleplugin-kvantum
    pkgs.kdePackages.qtstyleplugin-kvantum
    pkgs.libsForQt5.qtstyleplugin-kvantum
  ];
}
