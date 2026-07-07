# 🚀 Examen de Comunicaciones Unificadas (CCUU)

Este repositorio contiene los scripts de automatización, topologías de red, configuraciones de Docker y archivos de configuración del motor de señalización requeridos para el desarrollo y despliegue del examen de Comunicaciones Unificadas (CCUU).

El entorno de laboratorio despliega un **Kamailio SBC** como proxy SIP y balanceador con TLS/SRTP en la frontera (Internet), y un servidor **Asterisk + FreePBX** en la red interna para la gestión de extensiones y media.

---

## 📐 Arquitectura del Sistema

El flujo de señalización y media sigue el siguiente esquema lógico:
![Diagrama de Arquitectura](assets/architecture_diagram.png)

* **Tramo Externo (Seguro):** Cliente SIP (TLS:5061 + SRTP) ──> **Kamailio SBC**
* **Tramo Interno (Plano):** **Kamailio SBC** ──(UDP:5060 + RTP)──> **Asterisk PBX**

---

## 📂 Estructura del Repositorio

La estructura del repositorio se organiza por servicio y rol de la siguiente manera:

```text
/
├── kamailio/                             # Componentes del Session Border Controller (SBC)
│   ├── config/
│   │   └── kamailio-lab2.3.cfg           # Configuración unificada de Kamailio (SIP, TLS, RTPEngine)
│   └── scripts/
│       └── instalar_kamailio.sh          # Script de aprovisionamiento de Kamailio y RTPEngine
├── asterisk-freepbx/                     # Componentes de la Central Telefónica (PBX)
│   ├── scripts/
│   │   └── instalar_pbx.sh               # Script de instalación bare-metal (Asterisk 22 + FreePBX 17)
│   └── docker/                           # Despliegue alternativo mediante contenedores Docker
│       ├── Dockerfile                    # Receta de construcción de Asterisk/FreePBX en Ubuntu 24.04
│       ├── docker-compose.yml            # Orquestador del contenedor
│       ├── entrypoint.sh                 # Script de inicialización y permisos internos
│       ├── supervisord.conf              # Supervisor de procesos (MariaDB, Apache, Asterisk)
│       └── build_and_run.sh              # Script automatizado para compilar e iniciar Docker
├── assets/                               # Activos y recursos de documentación
│   └── architecture_diagram.png          # Diagrama visual de la arquitectura
├── LICENSE                               # Licencia del proyecto
└── README.md                             # Esta guía de uso y documentación general
```

### Enlaces Rápidos a Archivos Clave:
* [Configuración Kamailio SBC](file:///d:/Clone/examen-comunicaciones-unificadas/kamailio/config/kamailio-lab2.3.cfg)
* [Script Instalación Kamailio](file:///d:/Clone/examen-comunicaciones-unificadas/kamailio/scripts/instalar_kamailio.sh)
* [Script Instalación PBX Bare-Metal](file:///d:/Clone/examen-comunicaciones-unificadas/asterisk-freepbx/scripts/instalar_pbx.sh)
* [Dockerfile de FreePBX](file:///d:/Clone/examen-comunicaciones-unificadas/asterisk-freepbx/docker/Dockerfile)
* [Docker Compose de FreePBX](file:///d:/Clone/examen-comunicaciones-unificadas/asterisk-freepbx/docker/docker-compose.yml)

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

## 🚀 Guía de Despliegue rápido

### 1. Despliegue de Kamailio (Servidor SBC)
En el servidor designado como SBC (Ubuntu 24.04), ejecuta el script de instalación:
```bash
chmod +x kamailio/scripts/instalar_kamailio.sh
sudo ./kamailio/scripts/instalar_kamailio.sh
```
Una vez terminada la instalación básica, copia el archivo de configuración unificado [kamailio-lab2.3.cfg](file:///d:/Clone/examen-comunicaciones-unificadas/kamailio/config/kamailio-lab2.3.cfg) a `/etc/kamailio/kamailio.cfg` y edita las IPs locales y públicas según corresponda.

### 2. Despliegue de Asterisk + FreePBX (Servidor PBX)

#### Opción A: Despliegue Bare-Metal (Recomendado para servidores dedicados)
Ejecuta el script automatizado para compilar Asterisk y desplegar la interfaz de administración FreePBX:
```bash
chmod +x asterisk-freepbx/scripts/instalar_pbx.sh
sudo ./asterisk-freepbx/scripts/instalar_pbx.sh
```

#### Opción B: Despliegue Dockerizado (Rápido y portable)
Ingresa al directorio de Docker y ejecuta el script de aprovisionamiento automatizado:
```bash
cd asterisk-freepbx/docker
chmod +x build_and_run.sh
./build_and_run.sh
```

---

## 🛠️ Comandos de Verificación y Diagnóstico

### Validación de Kamailio
Antes de reiniciar el servicio SBC, valida siempre que no existan errores de sintaxis:
```bash
# Validar sintaxis del archivo kamailio.cfg
sudo kamailio -c

# Reiniciar servicios de Kamailio y RTPEngine
sudo systemctl restart kamailio rtpengine

# Monitorear tráfico SIP en tiempo real
sudo sngrep
```

### Verificación de Asterisk
```bash
# Ingresar al CLI interactivo de Asterisk
sudo asterisk -rvvv

# Mostrar peers PJSIP registrados
*CLI> pjsip show endpoints
```
