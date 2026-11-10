#!/bin/bash

# Colores para la interfaz en la terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
NC='\033[0m' # Sin color

# Validar privilegios de administrador (SUDO)
if [ "$EUID" -ne 0 ]; then
  echo -e "${AMARILLO}Por favor, ejecuta este script usando 'sudo':${NC}"
  echo "sudo $0"
  exit 1
fi

clear
echo -e "${AZUL}=====================================================${NC}"
echo -e "${AZUL}    WIZARD REPLICA DE LGL (NVIDIA + CACHYOS KERNEL)  ${NC}"
echo -e "${AZUL}=====================================================${NC}"
echo -e "Este script instalará los controladores NVIDIA y/o el kernel"
echo -e "optimizado de CachyOS siguiendo la misma lógica de LGL."
echo -e "${AZUL}=====================================================${NC}"

# Variables de selección
INSTALAR_REPOS=false
INSTALAR_DRIVERS=false
INSTALAR_CUDA=false
INSTALAR_CACHYOS=false

# --- MENÚ DE SELECCIÓN (Estilo LGL) ---
echo -e "\n${AMARILLO}Por favor, selecciona los componentes de tu loadout (s/n):${NC}"

# Opción 1: Repositorios NVIDIA
read -p "¿Habilitar Repositorios RPM Fusion Nonfree? [Recomendado] (s/n): " resp
if [[ "$resp" =~ ^[Ss]$ ]]; then INSTALAR_REPOS=true; fi

# Opción 2: Controlador NVIDIA
read -p "¿Instalar Controlador Oficial NVIDIA Actual (akmod-nvidia)? (s/n): " resp
if [[ "$resp" =~ ^[Ss]$ ]]; then INSTALAR_DRIVERS=true; fi

# Opción 3: Soporte CUDA
read -p "¿Instalar Aceleración CUDA / NVENC / NVDEC (Para OBS/Blender)? (s/n): " resp
if [[ "$resp" =~ ^[Ss]$ ]]; then INSTALAR_CUDA=true; fi

# Opción 4: Kernel CachyOS
read -p "¿Instalar Kernel de CachyOS (Optimizado para Gaming/Bore Scheduler)? (s/n): " resp
if [[ "$resp" =~ ^[Ss]$ ]]; then INSTALAR_CACHYOS=true; fi


# --- PROCESAMIENTO E INSTALACIÓN ---
echo -e "\n${AZUL}=====================================================${NC}"
echo -e "${AZUL}              PROCESANDO TU LOADOUT                  ${NC}"
echo -e "${AZUL}=====================================================${NC}"

# Paso 1: Actualización previa indispensable de Fedora
echo -e "\n${VERDE}[1/5] Asegurando que el sistema esté al día...${NC}"
dnf upgrade --refresh -y

# Paso 2: Habilitar Repositorios RPM Fusion
if [ "$INSTALAR_REPOS" = true ]; then
    echo -e "\n${VERDE}[2/5] Habilitando repositorios RPM Fusion Free y Nonfree...${NC}"
    dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                   https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    # Habilitar AppStream metadata (Para que Discover/GNOME Software los reconozcan visualmente como hace LGL)
    dnf install -y rpmfusion-\*-appstream-data
else
    echo -e "\n${AMARILLO}[2/5] Saltando repositorios de NVIDIA. Required si vas a instalar el driver.${NC}"
fi

# Paso 3: Configurar e instalar Kernel CachyOS
if [ "$INSTALAR_CACHYOS" = true ]; then
    echo -e "\n${VERDE}[3/5] Habilitando repositorio COPR de CachyOS e instalando kernel...${NC}"
    dnf copr enable bieszczaders/kernel-cachyos -y
    
    # Instalamos el kernel base
    dnf install -y kernel-cachyos
    
    # Si también se eligió el driver de NVIDIA, se instalan obligatoriamente los headers "matched" para CachyOS
    if [ "$INSTALAR_DRIVERS" = true ]; then
        echo -e "${AZUL}Instalando entornos de desarrollo aparejados para CachyOS...${NC}"
        dnf install -y kernel-cachyos-devel-matched
    fi
else
    echo -e "\n${AMARILLO}[3/5] Saltando el Kernel de CachyOS.${NC}"
fi

# Paso 4: Instalar Controlador akmod-nvidia
if [ "$INSTALAR_DRIVERS" = true ]; then
    echo -e "\n${VERDE}[4/5] Instalando el driver akmod-nvidia...${NC}"
    # Si no tienes CachyOS, se bajan los headers normales de Fedora para asegurar la compilación
    if [ "$INSTALAR_CACHYOS" = false ]; then
        dnf install -y kernel-devel
    fi
    dnf install -y akmod-nvidia
else
    echo -e "\n${AMARILLO}[4/5] Saltando la instalación del controlador NVIDIA.${NC}"
fi

# Paso 5: Instalar CUDA / Codificadores de Video
if [ "$INSTALAR_CUDA" = true ]; then
    echo -e "\n${VERDE}[5/5] Instalando librerías CUDA y soporte NVENC/NVDEC...${NC}"
    dnf install -y xorg-x11-drv-nvidia-cuda
else
    echo -e "\n${AMARILLO}[5/5] Saltando soporte CUDA.${NC}"
fi

# --- ACCIONES POST-INSTALACIÓN ---
echo -e "\n${AZUL}=====================================================${NC}"
echo -e "${AZUL}            PROCESO DE CARGA TERMINADO               ${NC}"
echo -e "${AZUL}=====================================================${NC}"

if [ "$INSTALAR_DRIVERS" = true ]; then
    echo -e "${AMARILLO}AVISO MUY IMPORTANTE:${NC}"
    echo "Fedora y akmod están compilando el módulo de NVIDIA para tus kernels instalados."
    echo "Por favor, ESPERA de 3 a 5 minutos exactos antes de reiniciar tu computadora."
    echo -e "\nUna vez pasados los minutos, ejecuta: ${VERDE}sudo reboot${NC}"
    echo "En la pantalla de GRUB podrás elegir arrancar con el kernel estándar o el de CachyOS."
else
    echo -e "${VERDE}¡Hecho! No has seleccionado cambios que requieran compilación masiva. Ya puedes reiniciar si lo deseas.${NC}"
fi


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
    dnf install -y https://rpmfusion.org(rpm -E %fedora).noarch.rpm \
                   https://rpmfusion.org(rpm -E %fedora).noarch.rpm
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
