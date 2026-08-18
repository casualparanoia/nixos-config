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

  programs.fish = {
    enable = true;
  };

  programs.eza = {
    enable = true;

    #enableNushellIntegration = true;
    enableFishIntegration = true;

    icons = "auto";
    git = true;
  };
  
  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
    enableFishIntegration = true;
  };
 
  programs.bat = {
    enable = true;

    config = {
	pager = "less -FR";
	style = "numbers,changer,header";
    };
  };

  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

}
