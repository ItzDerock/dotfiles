{ config, inputs, outputs, pkgs, lib, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      inputs.home-manager.nixosModules.home-manager
      ../../nixos
      ./hardware-configuration.nix
    ];

  home-manager = {
    extraSpecialArgs = { 
      inherit inputs outputs; 
      host = "supernova";
    };

    users = {
      derock = import ../../home-manager/home.nix;
    };
  };

  # Experimental features
  nix.settings.experimental-features = ["nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "derock-desktop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Kentucky/Louisville";

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
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraGroups.plugdev = { };
  users.users.derock = {
    isNormalUser = true;
    description = "Derock";
    extraGroups = [ "networkmanager" "wheel" "dialout" "plugdev" ];
    packages = with pkgs; [];
  };

  # Enable automatic login for the user.
  services.getty.autologinUser = "derock";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
 
  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "client";
 
  dm.lemurs.enable = true;
  wm.hyprland.enable = true;
  rockcfg = {
    printing.enable = true;
    power.enable = false;
    laptop.enable = false;
    wireplumber.enable = true;
    instantreplay.enable = true;
    nvidia = {
      enable = true;
      primary = true;
    };
  };

  # drives
  fileSystems."/mnt/LARGESHIT" = {
   device = "/dev/disk/by-uuid/82542B4F542B44EF";
   fsType = "ntfs";
   options = ["users" "nofail" "x-gvfs-show"];
  };

  fileSystems."/mnt/speedy" = {
    device = "/dev/disk/by-uuid/9856F4B056F48FEC";
    fsType = "ntfs";
    options = ["users" "nofail" "x-gvfs-show" "exec" "uid=1000" "gid=100" "dmask=007" "fmask=117"];
    # options = ["nofail" "rw" "suid" "dev" "exec" "auto" "nouser" "async" "relatime"];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma6.enable = true;
}
