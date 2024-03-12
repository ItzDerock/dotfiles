# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./git.nix
    ./1password.nix
  ];

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
  home.packages = with pkgs; [ 
    # browser
    firefox 

    # misc
    # inputs.nixpkgs-unstable.legacyPackages."${pkgs.system}".obsidian
    ((import inputs.nixpkgs-unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    }).obsidian) 

 
    # dev tools
    vscode 
    arduino-core
    arduino-cli
    imagemagick
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

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
