#!/usr/bin/env bash

# =====================================================================
# MINI SCRIPT: APLICAR EXCLUSIVAMENTE ICONOS CUSTOM (NEMO)
# =====================================================================

VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
NC='\033[0m'

# Configuración estricta de rutas solicitadas
RUTA_LOCAL_APPS="$HOME/.local/share/applications"
RUTA_ICONOS="$HOME/Pictures/Iconos"

# Listas de mapeo actualizadas (Nemo en lugar de Dolphin)
ARCHIVOS_DESKTOP=("com.discordapp.Discord.desktop" "nemo.desktop" "kitty.desktop" "org.mozilla.firefox.desktop" "steam.desktop")
ARCHIVOS_ICONO=("scribcord.png" "scribder.png" "Scribbled_Kitty.png" "scribfox.png" "scribsteam.png")
RUTAS_SUGERIDAS=("/var/lib/flatpak/exports/share/applications" "/usr/share/applications" "/usr/share/applications" "/var/lib/flatpak/exports/share/applications" "/usr/share/applications")

echo -e "${AZUL}=======================================================${NC}"
echo -e "${AZUL}🎨 Aplicando Suite de Iconos Personalizados (Nemo v5)${NC}"
echo -e "${AZUL}=======================================================${NC}"

A_MENOS_UNO_CAMBIADO=false

if [ -d "$RUTA_ICONOS" ]; then
    for i in "${!ARCHIVOS_DESKTOP[@]}"; do
        desktop_file="${ARCHIVOS_DESKTOP[$i]}"
        icono_file="${ARCHIVOS_ICONO[$i]}"
        ruta_origen="${RUTAS_SUGERIDAS[$i]}"

        if [ -f "$RUTA_ICONOS/$icono_file" ]; then
            # Si el lanzador base no está en la ruta sugerida, lo buscamos en el sistema
            if [ ! -f "$ruta_origen/$desktop_file" ]; then
                ruta_detectada=$(find /var/lib/flatpak/ ~/.local/share/ /usr/share/applications/ -name "$desktop_file" -print -quit 2>/dev/null)
                [ -n "$ruta_detectada" ] && ruta_origen=$(dirname "$ruta_detectada")
            fi

            if [ -f "$ruta_origen/$desktop_file" ]; then
                echo -e "${AZUL} -> Enlazando icono custom a ${VERDE}${desktop_file}${NC}"
                mkdir -p "$RUTA_LOCAL_APPS"
                cp "$ruta_origen/$desktop_file" "$RUTA_LOCAL_APPS/"
                sed -i "s|^Icon=.*|Icon=${RUTA_ICONOS}/${icono_file}|" "$RUTA_LOCAL_APPS/$desktop_file"
                A_MENOS_UNO_CAMBIADO=true
            else
                echo -e "${ROJO} ⚠ No se encontró el lanzador de origen para $desktop_file${NC}"
            fi
        else
            echo -e "${AMARILLO} ⚠ Saltando $desktop_file: El icono $icono_file no existe en $RUTA_ICONOS${NC}"
        fi
    done
else
    echo -e "${ROJO}❌ Error: No existe la carpeta de origen: $RUTA_ICONOS${NC}"
fi

if [ "$A_MENOS_UNO_CAMBIADO" = true ]; then
    update-desktop-database "$RUTA_LOCAL_APPS" &>/dev/null
    echo -e "\n${VERDE}✔ ¡Suite de iconos aplicados correctamente en tu sesión!${NC}"
else
    echo -e "\n${AMARILLO}⚠ No se realizó ninguna modificación.${NC}"
fi
