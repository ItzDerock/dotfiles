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

      vimPlugins.kanagawa-nvim
    ];

    hm-activation = true;
    backup = true;

    extraConfig = ''
      vim.opt.relativenumber = true
    '';

    chadrcConfig = ''
      local M = {}
      M.base46.transparency = true
      M.ui.theme = "kanagawa"
      return M
    '';

    extraPlugins = ''
      return {
        {
          "rebelot/kanagawa.nvim",
          lazy = false,
          priority = 1000,
          config = function ()
            -- local dragon_theme = require("kanagawa.colors").setup({
            --   theme = "dragon"
            -- }).theme
            -- 
            -- dragon_theme.ui.bg_gutter = "none"

            require("kanagawa").setup({
              transparent = true,
              colors = {
                theme = {
                  all = {
                    ui = { bg_gutter = "none" }
                  },
                },
              },
            })

            vim.cmd("colorscheme kanagawa")
            vim.api.nvim_create_autocmd("VimEnter", {
              pattern = "*",
              callback = function()
                vim.cmd("colorscheme kanagawa")
              end,
            })
          end,
        },
      }
    '';
  };
}
