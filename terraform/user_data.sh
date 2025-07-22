#!/bin/bash
set -euxo pipefail
exec > >(tee /var/log/user_data.log | logger -t user_data -s 2>/dev/console) 2>&1

# Install Docker
yum update -y
yum install -y docker

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group (optional)
usermod -aG docker ec2-user

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create app directory
mkdir -p /opt/strapi
cd /opt/strapi

# Write .env file (editable via Terraform variables if templated)
cat > .env <<EOF
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB}
EOF

# Write docker-compose.yml with environment variables expanded
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: strapi_postgres
    restart: always
    env_file: .env
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - strapi_network

  strapi:
    image: ${docker_image}
    container_name: strapi_app
    restart: always
    env_file: .env
    ports:
      - "1337:1337"
    depends_on:
      - postgres
    volumes:
      - ./strapi:/app
    networks:
      - strapi_network

volumes:
  postgres_data:

networks:
  strapi_network:
EOF

# Pull and run the containers
/usr/local/bin/docker-compose pull
/usr/local/bin/docker-compose up -d
