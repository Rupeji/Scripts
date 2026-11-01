#!/usr/bin/fish

# =====================================================================
# SUITE PORTÁTIL DE MANTENIMIENTO Y DESARROLLO (NATIVO EN FISH)
# =====================================================================

# Colores premium para la terminal en Fish
set verde (set_color green)
set azul (set_color cyan)
set rojo (set_color red)
set amarillo (set_color yellow)
set reset (set_color normal)

# Función auxiliar para pausar la pantalla
function pausar
    echo ""
    read -p 'echo "Presiona [Enter] para volver al menú..."'
end

# Obtener de forma dinámica la ruta física del pendrive en Fish
set RUTA_PENDRIVE (cd (dirname (status filename)); and pwd)

# Variables de entorno compartidas
set AGENTE_BIN "/usr/libexec/kf6/polkit-kde-authentication-agent-1"
set DIRECTORIO_AUTOSTART "$HOME/.config/autostart"
set ARCHIVO_DESKTOP "$DIRECTORIO_AUTOSTART/polkit-kde-authentication-agent-1.desktop"
set RUTA_ICONOS "$RUTA_PENDRIVE/Iconos"
set RUTA_LOCAL_APPS "$HOME/.local/share/applications"

# Lista de aplicaciones registradas para los iconos
set APPS_ICONOS \
    "com.discordapp.Discord.desktop|scribcord.png|/var/lib/flatpak/exports/share/applications" \
    "org.kde.dolphin.desktop|scribder.png|/usr/share/applications" \
    "kitty.desktop|Scribbled_Kitty.png|/usr/share/applications" \
    "org.mozilla.firefox.desktop|scribfox.png|/var/lib/flatpak/exports/share/applications" \
    "steam.desktop|scribsteam.png|/usr/share/applications"

