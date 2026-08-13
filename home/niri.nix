{config, ...}:
{
  xdg.configFile."niri/config.kdl".source = 
    if config.my.dotfiles.mode == "live" then
	config.lib.file.mkOutOfStoreSymlink
	  "${config.home.homeDirectory}/nixos-config/dotfiles/niri/config.kdl"
    else
	.../dotfiles/niri/config.kdl;
}
