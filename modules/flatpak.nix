{ ... }:

{
  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    packages = [
      "com.github.dynobo.normcap"
      "org.libreoffice.LibreOffice"
      "org.jaspstats.JASP"
      "org.jamovi.jamovi"
      "org.gimp.GIMP"
    ];

    # Keep unrelated manual installations while this policy is being adopted.
    uninstallUnmanaged = false;
    uninstallUnused = false;

    update = {
      onActivation = false;
      auto = {
        enable = true;
        onCalendar = "weekly";
      };
    };
  };
}
