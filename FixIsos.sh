#!/usr/bin/env bash

# =====================================================================
# Script de Reparación Post-Instalación: Agente Polkit para KineticWE
# =====================================================================

# Colores para una salida limpia en terminal
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AZUL='\033[0;34m'
NC='\033[0m' # Sin color

echo -e "${AZUL}=======================================================${NC}"
echo -e "${AZUL}🛠️  Iniciando reparación local de Polkit para KineticWE${NC}"
echo -e "${AZUL}=======================================================${NC}"

# 1. Definir rutas del agente y del autostart local
AGENTE_BIN="/usr/libexec/kf6/polkit-kde-authentication-agent-1"
DIRECTORIO_AUTOSTART="${HOME}/.config/autostart"
ARCHIVO_DESKTOP="${DIRECTORIO_AUTOSTART}/polkit-kde-authentication-agent-1.desktop"

# 2. Comprobar si el binario del agente existe en el sistema inmutable
echo "Verificando la existencia del componente Polkit de KDE6..."
if [ ! -f "$AGENTE_BIN" ]; then
    echo -e "${ROJO}❌ Error crítico: El archivo $AGENTE_BIN no existe.${NC}"
    echo "Asegúrate de que tu build incluye el paquete 'polkit-kde-agent-1'."
    exit 1
fi
echo -e "${VERDE}✓ Componente Polkit encontrado en el sistema.${NC}"

# 3. Crear el directorio de autostart local en el /home del usuario si no existe
echo "Preparando el directorio de inicio automático del usuario..."
mkdir -p "$DIRECTORIO_AUTOSTART"

# 4. Escribir el archivo .desktop utilizando la estructura limpia estándar de Freedesktop
echo "Creando el lanzador de escritorio local..."
cat << EOF > "$ARCHIVO_DESKTOP"
[Desktop Entry]
Type=Application
Name=KDE Polkit Authentication Agent
Comment=Motor de contraseñas de administrador para apps gráficas
Exec=$AGENTE_BIN
Terminal=false
X-KDE-Autostart-phase=1
EOF

# 5. Aplicar los permisos correctos de ejecución
chmod +x "$ARCHIVO_DESKTOP"
echo -e "${VERDE}✓ Lanzador .desktop configurado correctamente en:${NC}"
echo "   $ARCHIVO_DESKTOP"

# 6. Lanzar el agente inmediatamente en segundo plano para evitar reiniciar
echo "Iniciando el agente de autenticación en la sesión actual..."
# Comprobar si ya se está ejecutando para no duplicar procesos
if pgrep -f "$(basename "$AGENTE_BIN")" > /dev/null; then
    echo -e "${AZUL}ℹ El agente ya se encuentra corriendo en segundo plano.${NC}"
else
    "$AGENTE_BIN" &
    echo -e "${VERDE}✅ ¡Agente Polkit iniciado con éxito en segundo plano!${NC}"
fi

echo -e "${AZUL}=======================================================${NC}"
echo -e "${VERDE}🎉 ¡Proceso terminado! Ya puedes abrir Fedora Media Writer.${NC}"
echo -e "${AZUL}=======================================================${NC}"
