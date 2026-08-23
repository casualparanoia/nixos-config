{ pkgs, pkgsUnstable, ... }:

{
  home.packages = [
    # File management
    pkgsUnstable.kdePackages.dolphin

    # Archive
    pkgsUnstable.kdePackages.ark
    pkgsUnstable._7zz
    pkgsUnstable.ouch
    pkgsUnstable.unzip
    pkgsUnstable.zip

    # Documents
    pkgsUnstable.kdePackages.okular

    # Dolphin/KDE integration
    pkgsUnstable.kdePackages.kservice
    pkgsUnstable.kdePackages.qtsvg
    pkgsUnstable.kdePackages.kio
    pkgsUnstable.kdePackages.kio-fuse
    pkgsUnstable.kdePackages.kio-extras
    pkgsUnstable.qt6Packages.qtstyleplugin-kvantum
    pkgsUnstable.kdePackages.qtstyleplugin-kvantum
    pkgsUnstable.libsForQt5.qtstyleplugin-kvantum
  ];
}
