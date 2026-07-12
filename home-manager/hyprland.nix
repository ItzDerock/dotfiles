{
  lib,
  inputs,
  pkgs,
  config,
  outputs,
  ...
}:
let
  cursorTheme = inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default;
  caelestia = inputs.caelestia.packages.${pkgs.system}.default;
  caelestia-cli = inputs.caelestia.inputs.caelestia-cli.packages.${pkgs.system}.default;
  hyprlandReload = ''
    for instance in /run/user/$(id -u)/hypr/*/; do
      [ -S "$instance/.socket.sock" ] || continue
      HYPRLAND_INSTANCE_SIGNATURE=$(basename "$instance") \
        ${inputs.hyprland.packages.${pkgs.system}.hyprland}/bin/hyprctl reload || true
    done
  '';
in
{
  # programs.bash.profileExtra = ''
  #   [ "$(tty)" = "/dev/tty1" ] && ! pgrep Hyprland >/dev/null && exec Hyprland &> /dev/null
  # '';

  systemd.user.sessionVariables = config.home.sessionVariables;

  home.packages = with pkgs; [
    # shell
    caelestia-cli
    caelestia

    swww
    foot
    (grimblast.override {
      hyprpicker = inputs.hyprpicker.packages.${pkgs.system}.hyprpicker;
    })
    playerctl

    adwaita-icon-theme
    libnotify

    # theme
    hyprcursor # cursor cursorTheme
    rose-pine-cursor

    cliphist # clipboard
    inputs.hyprpicker.packages.${pkgs.system}.hyprpicker # color picker + freeze screen
    annotator # editor
    kooha # video recorder

    # launcher
    kickoff
    outputs.packages.${pkgs.system}.kickoff-dot-desktop

    # display window
    nwg-displays
  ];

  services.network-manager-applet.enable = true;

  home.sessionVariables = {
    GDK_SCALE = "1";
    QT_SCALE_FACTOR = "1";
    QT_SCREEN_SCALE_FACTORS = "1;1";
    BROWSER = "zen";
    SUDO_EDITOR = "${pkgs.neovim}/bin/nvim";
    EDITOR = "${pkgs.neovim}/bin/nvim";
    WLR_NO_HARDWARE_CURSORS = "1";

    # enable wayland for stuff
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";

    # Disable QT window decoration
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

    # cursor
    HYPRCURSOR_THEME = "rose-pine-hyprcursor";
    HYPRCURSOR_SIZE = "18";
    XCURSOR_SIZE = "18";
    XCURSOR_THEME = "rose-pine-cursor";
  };

  programs.waybar = {
    enable = true;
  };

  # cursor
  home.file.".local/share/icons/rose-pine-hyprcursor".source =
    "${cursorTheme}/share/icons/rose-pine-hyprcursor/";

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    # use Hyprland package from the NixOS module (nixos/wm_hyprland.nix)
    package = null;
    portalPackage = null;

    # make dbus activation inherit all variables
    systemd.variables = [ "--all" ];

    plugins = [
      # WIN + TAB, show all workspaces
      pkgs.hyprexpo-plus
    ];

    settings = { };

    extraConfig = ''require("hyprland-user")'';
  };

  # HM only auto-reloads Hyprland when its own generated config changes, so
  # reload manually whenever these deployed files change. Discovers the
  # instance via the runtime dir since activation may run without session env
  # (e.g. nixos-rebuild).
  home.file.".config/hypr/hyprland-user.lua" = {
    source = ../assets/hyprland.lua;
    onChange = hyprlandReload;
  };

  home.file.".config/hypr/clamshell.lua" = {
    source = ../assets/clamshell.lua;
    onChange = hyprlandReload;
  };

  home.file.".config/hypr/hyprsplit/init.lua".source = "${inputs.hyprsplit}/init.lua";

  home.activation.createMonitorsLua = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/hypr/monitors.lua" ]; then
      run mkdir -p "$HOME/.config/hypr"
      run touch "$HOME/.config/hypr/monitors.lua"
    fi
  '';

  # caelestia shell systemd unit
  systemd.user.services.caelestia = {
    Unit = {
      Description = "Caelestia Shell Hyprland";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${caelestia}/bin/caelestia-shell";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
