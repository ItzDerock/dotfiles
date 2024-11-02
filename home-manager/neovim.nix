{ pkgs, ... }:
{
  home.packages = with pkgs; [ ripgrep ripgrep-all ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # programs.nixvim = {
  #   enable = true;
  #   defaultEditor = true;
  #
  # }; 
}

