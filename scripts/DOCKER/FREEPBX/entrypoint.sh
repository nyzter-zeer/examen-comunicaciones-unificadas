#!/bin/bash
set -e

mkdir -p /var/log/supervisor
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

# Si el volumen de /etc/asterisk vino vacío (primera vez con bind-mount
# en vez de volumen nombrado), avisamos en vez de arrancar roto.
if [ -z "$(ls -A /etc/asterisk 2>/dev/null)" ]; then
    echo "[ENTRYPOINT] AVISO: /etc/asterisk está vacío. Si estás usando" >&2
    echo "[ENTRYPOINT] bind-mounts en vez de volúmenes nombrados de Docker," >&2
    echo "[ENTRYPOINT] la configuración horneada en la imagen no se copió." >&2
    echo "[ENTRYPOINT] Usa 'docker volume' en vez de una carpeta vacía del host," >&2
    echo "[ENTRYPOINT] o copia manualmente la config antes del primer arranque." >&2
fi

chown -R asterisk:asterisk /etc/asterisk /var/lib/asterisk /var/spool/asterisk /var/log/asterisk /var/run/asterisk 2>/dev/null || true

# Apache corre como usuario 'asterisk' (ver Dockerfile), asegurar que pueda
# leer/escribir el webroot de FreePBX, sobre todo la primera vez que el
# volumen nombrado 'freepbx-web' se crea vacío y se llena desde la imagen.
chown -R asterisk:asterisk /var/www/html 2>/dev/null || true

# Aviso si /var/www/html quedó vacío o solo con el index.html por defecto de
# Apache: significa que la instalación de FreePBX nunca terminó de copiar
# los archivos web (por ejemplo si el instalador abortó por falta de cron).
if [ ! -f /var/www/html/admin/config.php ] && [ ! -f /etc/freepbx.conf ]; then
    echo "[ENTRYPOINT] AVISO: no se detecta una instalación de FreePBX completa" >&2
    echo "[ENTRYPOINT] (falta /etc/freepbx.conf o /var/www/html/admin/config.php)." >&2
    echo "[ENTRYPOINT] El panel web probablemente devuelva 404. Podés reinstalar" >&2
    echo "[ENTRYPOINT] manualmente con: docker exec -it <contenedor> bash -c" >&2
    echo "[ENTRYPOINT]   'cd /usr/src/freepbx && ./install -n'" >&2
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/freepbx.conf
