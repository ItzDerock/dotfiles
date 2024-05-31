{ config, pkgs, inputs, outputs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      inputs.home-manager.nixosModules.home-manager
      ../../nixos
      ./hardware-configuration.nix
    ];

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs;
      host = "galaxy";
    };
    users = {
      derock = import ../../home-manager/home.nix;
    };
  };

  # Bootloader.
  boot.initrd.luks.devices."luks-b2c00540-b801-4ae1-bb27-7f5dfaae4194".device = "/dev/disk/by-uuid/b2c00540-b801-4ae1-bb27-7f5dfaae4194";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "derock-nix"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  boot.kernel.sysctl = {
    "net.ipv4.tcp_mtu_probing" = 1;
  };

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

  # Experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.derock = {
    isNormalUser = true;
    description = "Derock";
    extraGroups = [ "networkmanager" "wheel" "dialout" "storage" ];
    packages = with pkgs; [ ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  services.tailscale.enable = true;

  dm.lemurs.enable = true;
  wm.hyprland.enable = true;

  rockcfg = {
    onepass.enable = true;
    syncthing.enable = true; 
    printing.enable = true;
    power.enable = true;
    laptop = {
      enable = true;
      soundFix = true;
    };
    wireplumber.enable = true;
    nvidia.enable = true;
    vpn.wireguard.enable = true;
    docker = {
      enable = true;
      nvidia = true;
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    tmux
    git
    powertop
    firefox
    foot

    # arduino
    # libgcc
    # libstdcxx5
    libgccjit
    #  wget

    mesa
  ];

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # battery stuff
  powerManagement.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_zen;
  boot.kernelParams = [
    # https://wiki.archlinux.org/title/Intel_graphics#Crash/freeze_on_low_power_Intel_CPUs
    "ahci.mobile_lpm_policy=1" 
  ];
  # boot.crashDump.enable = true;
  boot.extraModulePackages = 
    let 
      sgbextras = config.boot.kernelPackages.callPackage ../../pkgs/samsung-galaxybook-extras.nix { };
    in
    [ sgbextras ];

  boot.kernelModules = ["samsung-galaxybook"];
}
