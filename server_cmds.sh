#!/bin/bash

IMAGE_NAME=$1
MYSQL_ROOT_PASSWORD=$2
DB_USER=$3
DB_PWD=$4
ECR_USER=$5
ECR_PASSWORD=$6
ECR_URL=$7

echo "${ECR_PASSWORD}" | docker login --username ${ECR_USER} --password-stdin ${ECR_URL}

docker-compose -f docker-compose.yaml up --detach

echo "success"