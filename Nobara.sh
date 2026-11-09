#!/bin/bash
# Script definitivo de optimización extrema para Nobara (DNF5)
# Fusiona la limpieza de Nobara KDE con la purga avanzada de Bazzite

echo "=== 1. Activando el repositorio oficial de Don ==="
sudo dnf5 copr enable theblackdon/kwee -y

echo "=== 2. Instalando KineticWE, Noctalia, el Greeter y Kitty ==="
sudo dnf5 install kineticwe kineticwe-greeter kitty -y

echo "=== 3. Lanzando purga masiva del sistema (KDE + Bazzite Bloat + Impresoras + Intel) ==="
sudo dnf5 remove \
  plasma-workspace "plasma-*" "kde-*" sddm sddm-kcm dolphin konsole okular ark spectacle kcalc okular \
  gwenview elisa kontainer kalarm kolourpaint krecorder kmail neochat krfb krdc kfind kwrite kcmshell \
  plasma-systemsettings plasma-breeze breeze-gtk glibc-all-langpacks \
  lutris waydroid waydroid-selinux waydroid-nvidia waydroid-nvidia-selinux input-remapper cardwire \
  terra-mangohud bazzite-portal bazzite-updater msedit \
  "fcitx5*" "ibus*" mariadb mariadb-server mariadb-common mariadb-connector-c \
  intel-gmmlib intel-igc intel-igc-libs intel-mediasdk intel-opencl intel-opencl-clang intel-vaapi-driver intel-vpl-gpu-rt libva-intel-media-driver \
  intel-lpmd thermald intel-gpu-firmware intel-npu-firmware intel-vsc-firmware \
  bluez-cups braille-printer-app c2esp cups cups-browsed cups-client cups-filters cups-filters-driverless cups-ipptool dymo-cups-drivers ghostscript ghostscript-tools-fontutils ghostscript-tools-printing gutenprint gutenprint-cups gutenprint-libs hplip hplip-common hplip-libs ipp-usb libcupsfilters libieee1284 libppd libsane-airscan libsane-hpaio mpage paps plasma-print-manager plasma-print-manager-libs printer-driver-brlaser ptouch-driver python3-cups sane-airscan sane-backends sane-backends-drivers-cameras sane-backends-drivers-scanners sane-backends-libs splix system-config-printer-libs system-config-printer-udev uld \
  fprintd fprintd-pam libfprint espeak-ng espeak-ng-data orca brltty fedora-ea-notification "abrt*" \
  blender obs-studio kdenlive inkscape libreoffice \
  -y

echo "=== 4. Limpieza profunda de paquetes huérfanos ==="
sudo dnf5 autoremove -y

echo "=========================================================="
echo "¡Tu Nobara ha sido purgada al extremo con éxito!"
echo "Tu terminal ligera es Kitty. Entorno KineticWE inyectado."
echo "Por favor, reinicia tu ordenador para aplicar los cambios."
echo "=========================================================="
