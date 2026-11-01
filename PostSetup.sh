#!/usr/bin/env bash

# =====================================================================
# SUITE PORTÁTIL DE MANTENIMIENTO: REPARACIÓN, RICE Y ICONOS (BAZZITE)
# =====================================================================

# Colores para una salida limpia en terminal
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
NC='\033[0m' # Sin color

# Función auxiliar para pausar la pantalla
pausar() {
    echo ""
    read -p "Presiona [Enter] para volver al menú..."
}

# Obtener de forma dinámica la ruta física del pendrive donde está corriendo el script
RUTA_PENDRIVE="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"

# Variables de entorno compartidas
AGENTE_BIN="/usr/libexec/kf6/polkit-kde-authentication-agent-1"
DIRECTORIO_AUTOSTART="${HOME}/.config/autostart"
ARCHIVO_DESKTOP="${DIRECTORIO_AUTOSTART}/polkit-kde-authentication-agent-1.desktop"
RUTA_ICONOS="$RUTA_PENDRIVE/Iconos"
RUTA_LOCAL_APPS="${HOME}/.local/share/applications"

# Lista de aplicaciones registradas (para aplicar/revertir iconos)
declare -a APPS_ICONOS=(
    "com.discordapp.Discord.desktop|scribcord.png|/var/lib/flatpak/exports/share/applications"
    "org.kde.dolphin.desktop|scribder.png|/usr/share/applications"
    "kitty.desktop|Scribbled_Kitty.png|/usr/share/applications"
    "org.mozilla.firefox.desktop|scribfox.png|/var/lib/flatpak/exports/share/applications"
    "steam.desktop|scribsteam.png|/usr/share/applications"
)

# =====================================================================
# LOGICA DE LOS MÓDULOS (INSTALACIÓN COMPLETA)
# =====================================================================

