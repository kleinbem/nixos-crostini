# ChromeOS VM Kernel Builder

A Nix-based toolkit to build custom kernels for ChromeOS Crostini and Baguette containers, enabling support for Waydroid (Binder/Ashmem).

## Prerequisites
* **Share Downloads:** Open the ChromeOS "Files" app, right-click **Downloads**, and select **"Share with Linux"**. This allows you to easily copy the final kernel to ChromeOS.

## Quick Start

1.  **Enter the Environment:**
    ```bash
    nix develop
    ```

2.  **Build Everything (Automated):**
    This single command clones the repo, configures it (copying your running system config), enables Waydroid drivers, and builds the kernel.
    ```bash
    just build
    ```
    * *Artifact location:* `./out/bzImage`

## Advanced Usage

If you need to debug or change specific settings, you can run steps individually:

* **Prepare Configuration Only:**
    Runs the setup and applies Waydroid flags without starting the long compile process.
    ```bash
    just config
    ```

* **Interactive Menu:**
    Opens the text-based kernel configuration menu (ncurses) to manually toggle drivers.
    ```bash
    just menuconfig
    ```

* **Clean Artifacts:**
    Removes compiled objects to force a rebuild of changed files.
    ```bash
    just clean
    ```

* **Factory Reset (Nuke):**
    Completely deletes the `kernel/` and `out/` directories to start fresh.
    ```bash
    just nuke
    ```

## Installation (How to Boot)

Once the build finishes:

1.  **Copy the kernel to Windows/ChromeOS:**
    ```bash
    cp out/bzImage /mnt/chromeos/MyFiles/Downloads/bzImage-waydroid
    ```

2.  **Boot (On ChromeOS Host):**
    Open Crosh (`Ctrl+Alt+T`) and run:
    ```bash
    vmc stop baguette
    vmc start --vm-type BAGUETTE --kernel /home/chronos/user/MyFiles/Downloads/bzImage-waydroid baguette
    ```
    