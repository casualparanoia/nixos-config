{ ... }:

{
  imports = [
    ./appearance.nix
    ./packages.nix
    ./dotfiles.nix
    ./niri.nix
    ./mime.nix
    ./cli.nix
    ./desktop.nix
    ./alacritty.nix
    ./screenshot.nix
    ./downloads.nix
    ./engsci.nix
    ./development.nix
    ./gaming.nix
    ./wezterm.nix
    ./yazi.nix
    ./helix.nix
  ];

  my.dotfiles.mode = "live";

  home = {
    username = "casua";
    homeDirectory = "/home/casua";
    stateVersion = "26.05";
  };
}
