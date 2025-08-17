{ ... }:
let
  secrets = import ../../secrets.nix;
in
{
  # Custom firefox wrapper that runs it on dGPU
  xdg.desktopEntries.firefox-discrete = {
    name = "Firefox Discrete";
    genericName = "Web Browser";
    exec = "nvidia-offload firefox %U";
    terminal = false;
    categories = [ "Application" "Network" "WebBrowser" ];
    mimeType = [ "text/html" "text/xml" ];
  };

  # configure winapps
  rockcfg.winapps = {
    enable = true;
    rdp_password = secrets.winapps.rdp_password;
  };

  wayland.windowManager.hyprland = {
    plugins = [
      # Separate workspaces per monitor
      inputs.hyprsplit.packages.${pkgs.system}.hyprsplit
    ];
  };
}
