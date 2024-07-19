{ config, inputs, outputs, pkgs, lib, ... }:
let
  homeConfig = import ../../home-manager/home.nix {
    inherit config pkgs inputs outputs lib;
    host = "nebula";
  };
in
{
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      ../../nixos
    ];

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs;
      host = "nebula";
    };

    # users = {
    #   nixos = import ../../home-manager/home.nix;
    #   nixos.home.username = lib.mkForce "nixos";
    #   nixos.home.homeDirectory = lib.mkForce "/home/nixos";
    # };
    users.nixos = lib.recursiveUpdate
      homeConfig
      {
        home = {
          username = lib.mkForce "nixos";
          homeDirectory = lib.mkForce "/home/nixos";
        };
      };
  };

  # Experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nebula"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraGroups.plugdev = { };
  users.users.nixos = {
    isNormalUser = true;
    description = "NixOS default user";
    extraGroups = [ "networkmanager" "wheel" "dialout" "plugdev" ];
    packages = with pkgs; [ ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;

  wm.hyprland.enable = true;

  rockcfg = {
    printing.enable = true;
    wireplumber.enable = true;
    instantreplay.enable = true;
    docker.enable = true;
    nvidia = {
      enable = true;
      primary = true;
    };
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
  boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_zen;
}
