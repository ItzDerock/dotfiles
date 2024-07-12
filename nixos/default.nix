{ pkgs, config, ... }: {
  imports = [
    # /etc/nixos/cachix.nix
    ./lemurs.nix
    ./wm_hyprland.nix
    ./wayland.nix
    ./nvidia.nix
    ./power.nix
    ./laptop.nix
    ./wireplumber.nix
    ./printing.nix
    ./vpn.nix
    ./docker.nix
    ./instant-replay.nix
    ./polkit.nix
    ./syncthing.nix
    ./1password.nix
  ];

  # global configuration regardless of system
  fonts.packages = with pkgs; [
    jetbrains-mono
    (nerdfonts.override {
      fonts = [
        "JetBrainsMono"
        "Iosevka"
      ];
    })
  ];

  environment.systemPackages = with pkgs; [
    cachix

    libgcc
    nix-index
    libva
    vulkan-loader
    vulkan-tools

    jq # how am i supposed to do anythign without this amazing tool
    psmisc

    appimage-run

    # https://github.com/NixOS/nixpkgs/issues/206378
    alsa-oss
    blueberry

    # additional tumbler support
    webp-pixbuf-loader # webp
    poppler_gi # adobe pdf
    evince # pdf
    ffmpegthumbnailer # videos
    ftgl # font
    libgsf # .odf
    nufraw-thumbnailer # .raw
    gnome-epub-thumbnailer # .epub, .mobi
    f3d
  ];


  home-manager.backupFileExtension = "bak";

  # auto mount USBs
  services.devmon.enable = true;
  services.udisks2 = {
    enable = true;
    settings = {
      "udisks2.conf" = {
        defaults.defaults = "rw,exec";
      };
    };
  };

  # dbus stuff
  services.upower.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # bluetooth
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experiment = true;
      };
    };
  };
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # for some reason this is how you fix vulkan..
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  # appimage
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
    magicOrExtension = ''\x7fELF....AI\x02'';
  };

  # timezone
  services.automatic-timezoned.enable = true;
  location.provider = "geoclue2";

  nix.settings.trusted-users = [ "root" "@wheel" ];
}
