{ ... }:

{
  services.adguardhome.enable = true;

  networking.resolvconf.useLocalResolver = true;
}
