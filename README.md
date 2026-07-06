# 🚀 Examen de Comunicaciones Unificadas (CCUU)

Este repositorio contiene los scripts, topologías de red y archivos de configuración requeridos para el desarrollo y despliegue del examen de Comunicaciones Unificadas.

---

## 🌐 Herramientas y Plataformas Utilizadas

| Plataforma / Servicio | Propósito / Enlace |
| :--- | :--- |
| **Google AI Studio** | 🔗 [Prototipado e Inteligencia Artificial](https://aistudio.google.com/) |
| **Slack App Management** | 🔗 [Configuración y API de Aplicaciones](https://api.slack.com/apps) |
| **Slack Workspace** | 🔗 [Entorno de Trabajo e Integración](https://app.slack.com/) |
| **OpenRouter** | 🔗 [Acceso unificado a Modelos de Lenguaje](https://openrouter.ai) |
| **DuckDNS** | 🔗 [Servicio de DNS Dinámico (DDNS)](https://www.duckdns.org/) |

---

## 🛠️ Comandos Esenciales de Verificación y Diagnóstico

Usa estos comandos en la consola del servidor para validar configuraciones, gestionar servicios y resolver problemas de conectividad durante el examen.

### 1. Validación de Sintaxis y Gestión de Servicios
Antes de reiniciar cualquier servicio en producción, asegúrate de validar que no existan errores de sintaxis en los archivos de configuración.

```bash
# Validar la sintaxis de Kamailio antes de aplicar cambios
sudo kamailio -c

# Reiniciar los servicios de señalización y manejo de medios de forma segura
sudo systemctl restart kamailio rtpengine
