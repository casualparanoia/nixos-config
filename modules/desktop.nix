# /etc/nixos/desktop.nix
{ pkgs, lib, ... }:

{
	# ------------------------------
	# AUDIO: Pipewire + WirePlumber
	# ------------------------------

	security.rtkit.enable = true; # Allows pipewire to request real-tile scheduling.
	
	services.pipewire = {
		enable = true;

		# Native ALSA applications : Pipewire
		alsa = {
			enable = true;

			# For 32-bit applications
			support32Bit = true;
		};

		#PulseAudio application : Pipewire compatibility server.
		pulse.enable = true;

		#WirePlumber as Pipewire session and policy manager.
		wireplumber.enable = true;
	};

	# ------------------------------
	# BLUETOOTH
	# ------------------------------

	hardware.bluetooth = {
		enable = true;

		powerOnBoot = true;
	};

	# GUI Bluetooth Manager for a WN-only environment
	services.blueman.enable = true;

	# -----------------------------------
	# DESKTOP Hardware/Device Services
	# -----------------------------------

	# Exposes battery and power-device information over D-bus
	# Bars/Shells and other desktop programs can consume this later.
	#services.upower.enable = true;

	# Gives desktop/user applications controlled access to removable storage
	services.udisks2.enable = true;

	# ------------------------------------------------
	# Basic desktop control/diagnostic applications
	# ------------------------------------------------

	environment.systemPackages = with pkgs; [
		# Pipewire/PulseAudio GUI mixer and device/profile selector
		pavucontrol

		# MPRIS media-player control
		playerctl

		# Utilities such as xdg-open, xdg-utils already installed via services.graphical-desktop.enable
		
	];

	# -----------------------------------
	# KDE / Dolphin integration
	# -----------------------------------

	# Dolphin/KService expects a generic applications.menu outside Plasma.
environment.etc."xdg/menus/applications.menu".text = ''
  <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
    "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">

  <Menu>
    <Name>Applications</Name>

    <DefaultAppDirs/>

    <Include>
      <All/>
    </Include>
  </Menu>
'';


  programs.nix-ld = {
    enable = true;

    libraries = [
      (lib.getLib pkgs.openssl)
      pkgs.stdenv.cc.cc.lib
    ];
  };
programs.thunar = {
  enable = true;

  plugins = with pkgs; [
    thunar-archive-plugin
    thunar-volman
  ];
};

services.tumbler.enable = true;
services.gvfs.enable = true;


}
