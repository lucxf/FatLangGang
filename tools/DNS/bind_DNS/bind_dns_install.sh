#!/bin/bash

# Archivo de log
LOGFILE="/var/log/Project/bind_installation.log"

# Función para escribir errores en el log y mostrar el mensaje en rojo
log_error() {
    # Registrar el error en el archivo de log
    echo "$(date) - ERROR: $1" | tee -a $LOGFILE
    # Mostrar el error en la terminal en rojo
    echo -e "\033[31m$(date) - ERROR: $1\033[0m"
    sudo apt purge -y bind9 bind9utils bind9-doc
    # Detener la ejecución del script
    exit 1
}

# Crear el directorio de logs si no existe
mkdir -p /var/log/Project

# Comenzamos la instalación de BIND DNS
echo -e "\033[34mInstalando BIND DNS...\033[0m"
if ! sudo apt update -y && sudo apt upgrade -y; then
    log_error "Error al ejecutar 'apt update' o 'apt upgrade'."
fi

if ! sudo apt install -y bind9 bind9utils bind9-doc; then
    log_error "Error al instalar BIND DNS (bind9)."
fi

echo -e "\033[32mInstalación y configuración de BIND DNS completada con éxito.\033[0m"

# Fin del script
exit 0
