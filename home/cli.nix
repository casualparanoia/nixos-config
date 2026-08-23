{ pkgs, pkgsUnstable, ... }:

{
  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
  };

  programs.carapace = {
    enable = true;
  };

  programs.bat = {
    enable = true;

    config = {
      pager = "less -FR";
      style = "numbers,changer,header";
    };
  };

  programs.zoxide = {
    enable = true;
  };

  programs.fzf = {
    enable = true;
  };

  home.packages = [
    # General CLI
    pkgs.jq
    pkgs.yq-go
    pkgs.sd
    pkgs.patchelf

    pkgs.dust
    pkgsUnstable.dua
    pkgs.duf
    pkgs.bottom
    pkgs.procs

    pkgs.hyperfine
    pkgs.fastfetch
    pkgs.tealdeer
    pkgs.tokei

    pkgs.libqalculate

    # Rust coreutils
    pkgs.uutils-coreutils
  ];
}
