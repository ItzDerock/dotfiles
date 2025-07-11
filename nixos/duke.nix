{ lib, pkgs, config, outputs, ... }: 
with lib;
let
  cfg = config.rockcfg.duke;
in 
{
  options.rockcfg.duke = {
    enable = mkEnableOption "Duke OIT services";

    netid = mkOption {
      type = types.str;
      example = "jbduke";
      description = "Duke NetID for ePrint authentication.";
    };
  };

  config = mkIf cfg.enable {
    # VPN support
    environment.systemPackages = with pkgs; [
      networkmanager-openconnect
    ];

    # ePrint
    services.printing.drivers = with pkgs; [
      gutenprint
      gutenprintBin 
    ];

    # define the printers
    hardware.printers.ensurePrinters = [
      { 
        name = "Duke-ePrint-BW";
        description = "Duke ePrint (B&W)";
        location = "Duke Campus";
        deviceUri = "lpd://${cfg.netid}@ep-ps-cmp3-pap1.oit.duke.edu/ePrint-OIT";
        model = "drv:///sample.drv/generic.ppd";
      }

      # { 
      #   name = "Duke-ePrint-Color-Library";
      #   description = "Duke ePrint Color (Library)";
      #   location = "Duke Libraries";
      #   deviceUri = "lpd://${cfg.netid}@ep-ps-clr2-pap1.win.duke.edu/ePrint-Color-Library";
      #   model = "gutenprint.5.3:///ricoh-afc_mp_c3501/expert";
      # }
      # 
      # { 
      #   name = "Duke-ePrint-Color-Campus";
      #   description = "Duke ePrint Color (Campus)";
      #   location = "Duke Campus";
      #   deviceUri = "lpd://${cfg.netid}@ep-ps-clr-pap1.win.duke.edu/ePrint-Color-Campus";
      #   model = "gutenprint.5.3:///sharp-mx-3500n/expert";
      # }
    ]; 
  }; 
}