# --- FUNCIÓN: INSTALACIÓN COMPLETA DE USUARIO ---
function ejecutar_instalacion_completa
    global verde azul rojo amarillo reset RUTA_PENDRIVE AGENTE_BIN DIRECTORIO_AUTOSTART ARCHIVO_DESKTOP RUTA_ICONOS RUTA_LOCAL_APPS APPS_ICONOS
    
    echo ""
    echo "$azul========================================================$reset"
    echo "$azul🚀 Iniciando Instalación Completa Post-Instalación$reset"
    echo "$azul========================================================$reset"

    # 1. POLKIT FIX
    echo ""
    echo "$amarillo[+] Paso 1: Configurando Agente Polkit para KineticWE...$reset"
    if not test -f "$AGENTE_BIN"
        echo "$rojo❌ Error crítico: El archivo $AGENTE_BIN no existe.$reset"
        pausar
        return 1
    end

    mkdir -p "$DIRECTORIO_AUTOSTART"
    printf '[Desktop Entry]\nType=Application\nName=KDE Polkit Authentication Agent\nComment=Motor de contraseñas de administrador para apps gráficas\nExec=%s\nTerminal=false\nX-KDE-Autostart-phase=1\n' "$AGENTE_BIN" > "$ARCHIVO_DESKTOP"
    chmod +x "$ARCHIVO_DESKTOP"
    echo "$verde✔ Lanzador Polkit configurado correctamente en el Home.$reset"

    if pgrep -f (basename "$AGENTE_BIN") > /dev/null
        echo "$azulℹ El agente ya se encuentra corriendo en segundo plano.$reset"
    else
        eval "$AGENTE_BIN &"
        echo "$verde✔ ¡Agente Polkit iniciado con éxito en segundo plano!$reset"
    end

    # 2. RESTAURACIÓN RICE
    echo ""
    echo "$amarillo[+] Paso 2: Preparando la restauración del entorno...$reset"
    set backups (ls -t "$RUTA_PENDRIVE"/rice_kineticos_*.tar.gz 2>/dev/null)
    if test -n "$backups"
        set Archivo_Mas_Reciente $backups[1]
        set Nombre_Base_Archivo (basename "$Archivo_Mas_Reciente")
        echo "$verde✔ Copia de seguridad encontrada en el pendrive:$reset"
        echo "   📦 $Nombre_Base_Archivo"
    else
        echo "$rojo❌ Error: No se encontró ninguna copia ('rice_kineticos_*.tar.gz') en la raíz del pendrive.$reset"
        pausar
        return 1
    end

    read -p 'echo "¿Deseas restaurar este archivo específico? [s/N]: "' confirmar
    if string match -ri '^[s]$' "$confirmar"
        echo ""
        echo "$azul-> Purgando entornos antiguos (Noctalia y KineticWE)...$reset"
        rm -rf "$HOME/.config/kineticwe" "$HOME/.config/noctalia" "$HOME/.config/noctalia-kwe" \
               "$HOME/.config/noctalia-greeter-kwe" "$HOME/.config/noctalia-greeter" \
               "$HOME/.config/niri" "$HOME/.local/state/noctalia" "$HOME/.local/state/noctalia-kwe"

        echo "$azul-> Extrayendo archivos en tu zona personal ($HOME)...$reset"
        tar -xzf "$Archivo_Mas_Reciente" -C "$HOME/"
        if test $status -eq 0
            echo "$verde✔ ¡Tu personalización ha sido restaurada con éxito!$reset"
        else
            echo "$rojo❌ Error: Falló la extracción del archivo tar.gz.$reset"
            pausar
            return 1
        end
    else
        echo "$amarillo⚠ Restauración del Rice omitida por el usuario.$reset"
    end

    # 3. APLICAR ICONOS CUSTOM
    echo ""
    echo "$amarillo[+] Paso 3: Verificando y reaplicando iconos personalizados...$reset"
    set A_MENOS_UNO_CAMBIADO false

    if test -d "$RUTA_ICONOS"
        for app in $APPS_ICONOS
            set partes (string split "|" "$app")
            set desktop_file $partes[1]
            set icono_file $partes[2]
            set ruta_origen $partes[3]

            if test -f "$RUTA_ICONOS/$icono_file"
                if test -z "$ruta_origen"; or not test -f "$ruta_origen/$desktop_file"
                    set ruta_detectada (find /var/lib/flatpak/ ~/.local/share/ /usr/share/applications/ -name "$desktop_file" -print -quit 2>/dev/null)
                    if test -n "$ruta_detectada"
                        set ruta_origen (dirname "$ruta_detectada")
                    end
                end

                if test -f "$ruta_origen/$desktop_file"
                    echo "$azul -> Aplicando icono personalizado a $verde$desktop_file$reset"
                    mkdir -p "$RUTA_LOCAL_APPS"
                    cp "$ruta_origen/$desktop_file" "$RUTA_LOCAL_APPS/"
                    sed -i "s|^Icon=.*|Icon=$(string escape --style=regex "$RUTA_ICONOS/$icono_file")|" "$RUTA_LOCAL_APPS/$desktop_file"
                    set A_MENOS_UNO_CAMBIADO true
                else
                    echo "$rojo ⚠ No se encontró el archivo de origen para $desktop_file$reset"
                end
            else
                echo "$amarillo ⚠ Saltando $desktop_file: El icono $icono_file no existe en el pendrive.$reset"
            end
        end
    else
        echo "$rojo❌ Error: No se encontró la carpeta 'Iconos' en la raíz del pendrive.$reset"
    end

    if test "$A_MENOS_UNO_CAMBIADO" = true
        update-desktop-database "$RUTA_LOCAL_APPS" >/dev/null 2>&1
        echo "$verde✔ ¡Iconos personalizados aplicados correctamente!$reset"
    end

    echo ""
    echo "$azul========================================================$reset"
    echo "$verde🎉 ¡Todo el proceso se ha completado correctamente!$reset"
    echo "$azul========================================================$reset"
    echo ""
    echo "$amarilloEl sistema se reiniciará automáticamente en 5 segundos...$reset"
    for i in 5 4 3 2 1
        echo "$amarillo$i...$reset"
        sleep 1
    done
    echo "$azulReiniciando sistema... Bye!$reset"
    reboot
end

# --- FUNCIÓN: REVERTIR ICONOS A DE FÁBRICA ---
function restaurar_iconos_defecto
    global verde rojo amarillo azul reset RUTA_LOCAL_APPS APPS_ICONOS
    echo ""
    echo "$amarillo[+] Preparando la restauración de iconos por defecto...$reset"
    echo "$azul(Esto eliminará los accesos directos modificados de tu usuario)$reset"

    read -p 'echo "¿Restaurar iconos originales? [s/N]: "' respuesta

    if string match -ri '^[s]$' "$respuesta"
        set A_MENOS_UNO_REVERTIDO false

        for app in $APPS_ICONOS
            set partes (string split "|" "$app")
            set desktop_file $partes[1]

            if test -f "$RUTA_LOCAL_APPS/$desktop_file"
                echo "$rojo -> Eliminando custom desktop de $verde$desktop_file$reset"
                rm "$RUTA_LOCAL_APPS/$desktop_file"
                set A_MENOS_UNO_REVERTIDO true
            end
        end

        if test "$A_MENOS_UNO_REVERTIDO" = true
            update-desktop-database "$RUTA_LOCAL_APPS" >/dev/null 2>&1
            echo ""
            echo "$verde✔ ¡Iconos restaurados! El sistema vuelve a usar los de fábrica.$reset"
            echo "$amarillo(Nota: Puede que necesites desanclar y volver a anclar las apps de tu barra para ver el cambio).$reset"
        else
            echo ""
            echo "$verde✔ No se encontraron iconos personalizados activos que restaurar.$reset"
        fi
    else
        echo "$azul-> Manteniendo tu set de iconos personalizados activos.$reset"
    fi
    pausar
