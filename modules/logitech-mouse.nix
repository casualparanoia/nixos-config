{
  lib,
  pkgs,
  pkgsUnstable,
  ...
}:

let
  openlogi = pkgs.callPackage ../packages/openlogi.nix { };
in
{
  environment.systemPackages = [
    openlogi
    pkgsUnstable.mouser
  ];

  # Mouser is a manual fallback. Do not enable its autostart while OpenLogi runs.
  services.udev.packages = [
    openlogi
    pkgsUnstable.mouser
  ];

  systemd.user.services.openlogi-agent = {
    description = "OpenLogi background agent";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = lib.getExe' openlogi "openlogi-agent";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
