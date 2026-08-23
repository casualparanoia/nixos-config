{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/user.nix
  ];

  # NixOS WSL configuration
  networking.hostName = "wsl";

  wsl.enable = true;
  wsl.defaultUser = "casua";

  # Important: preserve the stateVersion from the original WSL installation
  system.stateVersion = "26.05";
}
