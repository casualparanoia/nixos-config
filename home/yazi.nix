{ config, pkgsUnstable, ... }:
{
  programs.yazi = {
    enable = true;
    package = pkgsUnstable.yazi;
    
    # Shell integrations are managed in home/shell/*.nix

  };

  # Link the entire Yazi config directory
  xdg.configFile."yazi".source =
    if config.my.dotfiles.mode == "live" then
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/nixos-config/dotfiles/yazi"
    else
      ../dotfiles/yazi;
}
