#!/bin/bash
docker kill standby;
docker rm standby;
docker volume rm standby;
docker run -d --name standby --env-file .env -v standby:/var/lib/postgresql/data standby:latest; 