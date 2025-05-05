#!/bin/bash

# Archivo de log
LOGFILE="/var/log/Project/mailcow_installation.log"

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

log_info "Comprobando si docker y docker-compose estan instalados..."
# Comprobar si docker y docker-compose están instalados
if ! command -v docker &> /dev/null && ! command -v docker-compose &> /dev/null; then
    ./tools/docker/docker_installation.sh
fi

# Instalar Mailcow
log_info "Clonando repositorio de Mailcow..."
if ! git clone https://github.com/mailcow/mailcow-dockerized; then
    log_error "Error al clonar el repositorio de Mailcow."
fi

if ! mv mailcow-dockerized /opt/; then
    log_error "Error al mover el repositorio de Mailcow."
fi

# Ejecutar el script de instalación de Mailcow
log_info "Ejecutando el script de instalación de Mailcow..."
if ! /opt/mailcow-dockerized/generate_config.sh; then
    log_error "Error al ejecutar el script de instalación de Mailcow."
fi

log_info "Iniciando Mailcow..."
if ! dokcer compose -f docker-compose.yml up -d; then
    log_error "Error al iniciar Mailcow."
fi

