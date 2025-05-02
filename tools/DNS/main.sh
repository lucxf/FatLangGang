#!/bin/bash

# Definir archivo de log
LOGFILE="/var/log/Project/installation.log"
BIND_FOLDER_PATH="/etc/bind/"
DOMAIN="fatlangang.com"
USER="lucxf"
# Función para registrar mensajes en el log y mostrar los errores en pantalla
log_error() {
    # Registrar el error en el archivo de log
    echo "$(date) - ERROR: $1" | tee -a $LOGFILE
    # Mostrar el error en la terminal en rojo
    echo -e "\033[31m$(date) - ERROR: $1\033[0m"

    exit 1
}

log_info() {
    # Registrar el mensaje informativo en el archivo de log
    echo "$(date) - INFO: $1" | tee -a $LOGFILE
    # Mostrar el mensaje en la terminal en azul
    echo -e "\033[34m$(date) - INFO: $1\033[0m"
}

# Comprobar si el usuario es root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[31mERROR: Este script debe ejecutarse como usuario root.\033[0m"
    exit 1
fi

# Comprobar si el directorio actual termina en FATLANGANG
# if [[ "$(pwd)" != *FatLanGang ]]; then
#     echo -e "\033[31mERROR: Este script debe ejecutarse desde un directorio que termine en 'FATLANGANG'.\033[0m"
#     exit 1
# fi

# Creamos los directorios necesarios
mkdir -p /var/log/Project

#!/bin/bash

# Verificar si Webmin está instalado
if dpkg -l | grep -q webmin; then
    echo "✅ Webmin está instalado en el sistema."
else
    echo "❌ Webmin NO está instalado en el sistema."
    # Empezamos la instalación de Webmin
    log_info "Instalando Webmin..."
    chmod +x ./tools/webmin/webmin_install.sh
    if ! sudo ./tools/webmin/webmin_install.sh; then
        log_error "Error al instalar Webmin."
        log_info "Borrando todo lo instalado..."
        chmod +x ./tools/webmin/uninstall_webmin/uninstall_webmin.sh
        sudo ./tools/webmin/uninstall_webmin/uninstall_webmin.sh
    fi
fi

# Creamos la zona de DNS
log_info "Instalando bind DNS..."
chmod +x ./tools/DNS/bind_DNS/bind_dns_install.sh
if ! sudo ./tools/DNS/bind_DNS/bind_dns_install.sh; then
    rm -r $BIND_FOLDER_PATH
    rm -r /var/cache/bind/
    apt purge bind9 bind9utils bind9-doc -y
    log_error "Error al instalar bind DNS."
fi

log_info "Creando la zona de DNS..."
chmod +x ./tools/DNS/bind_DNS/create_dns_master_zone.sh
if ! sudo ./tools/DNS/bind_DNS/create_dns_master_zone.sh $DOMAIN $USER; then
    rm -r $BIND_FOLDER_PATH
    rm -r /var/cache/bind/
    apt purge bind9 bind9utils bind9-doc -y
    log_error "Error al crear la zona de DNS."
fi
