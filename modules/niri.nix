# /etc/nixos/niri.nix


{ pkgs, ... }:

{
	programs.niri = {
		enable = true;

		useNautilus = false;
	};

	environment.sessionVariables = {
		NIXOS_OZONE_WL = "1";
	};

	environment.systemPackages = with pkgs; [
		# Terminal
		alacritty
		
		# Fallback for DMS locking
		swaylock
		
		# Niri's default brightness bindings
		brightnessctl

		#X11 Compatibility
		xwayland-satellite

		#Desktop session utilities
		wl-clipboard

	];
}
