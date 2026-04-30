{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rockcfg.workserver;

  nft = "${pkgs.nftables}/bin/nft";

  # Idempotent: tear down then re-add our isolated table
  addRules = pkgs.writeShellScript "workserver-nft-up" ''
    ${nft} delete table inet workserver-filter 2>/dev/null || true
    ${nft} -f - <<'EOF'
    table inet workserver-filter {
      chain input {
        type filter hook input priority filter;
        # allow loopback and tailscale traffic
        iifname { "lo", "tailscale0" } tcp dport { 22, 11434 } accept
        # block everything else
        tcp dport { 22, 11434 } drop
      }
    }
    EOF
  '';

  removeRules = pkgs.writeShellScript "workserver-nft-down" ''
    ${nft} delete table inet workserver-filter 2>/dev/null || true
  '';
in
{
  options.rockcfg.workserver = {
    enable = mkEnableOption "work server mode (SSH + Ollama over Tailscale)";

    ollamaOrigins = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "CORS origins allowed to reach Ollama from a browser. Empty blocks all cross-origin browser access.";
      example = [ "http://localhost:3000" ];
    };
  };

  config = mkIf cfg.enable {
    # SSH
    services.openssh = {
      enable = true;
      openFirewall = false;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Ensure sshd only starts after the nftables filter is in place
    systemd.services.sshd = {
      after = [ "workserver-nftables.service" ];
      requires = [ "workserver-nftables.service" ];
    };

    # Ollama
    services.ollama = {
      enable = true;
      host = "0.0.0.0";
      port = 11434;
    };

    # Bind to all interfaces; nftables below restricts to tailscale0
    systemd.services.ollama = {
      after = [
        "workserver-nftables.service"
        "tailscaled.service"
      ];
      requires = [
        "workserver-nftables.service"
        "tailscaled.service"
      ];
      environment.OLLAMA_ORIGINS = concatStringsSep "," cfg.ollamaOrigins;
    };

    # Network filter - adds a single nftables table, doesn't clobber existing rules (docker etc.)
    systemd.services.workserver-nftables = {
      description = "Workserver nftables filter (SSH+Ollama → tailscale0 only)";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "tailscaled.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = addRules;
        ExecStop = removeRules;
        ExecReload = addRules;
      };
    };

    # Holds a systemd sleep inhibitor so the machine never suspends while the
    # work server is active. Monitor sleep (DPMS) is unaffected; hypridle handles that.
    systemd.services.workserver-inhibit-sleep = {
      description = "Inhibit system sleep for work server";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=sleep --who=workserver --why='SSH and Ollama are active' --mode=block ${pkgs.coreutils}/bin/sleep infinity";
      };
    };

    # gaming.target
    systemd.targets.gaming = {
      description = "Gaming mode – work server suspended";
      unitConfig.StopWhenUnneeded = "yes";
    };

    # Also stops the sleep inhibitor during gaming so the system can sleep if AFK mid-game.
    systemd.services.gaming-workserver = {
      description = "Suspend work server services during gaming mode";
      unitConfig = {
        PartOf = "gaming.target";
        After = "gaming.target";
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStart = "${pkgs.systemd}/bin/systemctl stop sshd ollama workserver-inhibit-sleep";
        ExecStop = "${pkgs.systemd}/bin/systemctl start sshd ollama workserver-inhibit-sleep";
      };
      wantedBy = [ "gaming.target" ];
    };

    # Allow wheel users to toggle gaming.target without a password prompt.
    # Needed because gamemode hooks run as the user, not root.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        var managed = ["gaming.target", "gaming-workserver.service"];
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            managed.indexOf(action.lookup("unit")) !== -1 &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';

    # Gamemode hooks
    programs.gamemode = {
      enable = true;
      settings.custom = {
        start = "${pkgs.systemd}/bin/systemctl start gaming.target";
        end = "${pkgs.systemd}/bin/systemctl stop gaming.target";
      };
    };
  };
}
