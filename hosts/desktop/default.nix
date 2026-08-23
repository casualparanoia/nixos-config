{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Include Disko storage layout
    ./disks.nix

    # Shared workstation profile
    ../../profiles/workstation.nix
  ];

  networking.hostName = "desktop";

  # NixOS Facter support
  # Facter report will be placed at hosts/desktop/facter.json
  # We use lib.mkIf to conditionally set it only if it exists so evaluation doesn't fail before installation.
  hardware.facter.reportPath = lib.mkIf (builtins.pathExists ./facter.json) ./facter.json;

  # Bootstrap-time password injection
  users.users.casua.hashedPasswordFile = "/etc/nixos-secrets/casua-password-hash";
}
