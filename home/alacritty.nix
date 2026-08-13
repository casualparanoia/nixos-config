{config, ...}:
{
  xdg.configFile."alacritty/alacritty.toml".source = 
    if config.my.dotfiles.mode == "live" then
	config.lib.file.mkOutOfStoreSymlink
	  "${config.home.homeDirectory}/nixos-config/dotfiles/alacritty/alacritty.toml"
    else
	../dotfiles/alacritty/alacritty.toml;
}
