{ config, pkgs, ... }:

{
  imports = [
    ../modules/logitech-mouse.nix
    ../modules/niri.nix
    ../modules/nirinit.nix
    ../modules/desktop.nix
    ../modules/gaming.nix
    ../modules/flatpak.nix
    ../modules/appearance.nix
    ../modules/dms.nix
    ../modules/hardware-tools.nix
    ../modules/adguard.nix
    ../modules/user.nix
  ];

  environment.variables = {
    EDITOR = "hx";
    VISUAL = "kate";
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Istanbul";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "tr_TR.UTF-8";
    LC_IDENTIFICATION = "tr_TR.UTF-8";
    LC_MEASUREMENT = "tr_TR.UTF-8";
    LC_MONETARY = "tr_TR.UTF-8";
    LC_NAME = "tr_TR.UTF-8";
    LC_NUMERIC = "tr_TR.UTF-8";
    LC_PAPER = "tr_TR.UTF-8";
    LC_TELEPHONE = "tr_TR.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define host-specific groups for casua.
  users.users."casua" = {
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };


  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
  };

  system.stateVersion = "26.05";
}
