#!/bin/bash

# Enhanced logging and error handling
exec > >(tee /var/log/user_data.log | logger -t user_data -s 2>/dev/console) 2>&1
set -euxo pipefail

echo "=== User Data Script Started at $(date) ==="
echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"

# Update packages
echo "=== Updating packages ==="
apt-get update -y
apt-get upgrade -y

# Install Docker
echo "=== Installing Docker ==="
apt-get install -y docker.io

# Enable and start Docker
echo "=== Starting Docker service ==="
systemctl enable docker
systemctl start docker

# Verify Docker installation
echo "=== Verifying Docker installation ==="
docker --version
systemctl status docker --no-pager

# Install docker-compose
echo "=== Installing Docker Compose ==="
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verify docker-compose installation
echo "=== Verifying Docker Compose installation ==="
/usr/local/bin/docker-compose --version

# Add ubuntu user to docker group
echo "=== Adding ubuntu user to docker group ==="
usermod -aG docker ubuntu

# Create app directory
echo "=== Creating application directory ==="
mkdir -p /opt/strapi
cd /opt/strapi

# Write .env file
echo "=== Creating .env file ==="
cat > .env <<EOF
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB}
EOF

# Verify .env file was created
echo "=== Verifying .env file ==="
ls -la /opt/strapi/
cat /opt/strapi/.env

# Write docker-compose.yml
echo "=== Creating docker-compose.yml ==="
cat > docker-compose.yml <<EOF
version: '3.8'
services:
  postgres:
    image: postgres:15
    container_name: strapi_postgres
    restart: always
    environment:
      POSTGRES_USER: \${POSTGRES_USER}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
      POSTGRES_DB: \${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - strapi_network

  strapi:
    image: ${docker_image}
    container_name: strapi_app
    restart: always
    environment:
      DATABASE_CLIENT: postgres
      DATABASE_HOST: postgres
      DATABASE_PORT: 5432
      DATABASE_NAME: \${POSTGRES_DB}
      DATABASE_USERNAME: \${POSTGRES_USER}
      DATABASE_PASSWORD: \${POSTGRES_PASSWORD}
      NODE_ENV: production
      HOST: 0.0.0.0
      PORT: 1337
    ports:
      - "1337:1337"
    depends_on:
      - postgres
    volumes:
      - strapi_data:/opt/app/public/uploads
    networks:
      - strapi_network

volumes:
  postgres_data:
  strapi_data:

networks:
  strapi_network:
    driver: bridge
EOF

# Verify docker-compose.yml was created
echo "=== Verifying docker-compose.yml ==="
ls -la /opt/strapi/
cat /opt/strapi/docker-compose.yml

# Set proper ownership
echo "=== Setting proper ownership ==="
chown -R ubuntu:ubuntu /opt/strapi

# Pull and run Docker Compose
echo "=== Pulling Docker images ==="
/usr/local/bin/docker-compose pull

echo "=== Starting containers ==="
/usr/local/bin/docker-compose up -d

# Wait a bit for containers to start
sleep 15

# Verify containers are running
echo "=== Verifying containers ==="
/usr/local/bin/docker-compose ps
docker ps -a

echo "=== User Data Script Completed at $(date) ==="