{ pkgs, pkgsUnstable, ... }:

{
  programs.eza = {
    enable = true;
    package = pkgsUnstable.eza;
    icons = "auto";
    git = true;
  };

  programs.carapace = {
    enable = true;
    # Kept on stable HM default: overriding package causes evaluation
    # conflicts due to Home Manager's tight wrapper schema.
    # enable case-insensitive matching if supported
    ignoreCase = true;
  };

  programs.bat = {
    enable = true;
    package = pkgsUnstable.bat;

    config = {
      pager = "less -FR";
      style = "numbers,changer,header";
    };
  };

  programs.zoxide = {
    enable = true;
    package = pkgsUnstable.zoxide;
  };

  programs.fzf = {
    enable = true;
    package = pkgsUnstable.fzf;
  };

  home.packages = [
    # General CLI
    pkgsUnstable.jq
    pkgsUnstable.yq-go
    pkgsUnstable.sd
    pkgsUnstable.patchelf

    pkgsUnstable.dust
    pkgsUnstable.dua
    pkgsUnstable.duf
    pkgsUnstable.bottom
    pkgsUnstable.procs

    pkgsUnstable.hyperfine
    pkgsUnstable.fastfetch
    pkgsUnstable.tealdeer
    pkgsUnstable.tokei

    pkgsUnstable.libqalculate
    pkgsUnstable.ripgrep
    pkgsUnstable.fd
    pkgsUnstable.file

    pkgsUnstable.ouch

    # Rust coreutils
    pkgsUnstable.uutils-coreutils
  ];
}
