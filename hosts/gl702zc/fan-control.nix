{ pkgs, pkgsUnstable, ... }:

let
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
  # ------------------
  # NBFC fan control
  # ------------------

  environment.systemPackages = [ pkgsUnstable.nbfc-linux ];

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

      ExecStart = "${pkgsUnstable.nbfc-linux}/bin/nbfc_service --config-file /etc/nbfc/nbfc.json";

      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
