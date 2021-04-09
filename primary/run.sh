
docker stop primary;
docker rm primary;
docker volume rm primary;
docker run --name primary --env-file .env -v primary:/var/lib/postgresql/data -d primary:latest; 