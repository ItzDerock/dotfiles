# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  kickoff-dot-desktop = pkgs.callPackage ./kickoff-dot-desktop.nix { };
}
