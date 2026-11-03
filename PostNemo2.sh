#!/usr/bin/env bash

# =====================================================================
# SUITE PORTÁTIL DE CONFIGURACIÓN Y DESARROLLO BAZZITE (GTK LIGHT)
# =====================================================================

# [SOLUCIÓN DEFINITIVA] Cálculo universal de ruta compatible con Bash y Fish
SCRIPT_DIR=$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")
RUTA_PENDRIVE=$(cd "$SCRIPT_DIR" &>/dev/null && pwd)

# Seguro anticaídas: si algo falla, usa tu HOME para no tocar la raíz inmutable
if [ -z "$RUTA_PENDRIVE" ] || [ "$RUTA_PENDRIVE" = "/" ]; then
    RUTA_PENDRIVE="$HOME"
fi

VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
NC='\033[0m'

# Variables de la Suite de Iconos adaptadas a Nemo
RUTA_LOCAL_APPS="$HOME/.local/share/applications"
RUTA_ICONOS="$RUTA_PENDRIVE/Iconos"
RUTA_LOCAL_ICONOS="$HOME/.local/share/icons"

ARCHIVOS_DESKTOP=("com.discordapp.Discord.desktop" "nemo.desktop" "kitty.desktop" "org.mozilla.firefox.desktop" "steam.desktop")
ARCHIVOS_ICONO=("scribcord.png" "scribder.png" "Scribbled_Kitty.png" "scribfox.png" "scribsteam.png")

# Función auxiliar para pausar los menús
pausar() {
    echo -e "\n${AMARILLO}Presiona [Intro] para continuar...${NC}"
    read -r
}

