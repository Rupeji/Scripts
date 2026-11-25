#!/bin/bash
# Loadout KineticWE para Arch Linux (equivalente al script de Fedora)
set -euo pipefail

VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
NC='\033[0m'

KINETICWE_FPR="FD258A99CDC5F61B04A335EEE163D34B273AE987"
KINETICWE_KEY_URL="https://theblackdon.gitlab.io/kineticwe/kineticwe.gpg"
KINETICWE_SERVER='https://theblackdon.gitlab.io/kineticwe/$arch'
DOTFILES_REPO="https://github.com/Rupeji/Fedora"
ASSETS_REPO="https://github.com/Rupeji/IconsWalls"

die()  { echo -e "${ROJO}Error: $*${NC}" >&2; exit 1; }
paso() { echo -e "\n${VERDE}$*${NC}"; }
info() { echo -e " -> $*"; }

# --- Validaciones iniciales ---
if [ "$EUID" -ne 0 ]; then
  echo -e "${AMARILLO}Ejecuta este script con sudo:${NC}"
  echo "sudo $0"
  exit 1
fi

USUARIO="${SUDO_USER:-}"
if [ -z "$USUARIO" ] || [ "$USUARIO" = "root" ]; then
  die "Ejecuta el script con sudo desde tu usuario normal."
fi
USER_HOME="$(getent passwd "$USUARIO" | cut -d: -f6)"
[ -d "$USER_HOME" ] || die "No existe el home de $USUARIO."
command -v pacman >/dev/null || die "Este script es para Arch Linux."

AUR_HELPER=""
for h in paru yay; do
  if command -v "$h" >/dev/null 2>&1; then AUR_HELPER="$h"; break; fi
done

TMP_DOTS="$(mktemp -d)"
TMP_ASSETS="$(mktemp -d)"
trap 'rm -rf "$TMP_DOTS" "$TMP_ASSETS"' EXIT

clear
echo -e "${AZUL}=====================================================${NC}"
echo -e "    LOADOUT PERSONALIZADO: ARCH + KINETICWE + DOTFILES"
echo -e "${AZUL}=====================================================${NC}"

INSTALAR_NVIDIA=false
echo -e "\n${AMARILLO}¿Instalar drivers NVIDIA (nvidia-open para el kernel CachyOS)? (s/n)${NC}"
read -r -p "-> " resp
if [[ "$resp" =~ ^[Ss]$ ]]; then INSTALAR_NVIDIA=true; fi

# Instala paquetes: los de repos oficiales con pacman, el resto desde AUR como $USUARIO
instalar() {
  local oficiales=() aur=() p
  for p in "$@"; do
    if pacman -Si "$p" >/dev/null 2>&1; then
      oficiales+=("$p")
    else
      aur+=("$p")
    fi
  done
  if [ "${#oficiales[@]}" -gt 0 ]; then
    pacman -S --needed "${oficiales[@]}"
  fi
  if [ "${#aur[@]}" -gt 0 ]; then
    [ -n "$AUR_HELPER" ] || die "No están en repos oficiales y no hay paru ni yay: ${aur[*]}"
    info "Compilando desde AUR con $AUR_HELPER: ${aur[*]}"
    sudo -u "$USUARIO" "$AUR_HELPER" -S --needed "${aur[@]}"
  fi
}

# Copia el contenido de un directorio y guarda los archivos sobrescritos como ~
copiar_dir() {
  [ -d "$1" ] || return 0
  mkdir -p "$2"
  cp -rTb "$1" "$2"
}

# --- [1/8] Repositorio KineticWE ---
paso "[1/8] Configurando el repositorio de KineticWE..."
if ! grep -q '^\[kineticwe\]' /etc/pacman.conf; then
  clave="$(mktemp)"
  curl -fL "$KINETICWE_KEY_URL" -o "$clave"
  huella="$(gpg --show-keys --with-colons "$clave" | awk -F: '/^fpr:/ {print $10; exit}')"
  if [ "$huella" != "$KINETICWE_FPR" ]; then
    rm -f "$clave"
    die "La huella de la clave es $huella, no $KINETICWE_FPR. No se ha instalado nada."
  fi
  pacman-key --add "$clave"
  pacman-key --lsign-key "$KINETICWE_FPR"
  rm -f "$clave"
  cp /etc/pacman.conf /etc/pacman.conf.bak
  printf '\n[kineticwe]\nServer = %s\n' "$KINETICWE_SERVER" >> /etc/pacman.conf
  info "Repositorio añadido. Copia de seguridad: /etc/pacman.conf.bak"
