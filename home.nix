{ config, pkgs, ... }:

{
  # ---------------------------------------------------------------------
  # Core Home Manager Configuration
  # ---------------------------------------------------------------------
  home = {
    username = "kleinbem";
    homeDirectory = "/home/kleinbem";

    # Should match your system stateVersion
    stateVersion = "25.05";

    # Fixes the "mismatched versions" warning (since you are on unstable)
    enableNixpkgsReleaseCheck = false;

    # BEST PRACTICE:
    # We use 'config' here to reference the homeDirectory defined above.
    # This satisfies the linter and keeps paths dynamic.
    sessionVariables = {
      EDITOR = "nvim";
      # Example: A variable for your development folder
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
    ];
  };

  # ---------------------------------------------------------------------
  # Programs
  # ---------------------------------------------------------------------
  programs = {
    # Let Home Manager manage itself
    home-manager.enable = true;

    # Direnv Configuration
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Git Configuration
    git = {
      enable = true;
      # Keeping your specific settings structure
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
  };
}
