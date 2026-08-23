{ pkgs, ... }:

{
  imports = [
    ./development-cli.nix
  ];

  home.packages = [
    pkgs.kdePackages.kate
  ];
}
