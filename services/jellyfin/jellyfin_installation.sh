#!/bin/bash

DOMAIN="jellyfin.fatlangang.com"
BASE_DIR="/opt/jellyfin"
CONFIG_DIR="${BASE_DIR}/config"
MEDIA_DIR="${BASE_DIR}/media"
CERT_DIR="/etc/nginx/ssl/$DOMAIN"

# Verificar permisos
if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] Este script debe ejecutarse como root."
  exit 1
fi

echo "[INFO] Preparando entorno para Jellyfin + Nginx + HTTPS..."

# Añadir a /etc/hosts si no está
if ! grep -q "$DOMAIN" /etc/hosts; then
  echo "127.0.0.1 $DOMAIN" >> /etc/hosts
  echo "[INFO] Añadido $DOMAIN a /etc/hosts"
fi

# Instalar dependencias
apt update && apt install -y nginx openssl docker.io docker-compose

# Crear carpetas
mkdir -p "$CONFIG_DIR/jellyfin" "$MEDIA_DIR" "$CERT_DIR"

# Crear certificados autofirmados
if [[ ! -f "$CERT_DIR/cert.pem" ]]; then
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$CERT_DIR/key.pem" \
    -out "$CERT_DIR/cert.pem" \
    -subj "/CN=$DOMAIN"
  echo "[INFO] Certificado autofirmado generado en $CERT_DIR"
fi

# Crear docker-compose.yml
cat > "$BASE_DIR/docker-compose.yml" <<EOF
version: '3.8'

services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    ports:
      - "8096:8096"
    volumes:
      - $CONFIG_DIR/jellyfin:/config
      - $MEDIA_DIR:/media
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped
EOF

# Levantar Jellyfin
cd "$BASE_DIR"
docker compose up -d

# Configurar Nginx
NGINX_CONF="/etc/nginx/sites-available/jellyfin"
cat > "$NGINX_CONF" <<EOF
server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate     $CERT_DIR/cert.pem;
    ssl_certificate_key $CERT_DIR/key.pem;

    location / {
        proxy_pass http://localhost:8096;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}
EOF

# Activar configuración
ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/jellyfin
nginx -t && systemctl restart nginx

echo "[OK] Jellyfin está disponible en: https://$DOMAIN"
echo "[NOTA] El certificado es autofirmado. Acepta el aviso del navegador para continuar."
