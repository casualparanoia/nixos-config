{ pkgs, ... }:

{
  imports = [
    ./dotfiles.nix
    ./cli.nix
    ./shell/bash.nix
    ./shell/zsh.nix
    ./development-cli.nix
    ./helix.nix
    ./yazi.nix
  ];
  my.dotfiles.mode = "store";

  home = {
    username = "casua";
    homeDirectory = "/home/casua";
    stateVersion = "26.05";
    packages = [ pkgs.wl-clipboard ];
    sessionVariables = {
      COLORTERM = "truecolor";
    };
  };
}
