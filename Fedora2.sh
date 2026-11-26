#!/bin/bash
set -euo pipefail   # [MEJORA] Detiene el script ante cualquier error

# Colores para la interfaz en la terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
NC='\033[0m'

# Validar privilegios de administrador (SUDO) antes de empezar
if [ "$EUID" -ne 0 ]; then
  echo -e "${AMARILLO}Por favor, ejecuta este script usando 'sudo':${NC}"
  echo "sudo $0"
  exit 1
fi

clear
echo -e "${AZUL}=====================================================${NC}"
echo -e "    LOADOUT PERSONALIZADO: FEDORA + NVIDIA + DOTFILES "
echo -e "${AZUL}=====================================================${NC}"

INSTALAR_NVIDIA=false

# --- MENÚ DE SELECCIÓN DE HARDWARE ---
echo -e "\n${AMARILLO}¿Deseas los drivers de NVIDIA a tu instalación? (s/n):${NC}"
read -p "-> Instalar controlador akmod-nvidia (RPM Fusion): " resp
if [[ "$resp" =~ ^[Ss]$ ]]; then INSTALAR_NVIDIA=true; fi

# --- PROCESAMIENTO E INSTALACIÓN ---
echo -e "\n${AZUL}=====================================================${NC}"
echo -e "              INICIANDO INSTALACIÓN                  "
echo -e "${AZUL}=====================================================${NC}"

# Paso 1: Actualización profunda
echo -e "\n${VERDE}[1/9] Limpiando caché y actualizando los repositorios y el sistema...${NC}"
dnf clean metadata
dnf upgrade --refresh -y

# Paso 2: Configuración de Repositorios
echo -e "\n${VERDE}[2/9] Configurando repositorios adicionales...${NC}"
dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo -e "${AZUL}Habilitando RPM Fusion para soporte de NVIDIA...${NC}"
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
               https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

dnf copr enable theblackdon/kwee -y
dnf copr enable bieszczaders/kernel-cachyos -y
dnf copr enable bieszczaders/kernel-cachyos-addons -y
dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release terra-gpg-keys -y
dnf makecache --refresh

# Paso 3: Instalación de aplicaciones del sistema
echo -e "\n${VERDE}[3/9] Instalando herramientas del sistema y utilidades...${NC}"
dnf5 install kineticwe kineticwe-greeter firefox fastfetch kitty fish loupe gnome-text-editor mediawriter luciole 7zip git tar -y
dnf remove alacritty -y

# Paso 4: Clonar repositorio para dotfiles/recursos
echo -e "\n${VERDE}[4/9] Descargando dotfiles y recursos desde bazzite-kinetic en GitHub...${NC}"
DIR_TMP_KINETIC="/tmp/git_bazzite_kinetic_setup"
rm -rf "$DIR_TMP_KINETIC"

# [MEJORA] URLs limpias, sin ofuscación con espacios
URL_KINETIC="https://github.com/Rupeji/Fedora"

