{ pkgs, inputs, ... }: let
  bash_preexec = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/rcaloras/bash-preexec/refs/heads/master/bash-preexec.sh";
    sha256 = "NF3hp2fF+rEp4tOhuPpAD4lW2AS+xdd/agN9965AZa8=";
    executable = true;
  };
in {
  home.packages =
    let
      nixpkgs-master = (import inputs.nixpkgs-master {
        system = pkgs.system;
        config.allowUnfree = true;
      });
    in
    with pkgs; [
      # include some scripting languages for ease
      nodejs_20
      nodePackages.pnpm
      bun
      python3

      # code editors
      vscode
      nixpkgs-master.zed-editor.fhs

      # cli tools
      imagemagick
      ffmpeg-full
      nodejs_20
      libsecret

      direnv
      devenv

      # terminals
      fish
    ];

  programs.bash = {
    enable = true;
    shellAliases = {
      "☕" = "ssh terminal.shop";
      "zed" = "zeditor -n";
    };

    bashrcExtra = (builtins.readFile ../assets/.bashrc) + ''
      # bash-preexec
      source ${bash_preexec}
    '';
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    options = [ "--cmd cd" ];
  };

  programs.starship = {
    enable = true;
  };

  # devenv
  services.lorri.enable = true;
}
