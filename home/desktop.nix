# ~/nixos-config/home/desktop.nix
{ config, pkgs, pkgsUnstable, ... }:
{
  services.copyq = {
    enable = true;
    package = pkgsUnstable.copyq;
    forceXWayland = false;
  };
  programs.zapzap = {
    enable = true;
    package = pkgsUnstable.zapzap;
  };
programs.vicinae = {
  enable = true;

  systemd = {
    enable = true;
    autoStart = true;

    environment = {
      USE_LAYER_SHELL = 1;
    };
  };
  settings = {
    search_files_in_root = true;
    close_on_focus_loss = true;
    pop_to_root_on_close = true;
  };
};

  xdg.autostart = {
    enable = true;

    entries = [
      "${config.programs.zapzap.package}/share/applications/com.rtosta.zapzap.desktop"
    ];
  };

}
