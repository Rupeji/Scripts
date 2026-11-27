#!/bin/bash
set -euo pipefail

# Colores para la interfaz en la terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
NC='\033[0m'

# Validar privilegios de administrador (SUDO)
if [ "$EUID" -ne 0 ]; then
  echo -e "${AMARILLO}Por favor, ejecuta este script usando 'sudo':${NC}"
  echo "sudo $0"
  exit 1
fi

clear
echo -e "${AZUL}=====================================================${NC}"
echo -e "    LOADOUT PERSONALIZADO: FEDORA + GAMING + DOTFILES  "
echo -e "${AZUL}=====================================================${NC}"

# ============================================================
# MENÚ DE PERFIL DE HARDWARE
# ============================================================
echo -e "\n${AMARILLO}Selecciona el perfil de hardware:${NC}"
echo "  1) NVIDIA (RTX 3070 Ti) + AMD Ryzen 5900X  [tu equipo actual]"
echo "  2) Todo AMD (GPU Radeon + CPU Ryzen)"
read -p "-> Opción [1/2]: " hw_profile

case "$hw_profile" in
    1)
        INSTALAR_NVIDIA=true
        PERFIL_CPU="amd"
        PAQUETES_GRAFICOS="akmod-nvidia xorg-x11-drv-nvidia-cuda libva-nvidia-driver libva-utils"
        echo -e "${VERDE}Perfil seleccionado: NVIDIA + Ryzen 5900X${NC}"
        ;;
    2)
        INSTALAR_NVIDIA=false
        PERFIL_CPU="amd"
        PAQUETES_GRAFICOS="mesa-vulkan-drivers mesa-dri-drivers vulkan-tools"
        echo -e "${VERDE}Perfil seleccionado: Todo AMD${NC}"
        ;;
    *)
        echo -e "${AMARILLO}Opción no válida. Saliendo.${NC}"
        exit 1
        ;;
esac

# --- PROCESAMIENTO E INSTALACIÓN ---
echo -e "\n${AZUL}=====================================================${NC}"
echo -e "              INICIANDO INSTALACIÓN                  "
echo -e "${AZUL}=====================================================${NC}"

# Paso 1: Actualización profunda
echo -e "\n${VERDE}[1/10] Limpiando caché y actualizando el sistema...${NC}"
dnf clean metadata
dnf upgrade --refresh -y

# Paso 2: Configuración de Repositorios
echo -e "\n${VERDE}[2/10] Configurando repositorios adicionales...${NC}"
dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo -e "${AZUL}Habilitando RPM Fusion...${NC}"
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
               https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

dnf copr enable theblackdon/kwee -y
dnf copr enable bieszczaders/kernel-cachyos -y
dnf copr enable bieszczaders/kernel-cachyos-addons -y
#dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release terra-gpg-keys -y
dnf copr enable lemmy/favorites -y
dnf makecache --refresh

# Paso 3: Aplicaciones base
echo -e "\n${VERDE}[3/10] Instalando herramientas del sistema...${NC}"
dnf5 install kineticwe kineticwe-greeter firefox fastfetch kitty fish loupe gnome-text-editor mediawriter luciole-git 7zip git tar -y
dnf remove alacritty -y

