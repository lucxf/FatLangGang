#!/bin/bash

# Archivo de log
LOGFILE="/var/log/Project/openfire_installation.log"
WORK_DIR="/home/root/openfire"

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

log_info "creando directorio de instalacion ..."

mkdir -p $WORK_DIR
cd $WORK_DIR

sudo apt update
sudo apt install default-jre-headless -y

log_info "Descargando el repositorio de openfire..."
if ! wget https://www.igniterealtime.org/downloadServlet?filename=openfire/openfire_4.7.5_all.deb -O openfire.deb; then
    log_error "Error al descargar el repositorio de openfire"
fi

log_info "Desempaqueando el paquete..."
if ! sudo dpkg -i openfire.deb ; then
    log_error "Error al desempaquetar el paquete de openfire"
fi

log_info "Instalando openfire..."
if ! sudo apt-get install -f; then
    log_error "Error al instalar openfire"
fi

