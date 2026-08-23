{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  programs.eza.enableBashIntegration = true;
  programs.carapace.enableBashIntegration = true;
  programs.zoxide.enableBashIntegration = true;
  programs.fzf.enableBashIntegration = true;
  programs.yazi.enableBashIntegration = true;
}
