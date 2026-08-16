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
    settings.launch = {
      "Alacritty" = "/run/current-system/sw/bin/alacritty";
      "ai.opencode.desktop" = "/etc/profiles/per-user/casua/bin/opencode-desktop";
      "com.github.dynobo.normcap" = "/run/current-system/sw/bin/nirinit-launch-normcap";
      "org.openlogi.openlogi" = "/run/current-system/sw/bin/openlogi-gui";
    };
  };
}
