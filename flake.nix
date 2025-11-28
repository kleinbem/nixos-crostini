{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 🌟 NEW: Input for your custom kernel builder
    kernel-builder = {
      url = "path:./kleinbem/chromeos-vm-kernel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 🌟 NEW: Input for nix-flatpaks
    nix-flatpaks = {
      url = "github:nix-community/nix-flatpaks";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixos-generators,
      nixpkgs,
      home-manager,
      self,
      kernel-builder, # Added
      nix-flatpaks, # Added
      ...
    }@inputs:
    let
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        # 🌟 NEW: Add the nix-flatpaks module
        nix-flatpaks.nixosModules.nix-flatpaks
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.kleinbem = import ./home.nix;
            # Pass all inputs to home.nix
            extraSpecialArgs = { inherit inputs nix-flatpaks; };
          };
        }
      ];

      targetSystem = "x86_64-linux";

      # Define the custom kernel package set
      customKernelPkgs = kernel-builder.packages.${targetSystem}.default;

      # Pass the custom kernel package set as a special argument
      specialArgs = {
        inherit inputs customKernelPkgs;
      };

      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];

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
