{
  config,
  pkgsUnstable,
  lib,
  ...
}:

{
  # Shared originals and application state: docs/services/private-server.md.
  services.immich = {
    enable = true;

    # Application comes from our pinned unstable package set.
    package = pkgsUnstable.immich;

    # Caddy is the only HTTP ingress; the external library stays UI-managed.
    host = "127.0.0.1";
    port = 2283;
    openFirewall = false;

    mediaLocation = "/srv/immich";

    environment = {
      IMMICH_MACHINE_LEARNING_TIMEOUT = "1200";
    };

    machine-learning = {
      enable = true;
      environment = {
        MACHINE_LEARNING_WORKER_TIMEOUT = lib.mkForce "1200";
        # Gunicorn otherwise fails creating /var/empty/.gunicorn. PrivateTmp
        # gives the ML worker a writable, service-private control-socket home.
        HOME = "/tmp";
      };
    };
  };

  users.groups.media = { };

  users.users.casua.extraGroups = [ "media" ];
  users.users.immich.extraGroups = [ "media" ];

  systemd.tmpfiles.rules = [
    # Non-recursive: never repair or walk the real archive during activation.
    "d /srv/media 2770 casua media - -"
    "d /srv/incoming 2770 casua media - -"
  ];

  services.photoprism = {
    enable = true;
    package = pkgsUnstable.photoprism;
    address = "127.0.0.1";
    port = 2342;
    # PrivateUsers preserves a static primary group but namespace-maps static
    # supplementary groups to nogroup. Keep the user dynamic and make media the
    # primary group so archive read access retains its intended identity.
    group = "media";
    originalsPath = "/srv/media/stuff";
    storagePath = "/var/lib/photoprism";
    importPath = "/var/lib/photoprism/import";
    passwordFile = "/var/lib/private-server-secrets/photoprism-admin-password";

    settings = {
      PHOTOPRISM_SITE_URL = "http://photoprism.home.arpa/";
      PHOTOPRISM_DISABLE_TLS = "true";
      PHOTOPRISM_TRUSTED_PROXY = "127.0.0.1/32";
      PHOTOPRISM_AUTH_MODE = "password";
      PHOTOPRISM_READONLY = "true";
      PHOTOPRISM_DISABLE_WEBDAV = "true";
      PHOTOPRISM_DATABASE_DRIVER = "sqlite";
      PHOTOPRISM_DISABLE_CLASSIFICATION = "false";
      PHOTOPRISM_DISABLE_FACES = "false";
      PHOTOPRISM_DISABLE_TENSORFLOW = "false";
      PHOTOPRISM_DISABLE_FFMPEG = "false";
      # No scheduled archive scans or bulk `photoprism convert` job. FFmpeg
      # remains available for previews and on-demand compatibility playback.
      PHOTOPRISM_INDEX_SCHEDULE = "";
      PHOTOPRISM_AUTO_INDEX = "-1";
      PHOTOPRISM_AUTO_IMPORT = "-1";
    };
  };

  systemd.services.photoprism.serviceConfig = {
    # Stable module emits a trailing empty LoadCredential when SQLite has no
    # database password. systemd treats that as a reset, losing the admin file.
    LoadCredential = lib.mkForce [
      "PHOTOPRISM_ADMIN_PASSWORD_FILE:${config.services.photoprism.passwordFile}"
    ];
    # The stable module includes originals/import in ReadWritePaths. Replace
    # that list, then mount the whole archive parent read-only (including the
    # directory entry for stuff). Application read-only mode is not a sandbox.
    ReadWritePaths = lib.mkForce [ config.services.photoprism.storagePath ];
    BindReadOnlyPaths = [ "/srv/media" ];
    ProtectSystem = "strict";
    PrivateTmp = true;
  };
}
