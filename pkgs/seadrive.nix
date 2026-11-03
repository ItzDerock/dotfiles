# Upstream's AppImage still bundles FUSE 2; nixpkgs' source package is broken
# after FUSE 2's removal. Extract and patch it rather than using an FHS sandbox:
# the mount must be visible to applications outside the client's namespace.
{
  lib,
  stdenv,
  fetchurl,
  appimageTools,
  autoPatchelfHook,
  makeWrapper,
  writeShellScriptBin,
  alsa-lib,
  cups,
  dbus,
  e2fsprogs,
  fontconfig,
  freetype,
  fribidi,
  glib,
  harfbuzz,
  libGL,
  libdrm,
  libgpg-error,
  libice,
  libsm,
  libxkbcommon,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxrender,
  libxtst,
  nspr,
  nss,
  wayland,
  xkeyboard-config,
  zlib,
}: let
  pname = "seadrive";
  version = "3.0.27";
  src = fetchurl {
    url = "https://sos-ch-dk-2.exo.io/seafile-downloads/SeaDrive-x86_64-${version}.AppImage";
    hash = "sha256-dM1+70XkE8VkJayovaPMrl9G7djxuoCQ3Uz/KkwhJ5Q=";
  };
  contents = appimageTools.extract {inherit pname version src;};
  # FUSE 2's mount protocol is supported by fusermount3. Use NixOS' existing
  # privileged helper, not an obsolete setuid fusermount bundled by upstream.
  mountHelper = writeShellScriptBin "fusermount" ''
    exec /run/wrappers/bin/fusermount3 "$@"
  '';
in
  stdenv.mkDerivation {
    inherit pname version;
    src = contents;
    nativeBuildInputs = [autoPatchelfHook makeWrapper];
    buildInputs = [
      alsa-lib
      cups
      dbus
      e2fsprogs
      fontconfig
      freetype
      fribidi
      glib
      harfbuzz
      libGL
      libdrm
      libgpg-error
      libice
      libsm
      libxkbcommon
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxrender
      libxtst
      nspr
      nss
      wayland
      zlib
      stdenv.cc.cc.lib
    ];
    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/seadrive $out/bin $out/share
      cp -r usr/. $out/lib/seadrive/
      # Use host graphics/Wayland libraries; the bundled client library is too
      # old for the current system's libwayland-cursor.
      rm $out/lib/seadrive/lib/libEGL_mesa.so.* \
        $out/lib/seadrive/lib/libwayland-*.so.*
      cp -r usr/share/applications usr/share/icons usr/share/pixmaps $out/share/
      makeWrapper $out/lib/seadrive/bin/seadrive-gui $out/bin/seadrive-gui \
        --prefix PATH : "$out/lib/seadrive/bin:${lib.makeBinPath [mountHelper]}" \
        --set QT_PLUGIN_PATH "$out/lib/seadrive/plugins" \
        --set QML2_IMPORT_PATH "$out/lib/seadrive/qml" \
        --set XKB_CONFIG_ROOT "${xkeyboard-config}/share/X11/xkb" \
        --set SEAFILE_SSL_CA_PATH /etc/ssl/certs/ca-certificates.crt
      runHook postInstall
    '';

    meta = {
      description = "Seafile virtual drive with on-demand file caching";
      homepage = "https://help.seafile.com/drive_client/drive_client_for_linux/";
      license = [lib.licenses.asl20 lib.licenses.gpl3Only];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = ["x86_64-linux"];
      mainProgram = "seadrive-gui";
    };
  }
