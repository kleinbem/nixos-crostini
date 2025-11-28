{
  config,
  pkgs,
  inputs,
  ...
}: # Accepts 'inputs'
{
  # ---------------------------------------------------------------------
  # Core Home Manager Configuration
  # ---------------------------------------------------------------------
  home = {
    username = "kleinbem";
    homeDirectory = "/home/kleinbem";
    stateVersion = "25.05";
    enableNixpkgsReleaseCheck = false;

    sessionVariables = {
      EDITOR = "nvim";
      PROJECTS = "${config.home.homeDirectory}/Develop";
    };

    # User-specific packages
    packages = with pkgs; [
      neovim
      gh
      gemini-cli
      bitwarden-cli
      ptyxis
      yubioath-flutter
      yubikey-manager
      mods
      claude-code
      vscode-fhs
      distrobox
      ripgrep
      htop
      podman-compose
      pass
      just
      fzf
    ];
  };

  # ---------------------------------------------------------------------
  # Programs
  # ---------------------------------------------------------------------
  programs = {
    home-manager.enable = true;
    bash = {
      enable = true;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    git = {
      enable = true;
      settings = {
        user = {
          name = "kleinbem";
          email = "martin.kleinberger@gmail.com";
        };
        push = {
          autoSetupRemote = true;
        };
        init = {
          defaultBranch = "main";
        };
      };
    };

    # 🌟 NEW: Declarative Flatpak Integration (via nix-flatpaks)
    flatpak = {
      enable = true;
      inherit (inputs.nix-flatpaks) portals;

      remotes = [
        "https://dl.flathub.org/repo/flathub.flatpakrepo"
      ];

      # Declare your applications here
      packages = [
        { id = "com.github.Pithos.Pithos"; } # Example application
      ];
    };
  };
}
