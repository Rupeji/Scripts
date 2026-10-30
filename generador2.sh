#!/usr/bin/fish

# Colores premium para la terminal
set verde (set_color green)
set azul (set_color cyan)
set rojo (set_color red)
set amarillo (set_color yellow)
set reset (set_color normal)

# Bucle infinito para mantener el menú activo hasta elegir salir
while true
    echo ""
    echo "$azul========================================================$reset"
    echo "$azul   KINETICOS / BAZZITE - ORQUESTADOR DE INSTALADORES  $reset"
    echo "$azul========================================================$reset"
    echo "1) $verde"."[CREAR ISO]$reset Hornear la ISO (Usa la caché local si está al día)"
    echo "2) $amarillo"."[SOLO DESCARGAR]$reset Bajar la última imagen de GitHub (Por si falla)"
    echo "3) $rojo"."[LIMPIAR TODO]$reset Purgar carpetas, blobs y cachés del disco"
    echo "4) $azul"."[PREPARAR ENTORNO]$reset Configurar carpetas y dependencias iniciales"
    echo "5) Salir"
    echo ""
    read -p 'echo "Selecciona una opción [1-5]: "' opcion

    switch "$opcion"
        case 1
            echo ""
            echo "$azul"."[+] Paso 1: Asegurando la estructura del config interactivo...$reset"
            
            printf '[customizations.installer.kickstart]\ncontents = "graphical"\n\n[customizations.installer.modules]\nenable = [\n  "org.fedoraproject.Anaconda.Modules.Storage",\n  "org.fedoraproject.Anaconda.Modules.Runtime",\n  "org.fedoraproject.Anaconda.Modules.Network",\n  "org.fedoraproject.Anaconda.Modules.Security",\n  "org.fedoraproject.Anaconda.Modules.Services",\n  "org.fedoraproject.Anaconda.Modules.Users",\n  "org.fedoraproject.Anaconda.Modules.Timezone"\n]\ndisable = [\n  "org.fedoraproject.Anaconda.Modules.Subscription"\n]\n' > ./builder-config.toml

            echo "$azul"."[+] Paso 2: Arrancando el motor de CentOS Bootc Image Builder...$reset"
            mkdir -p ./mi_iso_bazzite
            chmod 777 ./mi_iso_bazzite

            sudo podman run \
              --rm -it \
              --privileged \
              --pull=always \
              --net=host \
              --security-opt label=type:unconfined_t \
              -v ./builder-config.toml:/config.toml:ro \
              -v ./mi_iso_bazzite:/output \
              -v /var/lib/containers/storage:/var/lib/containers/storage \
              quay.io/centos-bootc/bootc-image-builder:latest \
              --type anaconda-iso \
              --rootfs btrfs \
              --use-librepo=True \
              ghcr.io/rupeji/bazzite-kinetic:latest

            if test $status -eq 0
                echo ""
                echo "$verde"."[✓] ¡ISO cocinada con éxito!$reset"
                echo "Tu instalador te espera en: $verde./mi_iso_bazzite/bootiso/install.iso$reset"
                sudo chown -R $USER:$USER ./mi_iso_bazzite >/dev/null 2>&1
            else
                echo ""
                echo "$rojo"."[X] Algo ha fallado durante la fundición de la ISO.$reset"
            end

        case 2
            echo ""
            echo "$amarillo"."[+] Sincronizando la capa más fresca desde GitHub Packages...$reset"
            sudo podman pull ghcr.io/rupeji/bazzite-kinetic:latest
            if test $status -eq 0
                echo "$verde"."[✓] Imagen descargada correctamente en el sistema local.$reset"
            else
                echo "$rojo"."[X] Error al conectar con GitHub Packages. Verifica tu conexión.$reset"
            end

        case 3
            echo ""
            echo "$rojo"."[-] Eliminando archivos, ISOs viejas y caché de imágenes del disco...$reset"
            sudo rm -rf ./mi_iso_bazzite/bootiso ./mi_iso_bazzite/qcow2 ./builder-config.toml
            
            if test -d ./mi_iso_bazzite
                eval sudo rm -f ./mi_iso_bazzite/manifest-\*.json >/dev/null 2>&1
            end

            echo "$rojo"."[-] Purgando blobs y cachés del motor de contenedores (Podman)...$reset"
            sudo podman rmi ghcr.io/rupeji/bazzite-kinetic:latest quay.io/centos-bootc/bootc-image-builder:latest --force >/dev/null 2>&1
            sudo podman system prune --all --force
            
            echo "$verde"."[✓] Limpieza absoluta completada.$reset"

        case 4
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
            echo ""
            echo "$verde"."[✓] ¡ENTORNO INICIALIZADO AL 100%!$reset"

        case 5
            echo "Saliendo del script. ¡Hasta luego, colega!"
            break # Rompe el bucle while y cierra el script limpiamente

        case '*'
            echo "$rojo"."[-] Opción no válida.$reset"
    end
end
