{ pkgs, inputs, ... }:
{
  imports = [
    inputs.nvchad4nix.homeManagerModule
  ];

  home.packages = with pkgs; [ 
    ripgrep 
    ripgrep-all 
    # inputs.nvchad4nix.packages."${pkgs.system}".nvchad;
  ];

  programs.nvchad = {
    enable = true;
    extraPackages = with pkgs; [
      nodePackages.bash-language-server
      nixd
      (python3.withPackages(ps: with ps; [
        python-lsp-server
      	flake8
      ]))
    ];

    hm-activation = true;
    backup = true;

    extraConfig = ''
      vim.opt.relativenumber = true
    '';

    chadrcConfig = ''
      local M = {}
      M.base46.transparency = true
      return M
    '';
  };

}
