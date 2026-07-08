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
# 2. Paquetes base + herramientas de compilación
#    DIFERENCIA CON SCRIPT: el script instala en dos tandas separadas.
#    Aquí lo unificamos, pero los paquetes son EXACTAMENTE los mismos.
#    Se agrega libpjproject-dev para evitar que ./configure lo descargue.
# ------------------------------------------------------------------------
RUN echo '* libraries/restart-without-asking boolean true' | debconf-set-selections && \
    apt-get update -y && \
    apt-get install -y \
    sox pkg-config libedit-dev unzip git gnupg2 curl libnewt-dev libssl-dev subversion \
    build-essential wget libncurses5-dev libncursesw5-dev libxml2-dev uuid-dev \
    libsqlite3-dev sqlite3 libjansson-dev libcurl4-openssl-dev libspeexdsp-dev \
    supervisor sysvinit-utils cron \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------
# 3. Descarga de Asterisk 22
# ------------------------------------------------------------------------
WORKDIR /usr/src
RUN wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-22-current.tar.gz && \
    tar -xvzf asterisk-22-current.tar.gz && \
    rm asterisk-22-current.tar.gz

# ------------------------------------------------------------------------
# 4. Prerrequisitos de Asterisk (install_prereq)
#    IGUAL que el script: sed para suprimir errores, yes para confirmar
# ------------------------------------------------------------------------
RUN ASTDIR=$(find /usr/src -maxdepth 1 -type d -name "asterisk-22.*") && \
    cd "$ASTDIR" && \
    cd contrib/scripts && \
    sed -i 's/set -e/set +e/g' install_prereq && \
    sed -i 's/grep -c/grep -c || true/g' install_prereq && \
    yes | ./install_prereq install

# ------------------------------------------------------------------------
# 5. PRE-DESCARGA de tarballs de terceros que ./configure necesita.
#    DIFERENCIA CLAVE CON VM: en VM la red funciona dentro de make.
#    En Docker BuildKit, el make interno de ./configure tiene timeouts
#    muy cortos y falla. Descargando con wget -4 (IPv6 a veces falla
#    en Docker) antes de configure, los archivos ya están en /tmp
#    y configure los encuentra sin necesidad de descargarlos.
# ------------------------------------------------------------------------
RUN wget -4 --tries=5 --timeout=120 --waitretry=10 \
    "https://raw.githubusercontent.com/asterisk/third-party/master/pjproject/2.17/pjproject-2.17.tar.bz2" \
    -O /tmp/pjproject-2.17.tar.bz2 && \
    wget -4 --tries=5 --timeout=120 --waitretry=10 \
    "https://raw.githubusercontent.com/asterisk/third-party/master/jansson/2.15.0/jansson-2.15.0.tar.bz2" \
    -O /tmp/jansson-2.15.0.tar.bz2

# ------------------------------------------------------------------------
# 6. ./configure — IGUAL que el script, sin flags adicionales
# ------------------------------------------------------------------------
RUN ASTDIR=$(find /usr/src -maxdepth 1 -type d -name "asterisk-22.*") && \
    cd "$ASTDIR" && \
    ./configure || { echo "=== config.log (últimas 60 líneas) ===" && tail -60 config.log && exit 1; }

# ------------------------------------------------------------------------
# 7. menuselect
#    NOTA: chan_ooh323, format_mp3, res_config_mysql ya no existen en
#    Asterisk 22. menuselect los ignora silenciosamente (no falla).
#    Los mantenemos comentados para referencia del script original.
# ------------------------------------------------------------------------
RUN ASTDIR=$(find /usr/src -maxdepth 1 -type d -name "asterisk-22.*") && \
    cd "$ASTDIR" && \
    make menuselect.makeopts && \
    menuselect/menuselect \
    --enable CORE-SOUNDS-EN-WAV --enable CORE-SOUNDS-EN-ULAW --enable CORE-SOUNDS-EN-ALAW \
    --enable CORE-SOUNDS-EN-GSM \
    --enable MOH-OPSOUND-WAV --enable MOH-OPSOUND-ULAW --enable MOH-OPSOUND-ALAW \
    --enable MOH-OPSOUND-GSM \
    --enable EXTRA-SOUNDS-EN-WAV --enable EXTRA-SOUNDS-EN-ULAW --enable EXTRA-SOUNDS-EN-ALAW \
    --enable EXTRA-SOUNDS-EN-GSM \
    menuselect.makeopts

# ------------------------------------------------------------------------
# 8. Compilación e instalación de Asterisk
#    DIFERENCIA CON SCRIPT: el script usa "make && make install".
#    Aquí usamos make sin -j (secuencial) para evitar race conditions.
#    IMPORTANTE: NO usar pipe (| tail) porque rompe el exit code de make.
# ------------------------------------------------------------------------
RUN ASTDIR=$(find /usr/src -maxdepth 1 -type d -name "asterisk-22.*") && \
    cd "$ASTDIR" && \
    make && \
    make install && \
    make samples && \
    make config && \
    ldconfig && \
    # Limpiar código fuente de Asterisk (~500MB) — ya no se necesita post-instalación
    rm -rf "$ASTDIR" && \
    # Limpiar tarballs de terceros de /tmp
    rm -f /tmp/pjproject-*.tar.bz2 /tmp/jansson-*.tar.bz2

