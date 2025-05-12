#!/bin/bash

# Configuración básica
PROJECT_NAME="jellyfin-local"
BASE_DIR="/opt/${PROJECT_NAME}"
CONFIG_DIR="${BASE_DIR}/config"
MEDIA_DIR="${BASE_DIR}/media"

# Colores para la salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# Función de registro de errores
log_error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

# Función de registro de información
log_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

# Función de registro de advertencia
log_warning() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

# Verificar si el script se ejecuta con privilegios de sudo
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
       log_error "Este script debe ejecutarse con sudo" 
       exit 1
    fi
}

# Preparar directorios
prepare_directories() {
    log_info "Preparando directorios de configuración y medios"
    mkdir -p "${CONFIG_DIR}/jellyfin"
    mkdir -p "${CONFIG_DIR}/caddy"
    mkdir -p "${MEDIA_DIR}"
    
    # Establecer permisos
    chown -R 1000:1000 "${CONFIG_DIR}/jellyfin"
    chown -R 1000:1000 "${MEDIA_DIR}"
}

# Crear Docker Compose
create_docker_compose() {
    log_info "Creando archivo docker-compose.yml"
    cat > "${BASE_DIR}/docker-compose.yml" <<'EOF'
version: '3.8'
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    user: 1000:1000
    network_mode: host
    volumes:
      - ${CONFIG_DIR}/jellyfin:/config
      - ${MEDIA_DIR}:/media
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped
    environment:
      - JELLYFIN_PublishedServerUrl=http://localhost:8096

  caddy:
    image: caddy:latest
    container_name: caddy
    ports:
      - 80:80
      - 443:443
    volumes:
      - ${CONFIG_DIR}/caddy/Caddyfile:/etc/caddy/Caddyfile
      - ${CONFIG_DIR}/caddy/data:/data
      - ${CONFIG_DIR}/caddy/config:/config
    restart: unless-stopped
EOF
}

# Crear Caddyfile
create_caddyfile() {
    log_info "Creando Caddyfile"
    cat > "${CONFIG_DIR}/caddy/Caddyfile" <<'EOF'
{
    # Usar un certificado autofirmado interno para desarrollo
    local_certs
}

# Proxy inverso para Jellyfin
localhost:443 {
    reverse_proxy localhost:8096
    tls internal
}

:80 {
    redir https://{host}{uri} permanent
}
EOF
}

# Instalar Docker y Docker Compose si no están instalados
install_docker() {
    log_info "Verificando e instalando Docker y Docker Compose"
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        log_warning "Docker no está instalado. Iniciando instalación..."
        
        # Desinstalar versiones antiguas
        apt-get remove -y docker docker-engine docker.io containerd runc
        
        # Preparar repositorio
        apt-get update
        apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release

        # Añadir clave GPG oficial de Docker
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        # Configurar repositorio
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Instalar Docker Engine
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    fi

    # Verificar Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_warning "Docker Compose no está instalado. Instalando..."
        curl -SL https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi

    # Habilitar Docker al inicio
    systemctl enable docker
}

# Iniciar servicios
start_services() {
    log_info "Iniciando servicios de Jellyfin y Caddy"
    cd "${BASE_DIR}"
    docker-compose up -d
}

# Función principal
main() {
    # Verificar sudo
    check_sudo

    # Limpiar pantalla
    clear

    log_info "===== Instalación de Jellyfin Local ====="
    
    # Instalar Docker
    install_docker

    # Preparar directorios
    prepare_directories

    # Crear configuraciones
    create_docker_compose
    create_caddyfile

    # Iniciar servicios
    start_services

    # Mensaje final
    log_info "Instalación completada. Accede a Jellyfin en:"
    log_info "- http://localhost:8096"
    log_info "- https://localhost (con certificado autofirmado)"
}

# Ejecutar script principal
main