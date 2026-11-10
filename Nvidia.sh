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
echo -e "${AZUL}    INSTALADOR DE LOADOUT PERSONALIZADO + NVIDIA    ${NC}"
echo -e "${AZUL}=====================================================${NC}"

# Variables de selección estilo LGL
INSTALAR_NVIDIA=false
INSTALAR_CUDA=false

# --- MENÚ DE SELECCIÓN DE HARDWARE ---
echo -e "\n${AMARILLO}¿Deseas añadir la pila gráfica de NVIDIA a tu instalación? (s/n):${NC}"
read -p "-> Instalar controlador akmod-nvidia (RPM Fusion): " resp
if [[ "$resp" =~ ^[Ss]$ ]]; then INSTALAR_NVIDIA=true; fi

read -p "-> Instalar aceleración CUDA / NVENC (OBS, Blender, etc): " resp
if [[ "$resp" =~ ^[Ss]$ ]]; then INSTALAR_CUDA=true; fi


# --- PROCESAMIENTO E INSTALACIÓN ---
echo -e "\n${AZUL}=====================================================${NC}"
echo -e "${AZUL}              INICIANDO INSTALACIÓN                  ${NC}"
echo -e "${AZUL}=====================================================${NC}"

# Paso 1: Actualización profunda (Fuerza la base antes de compilar nada)
echo -e "\n${VERDE}[1/6] Actualizando los repositorios y el sistema...${NC}"
dnf upgrade --refresh -y

# Paso 2: Configuración de Repositorios (Tu Kwee + RPM Fusion si elegiste NVIDIA)
echo -e "\n${VERDE}[2/6] Configurando repositorios adicionales...${NC}"
# Tu repositorio COPR de Kwee (Usando dnf5 como especificaste)
dnf5 copr enable theblackdon/kwee -y

# Repositorio COPR del Kernel de CachyOS
dnf copr enable bieszczaders/kernel-cachyos -y

# Repositorio Terra externo
dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release -y

# Si seleccionaste NVIDIA, activamos RPM Fusion automáticamente
if [ "$INSTALAR_NVIDIA" = true ] || [ "$INSTALAR_CUDA" = true ]; then
    echo -e "${AZUL}Habilitando RPM Fusion para soporte de NVIDIA...${NC}"
    dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                   https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    # Habilitar AppStream metadata (Para que Discover/GNOME Software los reconozcan visualmente como hace LGL)
    #dnf install -y rpmfusion-\*-appstream-data
fi

# Paso 3: Instalación de tus aplicaciones del sistema
echo -e "\n${VERDE}[3/6] Instalando herramientas del sistema y utilidades...${NC}"
dnf5 install kineticwe kineticwe-greeter firefox fastfetch kitty fish loupe gnome-text-editor mediawriter nemo nemo-fileroller -y
dnf remove alacritty -y

# Paso 4: Instalación del Kernel de CachyOS (Versión LGL Optimizada)
echo -e "\n${VERDE}[4/6] Instalando Kernel de CachyOS optimizado...${NC}"
dnf install -y kernel-cachyos

# Inyección inteligente de cabeceras de compilación según tu hardware
if [ "$INSTALAR_NVIDIA" = true ]; then
    # SI TIENES NVIDIA: Obligatorio usar "matched" para que el driver compile sobre CachyOS
    dnf install -y kernel-cachyos-devel-matched
else
    # SI NO TIENES NVIDIA: Bajamos los headers nativos de CachyOS por estabilidad general
    dnf install -y kernel-cachyos-devel
fi

# Paso 5: Instalación de Drivers Gráficos NVIDIA (Si se seleccionó)
if [ "$INSTALAR_NVIDIA" = true ]; then
    echo -e "\n${VERDE}[5/6] Instalando controlador gráfico akmod-nvidia...${NC}"
    dnf install -y akmod-nvidia
fi

if [ "$INSTALAR_CUDA" = true ]; then
    echo -e "${VERDE}Añadiendo librerías CUDA...${NC}"
    dnf install -y xorg-x11-drv-nvidia-cuda
fi

# Paso 6: Instalación de aplicaciones de Gaming y Terra
echo -e "\n${VERDE}[6/6] Instalando aplicaciones de juegos y comunicación...${NC}"
dnf install -y discord protonplus steam mangohud gamescope

# --- CIERRE Y REGENERACIÓN DE GRUB (Optimizado) ---
echo -e "\n${AZUL}=====================================================${NC}"
echo -e "${AZUL}            PROCESO DE CARGA TERMINADO               ${NC}"
echo -e "${AZUL}=====================================================${NC}"

if [ "$INSTALAR_NVIDIA" = true ]; then
    echo -e "${AMARILLO}AVISO DE COMPILACIÓN NVIDIA:${NC}"
    echo "El sistema está generando el controlador en segundo plano."
    echo "Por favor, ESPERA de 3 a 5 minutos completos antes de reiniciar."
    echo -e "Una vez transcurrido el tiempo, escribe: ${VERDE}sudo reboot${NC}"
else
    echo -e "${VERDE}¡Loadout finalizado! Ya puedes reiniciar tu equipo cuando quieras.${NC}"
fi
