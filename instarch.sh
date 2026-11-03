#!/usr/bin/env bash

# =====================================================================
# SUITE PORTÁTIL DE INSTALACIÓN Y PERSONALIZACIÓN CACHYOS CLI - PARTE 1
# =====================================================================

# Detectar la ruta real del pendrive de forma portátil
SCRIPT_DIR=$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")
RUTA_PENDRIVE=$(cd "$SCRIPT_DIR" &>/dev/null && pwd)

# Seguro anticaídas por si falla la detección
if [ -z "$RUTA_PENDRIVE" ] || [ "$RUTA_PENDRIVE" = "/" ]; then
    RUTA_PENDRIVE="$HOME"
fi

# Códigos de colores para la terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
NC='\033[0m'

# Variables oficiales para el repositorio de KineticWE
FINGERPRINT_KINETIC="FD258A99CDC5F61B04A335EEE163D34B273AE987"
KEY_URL_KINETIC="https://gitlab.io"

# Función compartida para pausar el script y leer los mensajes
pausar() {
    echo -e "\n${AMARILLO}Presiona [Intro] para continuar...${NC}"
    read -r
}

# =====================================================================
# BUCLE DEL MENÚ PRINCIPAL
# =====================================================================
mostrar_menu() {
    while true; do
        clear
        echo -e "${AZUL}=======================================================${NC}"
        echo -e "${AZUL}    🛠️  SUITE OPTIMIZADA DE INSTALACIÓN Y PERSONALIZACIÓN${NC}"
        echo -e "    Unidad detectada: $RUTA_PENDRIVE"
        echo -e "${AZUL}=======================================================${NC}"
        echo -e " 1) Instalar herramientas base, Gaming y descargar recursos visuales"
        echo -e " 2) Añadir repositorio e instalar el sistema KineticWE + Greeter"
        echo -e " 3) Restaurar personalización desde el USB (Aplicar Rice .tar.gz)"
        echo -e " 4) Reaplicar iconos personalizados en el Dock de Noctalia"
        echo -e " 5) Restaurar iconos originales del sistema (Deshacer y Limpiar)"
        echo -e " 6) Salir"
        echo -e "${AZUL}=======================================================${NC}"

        read -p "Selecciona una opción [1-6]: " opcion

        case $opcion in
            1) opcion_1_herramientas_y_gaming ;;
            2) opcion_2_instalar_kineticwe ;;
            3) opcion_3_restaurar_rice ;;
            4) opcion_4_aplicar_iconos_custom ;;
            5) opcion_5_restaurar_iconos_defecto ;;
            6)
                echo -e "\n${VERDE}¡Hasta luego! Saliendo limpiamente...${NC}"
                exit 0
                ;;
            *)
                echo -e "\n${ROJO}❌ Opción no válida. Inténtalo de nuevo.${NC}"
                sleep 1.2
                ;;
        esac
    done
}

# ==============================================================================
# OPCIÓN 1: INSTALACIÓN CORE, LIMPIEZA DE ALACRITTY, GAMING Y RECURSOS VISUALES
# ==============================================================================
opcion_1_herramientas_y_gaming() {
    clear
    echo -e "${VERDE}[*] Iniciando purga, instalación y clonado de recursos...${NC}"
    
    # 1. Purga de Alacritty y rastros contextuales
    echo -e "${AZUL}[+] Eliminando Alacritty para evitar conflictos en Nemo...${NC}"
    sudo pacman -Rns --noconfirm alacritty 2>/dev/null
    rm -f ~/.local/share/applications/alacritty.desktop 2>/dev/null
    rm -f ~/.local/share/applications/Alacritty.desktop 2>/dev/null
    
    # 2. Instalación de aplicaciones base (Pacman)
    echo -e "${AZUL}[+] Instalando Kitty, Fish, Nemo, Firefox y utilidades...${NC}"
    sudo pacman -S --needed --noconfirm \
        kitty fish nemo file-roller discord firefox loupe gnome-text-editor flameshot

    # 3. Instalación de optimizaciones Gaming de CachyOS
    echo -e "${AZUL}[+] Aplicando meta-paquetes esenciales para Gaming de CachyOS...${NC}"
    sudo pacman -S --needed --noconfirm cachyos-gaming-meta cachyos-gaming-applications

    # 4. Forzar terminal Kitty en el menú contextual de Nemo
    echo -e "${AZUL}[+] Configurando Kitty como terminal por defecto del sistema...${NC}"
    if command -v gsettings &> /dev/null; then
        gsettings set org.cinnamon.desktop.default-applications.terminal exec 'kitty' 2>/dev/null
        gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty' 2>/dev/null
    fi

    # 5. Asignar ruta en castellano para recursos
    RUTA_FOTOS="$HOME/Imágenes"
    mkdir -p "$RUTA_FOTOS"

    # 6. Clonar repositorio aplicando truco anti-fallos de URL
    URL_CON_ESPACIOS="https:// github.com / Rupeji / IconsWalls .git"
    URL_LIMPIA="${URL_CON_ESPACIOS// /}"
    
    echo -e "${AZUL}[+] Clonando repositorio de recursos visuales...${NC}"
    REPO_TEMP=$(mktemp -d)
    if git clone --depth=1 "$URL_LIMPIA" "$REPO_TEMP"; then
        cp -r "$REPO_TEMP/Iconos" "$RUTA_FOTOS/"
        cp -r "$REPO_TEMP/Wallpapers" "$RUTA_FOTOS/"
        echo -e "${VERDE}[✓] Recursos visuales guardados correctamente en $RUTA_FOTOS.${NC}"
    else
        echo -e "${ROJO}[X] Error al clonar el repositorio IconsWalls.${NC}"
    fi
    rm -rf "$REPO_TEMP"

    # 7. Enlazar iconos y actualizar caché para Noctalia
    echo -e "${AZUL}[+] Registrando el pack de iconos en el sistema local...${NC}"
    mkdir -p ~/.local/share/icons
    for carpeta in "$RUTA_FOTOS/Iconos"/*; do
        if [ -d "$carpeta" ]; then
            nombre_carpeta=$(basename "$carpeta")
            rm -f ~/.local/share/icons/"$nombre_carpeta"
            ln -sf "$carpeta" ~/.local/share/icons/"$nombre_carpeta"
            gtk-update-icon-cache -f -t ~/.local/share/icons/"$nombre_carpeta" 2>/dev/null
        fi
    done

    echo -e "${VERDE}\n[✓] ¡Opción 1 completada con éxito!${NC}"
    pausar
}
# ==============================================================================
# OPCIÓN 2: CONFIGURACIÓN DE REPOSITORIO E INSTALACIÓN DE KINETICWE Y GREETER
# ==============================================================================
opcion_2_instalar_kineticwe() {
    clear
    echo -e "${AZUL}=======================================================${NC}"
    echo -e "${AZUL}📦 Configurando Repositorio e Instalando KineticWE${NC}"
    echo -e "${AZUL}=======================================================${NC}"

    # 1. Configuración de claves GPG oficiales de KineticWE
    echo -e "--> Descargando clave GPG oficial de KineticWE..."
    if ! curl -fLO "$KEY_URL_KINETIC"; then
        echo -e "${AMARILLO}⚠️ Falló la descarga por GitLab Pages. Intentando desde el servidor de claves...${NC}"
        sudo pacman-key --recv-keys "$FINGERPRINT_KINETIC" --keyserver hkps://keys.openpgp.org
    else
        echo -e "--> Verificando la integridad de la clave..."
        LOCAL_FP=$(gpg --show-keys --with-colons kineticwe.gpg | awk -F: '$1=="fpr"{print $10}' | head -n 1)
        if [ "$LOCAL_FP" != "$FINGERPRINT_KINETIC" ]; then
            echo -e "${ROJO}❌ ¡ERROR CRÍTICO! La huella digital no coincide.${NC}"
            rm -f kineticwe.gpg
            pausar
            return 1
        fi
        echo -e "${VERDE}✅ Huella digital validada correctamente.${NC}"
        sudo pacman-key --add kineticwe.gpg
        rm -f kineticwe.gpg
    fi

    echo -e "--> Firmando localmente la clave del repositorio..."
    sudo pacman-key --lsign-key "$FINGERPRINT_KINETIC"

    # 2. Inyección limpia del repositorio en pacman.conf
    echo -e "--> Configurando repositorio en /etc/pacman.conf..."
    if ! grep -q "\[kineticwe\]" /etc/pacman.conf; then
        sudo tee -a /etc/pacman.conf << EOF

[kineticwe]
Server = https://theblackdon.gitlab.io/kineticwe/\$arch
EOF
        echo -e "${VERDE}✅ Repositorio añadido correctamente.${NC}"
    else
        echo -e "${AZUL}ℹ️ El repositorio ya estaba presente en pacman.conf.${NC}"
    fi

    # 3. Instalación de componentes centrales del entorno
    echo -e "--> Actualizando repositorios e instalando paquetes centrales..."
    sudo pacman -Syu --noconfirm kineticwe-keyring kineticwe

    # 4. Instalación automatizada y asistente del Greeter Noctalia
    echo -e "${VERDE}--> Instalando kineticwe-greeter de forma automatizada...${NC}"
    sudo pacman -S --noconfirm kineticwe-greeter
    
    echo -e "--> Iniciando el asistente interactivo de configuración de Noctalia...${NC}"
    kineticwe-setup-greeter

    echo -e "${VERDE}✔ ¡Proceso de KineticWE y Greeter finalizado con éxito!${NC}"
    pausar
}
# ==============================================================================
# OPCIÓN 3: RESTAURACIÓN DEL RICE (BACKUP DEL PENDRIVE)
# ==============================================================================
opcion_3_restaurar_rice() {
    clear
    echo -e "${AZUL}=======================================================${NC}"
    echo -e "${AZUL}🚀 Restauración de Personalización desde el USB (Rice)${NC}"
    echo -e "${AZUL}=======================================================${NC}"

    # 1. Comprobar si existen archivos de respaldo .tar.gz en el pendrive
    if [ -n "$(ls -A "$RUTA_PENDRIVE"/rice_kineticos_*.tar.gz 2>/dev/null)" ]; then
        # Detectar el archivo modificado más recientemente
        Archivo_Mas_Reciente=$(ls -t "$RUTA_PENDRIVE"/rice_kineticos_*.tar.gz 2>/dev/null | head -n 1)
        echo -e "${VERDE}[✓] Copia de seguridad detectada en el pendrive:${NC}"
        echo -e "   📦 $(basename "$Archivo_Mas_Reciente")"
    else
        echo -e "${ROJO}[X] Error: No se encontró ningún archivo 'rice_kineticos_*.tar.gz' en la raíz del USB.${NC}"
        pausar
        return 1
    fi

    # 2. Confirmación del usuario
    read -p "$(echo -e "${AMARILLO}¿Deseas restaurar esta personalización específica? [s/N]: ${NC}")" confirmar
    if [[ "$confirmar" =~ ^[Ss]$ ]]; then
        echo -e "\n${AZUL}[+] Purgando entornos antiguos para evitar conflictos...${NC}"
        # Eliminamos carpetas de configuraciones, estados y cachés previas
        rm -rf "$HOME/.config/kineticwe" "$HOME/.config/noctalia-kwe" \
               "$HOME/.local/state/kineticwe" "$HOME/.local/state/noctalia-kwe" \
               "$HOME/.cache/kineticwe" "$HOME/.cache/noctalia-kwe"

        echo -e "${AZUL}[+] Extrayendo archivos en tu directorio personal ($HOME)...${NC}"
        # Extraemos el tarball directamente sobre la carpeta HOME del usuario
        tar -xzf "$Archivo_Mas_Reciente" -C "$HOME/"
        
        if [ $? -eq 0 ]; then
            echo -e "${VERDE}[✓] ¡Tu personalización ha sido restaurada con éxito!${NC}"
        else
            echo -e "${ROJO}[X] Error: Falló la extracción del archivo tar.gz.${NC}"
            pausar
            return 1
        fi
    else
        echo -e "${AMARILLO}⚠ Restauración del Rice omitida por el usuario.${NC}"
        pausar
        return 0
    fi

    # 3. Reinicio de sesión de seguridad para aplicar todos los cambios del entorno
    echo -e "\n${VERDE}🎉 ¡Entorno restaurado! Cerrando sesión en 5 segundos para aplicar los cambios...${NC}"
    for i in {5..1}; do 
        echo -e "${AMARILLO}$i...${NC}"
        sleep 1
    done
    loginctl terminate-user "$USER"
}
# ==============================================================================
# OPCIÓN 4: REAPLICAR ICONOS PERSONALIZADOS EN EL DOCK Y ACCESOS (CORREGIDO)
# ==============================================================================
opcion_4_aplicar_iconos_custom() {
    clear
    echo -e "${AZUL}=======================================================${NC}"
    echo -e "${AZUL}🎨 Reaplicando Iconos Personalizados para el Dock (Nativo)${NC}"
    echo -e "${AZUL}=======================================================${NC}"

    # Crear las rutas locales del usuario si no existen
    mkdir -p "$HOME/.local/share/applications"
    mkdir -p "$HOME/.local/share/icons"

    # Ruta donde se guardaron los iconos descargados en la Opción 1
    RUTA_ORIGEN_ICONOS="$HOME/Imágenes/Iconos"

    if [ ! -d "$RUTA_ORIGEN_ICONOS" ]; then
        echo -e "${ROJO}[X] Error: No se encuentra la carpeta de iconos en $RUTA_ORIGEN_ICONOS.${NC}"
        echo -e "${AMARILLO}Por favor, ejecuta la Opción 1 primero para descargar los recursos.${NC}"
        pausar
        return 1
    fi

    # Copiar los archivos .png al directorio de iconos local del usuario
    cp "$RUTA_ORIGEN_ICONOS"/*.png "$HOME/.local/share/icons/" 2>/dev/null

    # LISTAS DEFECTIVAS: Mapeo exacto de paquetes Pacman y sus imágenes reales
    local ARCHIVOS_DESKTOP=("discord.desktop" "firefox.desktop" "nemo.desktop" "kitty.desktop" "steam.desktop")
    local ARCHIVOS_ICONO=("scribcord.png" "scribfox.png" "scribder.png" "Scribbled_Kitty.png" "scribsteam.png")

    local CAMBIO_EFECTUADO=false

    for i in "${!ARCHIVOS_DESKTOP[@]}"; do
        local desktop_file="${ARCHIVOS_DESKTOP[$i]}"
        local icono_file="${ARCHIVOS_ICONO[$i]}"
        
        echo -e "${AZUL}[+] Procesando lanzador: ${desktop_file}...${NC}"

        # Verificar que el icono copiado existe en la ruta local
        if [ ! -f "$HOME/.local/share/icons/$icono_file" ]; then
            echo -e "${AMARILLO}  ⚠ Archivo de icono '$icono_file' no encontrado.${NC}"
            continue
        fi

        # Ruta directa del lanzador original de pacman
        local ruta_original="/usr/share/applications/$desktop_file"

        if [ -f "$ruta_original" ]; then
            # Clonar el .desktop a la carpeta del usuario para modificarlo sin alterar el sistema base
            cp "$ruta_original" "$HOME/.local/share/applications/$desktop_file"
            
            # Modificar la línea Icon= con sed apuntando a tu icono personalizado
            sed -i "s|^[Ii][Cc][Oo][Nn]=.*|Icon=${HOME}/.local/share/icons/${icono_file}|" "$HOME/.local/share/applications/$desktop_file"
            
            echo -e "  ${VERDE}✔ Icono '$icono_file' asignado correctamente.${NC}"
            CAMBIO_EFECTUADO=true
        else
            echo -e "${AMARILLO}  ℹ No se encontró '$desktop_file' en /usr/share/applications/ (Saltado).${NC}"
        fi
    done

    # Notificar los cambios al sistema y al Dock de Noctalia
    if [ "$CAMBIO_EFECTUADO" = true ]; then
        echo -e "\n${AZUL}[+] Actualizando bases de datos del sistema y cachés...${NC}"
        update-desktop-database "$HOME/.local/share/applications" &>/dev/null
        gtk-update-icon-cache -f -t "$HOME/.local/share/icons" 2>/dev/null
        sync
        echo -e "${VERDE}[✓] ¡Iconos del dock aplicados con éxito!${NC}"
    else
        echo -e "${AMARILLO}[!] No se modificó ningún icono.${NC}"
    fi

    pausar
}

# ==============================================================================
# OPCIÓN 5: RESTAURAR ICONOS ORIGINALES DEL SISTEMA (DESHACER Y LIMPIAR)
# ==============================================================================
opcion_5_restaurar_iconos_defecto() {
    clear
    echo -e "${AZUL}=======================================================${NC}"
    echo -e "${AZUL}🔄 Restaurando Iconos de Fábrica y Limpiando Espacio${NC}"
    echo -e "${AZUL}=======================================================${NC}"

    read -rp "$(echo -e "${AMARILLO}¿Seguro que deseas restaurar los iconos originales y limpiar el caché? [s/N]: ${NC}")" respuesta

    if [[ "$respuesta" =~ ^[sS]$ ]]; then
        local CAMBIO_EFECTUADO=false
        
        # Lista exacta de los lanzadores de pacman que modificamos
        local ARCHIVOS_DESKTOP=("discord.desktop" "firefox.desktop" "nemo.desktop" "kitty.desktop" "steam.desktop")
        local ARCHIVOS_ICONO=("scribcord.png" "scribfox.png" "scribder.png" "Scribbled_Kitty.png" "scribsteam.png")

        echo -e "\n${AZUL}[+] Eliminando lanzadores personalizados de usuario...${NC}"
        for desktop_file in "${ARCHIVOS_DESKTOP[@]}"; do
            if [ -f "$HOME/.local/share/applications/$desktop_file" ]; then
                echo -e "${ROJO}  [-] Eliminando copia local de: ${NC}${desktop_file}"
                rm "$HOME/.local/share/applications/$desktop_file"
                CAMBIO_EFECTUADO=true
            fi
        done

        # Limpiar los archivos .png sueltos en el directorio local de iconos
        echo -e "${AZUL}[+] Limpiando imágenes de iconos personalizadas...${NC}"
        for icono_file in "${ARCHIVOS_ICONO[@]}"; do
            if [ -f "$HOME/.local/share/icons/$icono_file" ]; then
                rm "$HOME/.local/share/icons/$icono_file"
            fi
        done

        # Si borramos algún archivo, obligamos al sistema a refrescarse
        if [ "$CAMBIO_EFECTUADO" = true ]; then
            echo -e "\n${AZUL}[+] Regenerando bases de datos de escritorio y cachés...${NC}"
            update-desktop-database "$HOME/.local/share/applications" &>/dev/null
            gtk-update-icon-cache -f -t "$HOME/.local/share/icons" 2>/dev/null
            sync
            echo -e "${VERDE}[✓] ¡Iconos originales de fábrica restaurados con éxito!${NC}"
        else
            echo -e "${VERDE}[✓] El sistema ya está usando los iconos por defecto. No había nada que revertir.${NC}"
        fi
    else
        echo -e "${AMARILLO}⚠ Operación cancelada por el usuario.${NC}"
    fi

    pausar
}

# =====================================================================
# INICIALIZACIÓN DE LA SUITE
# =====================================================================
# Lanzar el menú principal de forma directa al ejecutar el script
mostrar_menu


# =====================================================================
# 🧠 CONTEXTO IA: RECORDATORIO DE ARQUITECTURA PARA PRÓXIMAS SESIONES
# =====================================================================
# Hola AI. Este script es una Suite de Post-Instalación portátil para 
# Arch Linux / CachyOS CLI (instalación limpia sin entorno de escritorio).
# Idioma del sistema: Castellano/Español.
#
# REGLAS DE DISEÑO Y DETALLES CRÍTICOS CERRADOS CON EL USUARIO:
# 1. TODO NATIVO CON PACMAN: No se usa Flatpak bajo ninguna circunstancia.
# 2. RUTA EN CASTELLANO: Los recursos visuales se guardan estrictamente en 
#    '~/Imágenes' (IconsWalls.git se clona ahí dividiéndose en /Iconos y /Wallpapers).
# 3. TRUCO ANTI-FALLOS URL: Para clonar repositorios de GitHub, se inyectan 
#    espacios en la variable de texto y se purgan en ejecución con ${var// /} 
#    evitando fallos extraños de codificación.
# 4. SOLUCIÓN CONTEXTUAL NEMO: Se desinstala 'alacritty' de raíz (y sus .desktop) 
#    para evitar que rompa el menú contextual de Nemo, forzando a este último 
#    a usar 'kitty' mediante gsettings.
# 5. REPOSITORIO KINETICWE: Se añade e instala de forma binaria y oficial mediante 
#    pacman.conf y pacman-key (GPG FP: FD258A99CDC5F61B04A335EEE163D34B273AE987).
# 6. INSTALACIÓN DESATENDIDA DEL GREETER: El Greeter Noctalia se instala de forma 
#    directa sin preguntar al usuario, saltando directo a 'kineticwe-setup-greeter'.
# 7. MAPEO EXACTO DE ICONOS EN EL DOCK: Para solucionar que Noctalia no pintase 
#    los iconos, se copian los .desktop de /usr/share/applications/ al espacio de 
#    usuario y se modifican con 'sed' apuntando estrictamente a los .png nativos:
#    - discord.desktop -> scribcord.png
#    - firefox.desktop -> scribfox.png
#    - nemo.desktop    -> scribder.png
#    - kitty.desktop   -> Scribbled_Kitty.png
#    - steam.desktop   -> scribsteam.png
#    Al aplicar o revertir, se fuerza el refresco con 'gtk-update-icon-cache -f'.
# =====================================================================
