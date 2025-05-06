#!/bin/bash

IMAGE_NAME=$1
MYSQL_ROOT_PASSWORD=$2
DB_USER=$3
DB_PWD=$4

sudo yum update -y && sudo yum install -y docker
sudo systemctl start docker
sudo usermode -aG docker ec2-user

# Dowload docker compose
curl -SL "https://github.com/docker/compose/releases/download/v2.35.0/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose
