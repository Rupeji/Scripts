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
