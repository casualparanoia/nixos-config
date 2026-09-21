{
  lib,
  pkgs,
  pkgsUnstable,
  ...
}:

let
  ntfySecrets = "/var/lib/private-server-secrets/ntfy.env";

  # Exercise the real Caddy route without depending on NetBird DNS locally.
  mkCaddyCheck =
    {
      name,
      host,
      path ? "/",
      conditions,
      ignoreRedirect ? false,
    }:
    {
      inherit name conditions;
      group = "Private services";
      url = "http://127.0.0.1${path}";
      interval = "5m";
      headers.Host = host;
      client = {
        timeout = "10s";
      }
      // lib.optionalAttrs ignoreRedirect {
        ignore-redirect = true;
      };
      alerts = [ { type = "ntfy"; } ];
    };

  smartdNtfy = pkgs.writeShellApplication {
    name = "smartd-ntfy";
    runtimeInputs = [ pkgs.curl ];
    text = ''
      set -o allexport
      # This root-owned file is also the Gatus EnvironmentFile.
      # shellcheck disable=SC1091
      source ${lib.escapeShellArg ntfySecrets}
      set +o allexport

      if [[ -z "''${SMARTD_NTFY_TOKEN:-}" ]]; then
        echo "SMARTD_NTFY_TOKEN is missing from ${ntfySecrets}" >&2
        exit 1
      fi

      printf '%s\n\n%s\n' "$SMARTD_SUBJECT" "$SMARTD_FULLMESSAGE" \
        | curl \
          --fail-with-body \
          --silent \
          --show-error \
          --retry 3 \
          --max-time 15 \
          --header "Authorization: Bearer $SMARTD_NTFY_TOKEN" \
          --header "Title: SMART warning on GL702ZC" \
          --header "Priority: high" \
          --header "Tags: warning,hard_disk" \
          --data-binary @- \
          http://127.0.0.1:2586/server-alerts
    '';
  };
