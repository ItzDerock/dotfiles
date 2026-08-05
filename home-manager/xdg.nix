{ pkgs, lib, ... }:
let
  # mimeapps.list is written as a real, writable file rather than a store symlink
  # (see the activation script below) so KDE's "Remember application association"
  # checkbox can actually persist a choice. Every rebuild restores this generated
  # content, so anything you want to keep belongs in allAssociations.
  mkSection = attrs: lib.concatStrings (
    lib.mapAttrsToList (type: handlers: "${type}=${lib.concatStringsSep ";" handlers};\n") attrs
  );

  # To find .desktop locations:
  # for p in ${XDG_DATA_DIRS//:/ }; do find $p/applications -name '*.desktop'; done

  # makeMimeAssociations $.desktop $prefix $mime[]
  makeMimeAssociations =
    handler: prefix: types:
    builtins.listToAttrs (
      map (type: {
        name = "${prefix}${type}";
        value = [ handler ];
      }) types
    );

  terminalApplication = "foot.desktop";

  # image/ auto-appended — these subtypes are all real
  imageTypes = [
    "png"
    "jpeg"
    "heic"
    "heif"
    "bmp"
    "gif"
    "webp"
    "tiff"
    "svg+xml"
    "avif"
  ];

  # Full mime names — these must match shared-mime-info exactly. Container
  # extensions are NOT mime subtypes: .mkv is video/x-matroska, .mov is
  # video/quicktime, .ts is video/mp2t, and video/{mkv,mov,wmv,mpg,ogv,ts}
  # match nothing at all. Check with:
  #   grep -o 'type="video/[^"]*"' $(nix eval --raw nixpkgs#shared-mime-info)/share/mime/packages/freedesktop.org.xml
  videoTypes = [
    "video/mp4"
    "video/x-matroska"
    "video/x-msvideo"
    "video/msvideo"
    "video/avi"
    "video/quicktime"
    "video/webm"
    "video/x-flv"
    "video/flv"
    "video/x-ms-wmv"
    "video/mpeg"
    "video/3gpp"
    "video/3gpp2"
    "video/ogg"
    "video/mp2t"
    "video/x-mpegurl"
    "video/vnd.mpegurl"
  ];

  browserTypes = [
    "text/html"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/about"
    "x-scheme-handler/unknown"
    "application/x-extension-html"
    "application/x-extension-htm"
  ];

  textTypes = [
    "application/x-extension-htm"
    "application/x-extension-html"
    "application/x-wine-extension-ini"
    "text/plain"
    "text/vbscript"
    "application/x-mswrite"
    "application/xml"
  ];

  # These associations override all pregen ones
  extraAssociations = {
    "inode/directory" = [ "org.kde.dolphin.desktop" ];
    "application/zip" = [ "org.kde.ark.desktop" ];
    "application/pdf" = [ "zen.desktop" ];
  };

  # [lowest prio ... highest prio]
  allAssociations =
    (makeMimeAssociations "zen.desktop" "" browserTypes)
    // (makeMimeAssociations "mpv.desktop" "" videoTypes)
    // (makeMimeAssociations "org.kde.gwenview.desktop" "image/" imageTypes)
    // (makeMimeAssociations "nvim.desktop" "" textTypes)
    // extraAssociations;

  mimeappsList = pkgs.writeText "mimeapps.list" ''
    [Default Applications]
    ${mkSection allAssociations}
    [Added Associations]
    ${mkSection allAssociations}
  '';
in
{
  home.packages = with pkgs; [
    kdePackages.gwenview
    mpv
  ];

  xdg = {
    enable = true;

    # Deliberately off: it would link mimeapps.list into the read-only store.
    # The activation script below installs a writable copy instead.
    mimeApps.enable = false;

    userDirs = {
      enable = true;
      desktop = "$HOME/Desktop/";
      download = "$HOME/Downloads/";
      documents = "$HOME/Documents/";
      videos = "$HOME/Videos/";
      pictures = "$HOME/Pictures/";
    };

    terminal-exec.settings.default = [ terminalApplication ];
  };

  # Writable mimeapps.list — replaces any prior store symlink, and stays a plain
  # file so KDE/GIO can rewrite it when you pick "remember this application".
  home.activation.writableMimeApps = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run rm -f "$HOME/.config/mimeapps.list" "$HOME/.local/share/applications/mimeapps.list"
    run install -Dm644 ${mimeappsList} "$HOME/.config/mimeapps.list"
  '';

  # Set default terminal
  home.file.".config/xdg-terminals.list" = {
    text = terminalApplication;
    force = true;
  };

  home.sessionVariables = {
    TERMINAL = terminalApplication;
  };
}
