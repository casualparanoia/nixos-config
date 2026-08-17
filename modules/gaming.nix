{ pkgs, ... }:

{
  # Keep non-Steam launchers independent from Steam's implicit graphics setup.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.steam = {
    enable = true;
    protontricks.enable = true;

    # Expose GE-Proton as a per-game fallback without replacing Valve Proton.
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  # Use the standard daemon integration without renice or hardware tuning.
  programs.gamemode = {
    enable = true;
    enableRenice = false;
  };

  # Permit GameMode's standard CPU-governor/procsys helpers for this user.
  users.users.casua.extraGroups = [ "gamemode" ];

  environment.systemPackages = with pkgs; [
    mesa-demos
    vulkan-tools
    evtest
  ];
}
