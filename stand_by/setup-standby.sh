#!/bin/bash
# Clear data dir
rm -r ${PGDATA}/*
# Make base copy
pg_basebackup -h "$PRIMARY_ADDR" -p 5432 -U replicator -D "${PGDATA}/" -Fp -Xs -R
# Reload configuration

cat << FOE >> "$PGDATA/postgresql.conf"

cluster_name = async_standby_node
recovery_target_timeline = 'latest'
recovery_target_action = 'promote'
primary_conninfo = 'host=172.17.0.2  port=5432 user=replicator password="${REPLICATOR_PASS}" application_name=async_standby_node'
    
FOE

psql -U postgres -c "SELECT pg_reload_conf();"