# =====================================================================
# FUNCIÓN COMPARTIDA: PROCESAR E INSTALAR ICONOS (SOLUCIÓN FLATPAK)
# =====================================================================
aplicar_iconos_custom() {
    echo -e "\n${AMARILLO}[+] Copiando y reaplicando iconos en el almacenamiento local...${NC}"
    local A_MENOS_UNO_CAMBIADO=false

    if [ -d "$RUTA_ICONOS" ]; then
        mkdir -p "$RUTA_LOCAL_APPS"
        mkdir -p "$RUTA_LOCAL_ICONOS"
        
        # Copiar iconos dentro de HOME para evadir el sandbox de Flatpak
        cp "$RUTA_ICONOS"/*.png "$RUTA_LOCAL_ICONOS/" 2>/dev/null

        for i in "${!ARCHIVOS_DESKTOP[@]}"; do
            local desktop_file="${ARCHIVOS_DESKTOP[$i]}"
            local icono_file="${ARCHIVOS_ICONO[$i]}"
            
            echo -e "${AZUL}Procesando: ${desktop_file}...${NC}"

            if [ ! -f "$RUTA_LOCAL_ICONOS/$icono_file" ]; then
                echo -e "${AMARILLO}  ⚠ El archivo de icono '$icono_file' no se pudo copiar al almacenamiento local.${NC}"
                continue
            fi

            local ruta_detectada=$(find /var/lib/flatpak/exports/share/applications/ \
                                 /var/lib/flatpak/app/ \
                                 "$HOME/.local/share/flatpak/" \
                                 "$HOME/.local/share/applications/" \
                                 /usr/share/applications/ \
                                 -name "$desktop_file" -print -quit 2>/dev/null)

            if [ -n "$ruta_detectada" ] && [ -f "$ruta_detectada" ]; then
                if [ "$ruta_detectada" != "$RUTA_LOCAL_APPS/$desktop_file" ]; then
                    cp "$ruta_detectada" "$RUTA_LOCAL_APPS/"
                    echo -e "  -> Enlazando y clonando archivo original a espacio de usuario."
                fi
                
                sed -i "s|^[Ii][Cc][Oo][Nn]=.*|Icon=${RUTA_LOCAL_ICONOS}/${icono_file}|" "$RUTA_LOCAL_APPS/$desktop_file"
                echo -e "  ${VERDE}✔ Icono modificado correctamente en la ruta local.${NC}"
                A_MENOS_UNO_CAMBIADO=true
            else
                echo -e "  ${ROJO}❌ Error: No se pudo localizar el archivo del sistema para '$desktop_file'.${NC}"
            fi
        done
    else
        echo -e "${ROJO}❌ Error crítico: La carpeta '$RUTA_ICONOS' no fue detectada en el USB.${NC}"
    fi

    if [ "$A_MENOS_UNO_CAMBIADO" = true ]; then
        echo -e "\n${AZUL}[+] Forzando actualización de la base de datos de accesos...${NC}"
        update-desktop-database "$RUTA_LOCAL_APPS" &>/dev/null
        sync
    fi
}

# =====================================================================
# FUNCIÓN: INSTALACIÓN COMPLETA
# =====================================================================
ejecutar_instalacion_completa() {
    echo -e "\n${AZUL}=======================================================${NC}"
    echo -e "${AZUL}🚀 Iniciando Instalación Completa Post-Instalación (GTK)${NC}"
    echo -e "${AZUL}=======================================================${NC}"

    echo -e "\n${AMARILLO}[+] Paso 1: Configurando terminal e interfaz de Nemo...${NC}"
    if command -v gsettings &> /dev/null; then
        gsettings set org.cinnamon.desktop.default-applications.terminal exec 'kitty'
        echo -e "${VERDE}✔ Asociación de Nemo con Kitty configurada en el sistema.${NC}"
        gsettings set org.cinnamon.desktop.interface icon-theme 'Adwaita'
        echo -e "${VERDE}✔ Tema de iconos Adwaita asignado a Nemo con éxito.${NC}"
    fi

    echo -e "\n${AMARILLO}[+] Paso 2: Preparando la restauración del entorno...${NC}"
    if [ -n "$(ls -A "$RUTA_PENDRIVE"/rice_kineticos_*.tar.gz 2>/dev/null)" ]; then
        Archivo_Mas_Reciente=$(ls -t "$RUTA_PENDRIVE"/rice_kineticos_*.tar.gz 2>/dev/null | head -n 1)
        echo -e "${VERDE}✔ Copia de seguridad encontrada en el pendrive:${NC}"
        echo "   📦 $(basename "$Archivo_Mas_Reciente")"
    else
        echo -e "${ROJO}❌ Error: No se encontró ninguna copia en la raíz del pendrive.${NC}"
        pausar
        return 1
    fi

    read -p "$(echo -e "${AMARILLO}¿Deseas restaurar este archivo específico? [s/N]: ${NC}")" confirmar
    if [[ "$confirmar" =~ ^[Ss]$ ]]; then
        echo -e "\n${AZUL}-> Purgando entornos antiguos...${NC}"
        rm -rf "$HOME/.config/kineticwe" "$HOME/.config/noctalia" "$HOME/.config/noctalia-kwe" \
               "$HOME/.config/noctalia-greeter-kwe" "$HOME/.config/noctalia-greeter" \
               "$HOME/.config/niri" "$HOME/.local/state/noctalia" "$HOME/.local/state/noctalia-kwe" \
               "$HOME/.config/mozilla/firefox"

        echo -e "${AZUL}-> Extrayendo archivos en tu zona personal ($HOME)...${NC}"
        tar -xzf "$Archivo_Mas_Reciente" -C "$HOME/"
        if [ $? -eq 0 ]; then
            echo -e "${VERDE}✔ ¡Tu personalización y perfil de Firefox han sido restaurados con éxito!${NC}"
        else
            echo -e "${ROJO}❌ Error: Falló la extracción del archivo tar.gz.${NC}"
            pausar
            return 1
        fi
    else
        echo -e "${AMARILLO}⚠ Restauración del Rice omitida por el usuario.${NC}"
    fi

    echo -e "\n${AMARILLO}[+] Paso 3: Lanzando actualización de iconos...${NC}"
    aplicar_iconos_custom

    echo -e "\n${VERDE}🎉 ¡Proceso completado! Reiniciando en 5 segundos...${NC}"
    for i in {5..1}; do echo -e "${AMARILLO}$i...${NC}"; sleep 1; done
    reboot
}
# =====================================================================
# PARTE 2: FUNCIONES DE SOPORTE Y DESARROLLO DE LA ISO
# =====================================================================
respaldar_rice_kinetic() {
    echo -e "\n${AMARILLO}[+] Iniciando copia de seguridad de tu personalización (Rice)...${NC}"
    local Archivo_Backup="$RUTA_PENDRIVE/rice_kineticos_$(date +%Y%m%d_%H%M%S).tar.gz"

    if [ -d "$HOME/.config/kineticwe" ]; then
        cd "$HOME" || return 1
        local RUTAS_A_COPIAR=".config/kineticwe"
        [ -d ".config/noctalia" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .config/noctalia"
        [ -d ".config/noctalia-kwe" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .config/noctalia-kwe"
        [ -d ".config/noctalia-greeter-kwe" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .config/noctalia-greeter-kwe"
        [ -d ".config/noctalia-greeter" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .config/noctalia-greeter"
        [ -d ".config/niri" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .config/niri"
        [ -d ".config/mozilla/firefox" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .config/mozilla/firefox"
        [ -d ".local/state/noctalia" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .local/state/noctalia"
        [ -d ".local/state/noctalia-kwe" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .local/state/noctalia-kwe"

        echo -e "${AZUL}-> Empaquetando componentes detectados hacia el pendrive...${NC}"
        tar --exclude='plugin-cache' --exclude='cache2' --exclude='jumpListCache' --exclude='startupCache' -czf "$Archivo_Backup" $RUTAS_A_COPIAR 2>/dev/null

        if [ $? -eq 0 ]; then
            echo -e "\n${VERDE}✔ ¡Copia de seguridad creada con éxito!${NC}"
            echo -e "${AZUL}Guardada de forma portátil en:${NC} 📦 $(basename "$Archivo_Backup")"
        else
            echo -e "${ROJO}❌ Error al intentar comprimir los archivos.${NC}"
        fi
    else
        echo -e "${ROJO}❌ Error: No se encontró la carpeta 'kineticwe' en ~/.config.${NC}"
    fi
    pausar
}

restaurar_iconos_defecto() {
    echo -e "\n${AMARILLO}[+] Preparando la restauración de iconos por defecto...${NC}"
    read -rp "$(echo -e "${AMARILLO}¿Restaurar iconos originales y limpiar caché? [s/N]: ${NC}")" respuesta

    if [[ "$respuesta" =~ ^[sS]$ ]]; then
        local A_MENOS_UNO_REVERTIDO=false
        
        # 1. Eliminar los accesos directos personalizados modificados en local de usuario
        for desktop_file in "${ARCHIVOS_DESKTOP[@]}"; do
            if [ -f "$RUTA_LOCAL_APPS/$desktop_file" ]; then
                echo -e "${ROJO} -> Revirtiendo modificaciones de ${VERDE}${desktop_file}${NC}"
                rm "$RUTA_LOCAL_APPS/$desktop_file"
                A_MENOS_UNO_REVERTIDO=true
            fi
        done

        # 2. LIMPIEZA DE RESIDUOS: Eliminar los PNGs de iconos copiados en ~/.local/share/icons
        for icono_file in "${ARCHIVOS_ICONO[@]}"; do
            if [ -f "$RUTA_LOCAL_ICONOS/$icono_file" ]; then
                rm "$RUTA_LOCAL_ICONOS/$icono_file"
            fi
        done

        if [ "$A_MENOS_UNO_REVERTIDO" = true ]; then
            update-desktop-database "$RUTA_LOCAL_APPS" &>/dev/null
            echo -e "\n${VERDE}✔ ¡Iconos restaurados de fábrica y caché local purgada limpiamente!${NC}"
        else
            echo -e "\n${VERDE}✔ No se encontraron modificaciones activas que revertir.${NC}"
        fi
    fi
    pausar
}

submenu_cocinar_iso() {
    while true; do
        clear
        echo -e "${AZUL}=======================================================${NC}"
        echo -e "   🛠️  HERRAMIENTAS DE DESARROLLO GITHUB (CUSTOM ISO)${NC}"
        echo -e "   Ruta Destino USB: $RUTA_PENDRIVE/CustomBazzite"
        echo -e "${AZUL}=======================================================${NC}"
        echo -e " 1) ${ROJO}[LIMPIAR TODO]${NC} Purgar carpetas, imágenes huérfanas y cachés"
        echo -e " 2) ${AMARILLO}[DESCARGAR BASE]${NC} Bajar última versión limpia desde GitHub"
        echo -e " 3) ${VERDE}[HORNEAR ISO]${NC} Construir CustomBazzite.iso en el Pendrive"
        echo -e " 4) Volver al Menú Principal"
        echo -e " 5) Salir"
        echo -e "${AZUL}=======================================================${NC}"

        read -p "Selecciona una opción [1-5]: " opcion_sub

        case $opcion_sub in
            1)
                echo -e "\n${ROJO}[-] Eliminando directorios residuales en el pendrive...${NC}"
                sudo rm -rf "$RUTA_PENDRIVE/CustomBazzite" ./builder-config.toml
                echo -e "${ROJO}[-] Ejecutando purga agresiva del motor Podman...${NC}"
                sudo podman system prune --all --volumes --force
                echo -e "${VERDE}[✓] Limpieza absoluta completada.${NC}"
                pausar
                ;;
            2)
                echo -e "\n${AMARILLO}[+] Sincronizando desde GitHub Packages...${NC}"
                sudo podman pull ghcr.io/rupeji/bazzite-kinetic:latest
                if [ $? -eq 0 ]; then
                    echo -e "${VERDE}[✓] Imagen base descargada con éxito.${NC}"
                else
                    echo -e "${ROJO}[X] Error crítico de conexión.${NC}"
                fi
                pausar
                ;;
            3)
                echo -e "\n${AZUL}[+] Preparando entorno y carpetas en el pendrive...${NC}"
                mkdir -p "$RUTA_PENDRIVE/CustomBazzite"
                chmod 777 "$RUTA_PENDRIVE/CustomBazzite"

                echo -e "${AZUL}[+] Configurando el entorno interactivo de Anaconda...${NC}"
                printf '[customizations.installer.kickstart]\ncontents = "graphical"\n\n[customizations.installer.modules]\nenable = [\n  "org.fedoraproject.Anaconda.Modules.Storage",\n  "org.fedoraproject.Anaconda.Modules.Runtime",\n  "org.fedoraproject.Anaconda.Modules.Network",\n  "org.fedoraproject.Anaconda.Modules.Security",\n  "org.fedoraproject.Anaconda.Modules.Services",\n  "org.fedoraproject.Anaconda.Modules.Users",\n  "org.fedoraproject.Anaconda.Modules.Timezone"\n]\ndisable = [\n  "org.fedoraproject.Anaconda.Modules.Subscription"\n]\n' > ./builder-config.toml

                if ! command -v podman &> /dev/null; then
                    echo -e "${AMARILLO}[!] Podman no encontrado en el sistema base. Intentando inicializar el servicio...${NC}"
                    sudo systemctl enable --now podman.socket &>/dev/null
                else
                    echo -e "${VERDE}[✓] El motor Podman está presente y activo.${NC}"
                fi

                echo -e "${AZUL}[+] Lanzando bootc-image-builder (Proceso pesado)...${NC}"
                sudo podman run \
                  --rm -it \
                  --privileged \
                  --pull=always \
                  --net=host \
                  --security-opt label=type:unconfined_t \
                  -v ./builder-config.toml:/config.toml:ro \
                  -v "$RUTA_PENDRIVE/CustomBazzite:/output" \
                  -v /var/lib/containers/storage:/var/lib/containers/storage \
                  quay.io/centos-bootc/bootc-image-builder:latest \
                  --type anaconda-iso \
                  --rootfs btrfs \
                  --use-librepo=True \
                  ghcr.io/rupeji/bazzite-kinetic:latest

                if [ $? -eq 0 ]; then
                    if [ -f "$RUTA_PENDRIVE/CustomBazzite/bootiso/install.iso" ]; then
                        sudo mv "$RUTA_PENDRIVE/CustomBazzite/bootiso/install.iso" "$RUTA_PENDRIVE/CustomBazzite/bootiso/CustomBazzite.iso"
                    fi
                    sudo chown -R $USER:$USER "$RUTA_PENDRIVE/CustomBazzite" >/dev/null 2>&1
                    echo -e "\n${VERDE}[✓] ¡ISO CustomBazzite.iso horneada directamente en tu USB!${NC}"
                    echo -e "Tu instalador definitivo te espera en: ${VERDE}$RUTA_PENDRIVE/CustomBazzite/bootiso/CustomBazzite.iso${NC}"
                else
                    echo -e "\n${ROJO}[X] La compilación ha fallado.${NC}"
                fi
                pausar
                ;;
            4)
                break
                ;;
            5)
                echo -e "\n${VERDE}Saliendo... ¡Hasta luego!${NC}"
                exit 0
                ;;
            *)
                echo -e "\n${ROJO}Opción incorrecta.${NC}"
                sleep 1.2
                ;;
        esac
    done
}

# =====================================================================
# BUCLE DEL MENÚ PRINCIPAL (REORDENADO Y CORREGIDO)
# =====================================================================
while true; do
    clear
    echo -e "${AZUL}=======================================================${NC}"
    echo -e "${AZUL}    🛠️  SUITE DE GESTIÓN Y CONFIGURACIÓN BAZZITE (USB)${NC}"
    echo -e "    Unidad detectada: $RUTA_PENDRIVE"
    echo -e "${AZUL}=======================================================${NC}"
    echo -e " 1) Ejecutar instalación completa + Rice + Iconos Custom (Reinicia)"
    echo -e " 2) Solo reaplicar iconos personalizados (Sin tocar el Rice)"
    echo -e " 3) Restaurar iconos originales del sistema (Deshacer y Limpiar)"
    echo -e " 4) Respaldar personalización actual (Crea .tar.gz en el USB)"
    echo -e " 5) Opciones de Desarrollo / Cocinar ISO de GitHub -->"
    echo -e " 6) Salir"
    echo -e "${AZUL}=======================================================${NC}"

    read -p "Selecciona una opción [1-6]: " opcion

    case $opcion in
        1) ejecutar_instalacion_completa ;;
        2) 
            aplicar_iconos_custom
            pausar
            ;;
        3) restaurar_iconos_defecto ;;
        4) respaldar_rice_kinetic ;;
        5) submenu_cocinar_iso ;;
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

