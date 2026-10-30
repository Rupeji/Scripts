#!/bin/bash

# ==============================================================================
# CONFIGURACIÓN VISUAL Y COLORES
# ==============================================================================
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
NC='\033[0m' # Sin color

# Variable de control para automatizaciones fluidas
MODO_CADENA=false

pausar() {
    if [ "$MODO_CADENA" = false ]; then
        echo ""
        read -p "Presiona [ENTER] para regresar al menú..."
    fi
}

# ==============================================================================
# MÓDULO 1: ACTUALIZAR FLATPAK
# ==============================================================================
actualizar_apps_flatpak() {
    echo -e "\n${AMARILLO}[+] Iniciando actualización de aplicaciones...${NC}"

    # 1. Actualizar los paquetes Flatpak de usuario y sistema
    echo -e "\n${AZUL}-> Comprobando y aplicando actualizaciones de Flatpak...${NC}"
    flatpak update -y

    echo -e "\n${VERDE}✔ ¡Aplicaciones actualizadas con éxito!${NC}"
    echo -e "${AMARILLO}No es necesario reiniciar el sistema.${NC}"
    pausar
}
# ==============================================================================
# MÓDULO 2: INSTALACIÓN DE ICONOS Y CURSORES
# ==============================================================================
instalar_iconos_y_cursores() {
    echo -e "\n${AMARILLO}[+] Iniciando la instalación de Temas Visuales (Tela y Bibata)...${NC}"

    # 0. Asegurar la ruta moderna de iconos para el usuario local
    mkdir -p ~/.local/share/icons

    # 1. Instalación de Iconos Tela (Nivel Usuario)
    echo -e "\n${AZUL}-> Descargando e instalando la última versión de Tela Icon Theme...${NC}"

    # Limpiamos descargas anteriores en /tmp para evitar conflictos
    rm -rf /tmp/Tela-icon-theme

    # Definimos la URL rota con espacios a propósito para protegerla
    URL_TELA_CON_ESPACIOS="https:// github.com / vinceliuice / Tela-icon-theme .git"
    # Eliminamos todos los espacios en blanco de forma nativa en Bash
    URL_TELA="${URL_TELA_CON_ESPACIOS// /}"

    # Clonamos con la URL limpia
    git clone "$URL_TELA" /tmp/Tela-icon-theme

    # Forzamos permisos y ejecutamos solo si el clonado ha funcionado
    if [ -f /tmp/Tela-icon-theme/install.sh ]; then
        chmod +x /tmp/Tela-icon-theme/install.sh
        /tmp/Tela-icon-theme/install.sh -d "$HOME/.local/share/icons"
    else
        echo -e "${ROJO}❌ Error: No se pudo descargar el instalador de iconos Tela.${NC}"
    fi

    # Limpiamos los archivos temporales de la instalación
    rm -rf /tmp/Tela-icon-theme


    # 2. Instalación de Cursores Bibata Modern (Nivel Usuario)
    echo -e "\n${AZUL}-> Descargando e instalando la última versión de Cursores Bibata...${NC}"

    # Eliminamos posibles archivos corruptos anteriores en /tmp
    rm -f /tmp/Bibata-Modern-Classic.tar.xz /tmp/Bibata-Modern-Ice.tar.xz

    # Definimos las URLs de los paquetes separadas por espacios
    URL_CLASSIC_CON_ESPACIOS="https:// github.com / ful1e5 / Bibata_Cursor / releases / download / v2.0.7 / Bibata-Modern-Classic.tar.xz"
    URL_ICE_CON_ESPACIOS="https:// github.com / ful1e5 / Bibata_Cursor / releases / download / v2.0.7 / Bibata-Modern-Ice.tar.xz"

    # Limpiamos los espacios usando la propiedad de sustitución global (// /)
    URL_CLASSIC="${URL_CLASSIC_CON_ESPACIOS// /}"
    URL_ICE="${URL_ICE_CON_ESPACIOS// /}"

    # Descargamos los paquetes oficiales usando las URLs seguras
    curl -L "$URL_CLASSIC" -o /tmp/Bibata-Modern-Classic.tar.xz
    curl -L "$URL_ICE" -o /tmp/Bibata-Modern-Ice.tar.xz

    # Descomprimimos comprobando que los archivos existan y tengan tamaño
    if [ -s /tmp/Bibata-Modern-Classic.tar.xz ] && [ -s /tmp/Bibata-Modern-Ice.tar.xz ]; then
        tar -xf /tmp/Bibata-Modern-Classic.tar.xz -C "$HOME/.local/share/icons/"
        tar -xf /tmp/Bibata-Modern-Ice.tar.xz -C "$HOME/.local/share/icons/"
        echo -e "${VERDE}✔ Cursores desempaquetados correctamente.${NC}"
    else
        echo -e "${ROJO}❌ Error: Los archivos de cursores descargados están corruptos o vacíos.${NC}"
    fi

    # Limpiamos los archivos temporales de los cursores
    rm -f /tmp/Bibata-Modern-Classic.tar.xz /tmp/Bibata-Modern-Ice.tar.xz


    echo -e "\n${VERDE}✔ ¡Proceso de instalación finalizado!${NC}"
    echo -e "${AMARILLO}Revisa los mensajes anteriores para confirmar que todo se descargó al 100%.${NC}"
    pausar
}
# ==============================================================================
# MÓDULO 3: INSTALACIÓN DE GSLAPPER
# ==============================================================================
instalar_gslapper() {
    # Configuración del repositorio
    REPO="Nomadcxx/gSlapper"

    echo -e "\n${AMARILLO}[+] Buscando la última release de gSlapper para Fedora...${NC}"

    # Construcción de la URL de la API de GitHub
    PROTOCOLO="https://"
    DOMINIO="api.github.com"
    RUTA="/repos/$REPO/releases/latest"

    # Limpiamos los espacios internos solo para que curl pueda hacer la petición externa
    API_URL=$(echo "${PROTOCOLO}${DOMINIO}${RUTA}" | tr -d ' ')

    # 1. Obtener la información de la release y extraer el enlace .rpm de forma segura
    JSON_DATA=$(curl -s "$API_URL")
    URL_RPM=$(echo "$JSON_DATA" | grep -oP '"browser_download_url"\s*:\s*"\K[^"]+' | grep '\.rpm$')

    # 2. Verificar si se encontró el paquete de Fedora
    if [ -z "$URL_RPM" ]; then
        echo -e "${ROJO}❌ Error: No se pudo encontrar un paquete .rpm en la última versión.${NC}"
        echo "Respuesta del servidor:"
        echo "$JSON_DATA" | head -n 5
        pausar
        return 1
    fi

    # Extraer el nombre del archivo de la URL
    ARCHIVO=$(basename "$URL_RPM")

    echo -e "${VERDE}✔ Última versión encontrada: $ARCHIVO${NC}"
    echo -e "${AMARILLO}[+] Descargando paquete desde un servidor seguro...${NC}"

    # 3. Descargar el archivo usando curl
    curl -L -o "$ARCHIVO" "$URL_RPM"

    if [ $? -eq 0 ]; then
        echo -e "${VERDE}✔ ¡Descarga completada con éxito!${NC}"
        echo "El archivo se ha guardado como: $ARCHIVO"
        echo "------------------------------------------------"
        echo -e "${AMARILLO}[+] Instalando gSlapper en Bazzite...${NC}"
        echo "------------------------------------------------"

        # Instalamos el archivo .rpm descargado directamente en las capas del sistema
        rpm-ostree install "./$ARCHIVO"

        # Evaluar si la operación de rpm-ostree tuvo éxito
        if [ $? -eq 0 ]; then
            echo "------------------------------------------------"
            echo -e "${VERDE}¡Instalación procesada correctamente!${NC}"
            echo -e "${AMARILLO}Si es la primera vez que se añade el paquete,${NC}"
            echo -e "${AMARILLO}reinicia el sistema para aplicarlo: systemctl reboot${NC}"
            echo "------------------------------------------------"
            # Limpieza del archivo RPM descargado tras instalarse con éxito
            rm -f "./$ARCHIVO"
            pausar
            return 0
        else
            echo -e "${ROJO}❌ Error: Hubo un fallo durante la instalación con rpm-ostree.${NC}"
            pausar
            return 1
        fi
    else
        echo -e "${ROJO}❌ Error: Hubo un fallo al descargar el archivo.${NC}"
        pausar
        return 1
    fi
}
# ==============================================================================
# MÓDULO 4: INSTALACIÓN DE SOFTWARE ADICIONAL (KITTY + FISH + PROTONUP-QT)
# ==============================================================================
instalar_apps_esenciales() {
    echo -e "\n${AMARILLO}[+] Preparando la instalación de software adicional...${NC}"

    # 1. Instalación de paquetes del sistema (rpm-ostree)
    echo -e "${AZUL}-> Enviando solicitud de instalación a rpm-ostree (Kitty + Fish)...${NC}"
    # Unificamos en una sola llamada segura
    sudo rpm-ostree install kitty fish

    if [ $? -eq 0 ]; then
        echo -e "\n${VERDE}✔ ¡Éxito! Kitty y Fish se han añadido como capas del sistema.${NC}"
    else
        echo -e "\n${ROJO}❌ Ocurrió un error al intentar instalar los paquetes de sistema.${NC}"
    fi

    # 2. Instalación de JetBrainsMono Nerd Font
    echo -e "\n${AZUL}-> Descargando e instalando JetBrainsMono Nerd Font...${NC}"
    mkdir -p ~/.local/share/fonts/JetBrainsMono
    wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -O /tmp/JetBrainsMono.zip

    if [ $? -eq 0 ]; then
        unzip -q -o /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono
        rm -f /tmp/JetBrainsMono.zip
        fc-cache -f
        echo -e "${VERDE}✔ ¡Éxito! JetBrainsMono Nerd Font instalada correctamente y caché actualizado.${NC}"
    else
        echo -e "${ROJO}❌ Ocurrió un error al intentar descargar la fuente.${NC}"
    fi

    # 3. Instalación de aplicaciones de escritorio (Flatpak)
    echo -e "\n${AZUL}-> Instalando aplicaciones mediante Flatpak (Incluyendo Firefox)...${NC}"
    # Unificamos todas las aplicaciones en una sola línea, añadiendo org.mozilla.firefox
    flatpak install flathub \
        org.mozilla.firefox \
        org.gnome.FileRoller \
        net.davidotek.pupgui2 \
        com.bambulab.BambuStudio \
        com.discordapp.Discord -y

    if [ $? -eq 0 ]; then
        echo -e "${VERDE}✔ ¡Éxito! Aplicaciones Flatpak instaladas correctamente.${NC}"
    else
        echo -e "${ROJO}❌ Ocurrió un error al intentar instalar las aplicaciones Flatpak.${NC}"
    fi

    pausar
}
# ==============================================================================
# MÓDULO 5: CONFIGURACIÓN DE DOTFILES (PALETA PREMIUM + PROMPT PERSONALIZADO)
# ==============================================================================
aplicar_dotfiles_esteticos() {
    echo -e "\n${AMARILLO}[+] Generando configuraciones estéticas premium para la consola...${NC}"

    # 1. Asegurar directorios locales requeridos
    mkdir -p ~/.local/bin
    mkdir -p ~/.config/kitty
    mkdir -p ~/.config/fish

    # 2. Configurar Kitty restaurando Catppuccin Mocha + las estelas del cursor
    echo -e "${AZUL}-> Configurando Kitty (Catppuccin Mocha + Estelas de Cursor)...${NC}"
    cat << 'EOF' > ~/.config/kitty/kitty.conf
# Configuración del Shell (Fuerza a Kitty a iniciar siempre con Fish)
shell /usr/bin/fish

# Fuentes
font_family      JetBrainsMono Nerd Font
font_size        11.0

# Ventana y Estilo Estético
background_opacity 0.60
background_blur    5
window_padding_width 10

# Paleta de Colores Completa - Catppuccin Mocha
background #1e1e2e
foreground #cdd6f4
cursor     #f5e0dc
color0     #45475a
color8     #585b70
color1     #f38ba8
color9     #f38ba8
color2     #a6e3a1
color10    #a6e3a1
color3     #f9e2af
color11    #f9e2af
color4     #89b4fa
color12    #89b4fa
color5     #f5c2e7
color13    #f5c2e7
color6     #94e2d5
color14    #94e2d5
color7     #bac2de
color15    #a6adc8

# Tweaks del Cursor (It's FOSS Linux Portal Style)
cursor_shape block
cursor_trail 1
cursor_trail_decay 0.1 0.4
cursor_trail_start_threshold 2
EOF

    # 3. Descargar e instalar Starship Prompt aplicando el escudo de URLs
    echo -e "${AZUL}-> Descargando motor de diseño Starship Prompt...${NC}"

    URL_STARSHIP_CON_ESPACIOS="https:// starship.rs / install.sh"
    URL_STARSHIP="${URL_STARSHIP_CON_ESPACIOS// /}"

    # Descargamos el instalador de forma segura en la ruta local del usuario
    curl -sS -L "$URL_STARSHIP" | sh -s -- -y --bin-dir "$HOME/.local/bin"

    # Configuración del prompt con colores Catppuccin Mocha basados en Lavanda
    cat << 'EOF' > ~/.config/starship.toml
# Formato visual con tema starship-tokyonight-neo
format = """

[  Inhumano@Bazzite](bg:#d3daf2 fg:#090c0c bold)\
[](bg:#497de3 fg:#d3daf2)\
$directory\
[](fg:#497de3 bg:#394260)\
$git_branch\
$git_status\
[](fg:#394260 bg:#212736)\
$nodejs\
$rust\
$golang\
$php\
$python\
$c\
[](fg:#212736 bg:#1d2230)\
$time\
[](fg:#1d2230 bg:#090c0c)\
$cmd_duration\
[ ](fg:#090c0c)\
\n$character"""

[directory]
style = "fg:#e3e5e5 bg:#497de3 bold"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
"Documents" = "   "
"Downloads" = " "
"Music" = " "
"Pictures" = " "

[git_branch]
symbol = ""
style = "bg:#394260"
format = '[[ $symbol $branch ](fg:#497de3 bg:#394260)]($style)'

[git_status]
style = "bg:#394260"
format = '[[($all_status$ahead_behind )](fg:#497de3 bg:#394260)]($style)'

[nodejs]
symbol = "  "
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#497de3 bg:#212736)]($style)'

[rust]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#497de3 bg:#212736)]($style)'

[golang]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#497de3 bg:#212736)]($style)'

[php]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#497de3 bg:#212736)]($style)'

[python]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#497de3 bg:#212736)]($style)'

[c]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#497de3 bg:#212736)]($style)'

[time]
disabled = false
time_format = "%R" # Hour:Minute Format
style = "bg:#1d2230"
format = '[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)'

[cmd_duration]
show_milliseconds = false
min_time = 0
format = '[[ ⏱️ $duration ](fg:#a0a9cb bg:#090c0c)]($style)'
style = "bg:#090c0c"
disabled = false
show_notifications = false
EOF

    # 4. Configurar Fish Shell limpia (Sin los avisos raros de Bazzite)
    cat << 'EOF' > ~/.config/fish/config.fish
# Deshabilitar saludo por defecto (Quita el aviso de Bazzite/Fish de bienvenida)
set fish_greeting

# Añadir binarios locales al PATH (necesario para encontrar starship)
fish_add_path "$HOME/.local/bin"

# Inicializar Starship Prompt asegurando la ruta absoluta por si acaso
if test -f "$HOME/.local/bin/starship"
    "$HOME/.local/bin/starship" init fish | source
else if command -v starship > /dev/null
    starship init fish | source
end

# Ejecutar Fastfetch al abrir la terminal
if command -v fastfetch > /dev/null
    fastfetch
end
EOF
    echo -e "\n${VERDE}✔ ¡Configuración estética premium aplicada por completo!${NC}"
    pausar
}
# ==============================================================================
# MÓDULO 7: MANTENIMIENTO Y LIMPIEZA PROFUNDA DEL SISTEMA
# ==============================================================================
mantenimiento_y_limpieza() {
    echo -e "\n${AMARILLO}[+] Iniciando tareas de mantenimiento en Bazzite...${NC}"

    # 1. Limpieza de dependencias huérfanas y tiempos de ejecución en Flatpak
    echo -e "${AZUL}-> Buscando y eliminando dependencias huérfanas de Flatpak (Runtimes no usados)...${NC}"
    flatpak uninstall --unused -y

    if [ $? -eq 0 ]; then
        echo -e "${VERDE}✔ Tiempos de ejecución huérfanos de Flatpak eliminados con éxito.${NC}"
    else
        echo -e "${ROJO}❌ Ocurrió un problema menor limpiando los paquetes Flatpak.${NC}"
    fi

    # 2. Purgar metadatos antiguos y cachés de rpm-ostree
    echo -e "\n${AZUL}-> Purgando cachés y metadatos antiguos de rpm-ostree...${NC}"
    sudo rpm-ostree cleanup -m

    # 3. Lanzar la suite nativa de limpieza profunda de Bazzite
    echo -e "\n${AZUL}-> Ejecutando la rutina interna de mantenimiento 'ujust clean-system'...${NC}"
    echo -e "${AMARILLO}(Esto eliminará imágenes de contenedores obsoletas y despliegues del sistema antiguos)${NC}"
    ujust clean-system

    echo -e "\n${VERDE}✔ ¡Mantenimiento general completado con éxito! Tu almacenamiento está optimizado.${NC}"
    pausar
}
# ==============================================================================
# MÓDULO 6: ACTUALIZAR KINETICOS DE FORMA MANUAL
# ==============================================================================
actualizar_sistema_kineticos() {
    echo -e "\n${AMARILLO}[+] Comprobando actualizaciones para KineticOS...${NC}"
    echo -e "${AZUL}(Base inmutable Bazzite / Entorno KineticWE)${NC}"

    # 1. Comprobar y descargar la imagen espejo del sistema
    echo -e "\n${AZUL}-> Conectando con los repositorios de KineticOS (rpm-ostree)...${NC}"

    # Ejecutamos la actualización del sistema base
    if sudo rpm-ostree upgrade; then
        echo -e "\n${VERDE}✔ ¡Chequeo de rpm-ostree finalizado!${NC}"

        # Comprobamos si realmente se ha descargado una capa nueva o si ya estaba actualizado
        # rpm-ostree nos avisa si hay un despliegue pendiente para el próximo reinicio
        if rpm-ostree status | grep -q "Staged: yes"; then
            echo -e "\n${AMARILLO}¡Atención! Se ha descargado una nueva versión de KineticOS.${NC}"
            echo -e "${VERDE}Para aplicar los cambios y ejecutar los servicios de limpieza de Don, debes reiniciar.${NC}"
        else
            echo -e "\n${VERDE}✔ Tu KineticOS ya se encuentra en la última versión disponible.${NC}"
        fi
    else
        echo -e "\n${ROJO}❌ Error al intentar buscar actualizaciones del sistema.${NC}"
    fi

    pausar
}

