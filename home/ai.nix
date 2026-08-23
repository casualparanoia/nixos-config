{
  pkgs,
  pkgsUnstable,
  antigravity-nix,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home.packages = [
    pkgsUnstable.codex
    pkgsUnstable.opencode-desktop
    antigravity-nix.packages.${system}.google-antigravity-ide
    antigravity-nix.packages.${system}.google-antigravity
    pkgsUnstable.t3code
  ];
}
