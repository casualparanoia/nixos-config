{ pkgs, pkgsUnstable, ... }:

{
  imports = [
    ./development-cli.nix
  ];

  home.packages = [
    pkgsUnstable.kdePackages.kate
  ];
}