else
  info "El repositorio [kineticwe] ya existe en pacman.conf."
fi

# --- [2/8] Sincronización y requisitos ---
paso "[2/8] Sincronizando repositorios y comprobando requisitos..."
pacman -Sy
grep -q '^\[multilib\]' /etc/pacman.conf || die "Activa [multilib] en /etc/pacman.conf (lo necesita Steam) y vuelve a ejecutar."
pacman -Si linux-cachyos >/dev/null 2>&1 || die "No encuentro linux-cachyos. Añade el repositorio [cachyos] a /etc/pacman.conf y vuelve a ejecutar."
pacman -Syu

# --- [3/8] KineticWE y aplicaciones base ---
paso "[3/8] Instalando KineticWE y herramientas del sistema..."
instalar kineticwe kineticwe-greeter xdg-desktop-portal-kwe \
         firefox fastfetch kitty fish loupe gnome-text-editor \
         mediawriter luciole 7zip git tar starship flatpak
if pacman -Qq alacritty >/dev/null 2>&1; then
  pacman -Rns alacritty
fi

# --- [4/8] Dotfiles y configuración del usuario ---
paso "[4/8] Descargando dotfiles y desplegando configuración en $USER_HOME..."
git clone --depth 1 "$DOTFILES_REPO" "$TMP_DOTS/repo" || die "No se pudo clonar $DOTFILES_REPO."
BUILD="$TMP_DOTS/repo/build_files"
RECURSOS="$BUILD/recursos"
DOTS="$BUILD/dotfiles"
[ -d "$DOTS" ] || die "No encuentro build_files/dotfiles en el repositorio."

CONFIG="$USER_HOME/.config"
mkdir -p "$CONFIG"
for d in kitty fish kineticwe niri noctalia-kwe luciole gtk-3.0 gtk-4.0 qt5ct qt6ct; do
  copiar_dir "$DOTS/$d" "$CONFIG/$d"
done
if [ -f "$DOTS/starship/starship.toml" ]; then
  cp -b "$DOTS/starship/starship.toml" "$CONFIG/starship.toml"
fi
copiar_dir "$DOTS/color-schemes" "$USER_HOME/.local/share/color-schemes"

# Portales de KineticWE
mkdir -p "$CONFIG/xdg-desktop-portal"
printf '[preferred]\ndefault=gtk\n' > "$CONFIG/xdg-desktop-portal/kineticwe-portals.conf"
cp "$CONFIG/xdg-desktop-portal/kineticwe-portals.conf" "$CONFIG/xdg-desktop-portal/portals.conf"

chown -R "$USUARIO:$USUARIO" "$CONFIG"
[ -d "$USER_HOME/.local/share/color-schemes" ] && chown -R "$USUARIO:$USUARIO" "$USER_HOME/.local/share/color-schemes"

# --- [5/8] Kernel CachyOS y optimizaciones ---
paso "[5/8] Kernel CachyOS y planificadores de rendimiento..."
PAQUETES_KERNEL=(linux-cachyos linux-cachyos-headers cachyos-settings
                 scx-scheds scx-tools ananicy-cpp cachyos-ananicy-rules zram-generator)
if [ "$INSTALAR_NVIDIA" = true ]; then
  PAQUETES_KERNEL+=(linux-cachyos-nvidia-open nvidia-utils lib32-nvidia-utils libva-nvidia-driver libva-utils)
fi
instalar "${PAQUETES_KERNEL[@]}"

