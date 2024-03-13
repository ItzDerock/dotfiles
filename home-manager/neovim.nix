{ pkgs, ... }: 
{
  home.packages = with pkgs; [ ripgrep ripgrep-all ];
  programs.neovim.enable = true;
  xdg.configFile."nvim".source = pkgs.stdenv.mkDerivation {
    name = "NvChad";
    src = pkgs.fetchFromGitHub {
      owner = "NvChad";
      repo = "starter";
      rev = "9d47133ba1433b07e1ac9e32fb110851cf1d6368";
      hash = "sha256-bQdO88FsBJBcxM43cyabqua9S3gWO/i2O0PL/8ulC7Y=";
    };

    installPhase = ''
      mkdir -p $out
      cp -r ./* $out/
      cd $out/
    ''; 

    # cp -r ${./neovim-custom} $out/lua/custom
    # add ^ if custom nvchad needed
  };
}
