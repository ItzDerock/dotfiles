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
  screenshot = pkgs.writeScriptBin "screenshot" (builtins.readFile ../assets/scripts/screenshot.sh);

  # vesktop fork with replaced shaggy.gif so its not weird
  customVesktop = pkgs.vesktop.overrideAttrs (oldAttrs: {
    postPatch = ''
      ${oldAttrs.postPatch or ""}
      cp ${../assets/vesktop/loading.gif} static/shiggy.gif
    '';
  });
in
{
  imports = [
    ./hyprland.nix
    ./hypridle.nix
    ./waybar.nix
    ./git.nix
    ./1password.nix
    ./neovim.nix
    ./xdg.nix
    ./wofi.nix
    ./theme.nix
    ./development.nix
    ./hwaccel.nix
    ./winapps.nix
    ./mpv.nix

    inputs.opnix.homeManagerModules.default
  ] ++ (if host == "supernova" then [ ./overrides/supernova.nix ] else [ ])
  ++ (if host == "galaxy" then [ ./overrides/galaxy.nix ] else [ ]);

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
        system = pkgs.system;
        config.allowUnfree = true;
      });
    in
    with pkgs; [
      # browser (i am indecisive)
      google-chrome
      firefox
      microsoft-edge
      inputs.zen-browser.packages."${pkgs.system}".default

      # file browser
      nautilus
      kdePackages.ark # zip
      kdePackages.dolphin
      kdePackages.kio
      kdePackages.kio-fuse
      kdePackages.kio-extras
      kdePackages.qtsvg

      # basic desktop apps
      kdePackages.kate
      kdePackages.gwenview

      # other apps
      mpv
      obsidian
      inkscape-with-extensions
      leela
      handbrake

      # social media
      customVesktop
      nixpkgs-master.thunderbird # need >145 for Exchange

      # gaymin
      steam
      mangohud
      wineWowPackages.waylandFull
      prismlauncher
      gamescope
      bottles
      lutris

      # vpn
      v2raya

      unzip
      yt-dlp
      obs-studio

      zoom-us

      # slicer stuff
      prusa-slicer

      # my scripts
      quick-record-script
      screenshot
      satty # screenshot deps

      # productivity
      libreoffice-qt6
      hunspell
      hunspellDicts.en_US
      zotero
      localsend

      comma
    ];

  # my cfg stuff
  rockcfg = {
    onepass.enable = true;
    git.enable = true;
  };

  # Enable home-manager and git
  programs.home-manager.enable = true;
  services.kdeconnect.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # make fonts work
  fonts.fontconfig.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
