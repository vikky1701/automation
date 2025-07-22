#!/bin/bash

exec > >(tee /var/log/user_data.log | logger -t user_data -s 2>/dev/console) 2>&1
set -euxo pipefail

echo "=== User Data Script Started at $(date) ==="
echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"

# Update packages
apt-get update -y
apt-get upgrade -y

# Install Docker
apt-get install -y docker.io

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Create app directory
mkdir -p /opt/strapi
cd /opt/strapi

# Create .env file
cat > .env <<EOF
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB}
EOF

# Create docker-compose.yml
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

# Set proper permissions
chown -R ubuntu:ubuntu /opt/strapi

# Start containers
/usr/local/bin/docker-compose pull
/usr/local/bin/docker-compose up -d

# Wait and verify
sleep 15
/usr/local/bin/docker-compose ps
docker ps -a

echo "=== User Data Script Completed at $(date) ==="
