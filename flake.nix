{
  description = "NixOS Configuration for Crostini and Baguette";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 1. New Input: The pre-commit hooks library
    # Using 'follows' prevents downloading a second copy of nixpkgs
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
      pre-commit-hooks, # Added here
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
      # Explicitly setting this allows me to run 'nix fmt' manually if I want to.
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      # 3. The Checks (The "Shift Left" Logic)
      # This defines the validation rules. This logic is now the "Single Source of Truth"
      # for both my local machine and the CI pipeline.
      checks = forAllSystems (system: {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            # Code Formatting (must match the formatter above)
            nixfmt-rfc-style.enable = true;

            # Linting (Check for syntax errors and anti-patterns)
            statix.enable = true;

            # Dead Code Detection (Find unused variables)
            deadnix.enable = true;
          };
        };
      });

      # 4. The DevShell (The Activator)
      # When I run 'nix develop', this shell installs the git hooks automatically.
      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
        };
      });

      # 5. Packages (Existing logic preserved)
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

      # 6. NixOS Configurations (Existing logic preserved)
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
