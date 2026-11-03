#!/bin/bash

# Detener el script inmediatamente si ocurre algún error
set -e

FINGERPRINT="FD258A99CDC5F61B04A335EEE163D34B273AE987"
KEY_URL="https://theblackdon.gitlab.io/kineticwe/kineticwe.gpg"
REPO_BLOCK="[kineticwe]\nServer = https://theblackdon.gitlab.io/kineticwe/\$arch"

echo "=================================================="
echo "    Iniciando instalación de KineticWE en Arch"
echo "=================================================="

# 1. Descarga y verificación de la clave GPG
echo "--> Descargando clave GPG oficial..."
if ! curl -fLO "$KEY_URL"; then
    echo "⚠️ Falló la descarga por GitLab Pages. Intentando desde el servidor de claves..."
    sudo pacman-key --recv-keys "$FINGERPRINT" --keyserver hkps://keys.openpgp.org
else
    echo "--> Verificando la integridad de la clave..."
    # Extrae la huella de la clave descargada de manera robusta
    DOWNLOADED_FP=$(gpg --show-keys --with-colons kineticwe.gpg | awk -F: '$1=="fpr"{print $10}' | head -n 1)

    if [ "$DOWNLOADED_FP" != "$FINGERPRINT" ]; then
        echo "❌ ¡ERROR CRÍTICO! La huella digital no coincide."
        echo "Esperada:  $FINGERPRINT"
        echo "Obtenida:  $DOWNLOADED_FP"
        rm -f kineticwe.gpg
        exit 1
    fi

    echo "✅ Huella digital validada correctamente."
    
    # Añadir y firmar localmente la clave descargada
    sudo pacman-key --add kineticwe.gpg
    rm -f kineticwe.gpg
fi

echo "--> Firmando localmente la clave del repositorio..."
sudo pacman-key --lsign-key "$FINGERPRINT"

# 2. Agregar el repositorio a /etc/pacman.conf si no existe
echo "--> Configurando repositorio en /etc/pacman.conf..."
if ! grep -q "\[kineticwe\]" /etc/pacman.conf; then
    sudo tee -a /etc/pacman.conf << EOF

[kineticwe]
Server = https://theblackdon.gitlab.io/kineticwe/\$arch
EOF
    echo "✅ Repositorio añadido correctamente."
else
    echo "ℹ️ El repositorio ya estaba presente en pacman.conf."
fi

# 3. Sincronizar bases de datos e instalar
echo "--> Actualizando repositorios e instalando paquetes centrales..."
sudo pacman -Syu --noconfirm kineticwe-keyring kineticwe

# 4. Componentes opcionales (Greeter Noctalia)
echo "=================================================="
read -p "¿Deseas instalar también el Greeter Noctalia (pantalla de inicio)? (s/n): " responder
if [[ "$responder" =~ ^[Ss]$ ]]; then
    echo "--> Instalando kineticwe-greeter..."
    sudo pacman -S --noconfirm kineticwe-greeter
    echo "--> Iniciando el asistente interactivo de configuración..."
    kineticwe-setup-greeter
fi

echo "=================================================="
echo " 🎉 ¡Proceso finalizado con éxito!"
echo "=================================================="
