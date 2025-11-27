# List available recipes
default:
    @just --list

# Build the LXC container image and metadata
build-lxc:
    nix build .#lxc-image-and-metadata

# Build the Baguette (VM) compressed image
build-baguette:
    nix build .#baguette-zimage

# Run flake checks (fmt, statix, deadnix)
check:
    nix flake check

# Format all nix files using the defined formatter
fmt:
    nix fmt