end
# --- FUNCIÓN: CREAR COPIA DE SEGURIDAD PORTÁTIL ---
function respaldar_rice_kinetic
    global verde azul rojo amarillo reset RUTA_PENDRIVE
    echo ""
    echo "$amarillo[+] Iniciando copia de seguridad de tu personalización (Rice)...$reset"
    
    set Archivo_Backup "$RUTA_PENDRIVE/rice_kineticos_$(date +%Y%m%d_%H%M%S).tar.gz"
    echo "$azul-> Rastreando componentes del sistema en tu usuario...$reset"

    if test -d "$HOME/.config/kineticwe"
        # Cambiamos de directorio a la Home del usuario
        cd "$HOME"
        
        set RUTAS_A_COPIAR ".config/kineticwe"
        test -d ".config/noctalia"; and set RUTAS_A_COPIAR $RUTAS_A_COPIAR ".config/noctalia"
        test -d ".config/noctalia-kwe"; and set RUTAS_A_COPIAR $RUTAS_A_COPIAR ".config/noctalia-kwe"
        test -d ".config/noctalia-greeter-kwe"; and set RUTAS_A_COPIAR $RUTAS_A_COPIAR ".config/noctalia-greeter-kwe"
        test -d ".config/noctalia-greeter"; and set RUTAS_A_COPIAR $RUTAS_A_COPIAR ".config/noctalia-greeter"
        test -d ".config/niri"; and set RUTAS_A_COPIAR $RUTAS_A_COPIAR ".config/niri"
        test -d ".local/state/noctalia"; and set RUTAS_A_COPIAR $RUTAS_A_COPIAR ".local/state/noctalia"
        test -d ".local/state/noctalia-kwe"; and set RUTAS_A_COPIAR $RUTAS_A_COPIAR ".local/state/noctalia-kwe"

        echo "$azul-> Empaquetando componentes detectados hacia el pendrive...$reset"
        tar -czf "$Archivo_Backup" $RUTAS_A_COPIAR >/dev/null 2>&1

        if test $status -eq 0
            echo ""
            echo "$verde✔ ¡Copia de seguridad creada con éxito!$reset"
            echo "$azulSe ha guardado de forma portátil en: $reset"
            echo "   📦 (basename "$Archivo_Backup")"
        else
            echo ""
            echo "$rojo❌ Error al intentar comprimir los archivos de personalización.$reset"
        end
    else
        echo ""
        echo "$rojo❌ Error: No se encontró la carpeta 'kineticwe' en ~/.config. No hay un Rice activo que respaldar.$reset"
    fi
    pausar
end

