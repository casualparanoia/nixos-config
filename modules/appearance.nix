# /etc/nixos/appearance.nix
{ pkgs, ... }:

{
	# ----------
	# FONTS
	# ----------

	fonts = {
		# Niri's graphical desktop infrastructre enables this;
		# However keeping it explicit to make this module compositor-independent.
		enableDefaultPackages = true;

		packages = with pkgs; [
			# General UI / document fonts
			inter
			ibm-plex
			noto-fonts

			# Emoji
			noto-fonts-color-emoji

			# Programming / terminal fonts
			nerd-fonts._0xproto
			nerd-fonts.jetbrains-mono

			# Icons used by bars, launchers, terminals, etc.
			nerd-fonts.symbols-only
		];

		fontconfig = {
		defaultFonts = {
			sansSerif = [
				"Inter"
				"Noto Sans"
			];
			serif = [
				"IBM Plex Serif"
				"Noto Serif"
			];
			monospace = [
				"0xProto Nerd Font Mono"
				"JetBrainsMono Nerd Font"
			];
			emoji = [
				"Noto Color Emoji"
			];
		};
		};
	};

	# -----------------
	# GTK Integration
	# -----------------

	# This defaults to services.xserver.enable, which is false on pure-Wayland Niri system.
	# Enabling it explicitly
	gtk.iconCache.enable = true;
	
	environment.systemPackages = with pkgs; [
		# Standard/fallback GTK icon set.
		adwaita-icon-theme
		# Compatibility themes for older GTK applications
		gnome-themes-extra
	];

	# -------------------
	# Qt Integration
	# -------------------

	# Makes Qt plugin discovery work correctly for applications installed throught the system profile
	qt.enable = true;
}

