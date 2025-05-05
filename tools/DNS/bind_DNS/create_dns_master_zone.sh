#!/bin/bash

DOMAIN=$1
USER=$2
ZONE_FILE="/etc/bind/$DOMAIN"

# Configuración de la zona DNS

log_error() {
    # Registrar el error en el archivo de log
    echo "$(date) - ERROR: $1" | tee -a $LOGFILE
    # Mostrar el error en la terminal en rojo
    echo -e "\033[31m$(date) - ERROR: $1\033[0m"
    # Detener la ejecución del script
    exit 1
}

# Creamos el archivo de zona para '$DOMAIN'
echo -e "\033[34mCreando el archivo de zona DNS\033[0m"

# Comprobamos si ya existe el archivo de zona
if [ -f $ZONE_FILE ]; then
    log_error "El archivo de zona '$ZONE_FILE' ya existe. Por favor, elimina el archivo o revisa permisos."
fi

# Mejora, que cree a partir de un excel

if ! python3 ./tools/DNS/bind_DNS/create_zone_file.py $DOMAIN $USER; then
    log_error "Error crear archivo de zona con python"
fi

if [ $? -ne 0 ]; then
    log_error "Error al crear el archivo de zona "
fi

# Configuración de BIND para que reconozca la nueva zona

# Configuración en 'named.conf.local'
echo -e "\033[34mConfigurando el archivo de zonas en named.conf.local...\033[0m"

if ! sudo bash -c "cat <<EOF > /etc/bind/named.conf.local
zone \"$DOMAIN.\" {
    type master;
    file \"/etc/bind/$DOMAIN\";
};
EOF"; then
    log_error "Error al configurar la zona en '/etc/bind/named.conf.local'."
fi

# Configuración de BIND (named.conf.options)
echo -e "\033[34mConfigurando las opciones de BIND...\033[0m"
cat <<EOF | sudo tee /etc/bind/named.conf.options > /dev/null
options {
    directory "/var/cache/bind";

    forwarders {
        1.1.1.1;
        8.8.8.8;
    };

    dnssec-validation auto;
    listen-on { any; };
    listen-on-v6 { any; };
    allow-query { any; };
};
EOF

if [ $? -ne 0 ]; then
    log_error "Error al crear el archivo de opciones de BIND '/etc/bind/named.conf.options'."
fi

# Verificamos si el servicio BIND está corriendo, si no lo está, lo iniciamos
echo -e "\033[34mVerificando si BIND está activo...\033[0m"
if ! sudo systemctl is-active --quiet bind9; then
    echo -e "\033[34mIniciando el servicio BIND...\033[0m"
    if ! sudo systemctl start bind9; then
        log_error "No se pudo iniciar BIND DNS."
    fi
else
    echo -e "\033[32mBIND ya está activo.\033[0m"
fi

# Recargamos BIND para que cargue la nueva configuración
echo -e "\033[34mRecargando BIND...\033[0m"
if ! sudo systemctl reload bind9; then
    log_error "Error al recargar BIND después de añadir la zona."
fi

# Comprobamos si la zona está configurada correctamente
echo -e "\033[34mVerificando la zona DNS...\033[0m"
if ! sudo named-checkzone $DOMAIN /etc/bind/$DOMAIN; then
    log_error "Error al comprobar la zona DNS con 'named-checkzone'."
fi

# Habilitamos el firewall para permitir tráfico en el puerto 53 (DNS)
echo -e "\033[34mConfigurando el firewall para permitir tráfico DNS...\033[0m"
if ! sudo ufw allow 53/tcp && sudo ufw allow 53/udp; then
    log_error "Error al permitir el tráfico DNS en el firewall."
fi

# Activamos y recargamos el firewall
echo -e "\033[34mHabilitando y recargando el firewall...\033[0m"
if ! sudo ufw enable; then
    log_error "Error al habilitar el firewall."
fi

if ! sudo ufw reload; then
    log_error "Error al recargar el firewall."
fi

# Verificamos el estado del firewall
echo -e "\033[34mVerificando el estado del firewall...\033[0m"
if ! sudo ufw status; then
    log_error "Error al verificar el estado del firewall."
fi

systemctl restart webmin

# Mensaje de éxito en verde
echo -e "\033[32mZona DNS creada correctamente.\033[0m"