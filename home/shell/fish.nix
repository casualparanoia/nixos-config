{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    # Kept on stable Nixpkgs because pkgsUnstable.fish (Fish 4.x) removed
    # the Python manpage completion script that HM 26.05 expects, breaking builds.
  };

  programs.eza.enableFishIntegration = true;
  programs.carapace.enableFishIntegration = true;
  programs.zoxide.enableFishIntegration = true;
  programs.fzf.enableFishIntegration = true;
  programs.yazi.enableFishIntegration = true;
}
