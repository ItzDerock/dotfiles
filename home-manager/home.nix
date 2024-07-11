# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ inputs
, outputs
, lib
, config
, pkgs
, host
, ...
}: 
let
  quick-record-script = pkgs.writeScriptBin "quick-record" (builtins.readFile ../assets/scripts/quick-record.sh); 
in
{
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./git.nix
    ./1password.nix
    ./neovim.nix
    ./xdg.nix
    ./wofi.nix
    ./theme.nix
  ] ++ (if host == "supernova" then [ ./overrides/supernova.nix ] else [])
    ++ (if host == "galaxy" then [ ./overrides/galaxy.nix ] else []);

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = "derock";
    homeDirectory = "/home/derock";
  };

  # Add stuff for your user as you see fit:
  home.packages =
    let
      nixpkgs-master = (import inputs.nixpkgs-master {
        system = "x86_64-linux";
        config.allowUnfree = true;
      });
    in
    with pkgs; [
      # browser (i am indecisive)
      # floorp
      google-chrome
      firefox
      vivaldi
      vivaldi-ffmpeg-codecs
      brave

      # file browser 
      xfce.thunar
      xfce.thunar-volman
      xfce.thunar-archive-plugin # unzip
      xfce.thunar-media-tags-plugin
      xfce.tumbler # dbus thumbnailer
      cinnamon.nemo-with-extensions
      kdePackages.ark # zip

      # other apps
      mpv
      obsidian
      inkscape-with-extensions
      leela
      handbrake

      # social media 
      # using webcord over official discord and vesktop cus it just works flawlessly with wayland.
      # normal discord just doesnt work (black screen)
      # vesktop is buggy af (and no krisp support)
      # this checks all the boxes
      webcord
      discord

      # gaymin
      steam
      nixpkgs-master.wineWowPackages.waylandFull
      prismlauncher
      nixpkgs-master.gamescope
      bottles
      lutris

      # dev tools
      nodejs_20
      vscode
      nixpkgs-master.zed-editor
      imagemagick
      # cura
      ffmpeg-full
      nodejs_20
      devenv

      unzip
      audacity
      yt-dlp
      obs-studio
      blender

      jetbrains.idea-ultimate
      libsecret

      quick-record-script
      zoom-us
      # nixpkgs-master.vmware-workstation
    ];

  # my cfg stuff
  rockcfg = {
    onepass.enable = true;
    git.enable = true;
  };

  # Enable home-manager and git
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      "☕" = "ssh terminal.shop";
    };

    bashrcExtra = builtins.readFile ../assets/.bashrc;
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    options = ["--cmd cd"];
  };
  programs.starship = {
    enable = true;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
