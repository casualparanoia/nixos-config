{ pkgs, pkgsUnstable, helium, ... }:
let 
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home.packages = [
	# Browser
	pkgs.floorp-bin
	pkgs.vivaldi
	helium.packages.${system}.helium	

	# File management 
	pkgs.kdePackages.dolphin

	# Alt

	# Archive
	pkgs.kdePackages.ark
	pkgs._7zz
	pkgsUnstable.ouch

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
