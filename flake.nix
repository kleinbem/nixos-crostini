{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Added Home Manager input
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixos-generators,
      nixpkgs,
      home-manager,
      self,
      ...
    }@inputs:
    let
      # We inject Home Manager into the modules list here so it applies
      # to both lxc-nixos and baguette-nixos automatically.
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          # FIXED: Grouped all home-manager settings into one block
          # This satisfies statix and keeps things organized.
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.kleinbem = import ./home.nix;
            # Pass flake inputs to home.nix
            extraSpecialArgs = { inherit inputs; };
          };
        }
      ];
      # https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-flake-and-module-system
      specialArgs = { inherit inputs; };
      # https://ayats.org/blog/no-flake-utils
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      targetSystem = "x86_64-linux";

    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
      packages = forAllSystems (system: rec {
        lxc = nixos-generators.nixosGenerate {
          inherit system specialArgs modules;
          format = "lxc";
        };
        lxc-metadata = nixos-generators.nixosGenerate {
          inherit system specialArgs modules;
          format = "lxc-metadata";
        };

        lxc-image-and-metadata = nixpkgs.legacyPackages.${system}.stdenv.mkDerivation {
          name = "lxc-image-and-metadata";
          dontUnpack = true;

          installPhase = ''
            mkdir -p $out
            ln -s ${lxc-metadata}/tarball/*.tar.xz $out/metadata.tar.xz
            ln -s ${lxc}/tarball/*.tar.xz $out/image.tar.xz
          '';
        };

        baguette-tarball = self.nixosConfigurations.baguette-nixos.config.system.build.tarball;
        baguette-image = self.nixosConfigurations.baguette-nixos.config.system.build.btrfsImage;
        baguette-zimage = self.nixosConfigurations.baguette-nixos.config.system.build.btrfsImageCompressed;

        default = self.packages.${system}.lxc-image-and-metadata;
      });

      # This allows you to re-build the container from inside the container.
      nixosConfigurations.lxc-nixos = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = modules ++ [ self.nixosModules.crostini ];
        system = targetSystem;
      };

      nixosConfigurations.baguette-nixos = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        system = targetSystem;
        modules = modules ++ [ self.nixosModules.baguette ];
      };

      nixosModules = rec {
        crostini = ./crostini.nix;
        baguette = ./baguette.nix;
        default = crostini;
      };

      templates.default = {
        path = self;
        description = "nixos-crostini quick start";
      };
    };
}
