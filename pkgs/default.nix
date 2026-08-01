# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  interactive-bg-remover = pkgs.callPackage ./interactive-bg-remover.nix { };
  kickoff-dot-desktop = pkgs.callPackage ./kickoff-dot-desktop.nix { };
  probe-rs-rules = pkgs.callPackage ./probe-rs-rules.nix { inherit pkgs; };
}