info "Configurando scx_lavd en modo Gaming..."
mkdir -p /etc/scx_loader
cat > /etc/scx_loader/config.toml <<'EOF'
default_sched = "scx_lavd"
default_mode = "Gaming"
EOF

for u in scx_loader.service ananicy-cpp.service; do
  if systemctl list-unit-files "$u" | grep -q "$u"; then
    systemctl enable "$u"
  else
    info "No existe la unidad $u. Revisa qué paquete la instala."
  fi
done

info "Configurando ZRAM (zstd, máximo 16 GB) y parámetros de memoria..."
cat > /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram, 16384)
compression-algorithm = zstd
EOF

cat > /etc/sysctl.d/99-memoria.conf <<'EOF'
vm.swappiness = 150
vm.page-cluster = 0
vm.vfs_cache_pressure = 50
EOF
sysctl --system >/dev/null

# --- [6/8] Gaming, comunicación y multimedia ---
paso "[6/8] Aplicaciones de juegos, comunicación y multimedia..."
instalar discord protonplus steam mangohud gamescope \
         gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav ffmpeg

# --- [7/8] Iconos, wallpapers, tipografías y cursores ---
paso "[7/8] Descargando activos (IconsWalls) y tipografías..."
git clone --depth 1 "$ASSETS_REPO" "$TMP_ASSETS/repo" || die "No se pudo clonar $ASSETS_REPO."
ASSETS="$TMP_ASSETS/repo"
mkdir -p "$USER_HOME/Imágenes" "$USER_HOME/.config/noctalia/activos"

if [ -d "$ASSETS/Wallpapers" ]; then
  info "Copiando Wallpapers..."
  cp -r "$ASSETS/Wallpapers" "$USER_HOME/Imágenes/"
fi
if [ -d "$ASSETS/Iconos" ]; then
  info "Copiando Iconos..."
  cp -r "$ASSETS/Iconos" "$USER_HOME/Imágenes/"
  cp "$ASSETS/Iconos/Bazzite_Logo.png" "$USER_HOME/.config/noctalia/activos/" 2>/dev/null || true
fi
chown -R "$USUARIO:$USUARIO" "$USER_HOME/Imágenes" "$USER_HOME/.config/noctalia"

instalar ttf-jetbrains-mono-nerd
fc-cache -f >/dev/null

if [ -f "$RECURSOS/Tela-icon-theme.tar.gz" ]; then
  info "Instalando iconos Tela..."
  tar -xzf "$RECURSOS/Tela-icon-theme.tar.gz" -C "$TMP_DOTS"
  if [ -f "$TMP_DOTS/Tela-icon-theme/install.sh" ]; then
    bash "$TMP_DOTS/Tela-icon-theme/install.sh" -d /usr/share/icons >/dev/null
  fi
fi

mkdir -p /usr/share/icons
for f in Bibata-Modern-Classic.tar.xz Bibata-Modern-Ice.tar.xz; do
  if [ -f "$RECURSOS/$f" ]; then
    info "Descomprimiendo $f..."
    tar -xf "$RECURSOS/$f" -C /usr/share/icons/
  fi
done

# --- [8/8] NVIDIA, Bambu Studio e initramfs ---
paso "[8/8] Drivers NVIDIA, Bambu Studio e initramfs..."
if [ "$INSTALAR_NVIDIA" = true ]; then
  info "Activando KMS para NVIDIA (necesario para Wayland)..."
  cat > /etc/modprobe.d/nvidia-kms.conf <<'EOF'
options nvidia_drm modeset=1 fbdev=1
EOF
fi

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.bambulab.BambuStudio
flatpak update -y

info "Regenerando initramfs para todos los kernels..."
mkinitcpio -P

# --- CIERRE ---
echo -e "\n${AZUL}=====================================================${NC}"
echo -e "            PROCESO DE INSTALACIÓN TERMINADO"
echo -e "${AZUL}=====================================================${NC}"
echo -e "${VERDE}Revisa que tu gestor de arranque tenga la entrada de linux-cachyos.${NC}"
echo -e "${VERDE}Reinicia con: sudo reboot${NC}"
