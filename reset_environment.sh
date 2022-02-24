#!/bin/bash
# this script deletes the Docker containers, the images and rebuilds the environment
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi $(docker images -q)
docker build . -t cluster-base
docker-compose up -d

