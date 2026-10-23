{ pkgs, inputs, lib, ... }: let
  bash_preexec = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/rcaloras/bash-preexec/refs/heads/master/bash-preexec.sh";
    sha256 = "NF3hp2fF+rEp4tOhuPpAD4lW2AS+xdd/agN9965AZa8=";
    executable = true;
  };
  nixpkgs-master = import inputs.nixpkgs-master {
    system = pkgs.system;
    config.allowUnfree = true;
  };
  kicadConfigVersion = "${lib.versions.major nixpkgs-master.kicad.version}.0";
  kicadTheme = pkgs.fetchurl {
    url = "https://gist.githubusercontent.com/i2cjak/a3d8e7365f80c32ffb022b12ce37bbd1/raw/790b56de6e7602a8fe38f1991e30f5b12adf5e72/american-embedded-dark.json";
    hash = "sha256-9SOVrJ2QUfg7WMeWllsnHUaUi91owxC6p0dOmEVmqWY=";
  };
in {
  home.packages =
    with pkgs; [
      # include some scripting languages for ease
      nodejs
      pnpm
      bun
      python3

      # code editors
      vscode-fhs
      # nixpkgs-master.zed-editor.fhs
      zed-editor.fhs

      # cli tools
      imagemagick
      ffmpeg-full
      libsecret

      devenv

      # pcb design
      nixpkgs-master.kicad

      # terminals
      fish

      # lsps
      nil
      ccls
  
      # rf
      gnuradio
      sdrangel

      # reverse engineering
      ghidra-scaled # ghidra + uiScale=2, via overlays/default.nix
    ];

  xdg.configFile."kicad/${kicadConfigVersion}/colors/american-embedded-dark.json".source =
    kicadTheme;

  programs = {
    bash = {
      enable = true;
      shellAliases = {
        "☕" = "ssh terminal.shop";
        "zed" = "zeditor -n";
        "cat" = "bat";
      };

      bashrcExtra = (builtins.readFile ../assets/.bashrc) + ''
        # bash-preexec
        source ${bash_preexec}

        # source
        source ${../assets/scripts/tssh.sh}
      '';
    };

    eza = {
      enable = true;
      enableBashIntegration = true;
      git = true;
      icons = "auto";
    };

    bat = {
      enable = true;
      config = {
        pager = "";
      };
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      options = [ "--cmd cd" ];
    };

    starship = {
      enable = true;
    };

    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    omp = {
      enable = true;
    };
  };
}
