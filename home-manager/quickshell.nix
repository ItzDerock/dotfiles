{ config, inputs, pkgs, ... }: {
  home.packages = with pkgs; [
    (inputs.quickshell.packages."${pkgs.system}".default.override {
      withJemalloc = true;
      withQtSvg = true;
      withWayland = true;
      withX11 = true;
      withPipewire = true;
      withPam = true;
      withHyprland = true;
    })

    (inputs.caelestia-scripts.packages."${pkgs.system}".caelestia)

    # dependencies for caelestia-dots
    git
    curl
    jq
    material-symbols
    ibm-plex
    fd
    nerd-fonts.jetbrains-mono
    material-design-icons # for material-symbols
    ibm-plex
    jetbrains-mono
  ];

  xdg.configFile = {
    quickshell = {
      # source = config.lib.file.mkOutOfStoreSymlink ../assets/quickshell;
      source = ../assets/quickshell;
      recursive = true;
    };
  };

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell UI";
      After = "graphical-session.target";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "%h/.config/quickshell/run.fish";
      Restart = "on-failure";
      Slice = "app-graphical.slice";
    };
  };
}
