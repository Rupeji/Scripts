#!/usr/bin/env bash

# =====================================================================
# MINI SCRIPT: INSTALACIÓN RÁPIDA DE COMPONENTES GTK (MATE-POLKIT VM)
# =====================================================================

VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
NC='\033[0m'

# Configuración estricta de rutas locales
RUTA_LOCAL_APPS="$HOME/.local/share/applications"
RUTA_ICONOS="$HOME/Pictures/Iconos"
AGENTE_BIN="/usr/libexec/polkit-mate-authentication-agent-1"
ARCHIVO_DESKTOP_MATE="$HOME/.config/autostart/polkit-mate-authentication-agent-1.desktop"

# Listas de mapeo actualizadas (Nemo nativo en lugar de Dolphin)
ARCHIVOS_DESKTOP=("com.discordapp.Discord.desktop" "nemo.desktop" "kitty.desktop" "org.mozilla.firefox.desktop" "steam.desktop")
ARCHIVOS_ICONO=("scribcord.png" "scribder.png" "Scribbled_Kitty.png" "scribfox.png" "scribsteam.png")
RUTAS_SUGERIDAS=("/var/lib/flatpak/exports/share/applications" "/usr/share/applications" "/usr/share/applications" "/var/lib/flatpak/exports/share/applications" "/usr/share/applications")

echo -e "${AZUL}=======================================================${NC}"
echo -e "${AZUL}🛠️  Iniciando Parche Rápido de Componentes MATE/GTK en VM${NC}"
echo -e "${AZUL}=======================================================${NC}"

# --- PASO 1: CONFIGURACIÓN Y PURGA DE POLKIT ---
echo -e "\n${AMARILLO}[+] Configurando entorno de seguridad Polkit-MATE...${NC}"

# Purgar lanzadores viejos de KDE o GNOME por si acaso
rm -f "$HOME/.config/autostart/polkit-kde-authentication-agent-1.desktop"
rm -f "$HOME/.config/autostart/polkit-gnome-authentication-agent-1.desktop"

if [ -f "$AGENTE_BIN" ]; then
    mkdir -p "$HOME/.config/autostart"
    cat << EOF > "$ARCHIVO_DESKTOP_MATE"
[Desktop Entry]
Type=Application
Name=MATE Polkit Authentication Agent
Comment=Motor de contraseñas de administrador ligero en GTK3
Exec=$AGENTE_BIN
Terminal=false
EOF
    chmod +x "$ARCHIVO_DESKTOP_MATE"
    
    # Matar instancias antiguas levantadas
    pkill -f "polkit-kde" 2>/dev/null
    pkill -f "polkit-gnome" 2>/dev/null
    
    if ! pgrep -f "$(basename "$AGENTE_BIN")" > /dev/null; then
        "$AGENTE_BIN" >/dev/null 2>&1 &
        echo -e "${VERDE}✔ ¡Agente Polkit de MATE activo en segundo plano!${NC}"
    else
        echo -e "${AZUL}ℹ El agente de MATE ya se encuentra corriendo.${NC}"
    fi
else
    echo -e "${ROJO}❌ Error: No se encontró el binario de mate-polkit en /usr/libexec/.${NC}"
fi

# --- PASO 2: MAPEO DE ICONOS PERSONALIZADOS ---
echo -e "\n${AMARILLO}[+] Aplicando Suite de Iconos desde Pictures/Iconos...${NC}"
A_MENOS_UNO_CAMBIADO=false

if [ -d "$RUTA_ICONOS" ]; then
    for i in "${!ARCHIVOS_DESKTOP[@]}"; do
        desktop_file="${ARCHIVOS_DESKTOP[$i]}"
        icono_file="${ARCHIVOS_ICONO[$i]}"
        ruta_origen="${RUTAS_SUGERIDAS[$i]}"

        if [ -f "$RUTA_ICONOS/$icono_file" ]; then
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
            fi
        fi
    done
else
    echo -e "${ROJO}❌ Error: No existe la carpeta: $RUTA_ICONOS${NC}"
fi

if [ "$A_MENOS_UNO_CAMBIADO" = true ]; then
    update-desktop-database "$RUTA_LOCAL_APPS" &>/dev/null
    echo -e "\n${VERDE}✔ ¡Suite de iconos y Polkit-MATE aplicados correctamente!${NC}"
fi
