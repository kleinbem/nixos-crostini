{
  pkgs,
  specialArgs, # Accepts customKernelPkgs
  ...
}:
{
  imports = [
    # ...
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  # ====================================================================
  # 🛡️ SECURITY CONFIGURATION (SELinux & Sudo consolidated)
  # ====================================================================

  security = {
    # SELinux Configuration
    selinux = {
      enable = true;
      # Set to 'false' (Permissive) for policy generation. Change to 'true' later.
      enforcing = false;
    };

    # Sudo Configuration
    sudo.wheelNeedsPassword = false;
  };

  # CRUCIAL: Required by SELinux to log denial events
  services.auditd.enable = true;

  # ====================================================================
  # 🚀 CUSTOM KERNEL LINKAGE
  # ====================================================================
  # Forces NixOS to use the custom kernel package set from your builder
  boot.kernelPackages = specialArgs.customKernelPkgs;

  environment.systemPackages = with pkgs; [
    wget
    btrfs-progs
    curl
    usbutils
    gnupg

    # SELinux Management Tools
    selinux-utils
    policycoreutils
    setools
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  services = {
    ollama = {
      enable = true;
      acceleration = "rocm";
    };

    pcscd.enable = true;

    udev.packages = [ pkgs.yubikey-personalization ];
  };

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

  system.stateVersion = "25.05";
}
