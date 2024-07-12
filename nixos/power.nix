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
    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
	CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        # CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_power";
        PLATFORM_PROFILE_ON_BAT = "low-power";
        PLATFORM_PROFILE_ON_AC = "performance";
        RUNTIME_PM_ON_AC = "auto";
        WIFI_PWR_ON_BAT = "on";
      };
    };
  };
}
