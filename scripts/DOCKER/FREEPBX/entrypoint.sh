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

exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/freepbx.conf
