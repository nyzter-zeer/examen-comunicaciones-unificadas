# examen-comunicaciones-unificadas
Scripts, topologías y configuraciones para el examen de CCUU

## Comandos de Verificación en el Examen

### Validar y reiniciar servicios
```bash
# Comprobar sintaxis de Kamailio sin romper producción
sudo kamailio -c

# Reinicios limpios
sudo systemctl restart kamailio rtpengine

# Ver logs de telefonía e hilos de conversión en tiempo real
sudo tail -f /var/log/syslog | grep -E 'kamailio|rtpengine'

#Captura de tráfico SIP/RTP (Troubleshooting)
sudo tcpdump -i any -n 'port 5060 or port 5061 or portrange 10000-20000' -w /tmp/nat-test.pcap
