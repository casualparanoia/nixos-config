# ~/nixos-config/home/downloads.nix
{ pkgs, pkgsUnstable, ... }:

let
  abDownloadManager = pkgs.callPackage ../packages/ab-download-manager.nix { };
in
{
  home.packages = [
    abDownloadManager

    # We can compare it with this later:
    # pkgs.persepolis
    pkgsUnstable.motrix-next
  ];
}
