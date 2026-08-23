{ config, pkgsUnstable, ... }:
{
  programs.wezterm = {
    enable = true;
    package = pkgsUnstable.wezterm;
  };

  # Link your config just like you did with Alacritty
  xdg.configFile."wezterm/wezterm.lua".source =
    if config.my.dotfiles.mode == "live" then
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/nixos-config/dotfiles/wezterm/wezterm.lua"
    else
      ../dotfiles/wezterm/wezterm.lua;
}
