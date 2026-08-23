{ config, pkgs, ... }:

let
  #temporary workaround
  #amdgpu_bl1 is valid up to requested brightness 65512
  #65512..65535 causes actual_brightness to wrap/drop to 0 on this machine
  clampAmdBacklight = pkgs.writeShellScript "clamp-amdgpu-backlight" ''
    set -eu
    max_safe=65512
    brightness_file=/sys/class/backlight/amdgpu_bl1/brightness
    if [ ! -e "$brightness_file" ]; then
      exit 0
    fi
    IFS= read -r current < "$brightness_file"
    if [ "$current" -gt "$max_safe" ]; then
      printf '%s\n' "$max_safe" > "$brightness_file"
    fi
  '';
in
{
  services.udev.extraRules = ''
    #backlight
    ACTION=="change",SUBSYSTEM=="backlight",KERNEL=="amdgpu_bl1",RUN+="${clampAmdBacklight}"
    ACTION=="add",SUBSYSTEM=="backlight",KERNEL=="amdgpu_bl1",TAG+="systemd",ENV{SYSTEMD_WANTS}+="amdgpu-backlight-clamp.service"
  '';

  # ------------------
  # TEMP: backlight
  # ------------------
  systemd.services.amdgpu-backlight-clamp = {
    description = "Clamp broken amdgpu_bl1 maximum brightness";
    wants = [ "systemd-backlight@backlight:amdgpu_bl1.service" ];

    after = [
      "systemd-backlight@backlight:amdgpu_bl1.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      #RemainAfterExit = true;
      #clamp after boot-time brightness restore
      ExecStart = clampAmdBacklight;
      #clamp before shutdown so systemd-backlight saves to a safe value
      #ExecStop = clampAmdBacklight;
    };
  };
}
