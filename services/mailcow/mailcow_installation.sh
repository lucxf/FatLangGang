#!/bin/bash

# Archivo de log
LOGFILE="/var/log/Project/mailcow_installation.log"
MAILCOW_CONF_DIR="/etc/mailcow-docker-config"

# Función para escribir errores en el log y mostrar el mensaje en rojo
log_error() {
    # Registrar el error en el archivo de log
    echo "$(date) - ERROR: $1" | tee -a $LOGFILE
    # Mostrar el error en la terminal en rojo
    echo -e "\033[31m$(date) - ERROR: $1\033[0m"
    # Detener la ejecución del script
    exit 1
}

log_info() {
    # Registrar el mensaje informativo en el archivo de log
    echo "$(date) - INFO: $1" | tee -a $LOGFILE
    # Mostrar el mensaje en la terminal en azul
    echo -e "\033[34m$(date) - INFO: $1\033[0m"
}

log_info "Comprobando usario..."
# Comprobar si el usuario es root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[31mERROR: Este script debe ejecutarse como usuario root.\033[0m"
    exit 1
fi

mkdir -p $MAILCOW_CONF_DIR

log_info "Comprobando si docker y docker-compose estan instalados..."
# Comprobar si docker y docker-compose están instalados
if ! docker --version &> /dev/null; then
    chmod +x ./tools/docker/docker_installation.sh
    ./tools/docker/docker_installation.sh
fi

log_info "Descargando el repositorio de mailcow..."
if ! git clone https://github.com/mailcow/mailcow-dockerized.git; then
    log_info "Error al descargar el repositorio de mailcow"
fi

mv mailcow-dockerized $MAILCOW_CONF_DIR

cd $MAILCOW_CONF_DIR 
log_info "DIRECTORIO ACTUAL"
pwd
cd mailcow-dockerized

log_info "generando archivo de configuracion..."
if ! ./generate_config.sh; then
    log_info "Error al generar el archivo de configuracion"
fi

cat <<EOF >> /etc/mailcow-docker-config/mailcow-dockerized/data/conf/unbound/unbound.conf
forward-zone:
  name: "."
  forward-addr: 172.31.9.254
  forward-addr: 172.31.9.255
EOF


log_info "Iniciando mailcow..."
if ! docker compose -f ./docker-compose.yml up -d; then
    log_info "Error al iniciar mailcow"
fi
