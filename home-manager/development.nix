{ pkgs, inputs, ... }: {
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
      nixpkgs-master.zed-editor
      jetbrains.idea-ultimate

      # cli tools
      imagemagick
      ffmpeg-full
      nodejs_20
      libsecret

      direnv
      devenv
    ];

  programs.bash = {
    enable = true;
    shellAliases = {
      "☕" = "ssh terminal.shop";
    };

    bashrcExtra = builtins.readFile ../assets/.bashrc;
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

