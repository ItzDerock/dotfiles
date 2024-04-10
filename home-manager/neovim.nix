{ pkgs, ... }: 
{
  home.packages = with pkgs; [ ripgrep ripgrep-all lunarvim ];
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
}
