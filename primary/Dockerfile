FROM postgres:12.6-alpine
COPY ./setup-primary.sh /docker-entrypoint-initdb.d/setup-primary.sh
COPY ./setup-db.sh /docker-entrypoint-initdb.d/setup-db.sh

WORKDIR /tables/
COPY actors.tar.gz .
COPY basics.tar.gz .