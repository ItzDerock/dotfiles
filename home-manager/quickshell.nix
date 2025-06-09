{ inputs, pkgs, ... }: {
  home.packages = [
    (inputs.quickshell.packages."${pkgs.system}".default.override {
      withJemalloc = true;
      withQtSvg = true;
      withWayland = true;
      withX11 = true;
      withPipewire = true;
      withPam = true;
      withHyprland = true;
    })
  ];
}