# ==============================================================================
# MÓDULO 8 y 9: COPIA Y RESTAURACION INTEGRAL CON AUTO-CIERRE DE FIREFOX
# ==============================================================================
respaldar_rice_kinetic() {
    echo -e "\n${AMARILLO}[+] Iniciando copia de seguridad integral (Rice, Dolphin y Firefox)...${NC}"

    Ruta_Backup="$HOME/Copias_Seguridad_Rice"
    mkdir -p "$Ruta_Backup"
    Archivo_Backup="$Ruta_Backup/rice_kineticos_$(date +%Y%m%d_%H%M%S).tar.gz"

    echo -e "${AZUL}-> Rastreando componentes del sistema en tu usuario...${NC}"

    if [ -d "$HOME/.config/kineticwe" ]; then
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

        # 3. Componentes de configuración de Dolphin
        [ -f ".config/dolphinrc" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .config/dolphinrc"
        [ -f ".config/kiorc" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .config/kiorc"
        [ -d ".local/share/dolphin" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .local/share/dolphin"

        # 4. Perfil completo de Firefox si existe
        [ -d ".mozilla/firefox" ] && RUTAS_A_COPIAR="$RUTAS_A_COPIAR .mozilla/firefox"

        echo -e "${AZUL}-> Empaquetando componentes detectados: $RUTAS_A_COPIAR...${NC}"
        tar -czf "$Archivo_Backup" $RUTAS_A_COPIAR 2>/dev/null

        if [ $? -eq 0 ]; then
            echo -e "\n${VERDE}✔ ¡Copia de seguridad integral creada con éxito!${NC}"
            echo -e "${AZUL}Se ha guardado en: ${NC}$Archivo_Backup"
        else
            echo -e "\n${ROJO}❌ Error al intentar comprimir los archivos de personalización.${NC}"
        fi
    else
        echo -e "\n${ROJO}❌ Error: No se encontró la carpeta 'kineticwe' en ~/.config.${NC}"
    fi

    pausar
}

restaurar_rice_kinetic() {
    echo -e "\n${AMARILLO}[+] Preparando la restauración inteligente del entorno...${NC}"
    Ruta_Backup="$HOME/Copias_Seguridad_Rice"
    
    Ruta_Actual="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
    Ruta_Busqueda=""

    if [ -d "$Ruta_Backup" ] && [ -n "$(ls -A "$Ruta_Backup"/rice_kineticos_*.tar.gz 2>/dev/null)" ]; then
        echo -e "${VERDE}✔ Carpeta oficial detectada en el Home.${NC}"
        Ruta_Busqueda="$Ruta_Backup"
    elif [ -n "$(ls -A "$Ruta_Actual"/rice_kineticos_*.tar.gz 2>/dev/null)" ]; then
        echo -e "${AMARILLO}[!] Carpeta oficial vacía o inexistente. Usando directorio de ejecución actual:${NC}"
        echo -e "    $Ruta_Actual"
        Ruta_Busqueda="$Ruta_Actual"
    else
        echo -e "${ROJO}❌ Error: No se ha encontrado ninguna copia ('rice_kineticos_*.tar.gz')${NC}"
        pausar
        return 1
    fi

    Archivo_Mas_Reciente=$(ls -t "$Ruta_Busqueda"/rice_kineticos_*.tar.gz 2>/dev/null | head -n 1)
    Nombre_Base_Archivo=$(basename "$Archivo_Mas_Reciente")

    echo -e "\n${AZUL}-> Copia de seguridad más reciente detectada:${NC}"
    echo "-------------------------------------------------------"
    echo -e "📦 $Nombre_Base_Archivo"
    echo "-------------------------------------------------------"
    
    read -p "¿Deseas restaurar este archivo específico? [s/N]: " confirmar
    if [[ ! "$confirmar" =~ ^[Ss]$ ]]; then
        echo -e "${AMARILLO}Restauración cancelada por el usuario.${NC}"
        pausar
        return 0
    fi

    # LA MEJORA SEGURO: Forzar el cierre limpio de Firefox antes de borrar nada
    if pgrep -x "firefox" >/dev/null; then
        echo -e "\n${AMARILLO}[!] Detectado Firefox abierto. Cerrando de forma segura...${NC}"
        pkill -x "firefox"
        sleep 2 # Le damos 2 segundos de cortesía para que vuelque la caché al disco
    fi

    echo -e "\n${AZUL}-> Purgando entornos antiguos (Noctalia, Dolphin y Firefox)...${NC}"
    rm -rf "$HOME/.config/kineticwe" \
           "$HOME/.config/noctalia" \
           "$HOME/.config/noctalia-kwe" \
           "$HOME/.config/noctalia-greeter-kwe" \
           "$HOME/.config/noctalia-greeter" \
           "$HOME/.config/niri" \
           "$HOME/.local/state/noctalia" \
           "$HOME/.local/state/noctalia-kwe" \
           "$HOME/.config/dolphinrc" \
           "$HOME/.config/kiorc" \
           "$HOME/.local/share/dolphin" \
           "$HOME/.mozilla/firefox"

    echo -e "${AZUL}-> Extrayendo archivos en tu zona personal ($HOME)...${NC}"
    tar -xzf "$Archivo_Mas_Reciente" -C "$HOME/"

    if [ $? -eq 0 ]; then
        echo -e "\n${VERDE}✔ ¡Tu personalización, Dolphin, Firefox y la GUI han sido restaurados con éxito!${NC}"
        echo -e "${AMARILLO}¡Listo! Ya puedes abrir Firefox o reiniciar sesión para disfrutar tu entorno.${NC}"
    else
        echo -e "\n${ROJO}❌ Error: Falló la extracción del archivo tar.gz.${NC}"
    fi

    pausar
}
# ==============================================================================
# MÓDULO 10: REAPLICAR ICONOS PERSONALIZADOS (SCRIBBLED SET)
# ==============================================================================
aplicar_iconos_custom() {
    echo -e "\n${AMARILLO}[+] Paso 10: Verificando y reaplicando iconos personalizados...${NC}"

    RUTA_ICONOS="/home/inhumano/Pictures/Iconos"
    RUTA_LOCAL_APPS="/home/inhumano/.local/share/applications"

    # Lista de aplicaciones: "Nombre_Archivo_Desktop|Nombre_Imagen_Icono|Ruta_Origen"
    declare -a APPS_ICONOS=(
        "com.discordapp.Discord.desktop|scribcord.png|/var/lib/flatpak/exports/share/applications"
        "org.kde.dolphin.desktop|scribder.png|/usr/share/applications"
        "kitty.desktop|Scribbled_Kitty.png|/usr/share/applications"
        "org.mozilla.firefox.desktop|scribfox.png|/var/lib/flatpak/exports/share/applications"
        "steam.desktop|scribsteam.png|/usr/share/applications"
    )

    A_MENOS_UNO_CAMBIADO=false

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
                sed -i "s|^Icon=.*|Icon=\/home\/inhumano\/Pictures\/Iconos\/$icono_file|" "$RUTA_LOCAL_APPS/$desktop_file"
                A_MENOS_UNO_CAMBIADO=true
            else
                echo -e "${ROJO} ⚠ No se encontró el archivo de origen para ${desktop_file}${NC}"
            fi
        else
            echo -e "${AMARILLO} ⚠ Saltando ${desktop_file}: El icono ${icono_file} no existe en la carpeta.${NC}"
        fi
    done

    if [ "$A_MENOS_UNO_CAMBIADO" = true ]; then
        update-desktop-database "$RUTA_LOCAL_APPS" &>/dev/null
        echo -e "\n${VERDE}✔ ¡Iconos personalizados aplicados correctamente!${NC}"
    fi

    pausar
}
# ==============================================================================
# MÓDULO EXTRA 11:  DESCARGAR ICONOS Y WALLPAPERS DESDE GITHUB
# ==============================================================================
descargar_assets_github() {
    echo -e "\n${AMARILLO}[+] Conectando con GitHub para descargar IconsWalls...${NC}"
    # Creamos una ruta temporal aislada en /tmp para clonar sin dejar rastro en tu Home
    DIR_TEMPORAL="/tmp/git_iconswalls_backup"
    RUTA_DESTINO="$HOME/Pictures"
    # Aseguramos que la carpeta Pictures exista en tu usuario
    mkdir -p "$RUTA_DESTINO"
    # Eliminamos restos previos en /tmp si el script falló en una ejecución anterior
    rm -rf "$DIR_TEMPORAL"
    echo -e "${AZUL}-> Clonando repositorio de forma superficial (sin historial pesado)...${NC}"

    # --depth 1 descarga solo el último commit, ahorrando mucho tiempo y ancho de banda
    if git clone --depth 1 https://github.com/Rupeji/IconsWalls "$DIR_TEMPORAL" &>/dev/null; then
        echo -e "${VERDE}✔ Repositorio clonado correctamente en zona temporal.${NC}"

        # Copiamos la carpeta de Iconos
        if [ -d "$DIR_TEMPORAL/Iconos" ]; then
            echo -e "${AZUL}-> Copiando carpeta Iconos a $RUTA_DESTINO/...${NC}"
            cp -r "$DIR_TEMPORAL/Iconos" "$RUTA_DESTINO/"
        fi
        # Copiamos la carpeta de Wallpapers
        if [ -d "$DIR_TEMPORAL/Wallpapers" ]; then
            echo -e "${AZUL}-> Copiando carpeta Wallpapers a $RUTA_DESTINO/...${NC}"
            cp -r "$DIR_TEMPORAL/Wallpapers" "$RUTA_DESTINO/"
        fi
        echo -e "${VERDE}✔ ¡Carpetas copiadas con éxito en tu directorio de imágenes!${NC}"
    else
        echo -e "${ROJO}❌ Error: No se pudo conectar con GitHub o clonar el repositorio.${NC}"
    fi
    # Limpieza absoluta de rastros
    echo -e "\n${AMARILLO}[+] Eliminando archivos temporales y limpiando rastro de Git...${NC}"
    rm -rf "$DIR_TEMPORAL"

    if [ ! -d "$DIR_TEMPORAL" ]; then
        echo -e "${VERDE}✔ ¡Sistema limpio de restos! El clon temporal ha sido eliminado.${NC}"
    fi
    pausar
}
# ==============================================================================
# MÓDULO 12: RESTAURAR ICONOS POR DEFECTO DEL SISTEMA
# ==============================================================================
restaurar_iconos_defecto() {
    echo -e "\n${AMARILLO}[+] Paso 11: Preparando la restauración de iconos por defecto...${NC}"
    echo -e "${AZUL}(Esto eliminará los accesos directos modificados de tu usuario)${NC}"

    RUTA_LOCAL_APPS="/home/inhumano/.local/share/applications"

    declare -a APPS_ICONOS=(
        "com.discordapp.Discord.desktop"
        "org.kde.dolphin.desktop"
        "kitty.desktop"
        "org.mozilla.firefox.desktop"
        "steam.desktop"
    )

    read -rp "$(echo -e "${AMARILLO}¿Restaurar iconos originales? [s/N]: ${NC}")" respuesta

    if [[ "$respuesta" =~ ^[sS]$ ]]; then
        A_MENOS_UNO_REVERTIDO=false

        for desktop_file in "${APPS_ICONOS[@]}"; do
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
            echo -e "${VERDE}✔ No se encontraron iconos personalizados activos que restaurar.${NC}"
        fi
    else
        echo -e "${AZUL}-> Manteniendo tu set de iconos personalizados activos.${NC}"
    fi

    pausar
}
# ==============================================================================
# MENÚ PRINCIPAL INTERACTIVO
# ==============================================================================
while true; do
    clear
    echo -e "${AZUL}=======================================================${NC}"
    echo -e "${AZUL}        INSTALADOR AVANZADO PERSONALIZADO (BAZZITE)     ${NC}"
    echo -e "${AZUL}=======================================================${NC}"
    echo -e "1) 🔄 Paso 1: Actualizar flatpaks"
    echo -e "2) 🚀 Paso 2: Instalar iconos y cursores"
    echo -e "3) 🖼️ Paso 3: Instalar gSlapper Wallpaper"
    echo -e "4) 🛠️ Paso 4: Instalar Apps esenciales Kitty + Fish, Discord, Firefox, etc"
    echo -e "5) ✨ Paso 5: Aplicar Tweaks Premium (Color Mocha + Prompt Morado)"
    echo -e "6) ⭐ Paso 6: Actualizar KineticOS de forma manual"
    echo -e "${AMARILLO}-------------------------------------------------------${NC}"
    echo -e "7) 🧹 Paso 7: Mantenimiento del Sistema (Limpieza de Huérfanos y Caché)"
    echo -e "8) 💾 Paso 8: Hacer Copia de Seguridad del Rice (Noctalia + Kinetic)"
    echo -e "9) ⏪ Paso 9: Restaurar Copia de Seguridad del Rice"
    echo -e "${AMARILLO}-------------------------------------------------------${NC}"
    echo -e "10)🎨 Paso 10: Aplicar Iconos Personalizados Scribbled"
    echo -e "11)↩️ Paso 11: Restaurar Iconos por Defecto del Sistema"
    echo -e "12)📦 Paso 12: Descargar Iconos y Wallpapers desde GitHub"
    echo -e "r) ↩️ Reiniciar Sistema (Obligatorio para aplicar cambios)"
    echo -e "q) ❌ Salir"
    echo -e "${AZUL}=======================================================${NC}"

    read -p "Selecciona una opción [1-12, r, q]: " opcion

    case $opcion in
        1) MODO_CADENA=false; actualizar_apps_flatpak ;;
        2) MODO_CADENA=false; instalar_iconos_y_cursores  ;;
        3) MODO_CADENA=false; instalar_gslapper ;;
        4) MODO_CADENA=false; instalar_apps_esenciales ;;
        5) MODO_CADENA=false; aplicar_dotfiles_esteticos ;;
        6) MODO_CADENA=false; actualizar_sistema_kineticos ;;
        7) MODO_CADENA=false; mantenimiento_y_limpieza ;;
        8) MODO_CADENA=false; respaldar_rice_kinetic ;;
        9) MODO_CADENA=false; restaurar_rice_kinetic ;;
        10) MODO_CADENA=false; aplicar_iconos_custom ;;
        11) MODO_CADENA=false; restaurar_iconos_defecto ;;
        12) MODO_CADENA=false; descargar_assets_github ;;

        [rR])
            echo -e "\n${AZUL}Reiniciando el sistema... ¡Disfruta de tu nuevo espacio de trabajo!${NC}"
            systemctl reboot
            break
            ;;
        [qQ])
            echo -e "\n${VERDE}¡Script cerrado correctamente!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${ROJO}Opción inválida. Intenta de nuevo.${NC}"
            sleep 1.5
            ;;
    esac
done
