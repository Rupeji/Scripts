#!/bin/bash

echo "=== 0. Actualizar el sistema ==="
# Actualizar el sistema
sudo dnf upgrade --refresh

echo "=== 1. Activando el repositorio oficial de Don ==="
sudo dnf5 copr enable theblackdon/kwee -y

echo "=== 2. Instalando KineticWE, Noctalia, el Greeter y Kitty ==="
sudo dnf5 install kineticwe kineticwe-greeter firefox fastfetch kitty -y

sudo dnf remove alacritty -y

## Fedora 45 Nvidia ##
sudo dnf install kernel-devel kernel-headers gcc make dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig libxcb egl-wayland -y

# drivers url

https://es.download.nvidia.com/XFree86/Linux-x86_64/615.78.08/NVIDIA-Linux-x86_64-615.78.08.run

su

./NVIDIA-Linux-x86_64-615.78.08.run

sudo dracut --force --regenerate-all

reboot


sudo dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

sudo dnf discord protonplus steam mangohud gamescope 


# Cachy kernel

sudo dnf copr enable bieszczaders/kernel-cachyos -y

sudo dnf install kernel-cachyos kernel-cachyos-devel-matched -y

sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg


#Mantenimiento
sudo dnf ditro-sync
sudo dnf update --refresh
sudo dnf5 autoremove -y
