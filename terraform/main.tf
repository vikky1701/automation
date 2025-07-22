terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"  # Ohio region
}

variable "docker_image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

# Security Group
resource "aws_security_group" "strapi_sg" {
  name_prefix = "strapi-sg-20250722075652927300000001"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "strapi" {
  ami           = "ami-0d1b5a8c13042c939"  # Ubuntu 24.04 LTS (us-east-2)
  instance_type = "t2.micro"
  
  key_name               = "my-strapi-key"  # CHANGE THIS to your .pem key name
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  
  user_data = templatefile("${path.module}/user_data.sh", {
  docker_image     = "vikky17/strapi-app:${var.docker_image_tag}"
  POSTGRES_DB      = var.POSTGRES_DB
  POSTGRES_USER    = var.POSTGRES_USER
  POSTGRES_PASSWORD = var.POSTGRES_PASSWORD
})

  tags = {
    Name = "Strapi-Server"
  }
}

output "ec2_public_ip" {
  value = aws_instance.strapi.public_ip
}