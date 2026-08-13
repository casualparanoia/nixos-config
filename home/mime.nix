# ~/nixos-config/home/mime.nix
{ ... }:
{
  xdg.mimeApps = {
    enable = true;

    associations.added = {
      "application/pdf" = [ "okularApplication_pdf.desktop" ];
    };

    defaultApplications = {
      # Web
      "text/html" = [ "helium.desktop" ];
      "x-scheme-handler/http" = [ "helium.desktop" ];
      "x-scheme-handler/https" = [ "helium.desktop" ];

      # File manager
      "inode/directory" = [ "org.kde.dolphin.desktop" ];

      # PDF
      "application/pdf" = [ "okularApplication_pdf.desktop" ];

      # Images
      "image/jpeg" = [ "org.kde.gwenview.desktop" ];
      "image/png" = [ "org.kde.gwenview.desktop" ];
      "image/webp" = [ "org.kde.gwenview.desktop" ];
      "image/gif" = [ "org.kde.gwenview.desktop" ];
    };
  };
}
