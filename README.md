# Gentoo-gnu-linux-installation-script
Just some badly written bash scripts to install Gentoo linux

## Hints
###  NOT EVERYTHING IS TESTED!
    for example: dockerserver profile
###  TESTED:
    minimal install
    desktop install
  
###  PROFILES:
    uses systemd and distkernel
    minimal: Equivalent to base and base-devel package on archlinux + some extras
    server: minimal profile + pipewire, docker and nginx (not tested)
      server docker: minimal profile + pipewire and nginx in docker (not tested)
    desktop: minimal profile + gnome-desktop, pipewire and flatpak
  
## How to use
###  Prepare
    1. Copy files to USB Storage device
    2. Boot in to any ISO image that has or can be installed to 'arch-install-scripts' for arch-chroot and genfstab
    3. Copy the script over to the live system (recommended) or skip this step

###  Configure and install
    1. Edit the gentoo_config-install_vVERSION.sh file.
    2. make sure everything is configured correctly
    3. Run `bash gentoo_config-install_vVERSION.sh`
    4. Lean back and relax (hopefully).
