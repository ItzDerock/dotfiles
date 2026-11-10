# Keep the upstream GUI, but replace its FUSE 2 daemon with the FUSE 3 fork.
# Extract and patch the AppImage without an FHS sandbox so mounts remain
# visible to applications outside the client's namespace.
{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  seadrive-fuse,
  fuse3,
  openssl,
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
  daemon = (seadrive-fuse.override {fuse = fuse3;}).overrideAttrs (old: {
    inherit version;
    src = fetchFromGitHub {
      owner = "ItzDerock";
      repo = "seadrive-fuse";
      rev = "4be7f8734348e3fad7d6637e0e36c54c65607286";
      hash = "sha256-W+Ny5b/OhS0RcNoqPDjqTpF68m7IhLpBequDyWzYlxc=";
    };
    buildInputs = old.buildInputs ++ [openssl];
    meta = old.meta // {
      broken = false;
      homepage = "https://github.com/ItzDerock/seadrive-fuse";
      changelog = "https://github.com/ItzDerock/seadrive-fuse/commit/4be7f8734348e3fad7d6637e0e36c54c65607286";
    };
  });
  # The GUI still invokes "fusermount" to clean up an existing mount.
  # Forward it to NixOS' privileged FUSE 3 helper.
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
      rm $out/lib/seadrive/bin/seadrive $out/lib/seadrive/lib/libfuse.so.2
      ln -s ${daemon}/bin/seadrive $out/lib/seadrive/bin/seadrive
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

    passthru = {inherit daemon;};

    meta = {
      description = "Seafile virtual drive with on-demand file caching";
      homepage = "https://help.seafile.com/drive_client/drive_client_for_linux/";
      license = [lib.licenses.asl20 lib.licenses.gpl3Only];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = ["x86_64-linux"];
      mainProgram = "seadrive-gui";
    };
  }
