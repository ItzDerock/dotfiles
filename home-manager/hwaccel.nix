# Fixes hardware accel for differnet apps
{ ... }: {
  xdg.configFile."mpv/mpv.conf".text = ''
    hwdec=auto-safe
    vo=gpu
    profile=gpu-hq
    gpu-context=wayland
  '';
}
