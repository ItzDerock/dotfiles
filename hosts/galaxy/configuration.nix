{ config, pkgs, inputs, outputs, lib, ... }:
let
  secrets = import ../../secrets.nix;

  dsdtPatch = pkgs.runCommand "dsdt-patch.cpio" {
    nativeBuildInputs = [ pkgs.cpio ];
  } ''
    mkdir -p kernel/firmware/acpi
    cp ${../../assets/dsdt/960XFH.aml} kernel/firmware/acpi/dsdt.aml   
    find kernel | cpio -H newc -o --reproducible > $out
  '';
in
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

  hardware.enableAllFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  # Enable networking
  networking.networkmanager = {
    enable = true;
    wifi = {
      powersave = true;
      # backend = "iwd";
    };
  };

  # power saving
  boot.extraModprobeConfig = ''
    options iwlwifi power_save=1
    options iwlmvm power_scheme=3
    options iwlwifi uapsd_disable=0
  '';
  boot.kernelParams = [ "pcie_aspm=force" ];

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
  users.extraGroups.plugdev = { };
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
    greeter.enable = true;
    onepass.enable = true;
    syncthing.enable = true;
    printing.enable = true;
    power.enable = true;
    laptop = {
      enable = true;
      samsung_960XFH = true;
    };
    wireplumber.enable = true;
    nvidia.enable = true;
    vpn.wireguard.enable = true;
    instantreplay.enable = true;
    docker = {
      enable = true;
      nvidia = true;
    };
    networking.enable = true;
    network-shares.enable = true;
    embedded-dev.enable = true;

    duke = {
      enable = true;
      netid = secrets.duke-netid;
    };

    hardware = {
      sharge.enable = true;
    };
  };

  # save alsamixer
  # On SBG3, the DP audio is muted by default
  # alsamixer -> f6 -> 0 -> m to unmute (any MM)
  hardware.alsa.enablePersistence = true;

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
    btop.withoutGpu
    sbctl
  ];

  virtualisation.waydroid.enable = true;
  powerManagement.enable = true;

  # TODO: switch back to linux_zen once kernel ver 6.15 is available
  # 6.15 merges the required Samsung Galaxybook driver
  # 6.14 doesn't have, and the out-of-tree module does not support 6.14 either.
  boot = {
    kernelPackages = pkgs.linuxSamsung;

    kernelModules = [
      "v4l2loopback"
    ];

    kernel.sysctl."kernel.sysrq" = 438;
    kernel.sysctl."kernel.panic" = 60;
  };

  services.throttled.enable = true;

  # more intel stuff
  hardware.graphics = {
    extraPackages = with pkgs; [
      mesa
      intel-ocl
    ];
  };

  hardware.ipu6 = {
    enable = true;
    platform = "ipu6ep";
  };

  # Update format to YUY2
  services.v4l2-relayd.instances.ipu6 = {
    input = {
      width = 1280;
      height = 720;
      format = "nv12";
    };
  };

  boot = {
    bootspec.enableValidation = true;

    initrd = {
      systemd.enable = true;
      availableKernelModules = [ "tpm_tis" ];

      luks.devices = {
        # ROOT Partition (nvme1n1p2)
        "luks-42c869fb-4b43-44c5-97ff-136cb326054c" = {
          crypttabExtraOpts = [ "tpm2-device=auto" ];
        };

        # SWAP Partition (nvme1n1p3)
        "luks-b2c00540-b801-4ae1-bb27-7f5dfaae4194" = {
          crypttabExtraOpts = [ "tpm2-device=auto" ];
        };
      };

      # prepend = [ "${dsdtPatch}" ];
    };

    loader = {
      systemd-boot.enable = lib.mkForce false;
      grub.enable = false;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot";
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };

  services.fprintd.enable = true;
  # services.fprintd.tod.enable = true;

  system.stateVersion = "23.11"; # dont change me
}
