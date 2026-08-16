{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,

  libGL,
  libxcb,
  libxkbcommon,
  vulkan-loader,
  wayland,
}:

stdenv.mkDerivation rec {
  pname = "openlogi";
  version = "0.7.1";

  src = fetchurl {
    url = "https://github.com/AprilNEA/OpenLogi/releases/download/v${version}/openlogi-v${version}-linux-amd64.deb";
    hash = "sha256-mMdL4C7EipMS2Ji4V8o+pVOd0WiiahRFVOrAvPwwzqo=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = [
    libxcb
    libxkbcommon
    stdenv.cc.cc.lib
  ];

  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/share" "$out/lib/udev/rules.d"
    cp -r usr/bin/* "$out/bin/"
    cp -r usr/share/* "$out/share/"
    cp etc/udev/rules.d/70-openlogi.rules "$out/lib/udev/rules.d/"

    graphicsRuntimePath="${
      lib.makeLibraryPath [
        libGL
        vulkan-loader
        wayland
      ]
    }"
    wrapProgram "$out/bin/openlogi-gui" \
      --prefix LD_LIBRARY_PATH : "$graphicsRuntimePath"
    wrapProgram "$out/bin/openlogi-overlay" \
      --prefix LD_LIBRARY_PATH : "$graphicsRuntimePath"

    runHook postInstall
  '';

  meta = {
    description = "Local-first companion for Logitech HID++ peripherals";
    homepage = "https://github.com/AprilNEA/OpenLogi";
    license = with lib.licenses; [
      asl20
      mit
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "openlogi";
  };
}
