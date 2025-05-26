# Fatlangang

Bienvenido al repositorio oficial de **Fatlangang**. Este repositorio contiene los scripts necesarios para instalar y configurar las herramientas y servicios que ofrecemos como parte de nuestras soluciones tecnológicas.

---

## 📁 Estructura del Repositorio

```bash
.
├── tools/
└── services/
```

🛠️ `tools/`

Esta carpeta contiene scripts de instalación y configuración de herramientas base necesarias para el entorno de servicios. Incluye:

    Docker: Instalación y configuración del motor Docker.

    Webmin: Instalación del panel de administración Webmin.

    BIND DNS: Scripts para la instalación y configuración del servidor DNS BIND.

Estos componentes son fundamentales para gestionar el entorno y facilitar la operación de los servicios que ofrece la empresa. Cada script en esta carpeta automatiza su respectiva instalación, con el objetivo de agilizar despliegues y mantener configuraciones consistentes.

💼 `services/`

Esta carpeta contiene los scripts de instalación de los principales servicios que ofrece Fatlangang:

· **Jellyfin**: Servidor multimedia para streaming local.

· **Openfire**: Servidor de mensajería instantánea basado en XMPP.

· **Mailcow**: Solución completa de servidor de correo electrónico, ideal para empresas.

· **FreePBX**: Plataforma de comunicaciones unificadas y VoIP basada en Asterisk, para centralitas telefónicas.

Cada script en esta carpeta está diseñado para simplificar la instalación de estos servicios, incluyendo dependencias, configuración base y puesta en marcha inicial.

## 📌 Requisitos

Antes de ejecutar cualquier script, asegúrate de contar con lo siguiente:

    Sistema operativo basado en Linux (preferiblemente Debian o Ubuntu).

    Acceso con privilegios de superusuario (root o sudo).

    Conexión a Internet activa para la descarga de paquetes y dependencias.

    Dependencias básicas: curl, wget, bash.

## 🚀 Uso

1. Clona el repositorio:

```bash
git clone https://github.com/lucxf/fatlangang.git
cd fatlangang
```

2. Accede a la carpeta según lo que necesites instalar:

>😁 Ejecutar como usario `root` no funciona en caso de no ser asi

2.1. Herramientas base (`tools/`):
```bash
./tools/DNS/main.sh                   # Para crear tu zona maestra de DNS, antes editar el archivo ./tools/DNS/registry.csv
./tools/docker/docker_installation.sh # Para instalar docker
./tools/webmin/webmin_install.sh      # Para instalar webmin
```

2.2. Servicios ofrecidos (`services/`):

>❗Los scripts de instalación ya instalan las dependencias en caso de no estar instaladas

```bash
./services/freepbx/freepbx_installation.sh   # Para instalar el servico de voz IP
./services/jellyfin/jellyfin_installation.sh # Para instalar jellyfin
./services/mailcow/mailcow_installation.sh   # Para instalar el servidor de correo mailcow
./services/openfire/openfire_installation.sh # Para instalar openfire
```

>⚠️ Instalar freepbx en maquina debian

>📖 Nota: Asegúrate de revisar cada script antes de ejecutarlo, y adapta las configuraciones a tus necesidades específicas si es necesario.