# ------------------------------------------------------------------------
# 9. Usuario y permisos de Asterisk
# ------------------------------------------------------------------------
RUN (id -u asterisk >/dev/null 2>&1 || (groupadd asterisk && useradd -r -d /var/lib/asterisk -g asterisk asterisk)) && \
    usermod -aG audio,dialout asterisk && \
    mkdir -p /var/run/asterisk && \
    chown -R asterisk:asterisk /etc/asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk /var/run/asterisk /usr/lib/asterisk

# ------------------------------------------------------------------------
# 10. Configuración de archivos de Asterisk
# ------------------------------------------------------------------------
RUN sed -i 's/^[#;]*AST_USER=.*/AST_USER="asterisk"/' /etc/default/asterisk && \
    sed -i 's/^[#;]*AST_GROUP=.*/AST_GROUP="asterisk"/' /etc/default/asterisk && \
    sed -i 's/^[#;]*runuser =.*/runuser = asterisk/' /etc/asterisk/asterisk.conf && \
    sed -i 's/^[#;]*rungroup =.*/rungroup = asterisk/' /etc/asterisk/asterisk.conf && \
    sed -i 's|;\[radius\]|\[radius\]|g' /etc/asterisk/cdr.conf && \
    sed -i 's|.*radiuscfg =>.*|radiuscfg => /etc/radcli/radiusclient.conf|g' /etc/asterisk/cdr.conf && \
    sed -i 's|.*radiuscfg =>.*|radiuscfg => /etc/radcli/radiusclient.conf|g' /etc/asterisk/cel.conf

# ------------------------------------------------------------------------
# 11. MariaDB + Apache + PHP + Node
# ------------------------------------------------------------------------
RUN apt-get update -y && apt-get install -y \
    mariadb-server apache2 php libapache2-mod-php php-intl php-mysql php-curl \
    php-cli php-zip php-xml php-gd php-common php-mbstring php-xmlrpc \
    php-bcmath php-json php-sqlite3 php-soap php-ldap php-imap php-cas \
    nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------
# 12. Instalación de FreePBX 17
#     IGUAL que el script:
#     - Levanta MariaDB y cron
#     - Lanza Asterisk en background antes del instalador
#     - Corre ./install -n (sin || true, para que falle si hay error real)
#     - Apaga Asterisk y MariaDB limpiamente
# ------------------------------------------------------------------------
WORKDIR /usr/src
RUN wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-17.0-latest.tgz && \
    tar -xvzf freepbx-17.0-latest.tgz && \
    rm freepbx-17.0-latest.tgz

RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld && \
    /usr/sbin/mariadbd --user=mysql & \
    MARIADB_PID=$! && \
    /usr/sbin/asterisk -U asterisk -G asterisk -f -C /etc/asterisk/asterisk.conf & \
    ASTERISK_PID=$! && \
    echo "[BUILD] Esperando a MariaDB..." && \
    for i in $(seq 1 30); do \
    mysqladmin ping --silent && echo "[BUILD] MariaDB está lista." && break; \
    sleep 1; \
    done && \
    echo "[BUILD] Esperando a Asterisk..." && \
    for i in $(seq 1 30); do \
    asterisk -rx "core show version" 2>/dev/null | grep -E -q "Asterisk [0-9]" && echo "[BUILD] Asterisk está listo." && break; \
    sleep 1; \
    done && \
    mysql -e "DROP DATABASE IF EXISTS asterisk;" || true && \
    mysql -e "DROP DATABASE IF EXISTS asteriskcdrdb;" || true && \
    cd /usr/src/freepbx && \
    ./install -n && \
    echo "[BUILD] FreePBX Install completado." && \
    (fwconsole ma install pm2 || true) && \
    echo "[BUILD] Apagando servicios..." && \
    (kill -15 $ASTERISK_PID || true) && \
    (kill -15 $MARIADB_PID || true) && \
    sleep 3

# NOTA: NO borramos /usr/src/freepbx — queda disponible para reinstalar manualmente:
#   docker exec -it freepbx-custom bash -c "cd /usr/src/freepbx && ./install -n"
RUN rm -f /usr/src/freepbx-17.0-latest.tgz


# ------------------------------------------------------------------------
# 13. Apache y PHP
# ------------------------------------------------------------------------
RUN sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf && \
    sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf && \
    for ini in $(find /etc/php -name php.ini); do \
    sed -i 's/\(^upload_max_filesize = \).*/\120M/' "$ini"; \
    done && \
    a2enmod rewrite

# ------------------------------------------------------------------------
# 14. Supervisord
# ------------------------------------------------------------------------
COPY supervisord.conf /etc/supervisor/conf.d/freepbx.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ------------------------------------------------------------------------
# Puertos expuestos
# ------------------------------------------------------------------------
EXPOSE 80 443 5060/udp 5060/tcp 5061/tcp 10000-20000/udp

# Volúmenes con los datos que deben persistir
VOLUME ["/etc/asterisk", "/var/lib/asterisk", "/var/spool/asterisk", "/var/lib/mysql", "/var/www/html"]

ENTRYPOINT ["/entrypoint.sh"]
