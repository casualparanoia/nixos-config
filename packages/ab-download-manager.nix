# ~/nixos-config/packages/ab-download-manager.nix
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,

  alsa-lib,
  fontconfig,
  freetype,
  libx11,
  libxext,
  libxi,
  libxrender,
  libxtst,
  libxkbcommon,
  wayland,
  libglvnd,
  zlib,
}:

stdenv.mkDerivation rec {
  pname = "ab-download-manager";
  version = "1.10.1";

  src = fetchurl {
    url = "https://github.com/amir1376/ab-download-manager/releases/download/v${version}/ABDownloadManager_${version}_linux_x64.tar.gz";
    hash = "sha256-2q5TLfwHIx2uAvzjcaZrUObB70ypSnBbs7XyuZaCXuc=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    fontconfig
    freetype

    libx11
    libxext
    libxi
    libxrender
    libxtst

    libxkbcommon
    wayland

    libglvnd
    zlib
    stdenv.cc.cc.lib
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt/ABDownloadManager"
    cp -r ./* "$out/opt/ABDownloadManager/"

    mkdir -p "$out/bin"

    makeWrapper \
      "$out/opt/ABDownloadManager/bin/ABDownloadManager" \
      "$out/bin/ABDownloadManager" \
      --prefix LD_LIBRARY_PATH : "${lib.getLib fontconfig}/lib"


    mkdir -p "$out/share/applications"
    cat > "$out/share/applications/com.abdownloadmanager.desktop" <<EOF
    [Desktop Entry]
    Name=AB Download Manager
    Comment=Manage and organize your download files better than before
    GenericName=Downloader
    Categories=Utility;Network;
    Exec=ABDownloadManager
    Icon=ab-download-manager
    Terminal=false
    Type=Application
    StartupWMClass=com-abdownloadmanager-desktop-AppKt
    EOF

    mkdir -p "$out/share/icons/hicolor/512x512/apps"

    if [ -f "$out/opt/ABDownloadManager/lib/ABDownloadManager.png" ]; then
      ln -s \
        "$out/opt/ABDownloadManager/lib/ABDownloadManager.png" \
        "$out/share/icons/hicolor/512x512/apps/ab-download-manager.png"
    fi

    runHook postInstall
  '';

  meta = {
    description = "Download manager with browser integration, queues and scheduling";
    homepage = "https://github.com/amir1376/ab-download-manager";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ABDownloadManager";
  };
}
