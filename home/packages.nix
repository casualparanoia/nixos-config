{
  pkgs,
  pkgsUnstable,
  helium,
  antigravity-nix,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home.packages = [
    # Browser
    pkgs.floorp-bin
    pkgs.vivaldi
    helium.packages.${system}.helium

    pkgsUnstable.adguardian

    # File management
    pkgs.kdePackages.dolphin

    # AI
    pkgsUnstable.codex
    pkgsUnstable.opencode-desktop
    antigravity-nix.packages.${system}.google-antigravity-ide
    antigravity-nix.packages.${system}.google-antigravity

    # Archive
    pkgs.kdePackages.ark
    pkgs._7zz
    pkgsUnstable.ouch
    pkgs.unzip
    pkgs.zip

    # Document / media
    pkgs.kdePackages.okular
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

    # Editor
    pkgs.kdePackages.kate

    # VPN
    pkgs.proton-vpn

    # Mail
    pkgs.thunderbird

    # Download Manager
    #pkgs.persepolis
    pkgsUnstable.motrix-next

    # Clipboard
    #pkgs.copyq

    # Communication
    pkgs.signal-desktop

    # Dolphin/KDE integration
    pkgs.kdePackages.kservice
    pkgs.kdePackages.qtsvg
    pkgs.kdePackages.kio
    pkgs.kdePackages.kio-fuse
    pkgs.kdePackages.kio-extras
    pkgs.qt6Packages.qtstyleplugin-kvantum
    pkgs.kdePackages.qtstyleplugin-kvantum
    pkgs.libsForQt5.qtstyleplugin-kvantum

    # ----- General CLI ----------

    pkgs.jq
    pkgs.yq-go
    pkgs.sd
    pkgs.patchelf

    pkgs.dust
    pkgsUnstable.dua
    pkgs.duf
    pkgs.bottom
    pkgs.procs

    pkgs.hyperfine
    pkgs.fastfetch
    pkgs.tealdeer
    pkgs.tokei

    pkgs.libqalculate

    pkgs.ffmpeg
    pkgs.exiftool

    pkgs.gh

    # Rust coreutils
    pkgs.uutils-coreutils

    # ----------- Version Control ------------
    pkgs.git
    pkgs.delta
    pkgs.lazygit

    pkgsUnstable.jujutsu
    pkgsUnstable.lazyjj

  ];
}
