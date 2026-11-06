#!/usr/bin/env bash

# Configuración de rutas (Detección inteligente e inmune a redundancias)
SCRIPT_DIR=$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")
RUTA_BASE=$(cd "$SCRIPT_DIR" &>/dev/null && pwd || echo "$HOME")

# Si el script ya se está ejecutando DENTRO de la carpeta "Iconos", usa esa misma carpeta.
# Si no, busca la carpeta "Iconos" en el mismo directorio del script.
if [[ "$(basename "$RUTA_BASE")" == "Iconos" ]]; then
    RUTA_ICONOS="$RUTA_BASE"
else
    RUTA_ICONOS="$RUTA_BASE/Iconos"
fi

RUTA_LOCAL_APPS="$HOME/.local/share/applications"
RUTA_LOCAL_ICONOS="$HOME/.local/share/icons"

# Listas de archivos emparejados
ARCHIVOS_DESKTOP=("com.discordapp.Discord.desktop" "nemo.desktop" "kitty.desktop" "org.mozilla.firefox.desktop" "steam.desktop")
ARCHIVOS_ICONO=("scribcord.png" "scribder.png" "Scribbled_Kitty.png" "scribfox.png" "scribsteam.png")

VERDE='\033[0;32m'
ROJO='\033[0;31m'
NC='\033[0m'

aplicar_iconos() {
    if [ ! -d "$RUTA_ICONOS" ]; then
        echo -e "${ROJO}❌ Error: No se encuentra la carpeta de origen en: $RUTA_ICONOS${NC}"
        return 1
    fi

    mkdir -p "$RUTA_LOCAL_APPS" "$RUTA_LOCAL_ICONOS"

    for i in "${!ARCHIVOS_DESKTOP[@]}"; do
        local desktop="${ARCHIVOS_DESKTOP[$i]}"
        local icono="${ARCHIVOS_ICONO[$i]}"
        
        # Buscar el archivo de imagen (.png) directamente en la ruta calculada
        local ruta_imagen_origen=$(find "$RUTA_ICONOS" -maxdepth 2 -name "$icono" -print -quit 2>/dev/null)

        if [ -z "$ruta_imagen_origen" ] || [ ! -f "$ruta_imagen_origen" ]; then
            echo -e "${ROJO}❌ Error: No se pudo localizar el archivo de icono '$icono' dentro de $RUTA_ICONOS${NC}"
            continue
        fi

        # Copiar el icono individualmente a la ruta local
        cp "$ruta_imagen_origen" "$RUTA_LOCAL_ICONOS/"

        # Buscar el archivo .desktop original en el sistema
        local ruta_origen=$(find /var/lib/flatpak/exports/share/applications/ /var/lib/flatpak/app/ "$HOME/.local/share/flatpak/" "$HOME/.local/share/applications/" /usr/share/applications/ -name "$desktop" -print -quit 2>/dev/null)

        if [ -n "$ruta_origen" ] && [ -f "$ruta_origen" ]; then
            # Clonar al espacio de usuario si no existe todavía
            if [ "$ruta_origen" != "$RUTA_LOCAL_APPS/$desktop" ]; then
                cp "$ruta_origen" "$RUTA_LOCAL_APPS/"
            fi
            
            # Reemplazar la línea del icono de forma limpia
            sed -i "s|^[Ii][Cc][Oo][Nn]=.*|Icon=${RUTA_LOCAL_ICONOS}/${icono}|" "$RUTA_LOCAL_APPS/$desktop"
            echo -e "${VERDE}✔ Icono personalizado aplicado a $desktop${NC}"
        else
            echo -e "${ROJO}❌ No se encontró el acceso .desktop del sistema para $desktop${NC}"
        fi
    done
    
    # Forzar actualización de la base de datos de escritorio de Linux
    update-desktop-database "$RUTA_LOCAL_APPS" &>/dev/null
    echo -e "${VERDE}👍 Proceso de aplicación finalizado con éxito.${NC}"
}

quitar_iconos() {
    echo -e "${ROJO}➡ Revirtiendo cambios y restaurando iconos por defecto...${NC}"
    for desktop in "${ARCHIVOS_DESKTOP[@]}"; do
        if [ -f "$RUTA_LOCAL_APPS/$desktop" ]; then
            rm "$RUTA_LOCAL_APPS/$desktop"
            echo "Restaurado: $desktop"
        fi
    done
    for icono in "${ARCHIVOS_ICONO[@]}"; do
        if [ -f "$RUTA_LOCAL_ICONOS/$icono" ]; then
            rm "$RUTA_LOCAL_ICONOS/$icono"
        fi
    done
    update-desktop-database "$RUTA_LOCAL_APPS" &>/dev/null
    echo -e "${VERDE}✔ Iconos originales restaurados con éxito.${NC}"
}

# Menú rápido de ejecución
echo -e "1) Aplicar Iconos Custom\n2) Quitar Iconos Custom y Restaurar"
read -p "Selecciona una opción [1-2]: " opt
case $opt in
    1) aplicar_iconos ;;
    2) quitar_iconos ;;
    *) echo "Opción inválida" ;;
esac


# gsettings set org.cinnamon.desktop.default-applications.terminal exec 'kitty'
# gsettings set org.cinnamon.desktop.default-applications.terminal exec-arg '-e'
