#!/bin/bash
# Archivo de log
LOGFILE="/var/log/Project/jellyfin_installation.log"
IP_LOCAL=$(hostname -I | awk '{print $1}')
DIR_PROJECT="/etc/jellyfin-caddy"

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

create_docker_compose() {
    # ==== docker-compose.yml ====
    log_info "Creando archivo docker-compose.yml para entorno local"
    cat > docker-compose.yml <<'EOF'
version: '3.8'
services:
  jellyfin:
    image: jellyfin/jellyfin
    container_name: jellyfin
    volumes:
      - ./jellyfin_config:/config
      - ./media:/media
    ports:
      - "8096:8096"    # Puerto web HTTP
      - "8920:8920"    # Puerto HTTPS opcional
    restart: unless-stopped
    environment:
      - JELLYFIN_PublishedServerUrl=http://localhost:8096  # Ajusta esto a tu IP local si es necesario
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
create_docker_compose

# Crear carpetas de configuración
log_info "Creando carpetas de configuración de Jellyfin"
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
log_info "Levantando Jellyfin..."
docker-compose up -d || docker compose up -d

# Verificar que los contenedores estén en ejecución
sleep 5
if docker ps | grep -q "jellyfin"; then
    log_info "✅ La instalación ha finalizado. Accede a Jellyfin en: http://$IP_LOCAL:8096"
    log_info "También puedes acceder usando: http://localhost:8096"
else
    log_error "❌ Hubo un problema al iniciar el contenedor. Revisa los logs con: docker logs jellyfin"
fi

# Mostrar los logs de Jellyfin para depuración
log_info "Mostrando los logs de Jellyfin para verificar la configuración:"
docker logs jellyfin