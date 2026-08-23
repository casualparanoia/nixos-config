{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    historyControl = [ "ignoredups" "ignorespace" ];
    historySize = 50000;
    historyFileSize = 100000;
  };

  programs.readline = {
    enable = true;
    variables = {
      completion-ignore-case = true;
      colored-stats = true;
      mark-symlinked-directories = true;
      show-all-if-ambiguous = true;
      menu-complete-display-prefix = true;
    };
  };

  programs.eza.enableBashIntegration = true;
  programs.carapace.enableBashIntegration = true;
  programs.zoxide.enableBashIntegration = true;
  programs.fzf.enableBashIntegration = true;
  programs.yazi.enableBashIntegration = true;
}
