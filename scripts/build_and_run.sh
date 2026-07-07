#!/bin/bash
#############################################################################
# Build & Run: Contenedor custom de Asterisk 22 + FreePBX 17
# (a partir del Dockerfile en este mismo directorio)
#############################################################################

set -e

log() { echo -e "\n\033[1;32m[INFO]\033[0m $1"; }
warn() { echo -e "\n\033[1;33m[AVISO]\033[0m $1"; }
error_exit() { echo -e "\n\033[1;31m[ERROR]\033[0m $1"; exit 1; }

if [[ $EUID -eq 0 ]]; then
    error_exit "No ejecutes este script como root directamente. Usa un usuario con permisos sudo."
fi

# ============================================================
# 1. Instalar Docker si falta
# ============================================================
if ! command -v docker &> /dev/null; then
    log "Instalando Docker Engine..."
    sudo apt update -y
    sudo apt install -y ca-certificates curl gnupg lsb-release
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker "$USER"
    warn "Se agregó tu usuario al grupo 'docker'. Cierra sesión y vuelve a entrar para usar docker sin sudo."
else
    log "Docker ya está instalado."
fi

# ============================================================
# 2. Firewall del host (UFW) - equivalente a tu paso 11 original
# ============================================================
if command -v ufw &> /dev/null; then
    if sudo ufw status | grep -q "Status: active"; then
        log "Configurando reglas de firewall (UFW) en el host..."
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw allow 5060/udp
        sudo ufw allow 5061/tcp
        sudo ufw allow 10000:20000/udp
        sudo ufw reload
    fi
fi

# ============================================================
# 3. Build de la imagen (tardará bastante: compila Asterisk desde fuente)
# ============================================================
log "Construyendo la imagen (esto puede tardar 15-40 minutos, compila Asterisk desde código fuente)..."
sudo docker compose build

# ============================================================
# 4. Levantar el contenedor
# ============================================================
log "Levantando el contenedor..."
sudo docker compose up -d

sleep 5
log "Verificando estado de los servicios dentro del contenedor..."
sudo docker exec freepbx-custom supervisorctl status || warn "Aún iniciando, revisa en unos segundos con: sudo docker exec freepbx-custom supervisorctl status"

IP_LOCAL=$(hostname -I | awk '{print $1}')

echo -e "\n\033[1;36m=========================================================="
echo " INSTALACIÓN COMPLETADA"
echo "==========================================================\033[0m"
echo " Panel web FreePBX:  http://${IP_LOCAL}/admin"
echo ""
echo " Comandos útiles:"
echo "   Estado de servicios:   sudo docker exec freepbx-custom supervisorctl status"
echo "   Consola Asterisk:      sudo docker exec -it freepbx-custom asterisk -rvvv"
echo "   Logs de FreePBX:       sudo docker exec -it freepbx-custom fwconsole log"
echo "   Reiniciar Asterisk:    sudo docker exec freepbx-custom supervisorctl restart asterisk"
echo "   Detener todo:          sudo docker compose down"
echo "   Reconstruir imagen:    sudo docker compose build --no-cache"
echo -e "\033[1;36m==========================================================\033[0m\n"
