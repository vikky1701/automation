terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "docker_image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

# Security Group
resource "aws_security_group" "strapi_sg" {
  name_prefix = "strapi-sg-"

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

# Key Pair (Corrected path)
resource "aws_key_pair" "strapi_key" {
  key_name   = "strapi-key"
  public_key = file("~/.ssh/strapi-key.pub")
}

# EC2 Instance
resource "aws_instance" "strapi" {
  ami           = "ami-0c94855ba95b798c7" # Amazon Linux 2 (change if needed)
  instance_type = "t2.micro"

  key_name               = aws_key_pair.strapi_key.key_name
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]

  user_data = templatefile("${path.module}/user_data.sh", {
    docker_image = "vikky17/strapi-app:${var.docker_image_tag}"
  })

  tags = {
    Name = "Strapi-Server"
  }
}

# Output EC2 Public IP
output "ec2_public_ip" {
  value = aws_instance.strapi.public_ip
}
