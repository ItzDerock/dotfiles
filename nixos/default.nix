{ pkgs, ... }: {
  imports = [
    ./lemurs.nix
    ./wm_hyprland.nix
    ./wayland.nix
    ./nvidia.nix
    ./power.nix
    ./laptop.nix
    ./wireplumber.nix
    ./printing.nix
  ];

  # global configuration regardless of system
  fonts.packages = with pkgs; [
    jetbrains-mono
    (nerdfonts.override { fonts = [ 
      "JetBrainsMono"
      "Iosevka"
    ]; })
  ];

  environment.systemPackages = with pkgs; [
    libgcc
    nix-index
  ];

  # auto mount USBs
  services.devmon.enable = true;
  services.udisks2.enable = true;

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
}