{ pkgsUnstable, ... }:

{
  # Host-local private ingress, connectivity and availability policy.
  # See docs/services/private-server.md and docs/runbooks/private-server.md.
  services.netbird = {
    enable = true;

    package = pkgsUnstable.netbird; # Intentional infrastructure exception.

    # This machine does not need the desktop tray app.
    ui.enable = false;
  };

  services.caddy = {
    enable = true;
    openFirewall = false;
    # Explicit schemes prevent automatic TLS and HTTPS redirects for home.arpa.
    virtualHosts = {
      "http://immich.home.arpa".extraConfig = "reverse_proxy 127.0.0.1:2283";
      "http://photoprism.home.arpa".extraConfig = "reverse_proxy 127.0.0.1:2342";
      "http://search.home.arpa".extraConfig = "reverse_proxy 127.0.0.1:8888";
    };
  };

  networking.firewall.interfaces = {
    wt0.allowedTCPPorts = [ 80 ];
    enp6s0.allowedTCPPorts = [ 80 ];
  };

  networking.networkmanager.ensureProfiles.profiles.gl702zc-direct = {
    connection = {
      id = "gl702zc-direct";
      type = "ethernet";
      interface-name = "enp6s0";
      autoconnect = true;
      autoconnect-priority = 100;
    };
    ipv4 = {
      method = "manual";
      address1 = "10.42.0.2/24";
      never-default = true;
      ignore-auto-dns = true;
      dns = "";
      dns-search = "";
      route-metric = 300;
    };
    ipv6.method = "disabled";
  };

  services.searx = {
    enable = true;
    package = pkgsUnstable.searxng;
    openFirewall = false;
    configureUwsgi = false; # Native module's small/private-instance mode.
    redisCreateLocally = false;
    environmentFile = "/var/lib/private-server-secrets/searx.env";
    settings = {
      general.debug = false;
      server = {
        bind_address = "127.0.0.1";
        port = 8888;
        base_url = "http://search.home.arpa/";
        secret_key = "$SEARX_SECRET_KEY";
        public_instance = false;
        limiter = false;
      };
    };
  };

  systemd.services.searx = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      PrivateTmp = true;

      # SearXNG performs DNS/network initialization during startup.
      # Retry instead of remaining failed if connectivity is briefly unavailable.
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  # An unattended, mains-powered server that also retains its workstation UI.
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    IdleAction = "ignore";
  };
  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    AllowHibernation = false;
    AllowHybridSleep = false;
    AllowSuspendThenHibernate = false;
  };
}
