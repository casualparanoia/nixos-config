{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
  };

  programs.eza.enableFishIntegration = true;
  programs.carapace.enableFishIntegration = true;
  programs.zoxide.enableFishIntegration = true;
  programs.fzf.enableFishIntegration = true;
  programs.yazi.enableFishIntegration = true;
}
