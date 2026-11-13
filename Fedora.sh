#!/bin/bash

# Colores para la interfaz en la terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
NC='\033[0m' # Sin color

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

# Variables de selección estilo LGL
INSTALAR_NVIDIA=false

# --- MENÚ DE SELECCIÓN DE HARDWARE ---
echo -e "\n${AMARILLO}¿Deseas los drivers de NVIDIA a tu instalación? (s/n):${NC}"
read -p "-> Instalar controlador akmod-nvidia (RPM Fusion): " resp
if [[ "$resp" =~ ^[Ss]$ ]]; then INSTALAR_NVIDIA=true; fi


# --- PROCESAMIENTO E INSTALACIÓN ---
echo -e "\n${AZUL}=====================================================${NC}"
echo -e "              INICIANDO INSTALACIÓN                  "
echo -e "${AZUL}=====================================================${NC}"

# Paso 1: Actualización profunda (Fuerza la base antes de compilar nada)
echo -e "\n${VERDE}[1/8] Limpiando caché y actualizando los repositorios y el sistema...${NC}"
dnf clean metadata
dnf upgrade --refresh -y

# Paso 2: Configuración de Repositorios
echo -e "\n${VERDE}[2/8] Configurando repositorios adicionales...${NC}"
# Habilitar Flathub para aplicaciones Flatpak
dnf install -y flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo -e "${AZUL}Habilitando RPM Fusion para soporte de NVIDIA...${NC}"
FEDORA_VER=$(rpm -E %fedora)
if grep -qi "rawhide" /etc/os-release; then
    RPMFUSION_TAG="rawhide"
else
    RPMFUSION_TAG="$FEDORA_VER"
fi
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
               https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sudo dnf copr enable theblackdon/kwee -y
sudo dnf copr enable bieszczaders/kernel-cachyos -y
sudo dnf copr enable bieszczaders/kernel-cachyos-addons -y
sudo dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release terra-gpg-keys -y

# Paso 3: Instalación de tus aplicaciones del sistema
echo -e "\n${VERDE}[3/8] Instalando herramientas del sistema y utilidades...${NC}"
dnf5 install kineticwe kineticwe-greeter firefox fastfetch kitty fish loupe gnome-text-editor mediawriter nemo nemo-fileroller git tar -y
dnf remove alacritty -y

# Paso 4: Clonar temporalmente tu repositorio bazzite-kinetic para extraer dotfiles/recursos
echo -e "\n${VERDE}[4/8] Descargando dotfiles y recursos desde bazzite-kinetic en GitHub...${NC}"
DIR_TMP_KINETIC="/tmp/git_bazzite_kinetic_setup"
rm -rf "$DIR_TMP_KINETIC"

URL_KINETIC_ESPACIOS="https://github .com /Rupeji /Fedora"
URL_KINETIC_LIMPIA=$(echo "$URL_KINETIC_ESPACIOS" | tr -d ' ')

