#!/bin/bash


# Actualizar el sistema
sudo dnf upgrade --refresh

sudo dnf5 copr enable theblackdon/kwee -y


sudo dnf5 install kineticwe kineticwe-greeter firefox fastfetch kitty fish loupe gnome-text-editor mediawriter nemo nemo-fileroller -y

sudo dnf remove alacritty -y

## Fedora 45 Nvidia ##
sudo dnf install kernel-devel kernel-headers gcc make dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig libxcb egl-wayland -y

# drivers url

https://es.download.nvidia.com/XFree86/Linux-x86_64/615.78.08/NVIDIA-Linux-x86_64-615.78.08.run

su

chmod +x NVIDIA-Linux-x86_64-615.78.08.run

./NVIDIA-Linux-x86_64-615.78.08.run

sudo dracut --force --regenerate-all

reboot


sudo dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

sudo dnf install discord protonplus steam mangohud gamescope 


# Cachy kernel

sudo dnf copr enable bieszczaders/kernel-cachyos -y

sudo dnf install kernel-cachyos kernel-cachyos-devel-matched -y

sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg


#Mantenimiento
sudo dnf ditro-sync
sudo dnf update --refresh
sudo dnf5 autoremove -y
