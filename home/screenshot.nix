{ pkgs, pkgsUnstable, ... }:

let

  screenshotKsnip =
    pkgs.writeShellScriptBin "screenshot-ksnip" ''
      set -eu

      file="''${XDG_RUNTIME_DIR:-/tmp}/ksnip-capture-$$.png"

      rm -f "$file"

      ${pkgs.niri}/bin/niri msg action screenshot \
        --path "$file"

      i=0

      while [ "$i" -lt 3000 ]; do
        if [ -s "$file" ]; then
          exec ${pkgs.ksnip}/bin/ksnip --edit "$file"
        fi

        ${pkgs.coreutils}/bin/sleep 0.02
        i=$((i + 1))
      done

      # Ctrl+C or cancelled screenshot:
      # Niri never wrote the requested file.
      exit 0
    '';


in
{
  home.packages = [
    pkgsUnstable.flameshot
    pkgs.grim
    pkgs.slurp
    pkgs.satty
    pkgs.ksnip
    pkgsUnstable.wayshot
    pkgs.shutter
    pkgs.kdePackages.spectacle
    screenshotKsnip
  ];

  xdg.configFile."satty/config.toml".text = ''
    [general]
    floating-hack = true

    copy-command = "${pkgs.wl-clipboard}/bin/wl-copy"

    # Copy button / Ctrl+C closes Satty afterwards.
    early-exit = ["copy"]

    # Enter = copy, which then triggers early-exit.
    actions-on-enter = ["save-to-clipboard"]

    # Escape just closes it.
    actions-on-escape = ["exit"]
  '';
}
