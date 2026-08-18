{ pkgs, pkgsUnstable, ... }:
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
  # ------------------
  # NBFC fan control
  # ------------------

  # Start from NBFC's known-good GL702ZC hardware configuration and
  # replace only the automatic fan curves.
  nbfcGl702zcConfig =
    pkgs.runCommand "nbfc-gl702zc-custom.json"
      {
        nativeBuildInputs = [ pkgs.jq ];
      }
      ''
            jq '
              .LegacyTemperatureThresholdsBehaviour = false |

              .CriticalTemperature = 90 |
              .CriticalTemperatureOffset = 5 |

              .FanConfigurations[0].TemperatureThresholds = [
                { "UpThreshold": 45, "DownThreshold":  0, "FanSpeed": 12.5 },
                { "UpThreshold": 50, "DownThreshold": 40, "FanSpeed": 25.0 },
                { "UpThreshold": 55, "DownThreshold": 45, "FanSpeed": 37.5 },
                { "UpThreshold": 65, "DownThreshold": 50, "FanSpeed": 50.0 },
                { "UpThreshold": 72, "DownThreshold": 60, "FanSpeed": 62.5 },
                { "UpThreshold": 78, "DownThreshold": 67, "FanSpeed": 75.0 },
                { "UpThreshold": 84, "DownThreshold": 73, "FanSpeed": 87.5 },
        	{ "UpThreshold": 90, "DownThreshold": 79, "FanSpeed": 100.0 }
              ] |

              .FanConfigurations[1].TemperatureThresholds = [
                { "UpThreshold": 45, "DownThreshold":  0, "FanSpeed": 12.5 },
                { "UpThreshold": 50, "DownThreshold": 40, "FanSpeed": 25.0 },
                { "UpThreshold": 55, "DownThreshold": 45, "FanSpeed": 37.5 },
                { "UpThreshold": 65, "DownThreshold": 50, "FanSpeed": 50.0 },
                { "UpThreshold": 72, "DownThreshold": 60, "FanSpeed": 62.5 },
                { "UpThreshold": 78, "DownThreshold": 67, "FanSpeed": 75.0 },
                { "UpThreshold": 84, "DownThreshold": 73, "FanSpeed": 87.5 },
        	{ "UpThreshold": 90, "DownThreshold": 79, "FanSpeed": 100.0 }
              ]
            ' \
              "${pkgsUnstable.nbfc-linux}/share/nbfc/configs/Asus ROG GL702ZC.json" \
              > "$out"
      '';
  waitForAmdgpuHwmon = pkgs.writeShellScript "wait-for-amdgpu-hwmon" ''
    set -eu

    i=0
    while [ "$i" -lt 300 ]; do
      for h in /sys/class/hwmon/hwmon*; do
        if [ -r "$h/name" ]; then
          IFS= read -r name < "$h/name"
          if [ "$name" = "amdgpu" ]; then
            exit 0
          fi
        fi
      done

      i=$((i + 1))
      ${pkgs.coreutils}/bin/sleep 0.1
    done

    echo "NBFC: timed out waiting for amdgpu hwmon" >&2
    exit 1
  '';

in
{
  #1.Power Profiles Daemon
  services.power-profiles-daemon.enable = true;

  # disable sleep/suspend stuff
  #systemd.sleep.settings.Sleep = {
  #  AllowSuspend = false;
  #  AllowHibernation = false;
  #  AllowHybridSleep = false;
  #  AllowSuspendThenHibernate = false;
  #};
  #
  hardware.rasdaemon.enable = true;

  #2. AMD Ryzen CPU Power Driver & Backlight Fix
  boot.kernelParams = [
    "amd_pstate=active"
    "acpi_backlight=native"
    #"i8042.nokbd" #DISABLE INTERNAL KEYBOARD
    #TPM DISABLE
    "modprobe.blacklist=tpm_crb,tpm_tis,tpm_tis_core,tpm"
    #nvme test
    #	"nvme_core.default_ps_max_latency_us=0"
    "amdgpu.gpu_recovery=1"
  ];

  #TPM DISABLE
  systemd.tpm2.enable = false;
  boot.initrd.systemd.tpm2.enable = false;

  #DISABLE INTERNAL KEYBOARD
  services.udev.extraRules = ''
    	ACTION=="add|change",ATTRS{name}=="Asus Keyboard", ENV{LIBINPUT_IGNORE_DEVICE}="1",ATTR{inhibited}="1"
    	#backlight
    	ACTION=="change",SUBSYSTEM=="backlight",KERNEL=="amdgpu_bl1",RUN+="${clampAmdBacklight}"
    	ACTION=="add",SUBSYSTEM=="backlight",KERNEL=="amdgpu_bl1",TAG+="systemd",ENV{SYSTEMD_WANTS}+="amdgpu-backlight-clamp.service"
  '';

  #3. ASUS Laptop Support
  #  services.asusd = {
  #    enable = true;
  #    package = pkgsUnstable.asusctl;
  #  };
  #  systemd.services.asus-shutdown = {
  #    serviceConfig = {
  #      TimeoutStopSec = "5s";
  #      SendSIGKILL = true;
  #    };
  #    # Optional: prevent switch-to-configuration from restarting it mid-session
  #    restartIfChanged = false;
  #  };

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
  # ------------------
  # NBFC fan control
  # ------------------

  # NBFC's preferred EC backend; we already verified it works on this machine.
  boot.kernelModules = [ "ec_sys" ];

  boot.extraModprobeConfig = ''
    options ec_sys write_support=1
  '';

  # Main NBFC service configuration.
  environment.etc."nbfc/nbfc.json".text = builtins.toJSON {
    SelectedConfigId = "${nbfcGl702zcConfig}";
    EmbeddedControllerType = "ec_sys";

    FanTemperatureSources = [
      {
        FanIndex = 0; # CPU fan
        TemperatureAlgorithmType = "Max";
        Sensors = [ "@CPU" ];
      }
      {
        FanIndex = 1; # GPU fan
        TemperatureAlgorithmType = "Max";
        Sensors = [ "@GPU" ];
      }
    ];
  };
  systemd.services.nbfc_service = {
    description = "NoteBook FanControl service";

    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];

    path = [ pkgs.kmod ];

    serviceConfig = {
      Type = "simple";

      ExecStartPre = waitForAmdgpuHwmon;

      ExecStart = "${pkgsUnstable.nbfc-linux}/bin/nbfc_service " + "--config-file /etc/nbfc/nbfc.json";

      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
