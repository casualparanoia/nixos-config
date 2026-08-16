{ pkgs, ... }:

let
  normcapLauncher = pkgs.writeShellScriptBin "nirinit-launch-normcap" ''
    exec ${pkgs.flatpak}/bin/flatpak run --system com.github.dynobo.normcap "$@"
  '';
in
{
  environment.systemPackages = [ normcapLauncher ];

  services.nirinit = {
    enable = true;
    settings.launch."com.github.dynobo.normcap" = "/run/current-system/sw/bin/nirinit-launch-normcap";
  };
}
