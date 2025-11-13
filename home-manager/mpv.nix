{ pkgs, ... }:
let
  scriptPath = ".config/mpv/scripts/open-in-losslesscut.sh";
  scriptContent = ''
    #!${pkgs.bash}/bin/bash
    
    # Get absolute paths to our tools from the Nix store
    LOSSLESSCUT="${pkgs.losslesscut-bin}/bin/losslesscut"
    WL_COPY="${pkgs.wl-clipboard}/bin/wl-copy"
    
    # Arguments passed from mpv
    FILE_PATH="$1"
    TIMESTAMP="$2"
    
    if [ -z "$FILE_PATH" ]; then
        exit 1
    fi
    
    nohup "$LOSSLESSCUT" "$FILE_PATH" > /dev/null 2>&1 & 
    echo -n "$TIMESTAMP" | "$WL_COPY"
  '';

in
{
  home.packages = with pkgs; [
    losslesscut-bin
    wl-clipboard
    mpv
  ];

  programs.mpv = {
    enable = true;
    
    extraInput = ''
      L run "$HOME/${scriptPath}" "''${path}" "''${playback-time}"
    '';
  };

  home.file."${scriptPath}" = {
    text = scriptContent;
    executable = true;
  };
}
