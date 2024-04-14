{ config, ... }:
{
  home.file."${config.xdg.configHome}/wofi/style.css" = {
    text = ''
      window {
        font-size: 20px;
        font-family: JetBrainsMonoNL NF;
      }
    '';
  };
}
