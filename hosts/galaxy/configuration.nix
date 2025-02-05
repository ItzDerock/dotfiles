{ config, pkgs, inputs, outputs, ... }:
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
    isNormalUser = true; description = "Derock";
    extraGroups = [ "networkmanager" "wheel" "dialout" "storage" ];
    packages = with pkgs; [ ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  services.tailscale.enable = true;

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_zen;
  boot.extraModulePackages =
    let
      sgbextras = config.boot.kernelPackages.callPackage ../../pkgs/samsung-galaxybook-extras.nix { };
    in
    [ sgbextras ];

  boot.kernelModules = [ "samsung-galaxybook" "v4l2loopback" ];
  
  # Temporary fix - linux-surface/linux-surface #1516
  # boot.blacklistedKernelModules = [ "intel-ipu6" "intel-ipu6-isys" ];

  boot.kernelPatches = [
  #   {
  #     name = "samsung-galaxy-sound";
  #     patch = ../../assets/kernel/samsung-galaxy-audio.patch;
  #   }
	  {
	    name = "intel-ipu6-fix";
      patch = builtins.fetchurl {
        url = "https://lore.kernel.org/stable/20241209175416.59433-1-stanislaw.gruszka@linux.intel.com/raw";
        sha256 = "sha256:0h8gnmr029mknp7fv001hbq6cjdmsrmk18khqry4iv7xaw7nhjcy";
	    };
    }
  ];

  boot.kernel.sysctl."kernel.sysrq" = 438;

  # Auto reboot if system locks up
  boot.kernel.sysctl."kernel.panic" = 60;
  systemd.watchdog.runtimeTime = "30s";

  # more intel stuff
  hardware.graphics = {
    extraPackages = with pkgs; [
      mesa.drivers
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
  };
}
