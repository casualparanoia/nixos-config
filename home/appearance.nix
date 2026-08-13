# ~/nixos-config/home/appearance.nix
{ pkgs, ... }:

{
  # Cursor
  home.pointerCursor = {
    enable = true;
    package = pkgs.kdePackages.breeze;
    name = "breeze_cursors";
    size = 24;

    gtk.enable = true;
  };

  # GTK 2/3/4
  gtk = {
    enable = true;

    # Prefer applications' native dark variants.
    colorScheme = "dark";

    font = {
	name = "Inter";
	size = 10;
    };

    iconTheme = {
	package = pkgs.kdePackages.breeze-icons;
	name = "breeze";
    };
  };

  # Qt 5/6
  qt = {
    enable = true;
    
    platformTheme.name = "qtct";
#    kvantum.enable = true;    
  };
}
