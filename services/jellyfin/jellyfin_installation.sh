#!/bin/bash
# Archivo de log
LOGFILE="/var/log/Project/jellyfin_installation.log"
DOMAIN="jellyfin.fatlangang.com"
DIR_PROJECT="/etc/jellyfin-caddy"
EMAIL="fatlangang@proton.me"

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

jellyfin_installation() {
    # ==== .env ====
    log_info "Creando archivo .env"
    cat > .env <<EOF
DOMAIN=$DOMAIN
EMAIL=$EMAIL
EOF
}

create_caddyfile() {
    # ==== Caddyfile ====
    log_info "Creando archivo Caddyfile"
    # Importante: Se ha corregido la sintaxis del Caddyfile y se evita la expansión de variables
    cat > Caddyfile <<EOF
$DOMAIN {
    reverse_proxy jellyfin:8096
    encode gzip
    tls $EMAIL
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

# Verifica si existe el directorio
if [ -d "$DIR_PROJECT" ]; then
  log_info "El directorio $DIR_PROJECT ya existe"
  # Verifica si hay archivos
  if [ "$(ls -A $DIR_PROJECT)" ]; then
    log_info "Limpiando el directorio de trabajo"
    cd $DIR_PROJECT && rm -rf *
  else
    log_info "Directorio de trabajo vacío"
    cd $DIR_PROJECT || log_error "No se pudo acceder al directorio $DIR_PROJECT"
  fi
# Crea el directorio de trabajo
else
    log_info "Creando el directorio de trabajo"
    mkdir -p $DIR_PROJECT
    cd $DIR_PROJECT || log_error "No se pudo acceder al directorio $DIR_PROJECT"
fi

# Ejecutando las funciones para crear los archivos
jellyfin_installation
create_caddyfile
create_docker_compose

# Crear carpetas de configuración
log_info "Creando carpetas de configuración de Jellyfin y Caddy"
mkdir -p jellyfin_config media

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    log_error "Docker no está instalado. Por favor, instala Docker y vuelve a intentar."
fi

# Verificar Docker Compose (compatible con versiones más recientes)
if ! command -v docker-compose &> /dev/null && ! command -v docker compose &> /dev/null; then
    log_error "Docker Compose no está instalado. Por favor, instala Docker Compose y vuelve a intentar."
fi

# Detener contenedores existentes si están en ejecución
log_info "Deteniendo contenedores existentes si están en ejecución..."
docker-compose down 2>/dev/null || docker compose down 2>/dev/null || true

# Levantar los contenedores
log_info "Levantando Jellyfin y Caddy con Docker Compose..."
docker-compose up -d || docker compose up -d

# Verificar que los contenedores estén en ejecución
sleep 5
if docker ps | grep -q "jellyfin" && docker ps | grep -q "caddy"; then
    log_info "✅ La instalación ha finalizado. Accede a Jellyfin en: https://$DOMAIN"
else
    log_error "❌ Hubo un problema al iniciar los contenedores. Revisa los logs con: docker logs caddy"
fi

# Mostrar los logs de Caddy para depuración
log_info "Mostrando los logs de Caddy para verificar la configuración:"
docker logs caddy