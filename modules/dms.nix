# /etc/nixos/dms.nix
{ pkgs, ... }:

let
	# Rofi
	rofiWithPlugins = pkgs.rofi.override {
		plugins = with pkgs; [
			rofi-calc
			rofi-emoji
		];
	};
in
{
	# ----------------------------
	# DankMaterialShell
	# ----------------------------

	programs.dms-shell = {
		enable = true;

		systemd = {
			enable = true;
			restartIfChanged = true;
		};
		
		# Monitoring
		enableSystemMonitoring = true;
		
		# Temprorary
		enableVPN = false;
		
		# Temprorary?
		enableDynamicTheming = false;
		
		# Optional - Temprorary
		enableAudioWavelength = false;
		enableCalendarEvents = false;
	};

	# --------
	# Rofi
	# --------

	environment.systemPackages = [
		rofiWithPlugins
	];

	# Temporary system-wide Rofi configuration.
	environment.etc."xdg/rofi/config.rasi".text = ''
		configuration {
			modes: [ combi, calc, drun, window, emoji ];
			combi-modes: [ window, drun, run, calc, filebrowser, recursivebrowser, keys, emoji ];
			show-icons: true;
		
			
			terminal: "alacritty";

			drun-display-format: "{icon} {name}";

			sidebar-mode: true;
			disable-history: false;
			
			calc{
				display-name: " 󰃬 Calc ";
			}
			emoji{
				display-name: "  Emoji ";
			}
			drun{
				display-name: " 󰀻 Apps ";
			}
			run{
				display-name: "  Run ";
			}
			window{
				display-name: "  Window ";
			}
			filebrowser{
				display-name: "  Files ";
			}
			recursivebrowser {
				display-name: "  Find ";
			}
			keys {
				display-name: "  Keys";
			}
			combi{
				display-name: "  All ";
			}
		}
		
		@theme "DarkBlue"
	'';
}

