{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.dm.lemurs;
in {
  options.dm.lemurs= {
    enable = mkEnableOption "Enables Lemurs DisplayManager";
  };

  config = mkIf cfg.enable {
    # programs.lemurs.enable = true;
    environment.systemPackages = [ pkgs.lemurs ];
  };
}
