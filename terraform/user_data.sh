#!/bin/bash
yum update -y
yum install -y docker

# Start Docker service
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create directory for app
mkdir -p /opt/strapi
cd /opt/strapi

# Create docker-compose.yml for production
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: strapi_postgres
    restart: always
    env_file: .env
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - strapi_network

  strapi:
    image: ${docker_image}
    container_name: strapi_app
    restart: always
    env_file: .env
    environment:
      DATABASE_CLIENT: postgres
      DATABASE_HOST: postgres
      DATABASE_PORT: 5432
      DATABASE_NAME: ${POSTGRES_DB}
      DATABASE_USERNAME: ${POSTGRES_USER}
      DATABASE_PASSWORD: ${POSTGRES_PASSWORD}
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

# Create .env file
cat > .env << 'EOF'
POSTGRES_USER=strapiuser
POSTGRES_PASSWORD=strapipass
POSTGRES_DB=strapidb
EOF

# Pull and run containers
/usr/local/bin/docker-compose pull
/usr/local/bin/docker-compose up -d