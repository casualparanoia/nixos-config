{ config, pkgsUnstable, ... }:
{
  programs.yazi = {
    enable = true;
    package = pkgsUnstable.yazi;
    
    # Optional: Enable shell integration so typing `y` wraps Yazi 
    # and changes your shell directory when you quit.
    enableNushellIntegration = true;
    enableFishIntegration = true;

  };

  # Link the entire Yazi config directory
  xdg.configFile."yazi".source =
    if config.my.dotfiles.mode == "live" then
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/nixos-config/dotfiles/yazi"
    else
      ../dotfiles/yazi;
}