in
{
  # Lightweight status history: seven days at a five-minute interval for each
  # endpoint, plus a small event history, all in one bounded SQLite database.
  services.gatus = {
    enable = true;
    package = pkgs.gatus;
    openFirewall = false;
    environmentFile = ntfySecrets;
    settings = {
      web = {
        address = "127.0.0.1";
        port = 8081;
      };
      metrics = false;
      storage = {
        type = "sqlite";
        path = "/var/lib/gatus/gatus.db";
        maximum-number-of-results = 2016;
        maximum-number-of-events = 50;
      };
      alerting.ntfy = {
        url = "http://127.0.0.1:2586";
        topic = "server-alerts";
        token = "\${GATUS_NTFY_TOKEN}";
        click = "http://status.home.arpa";
        priority = 4;
        default-alert = {
          enabled = true;
          failure-threshold = 3;
          success-threshold = 2;
          send-on-resolved = true;
          description = "Private service health check failed";
        };
      };
      endpoints = [
        (mkCaddyCheck {
          name = "Immich";
          host = "immich.home.arpa";
          path = "/api/server/ping";
          conditions = [
            "[STATUS] == 200"
            "[BODY].res == pong"
          ];
        })
        (mkCaddyCheck {
          name = "PhotoPrism";
          host = "photoprism.home.arpa";
          conditions = [ "[STATUS] == 307" ];
          ignoreRedirect = true;
        })
        (mkCaddyCheck {
          name = "SearXNG";
          host = "search.home.arpa";
          conditions = [ "[STATUS] == 200" ];
        })
        (mkCaddyCheck {
          name = "ntfy";
          host = "notify.home.arpa";
          path = "/v1/health";
          conditions = [
            "[STATUS] == 200"
            "[BODY].healthy == true"
          ];
        })
        (mkCaddyCheck {
          name = "linkding";
          host = "bookmarks.home.arpa";
          path = "/health";
          conditions = [ "[STATUS] == 200" ];
        })
        (mkCaddyCheck {
          name = "FreshRSS";
          host = "rss.home.arpa";
          conditions = [ "[STATUS] == any(200, 302)" ];
        })
        (mkCaddyCheck {
          name = "Glance";
          host = "dashboard.home.arpa";
          conditions = [ "[STATUS] == 200" ];
        })
      ];
    };
  };

  services.ntfy-sh = {
    enable = true;
    package = pkgs.ntfy-sh;
    settings = {
      base-url = "http://notify.home.arpa";
      listen-http = "127.0.0.1:2586";
      behind-proxy = true;

      # Authentication is provisioned statefully with the ntfy CLI. Anonymous
      # reads and writes remain denied, including when reached through Caddy.
      auth-default-access = "deny-all";
      enable-login = true;
      require-login = true;
      enable-signup = false;

      cache-duration = "72h";
      cache-batch-size = 10;
      # An empty cache directory disables ntfy-managed file attachments.
      attachment-cache-dir = "";
    };
  };

  services.smartd = {
    enable = true;
    autodetect = true;
    # Monitor SMART/NVMe attributes and error logs. No self-tests are scheduled.
    defaults = {
      monitored = "-a";
      autodetected = "-a -m <nomailer> -M exec ${lib.getExe smartdNtfy}";
    };
    notifications = {
      mail.enable = false;
      wall.enable = false;
      x11.enable = false;
      test = false;
    };
  };
  systemd.services.smartd = {
    wants = [ "ntfy-sh.service" ];
    after = [ "ntfy-sh.service" ];
  };

  services.glance = {
    enable = true;
    package = pkgsUnstable.glance;
    openFirewall = false;
    settings = {
      server = {
        host = "127.0.0.1";
        port = 8082;
      };
      branding = {
        app-name = "Home services";
        logo-text = "H";
      };
      pages = [
        {
          name = "Home";
          width = "wide";
          columns = [
            {
              size = "small";
              widgets = [
                {
                  type = "server-stats";
                  servers = [
                    {
                      type = "local";
                      name = "GL702ZC";
                      hide-mountpoints-by-default = true;
                      mountpoints."/".name = "System disk";
                    }
                  ];
                }
              ];
            }
            {
              size = "full";
              widgets = [
                {
                  type = "bookmarks";
                  groups = [
                    {
                      title = "Media and search";
                      same-tab = true;
                      links = [
                        {
                          title = "Immich";
                          url = "http://immich.home.arpa";
                        }
                        {
                          title = "PhotoPrism";
                          url = "http://photoprism.home.arpa";
                        }
                        {
                          title = "SearXNG";
                          url = "http://search.home.arpa";
                        }
                      ];
                    }
                    {
                      title = "Personal services";
                      same-tab = true;
                      links = [
                        {
                          title = "Status";
                          url = "http://status.home.arpa";
                        }
                        {
                          title = "Notifications";
                          url = "http://notify.home.arpa";
                        }
                        {
                          title = "Bookmarks";
                          url = "http://bookmarks.home.arpa";
                        }
                        {
                          title = "RSS";
                          url = "http://rss.home.arpa";
                        }
                      ];
                    }
                  ];
                }
              ];
            }
          ];
        }
      ];
    };
  };

  services.linkding = {
    enable = true;
    package = pkgsUnstable.linkding;
    address = "127.0.0.1";
    port = 9090;
    openFirewall = false;
    environmentFile = "/var/lib/private-server-secrets/linkding.env";
    database.type = "sqlite";
    settings = {
      LD_SUPERUSER_NAME = "casua";
      # Disables Wayback/HTML/PDF snapshot jobs and their background worker.
      LD_DISABLE_BACKGROUND_TASKS = "True";
      LD_REQUEST_MAX_CONTENT_LENGTH = "10485760";
    };
  };

  services.freshrss = {
    enable = true;
    package = pkgsUnstable.freshrss;
    defaultUser = "casua";
    passwordFile = "/run/credentials/freshrss-config.service/freshrss-password";
    baseUrl = "http://rss.home.arpa";
    authType = "form";
    database.type = "sqlite";
    webserver = "caddy";
    # The explicit scheme keeps this site HTTP-only like the other private
    # names while the native module supplies the PHP-FPM/socket integration.
    virtualHost = "http://rss.home.arpa";
    api.enable = false;
  };
  systemd.services.freshrss-config.serviceConfig.LoadCredential = [
    "freshrss-password:/var/lib/private-server-secrets/freshrss-password"
  ];

  # The native module defaults are sized for a busier deployment.
  services.phpfpm.pools.freshrss.settings = {
    "pm.max_children" = lib.mkForce 4;
    "pm.start_servers" = lib.mkForce 1;
    "pm.min_spare_servers" = lib.mkForce 1;
    "pm.max_spare_servers" = lib.mkForce 2;
  };
}
