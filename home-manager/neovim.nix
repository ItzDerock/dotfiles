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
      clang-tools
      nil
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

    # CHANGES MADE HERE MAY REQUIRE CACHE CLEAR TO APPLY
    # rm -rf ~/.local/share/nvim/base46
    # OR :lua require("base46").compile()
    chadrcConfig = ''
      local M = {}

      M.base46 = {
        transparency = true,
        theme = "dark_horizon",

        hl_override = {
          LineNr = { fg = "#9ca0a4" },
          Comment = { fg = "#abb2bf" },
        },
      }

      M.plugins = {
        {
          "neovim/nvim-lspconfig",
          config = function()
            local lspconfig = require("lspconfig")
            local on_attach = require("nvchad.configs.lspconfig").on_attach
            local on_init = require("nvchad.configs.lspconfig").on_init
            local capabilities = require("nvchad.configs.lspconfig").capabilities

            -- List of servers to initialize automatically.
            -- Ensure the binaries are in 'extraPackages' above!
            local servers = { 
              "html", "css", 
              "bashls",
              "nixd",
              "pylsp",
              "clangd",
              "jdtls",
              "gopls",
              "nil_ls"
            }

            for _, lsp in ipairs(servers) do
              lspconfig[lsp].setup {
                on_attach = on_attach,
                on_init = on_init,
                capabilities = capabilities,
              }
            end
          end,
        },
      }

      return M
    ''; 
  };
}
