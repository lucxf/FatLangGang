#!/bin/bash

# Archivo de log
LOGFILE="/var/log/Project/voip_installation.log"
SCRIPT_URL="https://github.com/FreePBX/sng_freepbx_debian_install/raw/master/sng_freepbx_debian_install.sh"
SCRIPT_PATH="/tmp/sng_freepbx_debian_install.sh"

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

# Función para verificar si FreePBX está instalado
is_installed_freepbx(){
    log_info "Iniciando verificación de si FreePBX está instalado..."

    # Verificar si FreePBX está instalado
    if [ -n "$(dpkg -l | grep freepbx | head -n 1)" ]; then
        log_info "FreePBX está instalado en el sistema 💪"
    else   
        log_info "FreePBX no está instalado en el sistema 🥹"
        log_info "Descargando script de instalación ⬇️"

        # Descargar el script de instalación
        wget $SCRIPT_URL -O $SCRIPT_PATH
        if [ $? -ne 0 ]; then
            log_error "No se pudo descargar el script de instalación. Verifica la conexión a internet o la URL."
        fi

        log_info "Ejecutando script de instalación 👀"
        
        # Ejecutar el script de instalación
        bash $SCRIPT_PATH
        if [ $? -eq 0 ]; then
            log_info "El script de instalación se ejecutó correctamente ✅"
        else
            log_error "El script de instalación falló ❌"
        fi
    fi
}

log_info "Iniciando el proceso de verificación de FreePBX..."
is_installed_freepbx
log_info "Proceso finalizado."
