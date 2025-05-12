#!/bin/bash
# Archivo de log
LOGFILE="/var/log/Project/jellyfin_installation.log"
DOMAIN="jellyfin.local"
DIR_PROJECT="/etc/jellyfin-caddy"
EMAIL="admin@localhost"

# Función para escribir errores en el log y mostrar el mensaje en rojo
log_error() {
    echo "$(date) - ERROR: $1" | tee -a $LOGFILE
    echo -e "\033[31m$(date) - ERROR: $1\033[0m"
    exit 1
}

log_info() {
    echo "$(date) - INFO: $1" | tee -a $LOGFILE
    echo -e "\033[34m$(date) - INFO: $1\033[0m"
}

jellyfin_installation() {
    # ==== .env ====
    log_info "Creando archivo .env"
    cat > .env <<EOF
DOMAIN=$DOMAIN
EMAIL=$EMAIL
EOF
}

create_caddyfile() {
    # ==== Caddyfile para entorno local ====
    log_info "Creando archivo Caddyfile para entorno local"
    cat > Caddyfile <<EOF
$DOMAIN {
    # Proxy a Jellyfin
    reverse_proxy jellyfin:8096
    
    # Deshabilitar HTTPS para entorno local
    @local host $DOMAIN
    
    # Configuración para desarrollo local
    tls internal
}
EOF
}

create_docker_compose() {
    # ==== docker-compose.yml ====
    log_info "Creando archivo docker-compose.yml"
    cat > docker-compose.yml <<'EOF'
version: '3.8'
services:
  jellyfin:
    image: jellyfin/jellyfin
    container_name: jellyfin
    volumes:
      - ./jellyfin_config:/config
      - ./media:/media
    expose:
      - "8096"
    networks:
      - caddy_net
    restart: unless-stopped

  caddy:
    image: caddy:latest
    container_name: caddy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - jellyfin
    networks:
      - caddy_net
    restart: unless-stopped

volumes:
  caddy_data:
  caddy_config:

networks:
  caddy_net:
    driver: bridge
EOF
}

# Configuración del archivo hosts local
configure_hosts() {
    log_info "Configurando entrada en /etc/hosts"
    if ! grep -q "$DOMAIN" /etc/hosts; then
        echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts
    fi
}

# Verificaciones y preparación
prepare_environment() {
    # Verifica si existe el directorio
    if [ -d "$DIR_PROJECT" ]; then
        log_info "El directorio $DIR_PROJECT ya existe"
        if [ "$(ls -A $DIR_PROJECT)" ]; then
            log_info "Limpiando el directorio de trabajo"
            cd $DIR_PROJECT && rm -rf *
        fi
    else
        log_info "Creando el directorio de trabajo"
        sudo mkdir -p $DIR_PROJECT
    fi

    cd $DIR_PROJECT || log_error "No se pudo acceder al directorio $DIR_PROJECT"
}

# Pasos principales
main() {
    # Preparar el entorno
    prepare_environment

    # Crear archivos de configuración
    jellyfin_installation
    create_caddyfile
    create_docker_compose

    # Crear carpetas de configuración
    log_info "Creando carpetas de configuración de Jellyfin y Caddy"
    mkdir -p jellyfin_config media

    # Configurar hosts local
    configure_hosts

    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker no está instalado. Por favor, instala Docker y vuelve a intentar."
    fi

    # Verificar Docker Compose
    if ! command -v docker-compose &> /dev/null && ! command -v docker compose &> /dev/null; then
        log_error "Docker Compose no está instalado. Por favor, instala Docker Compose y vuelve a intentar."
    fi

    # Detener contenedores existentes
    log_info "Deteniendo contenedores existentes si están en ejecución..."
    docker-compose down 2>/dev/null || docker compose down 2>/dev/null || true

    # Levantar los contenedores
    log_info "Levantando Jellyfin y Caddy con Docker Compose..."
    docker-compose up -d || docker compose up -d

    # Verificar contenedores
    sleep 5
    if docker ps | grep -q "jellyfin" && docker ps | grep -q "caddy"; then
        log_info "✅ La instalación ha finalizado. Accede a Jellyfin en: https://$DOMAIN"
        log_info "Recuerda añadir $DOMAIN al archivo /etc/hosts si no lo has hecho"
    else
        log_error "❌ Hubo un problema al iniciar los contenedores. Revisa los logs con: docker logs caddy"
    fi

    # Mostrar logs de Caddy
    log_info "Mostrando los logs de Caddy para verificación:"
    docker logs caddy
}

# Ejecutar el script principal
main