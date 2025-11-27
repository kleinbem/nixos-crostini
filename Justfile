# Run the interactive menu (requires fzf)
default:
    @just --choose

# Build the LXC container image and metadata
build-lxc:
    nix build .#lxc-image-and-metadata

# Build the Baguette (VM) compressed image
build-baguette:
    nix build .#baguette-zimage

# Copy the baguette image to ChromeOS Downloads
install-baguette: build-baguette
    @echo "Copying image to ChromeOS Downloads..."
    cp -f result/baguette_rootfs.img.zst /mnt/chromeos/MyFiles/Downloads/
    @echo "Done. Run 'vmc create ...' in crosh."

# Run flake checks (fmt, statix, deadnix)
check:
    nix flake check

# Dry-run the system build to catch errors fast
dry-run:
    nix build .#nixosConfigurations.baguette-nixos.config.system.build.toplevel --dry-run

# Format all nix files
fmt:
    nix fmt

# Update flake inputs
update:
    nix flake update

# Clean up build artifacts
clean:
    rm -rf result result-*