ejecutar_instalacion_completa() {
    echo -e "\n${AZUL}=======================================================${NC}"
    echo -e "${AZUL}🚀 Iniciando Instalación Completa Post-Instalación${NC}"
    echo -e "${AZUL}=======================================================${NC}"

    # --- PASO 1: POLKIT ---
    echo -e "\n${AMARILLO}[+] Paso 1: Configurando Agente Polkit para KineticWE...${NC}"
    if [ ! -f "$AGENTE_BIN" ]; then
        echo -e "${ROJO}❌ Error crítico: El archivo $AGENTE_BIN no existe.${NC}"
        pausar
        return 1
    fi

    mkdir -p "$DIRECTORIO_AUTOSTART"
    cat << EOF > "$ARCHIVO_DESKTOP"
[Desktop Entry]
Type=Application
Name=KDE Polkit Authentication Agent
Comment=Motor de contraseñas de administrador para apps gráficas
Exec=$AGENTE_BIN
Terminal=false
X-KDE-Autostart-phase=1
EOF
    chmod +x "$ARCHIVO_DESKTOP"
    echo -e "${VERDE}✔ Lanzador Polkit configurado correctamente en el Home.${NC}"

    if pgrep -f "$(basename "$AGENTE_BIN")" > /dev/null; then
        echo -e "${AZUL}ℹ El agente ya se encuentra corriendo en segundo plano.${NC}"
    else
        "$AGENTE_BIN" &
        echo -e "${VERDE}✔ ¡Agente Polkit iniciado con éxito en segundo plano!${NC}"
    fi

    # --- PASO 2: RESTAURACIÓN RICE ---
    echo -e "\n${AMARILLO}[+] Paso 2: Preparando la restauración del entorno...${NC}"
    if [ -n "$(ls -A "$RUTA_PENDRIVE"/rice_kineticos_*.tar.gz 2>/dev/null)" ]; then
        Archivo_Mas_Reciente=$(ls -t "$RUTA_PENDRIVE"/rice_kineticos_*.tar.gz 2>/dev/null | head -n 1)
        Nombre_Base_Archivo=$(basename "$Archivo_Mas_Reciente")
        echo -e "${VERDE}✔ Copia de seguridad encontrada en el pendrive:${NC}"
        echo "   📦 $Nombre_Base_Archivo"
    else
        echo -e "${ROJO}❌ Error: No se encontró ninguna copia ('rice_kineticos_*.tar.gz') en la raíz del pendrive.${NC}"
        pausar
        return 1
    fi

    read -p "¿Deseas restaurar este archivo específico? [s/N]: " confirmar
    if [[ "$confirmar" =~ ^[Ss]$ ]]; then
        echo -e "\n${AZUL}-> Purgando entornos antiguos (Noctalia y KineticWE)...${NC}"
        rm -rf "$HOME/.config/kineticwe" "$HOME/.config/noctalia" "$HOME/.config/noctalia-kwe" \
               "$HOME/.config/noctalia-greeter-kwe" "$HOME/.config/noctalia-greeter" \
               "$HOME/.config/niri" "$HOME/.local/state/noctalia" "$HOME/.local/state/noctalia-kwe"

        echo -e "${AZUL}-> Extrayendo archivos en tu zona personal ($HOME)...${NC}"
        tar -xzf "$Archivo_Mas_Reciente" -C "$HOME/"
        if [ $? -eq 0 ]; then
            echo -e "${VERDE}✔ ¡Tu personalización ha sido restaurada con éxito!${NC}"
        else
            echo -e "${ROJO}❌ Error: Falló la extracción del archivo tar.gz.${NC}"
            pausar
            return 1
        fi
    else
        echo -e "${AMARILLO}⚠ Restauración del Rice omitida por el usuario.${NC}"
    fi

    # --- PASO 3: APLICAR ICONOS ---
    echo -e "\n${AMARILLO}[+] Paso 3: Verificando y reaplicando iconos personalizados...${NC}"
    A_MENOS_UNO_CAMBIADO=false

    if [ -d "$RUTA_ICONOS" ]; then
        for app in "${APPS_ICONOS[@]}"; do
            IFS="|" read -r desktop_file icono_file ruta_origen <<< "$app"

            if [ -f "$RUTA_ICONOS/$icono_file" ]; then
                if [ -z "$ruta_origen" ] || [ ! -f "$ruta_origen/$desktop_file" ]; then
                    ruta_detectada=$(find /var/lib/flatpak/ ~/.local/share/ /usr/share/applications/ -name "$desktop_file" -print -quit 2>/dev/null)
                    if [ -n "$ruta_detectada" ]; then
                        ruta_origen=$(dirname "$ruta_detectada")
                    fi
                fi

                if [ -f "$ruta_origen/$desktop_file" ]; then
                    echo -e "${AZUL} -> Aplicando icono personalizado a ${VERDE}${desktop_file}${NC}"
                    mkdir -p "$RUTA_LOCAL_APPS"
                    cp "$ruta_origen/$desktop_file" "$RUTA_LOCAL_APPS/"
                    sed -i "s|^Icon=.*|Icon=${RUTA_ICONOS}/${icono_file}|" "$RUTA_LOCAL_APPS/$desktop_file"
                    A_MENOS_UNO_CAMBIADO=true
                else
                    echo -e "${ROJO} ⚠ No se encontró el archivo de origen para ${desktop_file}${NC}"
                fi
            else
                echo -e "${AMARILLO} ⚠ Saltando ${desktop_file}: El icono ${icono_file} no existe en el pendrive.${NC}"
            fi
        done
    else
        echo -e "${ROJO}❌ Error: No se encontró la carpeta 'Iconos' en la raíz del pendrive.${NC}"
    fi

    if [ "$A_MENOS_UNO_CAMBIADO" = true ]; then
        update-desktop-database "$RUTA_LOCAL_APPS" &>/dev/null
        echo -e "${VERDE}✔ ¡Iconos personalizados aplicados correctamente!${NC}"
    fi

    # --- REINICIO AUTOMÁTICO ---
    echo -e "\n${AZUL}=======================================================${NC}"
    echo -e "${VERDE}🎉 ¡Todo el proceso se ha completado correctamente!${NC}"
    echo -e "${AZUL}=======================================================${NC}"
    echo -e "\n${AMARILLO}El sistema se reiniciará automáticamente en 5 segundos...${NC}"
    for i in {5..1}; do
        echo -e "${AMARILLO}$i...${NC}"
        sleep 1
    done
    echo -e "${AZUL}Reiniciando sistema... Bye!${NC}"
    reboot
}
respaldar_rice_kinetic() {
    echo -e "\n${AMARILLO}[+] Iniciando copia de seguridad de tu personalización (Rice)...${NC}"
    
    # El archivo se guardará directamente en la raíz de tu pendrive
    Archivo_Backup="$RUTA_PENDRIVE/rice_kineticos_$(date +%Y%m%d_%H%M%S).tar.gz"

    echo -e "${AZUL}-> Rastreando componentes del sistema en tu usuario...${NC}"

    if [ -d "$HOME/.config/kineticwe" ]; then
        # Entramos a la home del usuario para empaquetar rutas relativas limpias
        cd "$HOME" || return 1

        # 1. Carpetas estándar de KineticWE, Noctalia y Niri en .config
        RUTAS_A_COPIAR=".config/kineticwe"
        [ -d ".config/noctalia" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .config/noctalia"
        [ -d ".config/noctalia-kwe" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .config/noctalia-kwe"
        [ -d ".config/noctalia-greeter-kwe" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .config/noctalia-greeter-kwe"
        [ -d ".config/noctalia-greeter" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .config/noctalia-greeter"
        [ -d ".config/niri" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .config/niri"

        # 2. Estado persistente de la interfaz gráfica (Noctalia GUI)
        [ -d ".local/state/noctalia" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .local/state/noctalia"
        [ -d ".local/state/noctalia-kwe" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .local/state/noctalia-kwe"

        echo -e "${AZUL}-> Empaquetando componentes detectados hacia el pendrive...${NC}"
        tar -czf "$Archivo_Backup" $RUTAS_A_COPIAR 2>/dev/null

        if [ $? -eq 0 ]; then
            echo -e "\n${VERDE}✔ ¡Copia de seguridad creada con éxito!${NC}"
            echo -e "${AZUL}Se ha guardado de forma portátil en: ${NC}\n   📦 $(basename "$Archivo_Backup")"
        else
            echo -e "\n${ROJO}❌ Error al intentar comprimir los archivos de personalización.${NC}"
        fi
    else
        echo -e "\n${ROJO}❌ Error: No se encontró la carpeta 'kineticwe' en ~/.config. No hay un Rice activo que respaldar.${NC}"
    fi

    pausar
}

restaurar_iconos_defecto() {
    echo -e "\n${AMARILLO}[+] Preparando la restauración de iconos por defecto...${NC}"
    echo -e "${AZUL}(Esto eliminará los accesos directos modificados de tu usuario)${NC}"

    read -rp "$(echo -e "${AMARILLO}¿Restaurar iconos originales? [s/N]: ${NC}")" respuesta

    if [[ "$respuesta" =~ ^[sS]$ ]]; then
        A_MENOS_UNO_REVERTIDO=false

        for app in "${APPS_ICONOS[@]}"; do
            # Extraemos únicamente el nombre del archivo desktop de la lista mapeada
            IFS="|" read -r desktop_file _ <<< "$app"

            if [ -f "$RUTA_LOCAL_APPS/$desktop_file" ]; then
                echo -e "${ROJO} -> Eliminando custom desktop de ${VERDE}${desktop_file}${NC}"
                rm "$RUTA_LOCAL_APPS/$desktop_file"
                A_MENOS_UNO_REVERTIDO=true
            fi
        done

        if [ "$A_MENOS_UNO_REVERTIDO" = true ]; then
            update-desktop-database "$RUTA_LOCAL_APPS" &>/dev/null
            echo -e "\n${VERDE}✔ ¡Iconos restaurados! El sistema vuelve a usar los de fábrica.${NC}"
            echo -e "${AMARILLO}(Nota: Puede que necesites desanclar y volver a anclar las apps de tu barra para ver el cambio).${NC}"
        else
            echo -e "\n${VERDE}✔ No se encontraron iconos personalizados activos que restaurar.${NC}"
        fi
    else
        echo -e "${AZUL}-> Manteniendo tu set de iconos personalizados activos.${NC}"
    fi

    pausar
}

# =====================================================================
# BUCLE PRINCIPAL DEL MENÚ
# =====================================================================
while true; do
    clear
    echo -e "${AZUL}=======================================================${NC}"
    echo -e "${AZUL}    🛠️  SUITE DE CONFIGURACIÓN Y MANTENIMIENTO BAZZITE${NC}"
    echo -e "    Unidad USB detectada en: $RUTA_PENDRIVE"
    echo -e "${AZUL}=======================================================${NC}"
    echo -e " 1) Ejecutar instalación completa + Rice + Iconos (Reinicia en 5s)"
    echo -e " 2) Respaldar personalización actual (Crea .tar.gz en el Pendrive)"
    echo -e " 3) Restaurar iconos originales del sistema (Deshacer cambios)"
    echo -e " 4) Salir"
    echo -e "${AZUL}=======================================================${NC}"
    
    read -p "Selecciona una opción [1-4]: " opcion

    case $opcion in
        1)
            ejecutar_instalacion_completa
            ;;
        2)
            respaldar_rice_kinetic
            ;;
        3)
            restaurar_iconos_defecto
            ;;
        4)
            echo -e "\n${VERDE}¡Hasta luego! Saliendo limpiamente...${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${ROJO}❌ Opción no válida. Por favor, introduce un número del 1 al 4.${NC}"
            sleep 1.5
            ;;
    esac
done
