#!/bin/bash

# ==============================================================================
# Script de Automatización: Kamailio SBC + RTPEngine + TLS (Ubuntu 24.04)
# Examen de Comunicaciones Unificadas - Servidor Kamailio
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Error: Debes ejecutar este script como root (sudo ./instalar_kamailio.sh)."
  exit 1
fi

echo "=== 1. Configurando Entorno Inicial ==="
sudo hostnamectl set-hostname SERVKAMAILO
sudo timedatectl set-timezone America/Santiago
sudo timedatectl set-ntp on

echo "=== 2. Instalando Kamailio y Paquetes de Expansión ==="
sudo apt update && sudo apt upgrade -y
sudo apt install kamailio kamailio-extra-modules kamailio-tls-modules kamailio-outbound-modules -y

echo "=== 3. Instalando y Configurando RTPEngine ==="
sudo apt install -y rtpengine

# El archivo rtpengine.conf se generará dinámicamente mediante el archivo de configs de tu repo.
# Alternativamente se inicializa un backup limpio aquí.
sudo cp /etc/rtpengine/rtpengine.conf /etc/rtpengine/rtpengine.conf.bak || true

echo "=== 4. Generación de Certificados TLS de manera Dinámica ==="
sudo mkdir -p /etc/kamailio/certs

PUBLIC_IP=$(curl -s ifconfig.me)
if [ -z "$PUBLIC_IP" ]; then
    echo "⚠️ ALERTA: No se pudo obtener la IP pública. Usando localhost para el certificado."
    PUBLIC_IP="127.0.0.1"
fi
echo "IP pública detectada: $PUBLIC_IP"

sudo openssl req -new -x509 -nodes \
  -days 365 \
  -out /etc/kamailio/certs/kamailio-cert.pem \
  -keyout /etc/kamailio/certs/kamailio-key.pem \
  -subj "/C=CL/ST=RM/L=Santiago/O=DUOC-UC/OU=VoIP-Lab/CN=$PUBLIC_IP"

# Asignación de permisos correctos a llaves
sudo chown -R kamailio:kamailio /etc/kamailio/certs
sudo chmod 640 /etc/kamailio/certs/kamailio-key.pem
sudo chmod 644 /etc/kamailio/certs/kamailio-cert.pem

echo "=== Ajustes del Servidor Completados ==="
echo "Proceda a copiar los archivos de configuración unificados desde la carpeta kamailio/config/"
