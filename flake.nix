{
  description = "NixOS Configuration for Crostini and Baguette";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 1. New Input: The pre-commit hooks library
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-generators,
      pre-commit-hooks,
      ...
    }@inputs:
    let
      modules = [ ./configuration.nix ];
      specialArgs = { inherit inputs; };

      targetSystem = "x86_64-linux";

      # Helper to generate attributes for multiple systems
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
      ];
    in
    {
      # 2. The Formatter
      # Allows you to run 'nix fmt' manually
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      # 3. The Checks (Shift Left Logic)
      # These run in CI (via nix flake check) and locally (via nix develop)
      checks = forAllSystems (system: {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            # Code Formatting
            # We use the standard 'nixfmt' hook but force the specific RFC-style package
            nixfmt = {
              enable = true;
              package = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
            };

            # Linting (Syntax & Anti-patterns)
            statix.enable = true;

            # Dead Code Detection
            deadnix.enable = true;
          };
        };
      });

      # 4. The DevShell
      # Run 'nix develop' to automatically install these hooks to .git/hooks
      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
        };
      });

      # 5. Packages (Your original logic)
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

      # 6. NixOS Configurations (Your original logic)
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
