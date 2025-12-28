{ pkgs, lib, ... }:
let

  # To find .desktop locations:
  # for p in ${XDG_DATA_DIRS//:/ }; do find $p/applications -name '*.desktop'; done

  # makeMimeAssociations $.desktop $prefix $mime[]
  makeMimeAssociations = handler: prefix: types:
    builtins.listToAttrs (
      map (type: { name = "${prefix}${type}"; value = [handler]; }) types
    );

  terminalApplication = "foot.desktop";

  # image/ auto-appended
  imageTypes = [
    "png" "jpeg" "heic" "bmp" "gif"
  ];

  # video/ auto-appended
  videoTypes = [
    "mp4" "mkv" "avi" "mov" "webm" "flv" "wmv" "mpeg" "mpg" "3gp" "ogv" "ts"
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
    "inode/directory" = ["org.gnome.Nautilus.desktop"];
    "application/zip" = ["ark.desktop"];
    "application/pdf" = ["zen.desktop"];
  };

  # [lowest prio ... highest prio]
  allAssociations = 
    (makeMimeAssociations "zen.desktop" "" browserTypes)
    // (makeMimeAssociations "mpv.desktop" "video/" videoTypes)
    // (makeMimeAssociations "org.kde.kdegraphics.gwenview.desktop" "image/" imageTypes)
    // (makeMimeAssociations "nvim.desktop" "" textTypes)
    // extraAssociations;
in
{
  home.packages = with pkgs; [
    kdePackages.gwenview
    mpv
  ];

  xdg = {
    enable = true;

    mimeApps = {
      enable = true;
      defaultApplications = allAssociations;
      associations.added = allAssociations;
    };

    userDirs = {
      enable = true;
      desktop = "$HOME/Desktop/";
      download = "$HOME/Downloads/";
      documents = "$HOME/Documents/";
      videos = "$HOME/Videos/";
      pictures = "$HOME/Pictures/";
    };

    # force override
    configFile."mimeapps.list".force = true;
  };

  # Set default terminal
  home.file.".config/xdg-terminals.list" = {
    text = terminalApplication;
    force = true;
  };

  home.sessionVariables = {
    TERMINAL = terminalApplication;
  };
}

