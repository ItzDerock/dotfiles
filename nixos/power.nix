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
    services.thermald.enable = true; # borken
    services.tlp = {
      enable = true;
      settings = {
	# CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        # CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
        PLATFORM_PROFILE_ON_BAT = "low-power";
        PLATFORM_PROFILE_ON_AC = "performance";
        RUNTIME_PM_ON_AC = "auto";
	RUNTIME_PM_ON_BAT = "auto";
        WIFI_PWR_ON_BAT = "on";
	WIFI_PWR_ON_AC = "on";
	NMI_WATCHDOG = "1";
      };
    };

    services.auto-cpufreq.enable = true;
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
