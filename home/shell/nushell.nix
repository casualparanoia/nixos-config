{ pkgs, pkgsUnstable, ... }:

{
  programs.nushell = {
    enable = true;
    package = pkgsUnstable.nushell;

    settings = {
      show_banner = false;

      history = {
        file_format = "sqlite";
        sync_on_enter = true;
        isolation = false;
      };
    };
  };

  # programs.eza.enableNushellIntegration = true; # currently commented in cli.nix
  programs.carapace.enableNushellIntegration = true;
  programs.zoxide.enableNushellIntegration = true;
  programs.yazi.enableNushellIntegration = true;
}
