# ==============================================================================
# Dockerfile: Asterisk 22 & FreePBX 17 (basado en instalar_pbx.sh V11)
# Imagen base: Ubuntu 24.04
# ==============================================================================
FROM ubuntu:24.04

LABEL maintainer="Basti"
LABEL description="Asterisk 22 + FreePBX 17 compilados desde fuente, dockerizado"

ENV DEBIAN_FRONTEND=noninteractive
ENV NEEDRESTART_MODE=a
ENV NEEDRESTART_SUSPEND=1
ENV TZ=America/Santiago

# ------------------------------------------------------------------------
# 1. Zona horaria + locales básicos
# ------------------------------------------------------------------------
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# ------------------------------------------------------------------------
# 2. Paquetes base + herramientas de compilación (equivalente a tus pasos 4 y 5)
# ------------------------------------------------------------------------
RUN echo '* libraries/restart-without-asking boolean true' | debconf-set-selections && \
    apt-get update -y && \
    apt-get install -y \
        sox pkg-config libedit-dev unzip git gnupg2 curl libnewt-dev libssl-dev subversion \
        build-essential wget libncurses5-dev libncursesw5-dev libxml2-dev uuid-dev \
        libsqlite3-dev sqlite3 libjansson-dev libcurl4-openssl-dev libspeexdsp-dev \
        supervisor sysvinit-utils \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------
# 3. Descarga y compilación de Asterisk 22 (equivalente a tus pasos 4 y 6)
# ------------------------------------------------------------------------
WORKDIR /usr/src
RUN wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-22-current.tar.gz && \
    tar -xvzf asterisk-22-current.tar.gz && \
    rm asterisk-22-current.tar.gz

# NOTA: el nombre real de la carpeta descomprimida varía según la versión
# exacta que se descargue (ej. asterisk-22.5.2), por eso se resuelve
# dinámicamente con `find` en vez de hardcodearlo.
RUN ASTDIR=$(find /usr/src -maxdepth 1 -type d -name "asterisk-22.*") && \
    cd "$ASTDIR" && \
    cd contrib/scripts && \
    sed -i 's/set -e/set +e/g' install_prereq && \
    sed -i 's/grep -c/grep -c || true/g' install_prereq && \
    yes | ./install_prereq install

RUN ASTDIR=$(find /usr/src -maxdepth 1 -type d -name "asterisk-22.*") && \
    cd "$ASTDIR" && \
    contrib/scripts/get_mp3_source.sh && \
    ./configure && \
    make menuselect.makeopts && \
    menuselect/menuselect \
      --enable chan_ooh323 --enable format_mp3 --enable res_config_mysql \
      --enable CORE-SOUNDS-EN-WAV --enable CORE-SOUNDS-EN-ULAW --enable CORE-SOUNDS-EN-ALAW \
      --enable CORE-SOUNDS-EN-GSM --enable CORE-SOUNDS-EN-G729 --enable CORE-SOUNDS-EN-G722 \
      --enable CORE-SOUNDS-EN-SLN16 --enable CORE-SOUNDS-EN-SIREN7 \
      --enable MOH-OPSOUND-WAV --enable MOH-OPSOUND-ULAW --enable MOH-OPSOUND-ALAW \
      --enable MOH-OPSOUND-GSM --enable MOH-OPSOUND-G729 \
      --enable EXTRA-SOUNDS-EN-WAV --enable EXTRA-SOUNDS-EN-ULAW --enable EXTRA-SOUNDS-EN-ALAW \
      --enable EXTRA-SOUNDS-EN-GSM --enable EXTRA-SOUNDS-EN-G729 \
      menuselect.makeopts && \
    make -j$(nproc) && make install && make samples && make config && ldconfig