if git clone --depth 1 "$URL_KINETIC" "$DIR_TMP_KINETIC"; then
    DIR_SOURCE_BUILD="$DIR_TMP_KINETIC/build_files"
    DIR_RECURSOS="$DIR_SOURCE_BUILD/recursos"
    DIR_DOTFILES_ORIGEN="$DIR_SOURCE_BUILD/dotfiles"
    USER_HOME="/home/inhumano"

    if [ -f "$DIR_RECURSOS/starship" ]; then
        echo " -> Inyectando Starship Prompt..."
        cp "$DIR_RECURSOS/starship" /usr/bin/starship
        chmod 755 /usr/bin/starship
    fi

    if [ -f "$DIR_RECURSOS/gslapper.rpm" ]; then
        echo " -> Instalando paquete local gslapper.rpm mediante dnf5..."
        dnf5 -y install "$DIR_RECURSOS/gslapper.rpm"
    fi

    if [ -d "$DIR_DOTFILES_ORIGEN" ]; then
        echo " -> Desplegando quirúrgicamente dotfiles en tu HOME ($USER_HOME)..."
        mkdir -p "$USER_HOME/.config"/{kitty,fish,kineticwe,niri,noctalia-kwe,luciole,gtk-3.0,gtk-4.0,qt5ct,qt6ct}

        [ -f "$DIR_DOTFILES_ORIGEN/kitty/kitty.conf" ] && cp "$DIR_DOTFILES_ORIGEN/kitty/kitty.conf" "$USER_HOME/.config/kitty/kitty.conf"
        [ -f "$DIR_DOTFILES_ORIGEN/fish/config.fish" ] && cp "$DIR_DOTFILES_ORIGEN/fish/config.fish" "$USER_HOME/.config/fish/config.fish"
        [ -f "$DIR_DOTFILES_ORIGEN/starship/starship.toml" ] && cp "$DIR_DOTFILES_ORIGEN/starship/starship.toml" "$USER_HOME/.config/starship.toml"

        [ -d "$DIR_DOTFILES_ORIGEN/kineticwe" ] && cp -r "$DIR_DOTFILES_ORIGEN/kineticwe"/* "$USER_HOME/.config/kineticwe/" 2>/dev/null || true
        [ -d "$DIR_DOTFILES_ORIGEN/niri" ] && cp -r "$DIR_DOTFILES_ORIGEN/niri"/* "$USER_HOME/.config/niri/" 2>/dev/null || true
        [ -d "$DIR_DOTFILES_ORIGEN/noctalia-kwe" ] && cp -r "$DIR_DOTFILES_ORIGEN/noctalia-kwe"/* "$USER_HOME/.config/noctalia-kwe/" 2>/dev/null || true
        [ -d "$DIR_DOTFILES_ORIGEN/luciole" ] && cp -r "$DIR_DOTFILES_ORIGEN/luciole"/* "$USER_HOME/.config/luciole/" 2>/dev/null || true
        [ -d "$DIR_DOTFILES_ORIGEN/gtk-3.0" ] && cp -r "$DIR_DOTFILES_ORIGEN/gtk-3.0"/* "$USER_HOME/.config/gtk-3.0/" 2>/dev/null || true
        [ -d "$DIR_DOTFILES_ORIGEN/gtk-4.0" ] && cp -r "$DIR_DOTFILES_ORIGEN/gtk-4.0"/* "$USER_HOME/.config/gtk-4.0/" 2>/dev/null || true
        [ -d "$DIR_DOTFILES_ORIGEN/qt5ct" ] && cp -r "$DIR_DOTFILES_ORIGEN/qt5ct"/* "$USER_HOME/.config/qt5ct/" 2>/dev/null || true
        [ -d "$DIR_DOTFILES_ORIGEN/qt6ct" ] && cp -r "$DIR_DOTFILES_ORIGEN/qt6ct"/* "$USER_HOME/.config/qt6ct/" 2>/dev/null || true

        mkdir -p "$USER_HOME/.config/xdg-desktop-portal"
        cat << 'EOF' > "$USER_HOME/.config/xdg-desktop-portal/kineticwe-portals.conf"
[preferred]
default=gtk
EOF
        cp "$USER_HOME/.config/xdg-desktop-portal/kineticwe-portals.conf" "$USER_HOME/.config/xdg-desktop-portal/portals.conf"

        chown -R inhumano:inhumano "$USER_HOME/.config"
    fi

    if [ -d "$DIR_DOTFILES_ORIGEN/color-schemes" ]; then
        echo " -> Desplegando esquemas de color en tu HOME..."
        mkdir -p "$USER_HOME/.local/share/color-schemes"
        cp -r "$DIR_DOTFILES_ORIGEN/color-schemes"/* "$USER_HOME/.local/share/color-schemes/" 2>/dev/null || true
        chown -R inhumano:inhumano "$USER_HOME/.local"
    fi

    echo " -> Inyectando tipografías JetBrainsMono Nerd Font..."
    mkdir -p /usr/share/fonts/jetbrains-mono-nerd
    [ -f "$DIR_RECURSOS/JetBrainsMonoNerdFont-Regular.ttf" ] && cp "$DIR_RECURSOS/JetBrainsMonoNerdFont-Regular.ttf" /usr/share/fonts/jetbrains-mono-nerd/
    [ -f "$DIR_RECURSOS/JetBrainsMonoNerdFont-Bold.ttf" ] && cp "$DIR_RECURSOS/JetBrainsMonoNerdFont-Bold.ttf" /usr/share/fonts/jetbrains-mono-nerd/
    chmod 644 /usr/share/fonts/jetbrains-mono-nerd/*.ttf 2>/dev/null || true
    fc-cache -f -v >/dev/null

    if [ -f "$DIR_RECURSOS/Tela-icon-theme.tar.gz" ]; then
        echo " -> Desempaquetando e instalando Iconos Tela..."
        mkdir -p /usr/share/icons
        rm -rf /tmp/Tela-icon-theme
        tar -xzf "$DIR_RECURSOS/Tela-icon-theme.tar.gz" -C /tmp/
        if [ -f /tmp/Tela-icon-theme/install.sh ]; then
            chmod +x /tmp/Tela-icon-theme/install.sh
            /tmp/Tela-icon-theme/install.sh -d "/usr/share/icons" >/dev/null
        fi
        rm -rf /tmp/Tela-icon-theme
    fi

    mkdir -p /usr/share/icons/
    if [ -f "$DIR_RECURSOS/Bibata-Modern-Classic.tar.xz" ]; then
        echo " -> Descomprimiendo Bibata Modern Classic..."
        tar -xf "$DIR_RECURSOS/Bibata-Modern-Classic.tar.xz" -C /usr/share/icons/
    fi
    if [ -f "$DIR_RECURSOS/Bibata-Modern-Ice.tar.xz" ]; then
        echo " -> Descomprimiendo Bibata Modern Ice..."
        tar -xf "$DIR_RECURSOS/Bibata-Modern-Ice.tar.xz" -C /usr/share/icons/
    fi
    chmod -R 755 /usr/share/icons/Bibata-Modern-* 2>/dev/null || true

else
    echo "Error crítico: No se pudo clonar bazzite-kinetic desde GitHub."
    exit 1
fi
rm -rf "$DIR_TMP_KINETIC"

# Paso 5: Kernel CachyOS y optimizaciones
echo -e "\n${VERDE}[5/9] Instalando Kernel de CachyOS y planificadores de rendimiento...${NC}"
dnf install -y kernel-cachyos cachyos-settings
dnf install -y scx-scheds scx-tools
dnf install -y ananicy-cpp cachyos-ananicy-rules

if [ "$INSTALAR_NVIDIA" = true ]; then
    dnf install -y kernel-cachyos-devel-matched kernel-devel
else
    dnf install -y kernel-cachyos-devel
fi

echo " -> Configurando planificador scx_lavd y servicio ananicy-cpp..."
mkdir -p /etc/scx_loader
cat << 'EOF' > /etc/scx_loader/config.toml
default_sched = "scx_lavd"
default_mode = "Gaming"
EOF

systemctl enable scx_loader.service
systemctl enable ananicy-cpp.service

# [MEJORA] Parámetros de rendimiento gaming validados en sistema real
echo " -> Configurando ZRAM (zstd a 16GB) y parámetros de memoria gaming..."
cat << 'EOF' > /etc/systemd/zram-generator.conf
[zram0]
zram-size = min(ram, 16384)
compression-algorithm = zstd
EOF

cat << 'EOF' > /etc/sysctl.d/99-gaming-kinetic.conf
# [MEJORA] Parámetros validados en instalación real
vm.max_map_count = 2147483642
vm.swappiness = 100
kernel.nmi_watchdog = 0
EOF

# [MEJORA] Servicio THP en modo madvise
cat << 'EOF' > /etc/systemd/system/thp-tweaks.service
[Unit]
Description=Transparent Hugepage tweaks (madvise mode)
DefaultDependencies=no
After=sysinit.target local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo madvise > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/sh -c 'echo defer+madvise > /sys/kernel/mm/transparent_hugepage/defrag'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable thp-tweaks.service
sysctl --system >/dev/null

# [MEJORA] Deshabilitar servicios innecesarios para gaming desktop
echo " -> Deshabilitando NetworkManager-wait-online (no bloquea arranque pero elimina trabajo)..."
systemctl disable NetworkManager-wait-online.service 2>/dev/null || true

# Bloquear futuras actualizaciones del kernel stock de Fedora
if ! grep -q "^exclude=kernel " /etc/dnf/dnf.conf; then
    echo "exclude=kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-devel" >> /etc/dnf/dnf.conf
fi

# Paso 6: Aplicaciones de Gaming
echo -e "\n${VERDE}[6/9] Instalando aplicaciones de juegos y comunicación...${NC}"
dnf install -y discord protonplus steam mangohud gamescope
dnf swap ffmpeg-free ffmpeg --allowerasing -y
dnf install @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y

if [ "$INSTALAR_NVIDIA" = true ]; then
    echo " -> Instalando códecs completos y aceleración de vídeo NVIDIA..."
    dnf install -y libva-nvidia-driver
fi

# Paso 7: Activos estéticos
echo -e "\n${VERDE}[7/9] Descargando activos estéticos externos (IconsWalls)...${NC}"
DIR_TMP_WALLS="/tmp/git_iconswalls_backup"
rm -rf "$DIR_TMP_WALLS"

# [MEJORA] URL limpia
URL_ASSETS="https://github.com/Rupeji/IconsWalls"

if git clone --depth 1 "$URL_ASSETS" "$DIR_TMP_WALLS"; then
    mkdir -p /home/inhumano/Imágenes
    mkdir -p /home/inhumano/.config/noctalia/activos

    if [ -d "$DIR_TMP_WALLS/Wallpapers" ]; then
        echo " -> Copiando carpeta Wallpapers a tu directorio Pictures..."
        cp -r "$DIR_TMP_WALLS/Wallpapers" /home/inhumano/Imágenes/
    fi

    if [ -d "$DIR_TMP_WALLS/Iconos" ]; then
        echo " -> Copiando carpeta Iconos a tu directorio Pictures..."
        cp -r "$DIR_TMP_WALLS/Iconos" /home/inhumano/Imágenes/
        echo " -> Inyectando logotipo personalizado del dock..."
        cp "$DIR_TMP_WALLS/Iconos/Bazzite_Logo.png" /home/inhumano/.config/noctalia/activos/ 2>/dev/null || true
    fi

    chown -R inhumano:inhumano /home/inhumano/Imágenes
    chown -R inhumano:inhumano /home/inhumano/.config/noctalia
    echo "¡Carpetas de assets aplicadas a tu /home de forma correcta!"
else
    echo "Error crítico: No se pudo clonar el repositorio de assets."
    exit 1
fi
rm -rf "$DIR_TMP_WALLS"

# Paso 8: Drivers NVIDIA, Flatpak e initramfs
echo -e "\n${VERDE}[8/9] Finalizando configuración del kernel, drivers gráficos y Bambu Studio...${NC}"

if [ "$INSTALAR_NVIDIA" = true ]; then
    echo " -> Instalando controlador gráfico NVIDIA..."
    dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda libva-utils

    echo -e "${AMARILLO}Compilando módulo gráfico de NVIDIA para CachyOS...${NC}"
    KERNEL_CACHY=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel-cachyos-core | sort -V | tail -n 1)
    akmods --force --kernels "$KERNEL_CACHY"
else
    echo " -> Omitiendo drivers de NVIDIA según tu selección."
fi

echo " -> Instalando Bambu Studio y sincronizando runtimes gráficos en Flatpak..."
flatpak install -y flathub com.bambulab.BambuStudio
flatpak update -y

# [MEJORA] Initramfs hostonly (más rápido y pequeño)
echo -e "${AMARILLO}Regenerando initramfs en modo hostonly...${NC}"
dracut --force --hostonly --kver "$(uname -r)"

# [MEJORA] Reducir timeout de GRUB
echo " -> Reduciendo GRUB_TIMEOUT a 2 segundos..."
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# Paso 9: Diagnóstico final
echo -e "\n${VERDE}[9/9] Diagnóstico de arranque...${NC}"
echo -e "${AZUL}Tiempo total de arranque:${NC}"
systemd-analyze
echo -e "\n${AZUL}Servicios más lentos (top 10):${NC}"
systemd-analyze blame | head -n 10

# --- CIERRE ---
echo -e "\n${AZUL}=====================================================${NC}"
echo -e "            PROCESO DE CARGA TERMINADO               "
echo -e "${AZUL}=====================================================${NC}"
echo -e "${VERDE} Recuerda hacer gsettings set org.cinnamon.desktop.default-applications.terminal exec 'kitty' al loguear en Kineticwe ! Ya puedes reiniciar con: sudo reboot${NC}"
