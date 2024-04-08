{ pkgs, ... }:
let
  imageTypes = ["png" "jpeg" "heic" "bmp" "gif"];
  
  associations = {
    "inode/directory" = ["thunar.desktop"];
  } // builtins.listToAttrs (
    map (imageType: { name = "image/${imageType}"; value = ["org.nomacs.ImageLounge.desktop"]; }) imageTypes
  );

in
{
  home.packages = with pkgs; [
    nomacs 
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
