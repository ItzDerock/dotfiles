{ lib, pkgs, config, outputs, ... }: 
with lib;
let
  cfg = config.rockcfg.hardware.sharge;
in 
{
  options.rockcfg.hardware.sharge = {
    enable = mkEnableOption "Sharge disk fixes";
  };

  config = mkIf cfg.enable {
    # disable autosuspend to fix drops
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2d01", ATTR{idProduct}=="d709", ATTR{power/autosuspend}="-1"
    '';

    # allow exec mount from sharge disk
    environment.etc."udisks2/mount_options.conf".text = ''
      [defaults]
      defaults=noexec,rw,nosuid,nodev,noatime
      allow=exec,noexec,nodev,nosuid,atime,noatime,nodiratime,ro,rw,sync,dirsync,noload

      # ATLAS (Btrfs)
      [/dev/disk/by-uuid/5e222bf6-e9ff-496e-9a41-3af44eb4f1b5]
      allow=exec,nodev,nosuid,atime,noatime,nodiratime,ro,rw,sync,dirsync,noload,compress,ssd,space_cache,subvolid,subvol
      defaults=exec,rw,nosuid,nodev,noatime,compress=zstd

      # HERMES (ExFAT)
      [/dev/disk/by-uuid/61D2-BA36]
      allow=exec,nodev,nosuid,atime,noatime,nodiratime,ro,rw,sync,dirsync,noload,uid,gid,fmask,dmask,iocharset,errors
      defaults=exec,rw,nosuid,nodev,noatime,uid=1000,gid=100
    '';
  };
}