# Paso 4: Dotfiles y recursos
echo -e "\n${VERDE}[4/10] Descargando dotfiles y recursos...${NC}"
DIR_TMP_KINETIC="/tmp/git_bazzite_kinetic_setup"
rm -rf "$DIR_TMP_KINETIC"

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
        echo " -> Instalando gslapper.rpm..."
        dnf5 -y install "$DIR_RECURSOS/gslapper.rpm"
    fi

    if [ -d "$DIR_DOTFILES_ORIGEN" ]; then
        echo " -> Desplegando dotfiles en $USER_HOME..."
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
        echo " -> Desplegando esquemas de color..."
        mkdir -p "$USER_HOME/.local/share/color-schemes"
        cp -r "$DIR_DOTFILES_ORIGEN/color-schemes"/* "$USER_HOME/.local/share/color-schemes/" 2>/dev/null || true
        chown -R inhumano:inhumano "$USER_HOME/.local"
    fi

    echo " -> Inyectando JetBrainsMono Nerd Font..."
    mkdir -p /usr/share/fonts/jetbrains-mono-nerd
    [ -f "$DIR_RECURSOS/JetBrainsMonoNerdFont-Regular.ttf" ] && cp "$DIR_RECURSOS/JetBrainsMonoNerdFont-Regular.ttf" /usr/share/fonts/jetbrains-mono-nerd/
    [ -f "$DIR_RECURSOS/JetBrainsMonoNerdFont-Bold.ttf" ] && cp "$DIR_RECURSOS/JetBrainsMonoNerdFont-Bold.ttf" /usr/share/fonts/jetbrains-mono-nerd/
    chmod 644 /usr/share/fonts/jetbrains-mono-nerd/*.ttf 2>/dev/null || true
    fc-cache -f -v >/dev/null

    if [ -f "$DIR_RECURSOS/Tela-icon-theme.tar.gz" ]; then
        echo " -> Instalando Iconos Tela..."
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
        tar -xf "$DIR_RECURSOS/Bibata-Modern-Classic.tar.xz" -C /usr/share/icons/
    fi
    if [ -f "$DIR_RECURSOS/Bibata-Modern-Ice.tar.xz" ]; then
        tar -xf "$DIR_RECURSOS/Bibata-Modern-Ice.tar.xz" -C /usr/share/icons/
    fi
    chmod -R 755 /usr/share/icons/Bibata-Modern-* 2>/dev/null || true

else
    echo "Error crítico: No se pudo clonar el repositorio de dotfiles."
    exit 1
fi
rm -rf "$DIR_TMP_KINETIC"

# Paso 5: Kernel CachyOS y optimizaciones
echo -e "\n${VERDE}[5/10] Instalando Kernel de CachyOS y optimizaciones...${NC}"
#dnf install -y kernel-cachyos cachyos-settings
# [FIX] Resolver conflicto de ZRAM antes de instalar cachyos-settings
dnf swap zram-generator-defaults cachyos-settings -y
dnf install -y kernel-cachyos
dnf install -y scx-scheds scx-tools
dnf install -y ananicy-cpp cachyos-ananicy-rules

if [ "$INSTALAR_NVIDIA" = true ]; then
    dnf install -y kernel-cachyos-devel-matched kernel-devel
else
    dnf install -y kernel-cachyos-devel
fi

echo " -> Configurando scx_lavd en modo Gaming..."
mkdir -p /etc/scx_loader
cat << 'EOF' > /etc/scx_loader/config.toml
default_sched = "scx_lavd"
default_mode = "Gaming"
EOF

systemctl enable scx_loader.service
systemctl enable ananicy-cpp.service

echo " -> Configurando ZRAM (zstd a 16GB)..."
cat << 'EOF' > /etc/systemd/zram-generator.conf
[zram0]
zram-size = min(ram, 16384)
compression-algorithm = zstd
EOF

echo " -> Aplicando parámetros de memoria gaming..."
cat << 'EOF' > /etc/sysctl.d/99-gaming-kinetic.conf
vm.max_map_count = 2147483642
vm.swappiness = 100
kernel.nmi_watchdog = 0
EOF

echo " -> Configurando THP en modo madvise..."
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

systemctl disable NetworkManager-wait-online.service 2>/dev/null || true

if ! grep -q "^exclude=kernel " /etc/dnf/dnf.conf; then
    echo "exclude=kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra kernel-devel" >> /etc/dnf/dnf.conf
fi

if [ "$PERFIL_CPU" = "amd" ]; then
    echo " -> Instalando microcódigo AMD y tuned..."
    dnf install -y linux-firmware tuned
    systemctl enable --now tuned
    tuned-adm profile latency-performance || true
fi

# Paso 6: Aplicaciones de Gaming
echo -e "\n${VERDE}[6/10] Instalando aplicaciones de juegos...${NC}"
dnf install -y discord protonplus steam mangohud gamescope
dnf swap ffmpeg-free ffmpeg --allowerasing -y
dnf install @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y

echo " -> Instalando drivers gráficos del perfil seleccionado..."
dnf install -y $PAQUETES_GRAFICOS

# Paso 7: Activos estéticos
echo -e "\n${VERDE}[7/10] Descargando activos estéticos (IconsWalls)...${NC}"
DIR_TMP_WALLS="/tmp/git_iconswalls_backup"
rm -rf "$DIR_TMP_WALLS"

URL_ASSETS="https://github.com/Rupeji/IconsWalls"

if git clone --depth 1 "$URL_ASSETS" "$DIR_TMP_WALLS"; then
    mkdir -p /home/inhumano/Imágenes
    mkdir -p /home/inhumano/.config/noctalia/activos

    if [ -d "$DIR_TMP_WALLS/Wallpapers" ]; then
        cp -r "$DIR_TMP_WALLS/Wallpapers" /home/inhumano/Imágenes/
    fi

    if [ -d "$DIR_TMP_WALLS/Iconos" ]; then
        cp -r "$DIR_TMP_WALLS/Iconos" /home/inhumano/Imágenes/
        cp "$DIR_TMP_WALLS/Iconos/Bazzite_Logo.png" /home/inhumano/.config/noctalia/activos/ 2>/dev/null || true
    fi

    chown -R inhumano:inhumano /home/inhumano/Imágenes
    chown -R inhumano:inhumano /home/inhumano/.config/noctalia
    echo "¡Assets aplicados correctamente!"
else
    echo "Error crítico: No se pudo clonar el repositorio de assets."
    exit 1
fi
rm -rf "$DIR_TMP_WALLS"

# Paso 8: Drivers NVIDIA (solo perfil 1), Flatpak e initramfs
echo -e "\n${VERDE}[8/10] Finalizando kernel, drivers y Bambu Studio...${NC}"

if [ "$INSTALAR_NVIDIA" = true ]; then
    echo " -> Compilando módulo NVIDIA para CachyOS..."
    KERNEL_CACHY=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel-cachyos-core | sort -V | tail -n 1)
    akmods --force --kernels "$KERNEL_CACHY"
else
    echo " -> Perfil AMD: no se instalan drivers propietarios."
fi

echo " -> Instalando Bambu Studio y sincronizando Flatpak..."
flatpak install -y flathub com.bambulab.BambuStudio
flatpak update -y

echo " -> Regenerando initramfs en modo hostonly para CachyOS..."
# [FIX] Obtener la versión exacta del kernel de CachyOS instalado, no el de Fedora
KERNEL_CACHY=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel-cachyos-core | sort -V | tail -n 1)
dracut --force --hostonly --kver "$KERNEL_CACHY"

echo " -> Reduciendo GRUB_TIMEOUT a 2 segundos..."
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# ============================================================
# NUEVOS PASOS DE AUTOMATIZACIÓN Y MANTENIMIENTO
# ============================================================

# Paso 9: Automatización y Red de Seguridad
echo -e "\n${VERDE}[9/10] Configurando automatizaciones de mantenimiento...${NC}"


# 2. Snapper para snapshots automáticos (BTRFS)
echo " -> Configurando Snapper para snapshots de BTRFS..."
dnf install -y snapper python3-dnf-plugin-snapper
snapper -c root create-config / 2>/dev/null || true
systemctl enable --now snapper-timeline.timer
systemctl enable --now snapper-cleanup.timer

# 3. Script de mantenimiento manual
echo " -> Creando script de mantenimiento en /usr/local/bin/mantenimiento..."
cat << 'EOF' > /usr/local/bin/mantenimiento
#!/bin/bash
echo "=== Iniciando mantenimiento del sistema ==="

echo "-> Actualizando Fedora..."
dnf upgrade --refresh -y

echo "-> Actualizando Flatpaks..."
flatpak update -y

if command -v akmods &>/dev/null; then
    echo "-> Verificando módulos de NVIDIA..."
    # [FIX] Compilar explícitamente para el kernel de CachyOS más reciente
    KERNEL_CACHY=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel-cachyos-core 2>/dev/null | sort -V | tail -n 1)
    if [ -n "$KERNEL_CACHY" ]; then
        akmods --force --kernels "$KERNEL_CACHY"
        dracut --force --kver "$KERNEL_CACHY"
    else
        akmods --force
        dracut --force
    fi
fi

echo "-> Limpiando kernels antiguos..."
dnf remove --oldinstallonly --setopt installonly_limit=2 kernel-cachyos kernel-cachyos-core kernel-cachyos-modules -y 2>/dev/null || true
dnf autoremove -y

echo "-> Limpiando caché..."
dnf clean all

echo "=== Mantenimiento completado ==="
EOF
chmod +x /usr/local/bin/mantenimiento

# Paso 10: Diagnóstico
echo -e "\n${VERDE}[10/10] Diagnóstico de arranque...${NC}"
systemd-analyze
echo -e "\n${AZUL}Servicios más lentos (top 10):${NC}"
systemd-analyze blame | head -n 10

# --- CIERRE ---
echo -e "\n${AZUL}=====================================================${NC}"
echo -e "            PROCESO DE CARGA TERMINADO               "
echo -e "${AZUL}=====================================================${NC}"
echo -e "${VERDE} Recuerda: gsettings set org.cinnamon.desktop.default-applications.terminal exec 'kitty' al loguear en Kineticwe. Reinicia con: sudo reboot${NC}"
