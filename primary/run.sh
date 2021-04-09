#!/bin/bash
docker stop primary;
docker rm primary;
docker volume rm primary;

if [ $1 == 'sync' ]; then
    docker run --name primary --env-file .env -e SYNC_REPLICATION_ON=1 -v primary:/var/lib/postgresql/data -d primary:latest; 
else
    docker run --name primary --env-file .env -v primary:/var/lib/postgresql/data -d primary:latest; 
fi    