if git clone --depth 1 "$URL_KINETIC_LIMPIA" "$DIR_TMP_KINETIC"; then
    DIR_SOURCE_BUILD="$DIR_TMP_KINETIC/build_files"
    DIR_RECURSOS="$DIR_SOURCE_BUILD/recursos"
    DIR_DOTFILES_ORIGEN="$DIR_SOURCE_BUILD/dotfiles"
    USER_HOME="/home/inhumano"

    # --- INYECTAR STARSHIP Y PAQUETES LOCALES ---
    if [ -f "$DIR_RECURSOS/starship" ]; then
        echo " -> Inyectando Starship Prompt..."
        cp "$DIR_RECURSOS/starship" /usr/bin/starship
        chmod 755 /usr/bin/starship
    fi

    if [ -f "$DIR_RECURSOS/gslapper.rpm" ]; then
        echo " -> Instalando paquete local gslapper.rpm mediante dnf5..."
        dnf5 -y install "$DIR_RECURSOS/gslapper.rpm"
    fi

    # --- INYECTAR DIRECTAMENTE EN TU HOME ---
    if [ -d "$DIR_DOTFILES_ORIGEN" ]; then
        echo " -> Desplegando quirúrgicamente dotfiles en tu HOME ($USER_HOME)..."
        mkdir -p "$USER_HOME/.config"/{kitty,fish,kineticwe,niri,noctalia-kwe,gtk-3.0,gtk-4.0,qt5ct,qt6ct}

        [ -f "$DIR_DOTFILES_ORIGEN/kitty/kitty.conf" ] && cp "$DIR_DOTFILES_ORIGEN/kitty/kitty.conf" "$USER_HOME/.config/kitty/kitty.conf"
        [ -f "$DIR_DOTFILES_ORIGEN/fish/config.fish" ] && cp "$DIR_DOTFILES_ORIGEN/fish/config.fish" "$USER_HOME/.config/fish/config.fish"
        [ -f "$DIR_DOTFILES_ORIGEN/starship/starship.toml" ] && cp "$DIR_DOTFILES_ORIGEN/starship/starship.toml" "$USER_HOME/.config/starship.toml"

        [ -d "$DIR_DOTFILES_ORIGEN/kineticwe" ] && cp -r "$DIR_DOTFILES_ORIGEN/kineticwe"/* "$USER_HOME/.config/kineticwe/" 2>/dev/null || true
        [ -d "$DIR_DOTFILES_ORIGEN/niri" ] && cp -r "$DIR_DOTFILES_ORIGEN/niri"/* "$USER_HOME/.config/niri/" 2>/dev/null || true
        [ -d "$DIR_DOTFILES_ORIGEN/noctalia-kwe" ] && cp -r "$DIR_DOTFILES_ORIGEN/noctalia-kwe"/* "$USER_HOME/.config/noctalia-kwe/" 2>/dev/null || true
        [ -d "$DIR_DOTFILES_ORIGEN/gtk-3.0" ] && cp -r "$DIR_DOTFILES_ORIGEN/gtk-3.0"/* "$USER_HOME/.config/gtk-3.0/" 2>/dev/null || true
        [ -d "$DIR_DOTFILES_ORIGEN/gtk-4.0" ] && cp -r "$DIR_DOTFILES_ORIGEN/gtk-4.0"/* "$USER_HOME/.config/gtk-4.0/" 2>/dev/null || true
        [ -d "$DIR_DOTFILES_ORIGEN/qt5ct" ] && cp -r "$DIR_DOTFILES_ORIGEN/qt5ct"/* "$USER_HOME/.config/qt5ct/" 2>/dev/null || true
        [ -d "$DIR_DOTFILES_ORIGEN/qt6ct" ] && cp -r "$DIR_DOTFILES_ORIGEN/qt6ct"/* "$USER_HOME/.config/qt6ct/" 2>/dev/null || true
        
        # Corregir permisos para tu usuario en .config
        chown -R inhumano:inhumano "$USER_HOME/.config"
    fi

    # --- INYECTAR COLOR-SCHEMES EN TU HOME ---
    if [ -d "$DIR_DOTFILES_ORIGEN/color-schemes" ]; then
        echo " -> Desplegando esquemas de color en tu HOME..."
        mkdir -p "$USER_HOME/.local/share/color-schemes"
        cp -r "$DIR_DOTFILES_ORIGEN/color-schemes"/* "$USER_HOME/.local/share/color-schemes/" 2>/dev/null || true
        chown -R inhumano:inhumano "$USER_HOME/.local"
    fi

    # --- INYECTAR TIPOGRAFÍAS (Se quedan en /usr por ser globales) ---
    echo " -> Inyectando tipografías JetBrainsMono Nerd Font..."
    mkdir -p /usr/share/fonts/jetbrains-mono-nerd
    [ -f "$DIR_RECURSOS/JetBrainsMonoNerdFont-Regular.ttf" ] && cp "$DIR_RECURSOS/JetBrainsMonoNerdFont-Regular.ttf" /usr/share/fonts/jetbrains-mono-nerd/
    [ -f "$DIR_RECURSOS/JetBrainsMonoNerdFont-Bold.ttf" ] && cp "$DIR_RECURSOS/JetBrainsMonoNerdFont-Bold.ttf" /usr/share/fonts/jetbrains-mono-nerd/
    chmod 644 /usr/share/fonts/jetbrains-mono-nerd/*.ttf 2>/dev/null || true
    fc-cache -f -v >/dev/null

    # --- INSTALACIÓN DE ICONOS TELA (Globales) ---
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

    # --- INSTALACIÓN DE CURSORES BIBATA (Globales) ---
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

# Paso 5: Instalación del Kernel de CachyOS y optimizaciones avanzadas (scx + ananicy)
echo -e "\n${VERDE}[5/8] Instalando Kernel de CachyOS y planificadores de rendimiento...${NC}"
dnf install -y kernel-cachyos cachyos-settings scx-scheds scx-tools ananicy-cpp cachyos-ananicy-rules

if [ "$INSTALAR_NVIDIA" = true ]; then
    dnf install -y kernel-cachyos-devel-matched kernel-devel
else
    dnf install -y kernel-cachyos-devel
fi

# Configurar scx_lavd como planificador predeterminado en modo rendimiento
echo " -> Configurando planificador scx_lavd y servicio ananicy-cpp..."
cat << 'EOF' > /etc/scx_loader.toml
default_sched = "scx_lavd"
default_mode = "Auto"

[scheds.scx_lavd]
auto_mode = ["--performance"]
EOF

# Activar servicios en segundo plano
systemctl enable scx_loader.service
systemctl enable ananicy-cpp.service

# Paso 6: Instalación de aplicaciones de Gaming y Terra
echo -e "\n${VERDE}[6/8] Instalando aplicaciones de juegos y comunicación...${NC}"
dnf install -y discord protonplus steam mangohud gamescope
dnf swap ffmpeg-free ffmpeg --allowerasing -y
dnf install @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y


if [ "$INSTALAR_NVIDIA" = true ]; then
    echo " -> Instalando códecs completos y aceleración de vídeo NVIDIA..."
    dnf install -y libva-nvidia-driver    
fi

# Paso 7: Clonar e inyectar activos globales en Pictures (Iconos y Wallpapers)
echo -e "\n${VERDE}[7/8] Descargando activos estéticos externos (IconsWalls)...${NC}"
DIR_TMP_WALLS="/tmp/git_iconswalls_backup"
rm -rf "$DIR_TMP_WALLS"

URL_ASSETS_ESPACIOS="https://github .com /Rupeji /IconsWalls"
URL_ASSETS_LIMPIA=$(echo "$URL_ASSETS_ESPACIOS" | tr -d ' ')

if git clone --depth 1 "$URL_ASSETS_LIMPIA" "$DIR_TMP_WALLS"; then
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

# Paso 8: Instalación de Drivers NVIDIA (opcional), Flatpak y reconstrucción de initramfs
echo -e "\n${VERDE}[8/8] Finalizando configuración del kernel, drivers gráficos y Bambu Studio...${NC}"

if [ "$INSTALAR_NVIDIA" = true ]; then
    echo " -> Instalando controlador gráfico NVIDIA..."
    dnf install -y akmod-nvidia
    
    echo -e "${AMARILLO}Compilando módulo gráfico de NVIDIA (esto tardará unos minutos)...${NC}"
    akmods --force
else
    echo " -> Omitiendo drivers de NVIDIA según tu selección."
fi

echo " -> Instalando Bambu Studio y sincronizando runtimes gráficos en Flatpak..."
flatpak install -y flathub com.bambulab.BambuStudio
flatpak update -y

echo -e "${AMARILLO}Regenerando initramfs para aplicar cachyos-settings y ajustes del kernel...${NC}"
dracut --force --regenerate-all

# --- CIERRE ---
echo -e "\n${AZUL}=====================================================${NC}"
echo -e "            PROCESO DE CARGA TERMINADO               "
echo -e "${AZUL}=====================================================${NC}"
echo -e "${VERDE} Recuerda hacer gsettings set org.cinnamon.desktop.default-applications.terminal exec 'kitty' al loguear en Kineticwe ! Ya puedes reiniciar con: sudo reboot${NC}"



# gsettings set org.cinnamon.desktop.default-applications.terminal exec 'kitty'


#Mantenimiento
#sudo dnf distro-sync
#sudo dnf update --refresh
#sudo dnf5 autoremove -y

# --- VERIFICACIÓN POST-REINICIO ---
# 1. Comprobar que arrancó con el Kernel de CachyOS:
# Muestra la versión del núcleo en uso y confirma que el gestor de arranque seleccionó CachyOS por defecto.
# uname -r

# 2. Verificar que el planificador scx_lavd está activo:
# Devuelve el nombre del planificador sched_ext cargado en tiempo real (scx_lavd) y su modo de energía.
# scxctl get

# 3. Comprobar el estado del servicio ananicy-cpp:
# Confirma que el demonio está activo (active running) gestionando prioridades de juegos y apps en segundo plano.
# systemctl status ananicy-cpp --no-pager

# 4. Verificar que el módulo NTSync del kernel está cargado:
# Verifica que la sincronización nativa de Windows NT está lista en el núcleo para Steam/Proton.
# lsmod | grep ntsync

# 5. Comprobar el límite de memoria virtual:
# Asegura que los ajustes de memoria de cachyos-settings (1048576 o 2147483642) se aplicaron en el arranque.
# sysctl vm.max_map_count

# 6. Verificar drivers y aceleración gráfica (solo si instalaste NVIDIA):
# Confirman que tanto el controlador propietario como la aceleración de vídeo por hardware están operativos.
# nvidia-smi
# vainfo
