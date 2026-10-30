#!/usr/bin/fish

# Colores premium para la terminal
set verde (set_color green)
set azul (set_color cyan)
set rojo (set_color red)
set amarillo (set_color yellow)
set reset (set_color normal)

echo "$azul========================================================$reset"
echo "$azul   KINETICOS / BAZZITE - ORQUESTADOR DE INSTALADORES  $reset"
echo "$azul========================================================$reset"
echo "1) $verde"."[CREAR]$reset Hornear la ISO interactiva (Usa caché local)"
echo "2) $rojo"."[ACTUALIZAR / LIMPIAR]$reset Traer cambios de GitHub y borrar ISO vieja"
echo "3) $amarillo"."[PREPARAR ENTORNO DESDE CERO]$reset Configurar carpetas, dependencias e imagen inicial"
echo "4) Salir"
echo ""
read -p 'echo "Selecciona una opción [1-4]: "' opcion

switch "$opcion"
    case 1
        echo ""
        echo "$azul"."[+] Paso 1: Asegurando la estructura del config interactivo...$reset"
        
        # EL TRUCO COMBINADO: Mapeamos los módulos de Anaconda Y forzamos el modo "graphical" interactivo
        printf '[customizations.installer.kickstart]\ncontents = "graphical"\n\n[customizations.installer.modules]\nenable = [\n  "org.fedoraproject.Anaconda.Modules.Storage",\n  "org.fedoraproject.Anaconda.Modules.Runtime",\n  "org.fedoraproject.Anaconda.Modules.Network",\n  "org.fedoraproject.Anaconda.Modules.Security",\n  "org.fedoraproject.Anaconda.Modules.Services",\n  "org.fedoraproject.Anaconda.Modules.Users",\n  "org.fedoraproject.Anaconda.Modules.Timezone"\n]\ndisable = [\n  "org.fedoraproject.Anaconda.Modules.Subscription"\n]\n' > ./builder-config.toml

        # Comprobar si la imagen existe en el almacenamiento rootful de podman
        if not sudo podman image exists localhost/bazzite-kinetic:latest
            echo "$rojo"."[-] Error: La imagen local 'localhost/bazzite-kinetic:latest' no existe.$reset"
            echo "Por favor, ejecuta primero la opción (3) si es un sistema recién formateado."
            exit 1
        end

        echo "$azul"."[+] Paso 2: Arrancando el motor de CentOS Bootc Image Builder...$reset"
        mkdir -p ./mi_iso_bazzite
        chmod 777 ./mi_iso_bazzite

        sudo podman run \
          --rm -it \
          --privileged \
          --pull=newer \
          --net=host \
          --security-opt label=type:unconfined_t \
          -v ./builder-config.toml:/config.toml:ro \
          -v ./mi_iso_bazzite:/output \
          -v /var/lib/containers/storage:/var/lib/containers/storage \
          quay.io/centos-bootc/bootc-image-builder:latest \
          --type anaconda-iso \
          --rootfs btrfs \
          --use-librepo=True \
          localhost/bazzite-kinetic:latest

        if test $status -eq 0
            echo ""
            echo "$verde"."[✓] ¡ISO cocinada con éxito!$reset"
            echo "Tu instalador te espera en: $verde./mi_iso_bazzite/bootiso/install.iso$reset"
            
            # Restaurar la propiedad del archivo al usuario actual para poder usarlo en GNOME Boxes
            sudo chown -R $USER:$USER ./mi_iso_bazzite >/dev/null 2>&1
        else
            echo ""
            echo "$rojo"."[X] Algo ha fallado durante la fundición de la ISO.$reset"
        end

    case 2
        echo ""
        echo "$rojo"."[-] Eliminando archivos e ISOs viejas del disco...$reset"
        sudo rm -rf ./mi_iso_bazzite/bootiso ./mi_iso_bazzite/qcow2 ./mi_iso_bazzite/manifest-*.json ./builder-config.toml
        
        echo "$azul"."[+] Descargando los datos nuevos desde GitHub Packages (Tick Verde)...$reset"
        sudo podman pull ghcr.io/rupeji/bazzite-kinetic:latest
        
        echo "$azul"."[+] Sincronizando etiquetas locales para Podman...$reset"
        sudo podman tag ghcr.io/rupeji/bazzite-kinetic:latest localhost/bazzite-kinetic:latest
        
        echo ""
        echo "$verde"."[✓] Limpieza completa y datos nuevos listos para hornear.$reset"

    case 3
        echo ""
        echo "$azul"."[+] Iniciando PREPARACIÓN TOTAL del entorno desde cero...$reset"
        
        mkdir -p ./mi_iso_bazzite
        sudo chown -R $USER:$USER ./mi_iso_bazzite >/dev/null 2>&1
        chmod 777 ./mi_iso_bazzite
        
        printf '[customizations.installer.modules]\nenable = ["org.fedoraproject.Anaconda.Modules.Users"]\n' > ./builder-config.toml
        
        if not type -q podman
            echo "$amarillo"."[!] Podman no encontrado en el sistema base. Intentando inicializarlo...$reset"
            sudo systemctl enable --now podman.socket >/dev/null 2>&1
        else
            echo "$verde"."[✓] El motor Podman está presente y activo.$reset"
        end
        
        echo "$azul"."[+] Descargando tu imagen modular de GitHub Packages por primera vez...$reset"
        sudo podman pull ghcr.io/rupeji/bazzite-kinetic:latest
        
        echo "$azul"."[+] Generando enlace local 'localhost/bazzite-kinetic'...$reset"
        sudo podman tag ghcr.io/rupeji/bazzite-kinetic:latest localhost/bazzite-kinetic:latest
        
        echo ""
        echo "$verde"."[✓] ¡ENTORNO INICIALIZADO AL 100%! Carpetas creadas, TOML listo e imagen descargada. Ya puedes pulsar la opción (1).$reset"

    case 4
        echo "Saliendo del script. ¡Hasta luego, colega!"
        exit 0

    case '*'
        echo "$rojo"."[-] Opción no válida.$reset"
end
