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
    pkgsUnstable.floorp-bin
    pkgsUnstable.vivaldi
    helium.packages.${system}.helium

    pkgsUnstable.adguardian
  ];
}
