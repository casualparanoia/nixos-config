{
  pkgs,
  pkgsUnstable,
  helium,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home.packages = [
    pkgs.floorp-bin
    pkgs.vivaldi
    helium.packages.${system}.helium

    pkgsUnstable.adguardian
  ];
}
