{ config, pkgs, inputs, outputs, lib, ... }:
# let
#     quartusPrime = ../../assets/quartus;
#     quartusEnv = pkgs.buildEnv {
#       name = "quartus-prime-lite-env";
#       paths = [ pkgs.quartus-prime-lite quartusPrime ];
#     };
#   in
{
  imports =
    [
      # Include the results of the hardware scan.
      inputs.home-manager.nixosModules.home-manager
      inputs.windscribe-bin.nixosModules.default
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
  networking.hostName = "derock-nix"; # Define your hostname.

  # Enable networking
  hardware.enableAllFirmware = true;
  networking.networkmanager = {
    enable = true;
    wifi = {
      powersave = false;
      # backend = "iwd";
    };
  };

  services.windscribe.enable = true;

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
    isNormalUser = true; description = "Derock";
    extraGroups = [ "networkmanager" "wheel" "dialout" "storage" "plugdev" "windscribe" ];
    packages = with pkgs; [ ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  services.tailscale.enable = true;
  services.flatpak.enable = true;

  # dm.lemurs.enable = true;
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
    instantreplay.enable = true;
    docker = {
      enable = true;
      nvidia = true;
    };
    network-shares.enable = true;
    embedded-dev.enable = true;
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
    libgccjit
    mesa
    linuxPackages.v4l2loopback
  ];

  virtualisation.waydroid.enable = true;
  powerManagement.enable = true;

  # TODO: switch back to linux_zen once kernel ver 6.15 is available
  # 6.15 merges the required Samsung Galaxybook driver
  # 6.14 doesn't have, and the out-of-tree module does not support 6.14 either.
  boot.kernelPackages = pkgs.linuxSamsung;

  boot.kernelModules = [
    "v4l2loopback"
  ];

  boot.kernel.sysctl."kernel.sysrq" = 438;

  # Auto reboot if system locks up
  boot.kernel.sysctl."kernel.panic" = 60;
  systemd.watchdog.runtimeTime = "30s";

  # more intel stuff
  hardware.graphics = {
    extraPackages = with pkgs; [
      mesa
      intel-ocl
    ];
  };

  boot.loader = {
    systemd-boot.enable = false;
    grub.enable = true;
    grub.device = "nodev";
    grub.useOSProber = true;
    grub.efiSupport = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot";

    # dsdt patches
    grub.extraFiles = {
      "samsung_acpi_patch.aml" = "${../../assets/dsdt/960XFH.aml}";
    };
    grub.extraConfig = ''
      acpi /samsung_acpi_patch.aml
    '';
  };


  system.stateVersion = "23.11"; # dont change me
}
