{ lib, pkgs, config, inputs, ... }:
with lib;
let
  cfg = config.rockcfg.power;
in {
  options.rockcfg.power = {
    enable = mkEnableOption "Enables power optimizations (targeted at laptops)";
  };

  config = mkIf cfg.enable { 
    powerManagement.enable = true;
    services.thermald.enable = true; 
    services.power-profiles-daemon.enable = true;
    services.tlp = {
      enable = false;
      settings = {
        # CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_DRIVER_OPMODE_ON_BAT="active"; # passive caps 400mhz
        CPU_SCALING_GOVERNOR_ON_BAT="powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
        PLATFORM_PROFILE_ON_BAT = "balanced";
        PLATFORM_PROFILE_ON_AC = "performance";
        RUNTIME_PM_ON_AC = "auto";
        RUNTIME_PM_ON_BAT = "auto";
        WIFI_PWR_ON_BAT = "off";
	      WIFI_PWR_ON_AC = "off";
	      NMI_WATCHDOG = "1";
      };
    };

    services.auto-cpufreq.enable = false;
    services.auto-cpufreq.settings = {
      battery = {
        governor = "powersave";
	      turbo = "auto";
      };
      charger = {
        governor = "performance";
	      turbo = "auto";
      };
    };

    # prevent docker from auto-starting
    systemd.services.docker.wantedBy = lib.mkForce [];
  };
}
