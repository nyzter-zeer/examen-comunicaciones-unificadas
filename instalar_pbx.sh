#!/bin/bash

# ==============================================================================
# Script de Automatización: Asterisk 22 & FreePBX 17 (Ubuntu 24.04)
# Examen de Comunicaciones Unificadas - Servidor Asterisk
# ==============================================================================

LOG_FILE="/var/log/instalacion_pbx.log"
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

set -e

error_handler() {
  echo ""
  echo "======================================================"
  echo "❌ ERROR CRÍTICO DETECTADO ❌"
  echo "La instalación se ha detenido."
  echo "- Línea del script donde ocurrió: $1"
  echo "- Comando exacto que falló: $2"
  echo "======================================================"
  exit 1
}

trap 'error_handler ${LINENO} "$BASH_COMMAND"' ERR

if [ "$EUID" -ne 0 ]; then
  echo "Error: Debes ejecutar este script como root (sudo ./instalar_pbx.sh)."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1
echo '* libraries/restart-without-asking boolean true' | debconf-set-selections

echo "======================================================"
echo "1. Configurando Entorno y hostname..."
echo "======================================================"
sudo hostnamectl set-hostname SERVASTERISK
sudo timedatectl set-timezone America/Santiago
sudo timedatectl set-ntp on

cat <<EOF > /etc/sysctl.d/99-disable-ipv6.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
sysctl -p /etc/sysctl.d/99-disable-ipv6.conf || true

echo "======================================================"
echo "2. Limpieza Profunda de Instalaciones Previas..."
echo "======================================================"
systemctl stop asterisk || true
pkill -9 asterisk || true
rm -rf /etc/asterisk /usr/lib/asterisk /var/lib/asterisk /var/spool/asterisk /var/log/asterisk /var/run/asterisk
rm -f /etc/freepbx.conf /etc/amportal.conf
rm -f /etc/apt/sources.list.d/ondrej* /etc/apt/sources.list.d/*php*
apt-get clean

echo "======================================================"
echo "3. Descarga de Fuentes de Asterisk..."
echo "======================================================"
cd /usr/src/
rm -f asterisk-22-current.tar.gz
rm -rf asterisk-22.*/ 

apt-get update -y
apt-get install sox pkg-config libedit-dev unzip git gnupg2 curl libnewt-dev libssl-dev subversion -y

wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-22-current.tar.gz
tar -xvzf asterisk-22-current.tar.gz
cd asterisk-22.*/

echo "======================================================"
echo "4. Instalación de Prerrequisitos..."
echo "======================================================"
apt-get install build-essential wget curl git subversion libncurses5-dev libncursesw5-dev libssl-dev libedit-dev libxml2-dev uuid-dev libsqlite3-dev sqlite3 libjansson-dev libcurl4-openssl-dev libspeexdsp-dev pkg-config -y

cd contrib/scripts
sed -i 's/set -e/set +e/g' install_prereq
sed -i 's/grep -c/grep -c || true/g' install_prereq
yes | ./install_prereq install

cd ../..
./configure
make menuselect.makeopts

echo "======================================================"
echo "5. Compilando Asterisk..."
echo "======================================================"
menuselect/menuselect \
  --enable chan_ooh323 --enable format_mp3 --enable res_config_mysql \
  --enable CORE-SOUNDS-EN-WAV --enable CORE-SOUNDS-EN-ULAW --enable CORE-SOUNDS-EN-ALAW \
  --enable CORE-SOUNDS-EN-GSM --enable CORE-SOUNDS-EN-G729 --enable CORE-SOUNDS-EN-G722 \
  --enable CORE-SOUNDS-EN-SLN16 --enable CORE-SOUNDS-EN-SIREN7 \
  --enable MOH-OPSOUND-WAV --enable MOH-OPSOUND-ULAW --enable MOH-OPSOUND-ALAW \
  --enable MOH-OPSOUND-GSM --enable MOH-OPSOUND-G729 \
  --enable EXTRA-SOUNDS-EN-WAV --enable EXTRA-SOUNDS-EN-ULAW --enable EXTRA-SOUNDS-EN-ALAW \
  --enable EXTRA-SOUNDS-EN-GSM --enable EXTRA-SOUNDS-EN-G729 \
  menuselect.makeopts

make && make install && make samples && make config && ldconfig

echo "======================================================"
echo "6. Ajuste de Permisos y Usuarios..."
echo "======================================================"
id -u asterisk &>/dev/null || (groupadd asterisk && useradd -r -d /var/lib/asterisk -g asterisk asterisk)
usermod -aG audio,dialout asterisk

mkdir -p /var/run/asterisk
chown -R asterisk:asterisk /etc/asterisk /var/{lib,log,spool,run}/asterisk /usr/lib/asterisk

echo "======================================================"
echo "7. Configuración de Archivos de Asterisk..."
echo "======================================================"
sed -i 's/^[#;]*AST_USER=.*/AST_USER="asterisk"/' /etc/default/asterisk
sed -i 's/^[#;]*AST_GROUP=.*/AST_GROUP="asterisk"/' /etc/default/asterisk
sed -i 's/^[#;]*runuser =.*/runuser = asterisk/' /etc/asterisk/asterisk.conf
sed -i 's/^[#;]*rungroup =.*/rungroup = asterisk/' /etc/asterisk/asterisk.conf
sed -i 's|;\[radius\]|\[radius\]|g' /etc/asterisk/cdr.conf
sed -i 's|.*radiuscfg =>.*|radiuscfg => /etc/radcli/radiusclient.conf|g' /etc/asterisk/cdr.conf
sed -i 's|.*radiuscfg =>.*|radiuscfg => /etc/radcli/radiusclient.conf|g' /etc/asterisk/cel.conf

systemctl enable asterisk
systemctl restart asterisk

echo "======================================================"
echo "8. Instalación de FreePBX 17 y Dependencias..."
echo "======================================================"
apt-get install mariadb-server apache2 php libapache2-mod-php php-intl php-mysql php-curl php-cli php-zip php-xml php-gd php-common php-mbstring php-xmlrpc php-bcmath php-json php-sqlite3 php-soap php-ldap php-imap php-cas -y

systemctl start mariadb || true
mysql -e "DROP DATABASE IF EXISTS asterisk;" || true
mysql -e "DROP DATABASE IF EXISTS asteriskcdrdb;" || true

cd /usr/src/
rm -rf freepbx/ 
rm -f freepbx-17.0-latest.tgz

wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-17.0-latest.tgz
tar -xvzf freepbx-17.0-latest.tgz
cd freepbx

apt-get install nodejs npm -y
./install -n || true
fwconsole ma install pm2 || true

echo "======================================================"
echo "9. Configurando Apache y PHP..."
echo "======================================================"
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf
sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

for ini in $(find /etc/php -name php.ini); do
    sed -i 's/\(^upload_max_filesize = \).*/\120M/' "$ini"
done

a2enmod rewrite
systemctl restart apache2

echo "======================================================"
echo "10. Firewall (UFW) - Aplicando Reglas de Red..."
echo "======================================================"
apt-get install ufw -y
ufw --force reset
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 5060/udp
ufw allow 5061/tcp
ufw allow 10000:20000/udp
ufw allow ssh
ufw allow telnet
ufw --force enable

echo "======================================================"
echo "¡INSTALACIÓN COMPLETADA CON ÉXITO!"
IP_SERVER=$(hostname -I | awk '{print $1}')
echo "Accede a FreePBX en: http://$IP_SERVER/admin"
echo "======================================================"
sleep 5
init 6