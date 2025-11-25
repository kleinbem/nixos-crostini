# Originally taken from:
# https://github.com/Misterio77/nix-starter-configs/blob/cd2634edb7742a5b4bbf6520a2403c22be7013c6/minimal/nixos/configuration.nix
# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  # inputs,
  # lib,
  # config,
  pkgs,
  ...
}:
{
  imports = [
    # You can import other NixOS modules here.
    # You can also split up your configuration and import pieces of it here:
    # ./users.nix
  ];

  # Enable flakes: https://nixos.wiki/wiki/Flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  # Search for additional packages here: https://search.nixos.org/packages
  environment.systemPackages = with pkgs; [
    neovim
    git
    btrfs-progs
    gemini-cli
    bitwarden-cli
    ptyxis
    yubioath-flutter
    yubikey-manager
    mods
    ollama
    claude-code
    vscode-fhs
  ];

  # Enable Ollama Service (For running Meta Llama locally)
  services.ollama = {
    enable = true;
    acceleration = "rocm"; # Use "cuda" if you have NVIDIA, "rocm" for AMD, or remove for CPU-only
  };



  # This daemon allows the system to talk to the smart card
  services.pcscd.enable = true;

  # This installs the UDEV rules so the USB stick is recognized permissions-wise
  # We use the package here for its rules, even if we don't install the binary to your path
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # Enable Direnv (loads .envrc files automatically)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    kleinbem = {
      isNormalUser = true;
      linger = true;
      extraGroups = [ "wheel" ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