# ------------------------------------------------------------------------
# 4. Usuario y permisos de Asterisk (equivalente a tu paso 7)
# ------------------------------------------------------------------------
RUN (id -u asterisk >/dev/null 2>&1 || (groupadd asterisk && useradd -r -d /var/lib/asterisk -g asterisk asterisk)) && \
    usermod -aG audio,dialout asterisk && \
    mkdir -p /var/run/asterisk && \
    chown -R asterisk:asterisk /etc/asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk /var/run/asterisk /usr/lib/asterisk

# ------------------------------------------------------------------------
# 5. Configuración de archivos de Asterisk (equivalente a tu paso 8)
# ------------------------------------------------------------------------
RUN sed -i 's/^[#;]*AST_USER=.*/AST_USER="asterisk"/' /etc/default/asterisk && \
    sed -i 's/^[#;]*AST_GROUP=.*/AST_GROUP="asterisk"/' /etc/default/asterisk && \
    sed -i 's/^[#;]*runuser =.*/runuser = asterisk/' /etc/asterisk/asterisk.conf && \
    sed -i 's/^[#;]*rungroup =.*/rungroup = asterisk/' /etc/asterisk/asterisk.conf && \
    sed -i 's|;\[radius\]|\[radius\]|g' /etc/asterisk/cdr.conf && \
    sed -i 's|.*radiuscfg =>.*|radiuscfg => /etc/radcli/radiusclient.conf|g' /etc/asterisk/cdr.conf && \
    sed -i 's|.*radiuscfg =>.*|radiuscfg => /etc/radcli/radiusclient.conf|g' /etc/asterisk/cel.conf

# ------------------------------------------------------------------------
# 6. MariaDB + Apache + PHP + Node (equivalente a tu paso 9)
# ------------------------------------------------------------------------
RUN apt-get update -y && apt-get install -y \
        mariadb-server apache2 php libapache2-mod-php php-intl php-mysql php-curl \
        php-cli php-zip php-xml php-gd php-common php-mbstring php-xmlrpc \
        php-bcmath php-json php-sqlite3 php-soap php-ldap php-imap php-cas \
        nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------
# 7. Instalación de FreePBX 17 (equivalente a tu paso 9, parte final)
#    NOTA: MariaDB se levanta manualmente DENTRO de esta capa de build,
#    se corre el instalador de FreePBX, y luego se apaga de forma limpia.
# ------------------------------------------------------------------------
WORKDIR /usr/src
RUN wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-17.0-latest.tgz && \
    tar -xvzf freepbx-17.0-latest.tgz && \
    rm freepbx-17.0-latest.tgz

RUN service mariadb start && \
    sleep 5 && \
    mysql -e "DROP DATABASE IF EXISTS asterisk;" || true && \
    mysql -e "DROP DATABASE IF EXISTS asteriskcdrdb;" || true && \
    cd /usr/src/freepbx && \
    (./install -n || true) && \
    (fwconsole ma install pm2 || true) && \
    mysqladmin shutdown

# ------------------------------------------------------------------------
# 8. Apache y PHP (equivalente a tu paso 10)
# ------------------------------------------------------------------------
RUN sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf && \
    sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf && \
    for ini in $(find /etc/php -name php.ini); do \
        sed -i 's/\(^upload_max_filesize = \).*/\120M/' "$ini"; \
    done && \
    a2enmod rewrite

# ------------------------------------------------------------------------
# 9. Supervisord: mantiene MariaDB + Apache + Asterisk vivos en 1 solo contenedor
# ------------------------------------------------------------------------
COPY supervisord.conf /etc/supervisor/conf.d/freepbx.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ------------------------------------------------------------------------
# Puertos expuestos (documentativo; el mapeo real se define en docker-compose)
# ------------------------------------------------------------------------
EXPOSE 80 443 5060/udp 5060/tcp 5061/tcp 10000-20000/udp

# Volúmenes con los datos que deben persistir
VOLUME ["/etc/asterisk", "/var/lib/asterisk", "/var/spool/asterisk", "/var/lib/mysql", "/var/www/html"]

ENTRYPOINT ["/entrypoint.sh"]
