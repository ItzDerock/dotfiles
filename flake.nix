{
  description = "Your new nix config";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      # "https://cuda-maintainers.cachix.org"
      "https://devenv.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      # "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];

    trustedUsers = [
      "root"
      "@wheel"
      "derock"
    ];
  };

  inputs = {
    self.submodules = true;

    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager = {
      # unstable
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # - HYPRLAND STUFF
    hyprland = {
      url = "github:hyprwm/Hyprland/v0.57.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprpicker.url = "github:hyprwm/hyprpicker";

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins/v0.57.0";
      inputs.hyprland.follows = "hyprland";
    };

    # Not loaded: upstream still needs a Hyprland v0.57 API port.
    Hyprspace = {
      url = "github:KZDKM/Hyprspace";
      inputs.hyprland.follows = "hyprland";
    };

    hyprsplit = {
      url = "github:shezdy/hyprsplit";
      # Only the Lua module is used; do not import another Hyprland dependency graph.
      flake = false;
    };

    hyprqt6engine = {
      url = "github:hyprwm/hyprqt6engine";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprexpo = {
      # hyprland-git revision verified by upstream CI against Hyprland v0.57.0.
      url = "github:sandwichfarm/hyprexpo/1db341b523dd833fa6d0f3dde26f17005977b669";
      inputs.hyprland.follows = "hyprland";
    };

    # Shell
    caelestia = {
      # url = "github:caelestia-dots/shell";
      url = "path:./external/caelestia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      # Qt 6.12 QObject metatype fix: https://github.com/quickshell-mirror/quickshell/pull/1002
      inputs.quickshell.url = "git+https://git.outfoxxed.me/outfoxxed/quickshell?rev=5d5d49873fe8cf1f99ddfd5006ceb2057c5c9b13";
    };

    # cursor theme
    rose-pine-hyprcursor.url = "github:ndom91/rose-pine-hyprcursor";

    # nixvim
    nixvim = {
      url = "github:nix-community/nixvim";
      # input.nixpkgs.follows = "nixpkgs";
    };

    nix4nvchad = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix";

    # Secrets w/ 1password
    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Browser
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    omp = {
      url = "github:can1357/oh-my-pi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    backplane = {
      url = "github:ItzDerock/backplane-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # kernel
    cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    wshowkeys = {
      url = "github:DreamMaoMao/wshowkeys";
      inputs.nixpkgs.follows = "nixpkgs"; # optional
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      # Supported systems for your flake packages, shell, etc.
      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      # This is a function that generates an attribute by calling a function you
      # pass to it, with each system as an argument
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # Your custom packages
      # Accessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      # Formatter for your nix files, available through 'nix fmt'
      # Other options beside 'alejandra' include 'nixpkgs-fmt'
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        galaxy = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/galaxy/configuration.nix
            inputs.stylix.nixosModules.stylix
            inputs.opnix.nixosModules.default
            inputs.lanzaboote.nixosModules.lanzaboote
          ];
        };

        supernova = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/supernova/configuration.nix
            inputs.stylix.nixosModules.stylix
            inputs.opnix.nixosModules.default
            inputs.lanzaboote.nixosModules.lanzaboote
          ];
        };

        nebula = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/nebula/configuration.nix
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            inputs.stylix.nixosModules.stylix
          ];
        };
      };
    };
}
