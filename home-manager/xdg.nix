{ pkgs, ... }:
let
  imageTypes = ["png" "jpeg" "heic" "bmp" "gif"];
  videoTypes = [
    "mp4" "mkv" "avi" "mov" "webm" "flv" "wmv" "mpeg" "mpg" "3gp" "ogv" "ts"
  ];
  browserTypes = [
    "text/html"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/about"
    "x-scheme-handler/unknown"
  ];

  associations = {
    "inode/directory" = ["nautilus.desktop"];
    "application/zip" = ["ark.desktop"];
    "application/pdf" = ["microsoft-edge.desktop"];
  } 
  // builtins.listToAttrs (
    map (imageType: { name = "image/${imageType}"; value = ["org.nomacs.ImageLounge.desktop"]; }) imageTypes
  ) 
  // builtins.listToAttrs (
    map (videoType: { name = "video/${videoType}"; value = ["mpv.desktop"]; }) videoTypes
  )
  // builtins.listToAttrs (
    map (browserType: { name = browserType; value = ["microsoft-edge.desktop"]; }) browserTypes
  );
in
{
  home.packages = with pkgs; [
    nomacs
    mpv
  ];

  xdg = {
    enable = true;

    mimeApps = {
      enable = true;
      defaultApplications = associations;
      associations.added = associations;
    };  
  };
}

