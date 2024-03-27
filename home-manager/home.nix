# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  host,
  ...
}: { 
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./git.nix 
    ./1password.nix
    ./neovim.nix
  ] ++ (if host == "supernova" then [./overrides/supernova.nix] else []); 

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
  home.packages = let 
    unstable = (import inputs.nixpkgs-unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    });
  in with pkgs; [ 
    # browser
    firefox 

    # desktop apps
    xfce.thunar
    xfce.thunar-volman

    # misc
    unstable.obsidian

    # social media 
    # (unstable.discord.override {
    #   withOpenASAR = true;
    #   withVencord = true;
    # })

    # gaymin
    steam
    unstable.wine-wayland
    unstable.prismlauncher
    unstable.gamescope
    bottles

    unstable.vesktop # screenshare audio
 
    # dev tools
    nodejs_21
    vscode 
    unstable.arduino-ide

    arduino-core
    arduino-cli
    imagemagick
    cura
    ffmpeg-full

    unzip
    audacity
    yt-dlp
    obs-studio 
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

  programs.bash.enable = true;
  programs.starship = {
    enable = true;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
