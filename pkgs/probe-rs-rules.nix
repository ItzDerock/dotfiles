{ lib, pkgs, ... }:
pkgs.stdenv.mkDerivation {
  name = "probe-rs-udev-rules";
  src = ../assets/probe-rs;
  
  installPhase = ''
    mkdir -p $out/lib/udev/rules.d
    cp 69-probe-rs.rules $out/lib/udev/rules.d
  '';
}

