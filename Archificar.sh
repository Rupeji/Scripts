#!/bin/bash

# 1. Crear el directorio de configuración si no existe
echo "Creando directorio de configuración de fastfetch..."
mkdir -p ~/.config/fastfetch

# 2. Escribir el archivo config.jsonc corregido
echo "Generando archivo config.jsonc..."
cat << 'EOF' > ~/.config/fastfetch/config.jsonc
{
  "$schema": "https://github.com",
  "logo": {
    "source": "arch"
  },
  "modules": [
    "title",
    "separator",
    {
      "type": "os",
      "format": "Arch Linux {2}"
    },
    "host",
    "kernel",
    "uptime",
    "packages",
    "shell",
    "display",
    "de",
    "wm",
    "wmtheme",
    "theme",
    "icons",
    "font",
    "cursor",
    "terminal",
    "terminalfont",
    "cpu",
    "gpu",
    "memory",
    "swap",
    "disk",
    "battery",
    "poweradapter",
    "localip",
    "locale",
    "break",
    "colors"
  ]
}
EOF

echo "¡Estructura de Fastfetch creada con éxito para Arch Linux!"