# --- SUBMENÚ: MOTOR DE DESARROLLO GITHUB / ISO ---
function submenu_cocinar_iso
    global verde azul rojo amarillo reset RUTA_PENDRIVE USER
    
    while true
        clear
        echo "$azul========================================================$reset"
        echo "$azul   🛠️  HERRAMIENTAS DE DESARROLLO GITHUB (CUSTOM ISO)  $reset"
        echo "   Ruta Destino USB: $RUTA_PENDRIVE/CustomBazzite"
        echo "$azul========================================================$reset"
        echo "1) $rojo"."[LIMPIAR TODO]$reset Purgar carpetas, imágenes huérfanas y cachés del disco"
        echo "2) $amarillo"."[DESCARGAR BASE]$reset Bajar la última versión limpia desde GitHub Packages"
        echo "3) $verde"."[HORNEAR ISO]$reset Fundir CustomBazzite.iso directamente al Pendrive"
        echo "4) Volver al Menú Principal"
        echo "5) Salir"
        echo "$azul========================================================$reset"
        
        read -p 'echo "Selecciona una opción [1-5]: "' opcion_sub

        switch "$opcion_sub"
            case 1
                echo ""
                echo "$rojo[-] Eliminando directorios residuales y archivos temporales...$reset"
                sudo rm -rf "$RUTA_PENDRIVE/CustomBazzite" ./builder-config.toml
                
                echo "$rojo[-] Purgando blobs agresivamente y liberando almacenamiento oculto (Podman)...$reset"
                # Elimina contenedores parados, volúmenes locales y todas las imágenes no asociadas a un contenedor vivo
                sudo podman system prune --all --volumes --force
                
                echo ""
                echo "$verde[✓] Limpieza absoluta completada en disco.$reset"
                pausar

            case 2
                echo ""
                echo "$amarillo[+] Sincronizando la capa más fresca desde GitHub Packages...$reset"
                sudo podman pull ghcr.io/rupeji/bazzite-kinetic:latest
                if test $status -eq 0
                    echo ""
                    echo "$verde[✓] Imagen base descargada e inyectada en el sistema local.$reset"
                else
                    echo ""
                    echo "$rojo[X] Error crítico al conectar con GitHub Packages. Revisa tu red.$reset"
                end
                pausar

            case 3
                echo ""
                echo "$azul[+] Configurando el entorno interactivo de Anaconda...$reset"
                printf '[customizations.installer.kickstart]\ncontents = "graphical"\n\n[customizations.installer.modules]\nenable = [\n  "org.fedoraproject.Anaconda.Modules.Storage",\n  "org.fedoraproject.Anaconda.Modules.Runtime",\n  "org.fedoraproject.Anaconda.Modules.Network",\n  "org.fedoraproject.Anaconda.Modules.Security",\n  "org.fedoraproject.Anaconda.Modules.Services",\n  "org.fedoraproject.Anaconda.Modules.Users",\n  "org.fedoraproject.Anaconda.Modules.Timezone"\n]\ndisable = [\n  "org.fedoraproject.Anaconda.Modules.Subscription"\n]\n' > ./builder-config.toml

                echo "$azul[+] Preparando directorio de salida en el pendrive...$reset"
                mkdir -p "$RUTA_PENDRIVE/CustomBazzite"
                chmod 777 "$RUTA_PENDRIVE/CustomBazzite"

                echo "$azul[+] Arrancando el motor bootc-image-builder (Espera a que finalice)...$reset"
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

                if test $status -eq 0
                    # Si compila con éxito, renombramos el instalador de fábrica a CustomBazzite.iso
                    if test -f "$RUTA_PENDRIVE/CustomBazzite/bootiso/install.iso"
                        mv "$RUTA_PENDRIVE/CustomBazzite/bootiso/install.iso" "$RUTA_PENDRIVE/CustomBazzite/bootiso/CustomBazzite.iso"
                    end
                    
                    sudo chown -R $USER:$USER "$RUTA_PENDRIVE/CustomBazzite" >/dev/null 2>&1
                    echo ""
                    echo "$verde[✓] ¡ISO cocinada con éxito directamente en tu Pendrive!$reset"
                    echo "Tu instalador definitivo te espera en: $verde$RUTA_PENDRIVE/CustomBazzite/bootiso/CustomBazzite.iso$reset"
                else
                    echo ""
                    echo "$rojo[X] Algo ha fallado durante la fundición de la ISO.$reset"
                end
                pausar

            case 4
                break # Rompe este bucle y regresa al menú anterior

            case 5
                echo "$verde¡Hasta luego, colega! Saliendo del asistente...$reset"
                exit 0

            case '*'
                echo "$rojo[-] Opción no válida.$reset"
                sleep 1.5
        end
    end
end

# =====================================================================
# BUCLE PRINCIPAL DEL MENÚ PRINCIPAL
# =====================================================================
while true
    clear
    echo "$azul========================================================$reset"
    echo "$azul    🛠️  SUITE DE GESTIÓN Y CONFIGURACIÓN BAZZITE (USB)$reset"
    echo "    Unidad actual: $RUTA_PENDRIVE"
    echo "$azul========================================================$reset"
    echo "1) Ejecutar instalación completa + Rice + Iconos Custom (Reinicia automáticamente)"
    echo "2) Respaldar personalización actual (Crea .tar.gz en la raíz del Pendrive)"
    echo "3) Restaurar iconos originales del sistema (Deshacer cambios)"
    echo "4) Opciones de Desarrollo / Cocinar ISO de GitHub -->"
    echo "5) Salir"
    echo "$azul========================================================$reset"
    
    read -p 'echo "Selecciona una opción [1-5]: "' opcion

    switch "$opcion"
        case 1
            ejecutar_instalacion_completa
        case 2
            respaldar_rice_kinetic
        case 3
            restaurar_iconos_defecto
        case 4
            submenu_cocinar_iso
        case 5
            echo ""
            echo "$verde¡Hasta luego! Saliendo limpiamente...$reset"
            exit 0
        case '*'
            echo ""
            echo "$rojo❌ Opción no válida. Por favor, introduce un número del 1 al 5.$reset"
            sleep 1.5
    end
end
