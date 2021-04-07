FROM postgres:12.6-alpine
ENV REPLICATOR_PASS=$V_REPLICATOR_PASS
ENV STAND_BY_ADDR=$V_STAND_BY_ADDR
COPY ./setup-primary.sh /docker-entrypoint-initdb.d/setup-db.sh