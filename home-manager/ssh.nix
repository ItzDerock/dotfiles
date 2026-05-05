{ lib, config, ... }:
{
  # Workaround for https://github.com/nix-community/home-manager/issues/322
  # Replaces the ~/.ssh/config symlink with a real 0600 file after activation,
  # so openssh's permission check passes inside FHS user envs (vscode, android-studio, etc.).
  config = lib.mkIf config.programs.ssh.enable {
    home.file.".ssh/config".force = true;

    home.activation.fixSshPermissions = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run install -d -m 0700 "$HOME/.ssh"
      if [ -L "$HOME/.ssh/config" ]; then
        src="$(readlink -f "$HOME/.ssh/config")"
        run rm -f "$HOME/.ssh/config"
        run install -m 0600 "$src" "$HOME/.ssh/config"
      fi
    '';
  };
}
