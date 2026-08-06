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
    services.power-profiles-daemon.enable = false;
    services.system76-scheduler.enable = true;
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

    services.tuned = {
      enable = true;

      # ppdSupport defaults to true, which means tuned picks its profile from
      # this map rather than from `recommend` -- without it the profiles below
      # are defined but never selected (tuned lands on vendored
      # "balanced-battery" and the gt_max_freq_mhz caps never apply).
      #
      # `profiles` is the on-AC map; `battery` overrides it on DC. Only the
      # battery entry uses intel-balanced-power, since it includes the
      # balanced-battery base which has no business running on AC.
      ppdSettings = {
        profiles = {
          power-saver = "intel-powersave";
          balanced = "balanced";
          performance = "throughput-performance";
        };

        battery.balanced = "intel-balanced-power";
      };

      # RAPL note: firmware leaves the MSR package domain effectively unlimited
      # (PL1 200W / PL2 115W), so the binding limit is the MMIO domain at
      # 45W/60W -- too high for battery, and enough to hold TSR1 over the 48C
      # EC fan trip indefinitely. Clamping the MSR path below MMIO makes it the
      # effective limit, since the hardware honours min(MSR, MMIO). tuned
      # restores the firmware values when the profile is deactivated, so this
      # stays scoped to battery without needing a separate daemon.
      profiles = {
        intel-powersave = {
          main = {
            include = "powersave";
          };

          sysfs = {
            # "/sys/bus/pci/devices/0000:00:02.0/drm/card*/gt_min_freq_mhz" = 300;
            "/sys/bus/pci/devices/0000:00:02.0/drm/card*/gt_max_freq_mhz" = 400;
            "/sys/bus/pci/devices/0000:00:02.0/drm/card*/gt_boost_freq_mhz" = 500;

            "/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw" = 15000000;
            "/sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw" = 30000000;
          };
        };

        intel-balanced-power = {
          main = {
            include = "balanced-battery";
          };

          sysfs = {
            "/sys/bus/pci/devices/0000:00:02.0/drm/card*/gt_max_freq_mhz" = 800;
            "/sys/bus/pci/devices/0000:00:02.0/drm/card*/gt_boost_freq_mhz" = 800;

            "/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw" = 20000000;
            "/sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw" = 35000000;
          };
        };
      };
    };

    # prevent docker from auto-starting
    systemd.services.docker.wantedBy = lib.mkForce [];
  };
}
