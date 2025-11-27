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
  # Only system-wide admin tools remain here. User tools moved to home.nix.
  environment.systemPackages = with pkgs; [
    wget
    btrfs-progs
    curl
    usbutils
    gnupg
  ];

  # Enable GPG agent
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    # Optional, if you use it for SSH too
    pinentryPackage = pkgs.pinentry-curses;
    # Or pinentry-qt/gtk2 depending on your taste
  };

  # Enable Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # Makes 'docker' alias to 'podman'
    defaultNetwork.settings.dns_enabled = true;
  };

  # FIXED: Grouped all services into one block.
  # This merges ollama, pcscd, and udev configurations.
  services = {
    # Enable Ollama Service (For running Meta Llama locally)
    ollama = {
      enable = true;
      acceleration = "rocm"; # Use "cuda" if you have NVIDIA, "rocm" for AMD, or remove for CPU-only
    };

    # This daemon allows the system to talk to the smart card
    pcscd.enable = true;

    # This installs the UDEV rules so the USB stick is recognized permissions-wise
    # We use the package here for its rules, even if we don't install the binary to your path
    udev.packages = [ pkgs.yubikey-personalization ];
  };

  # Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    kleinbem = {
      isNormalUser = true;
      linger = true;
      extraGroups = [
        "wheel"
        "podman"
      ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
