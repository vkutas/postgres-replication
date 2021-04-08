#!/bin/bash
# Clear data dir
rm -r ${PGDATA}/*
# Make base copy
rm -r "$PGDATA/*"
export PGPASSFILE=/var/lib/postgresql/.pgpass
echo "${PRIMARY_ADDR}:5432:replication:replicator:${REPLICATOR_PASS}" > /var/lib/postgresql/.pgpass
chown postgres:postgres /var/lib/postgresql/.pgpass
chmod 600 /var/lib/postgresql/.pgpass
pg_basebackup -h "$PRIMARY_ADDR" -p 5432 -U replicator -D "${PGDATA}/" -Fp -Xs -R



cat << FOE >> "$PGDATA/postgresql.conf"

cluster_name = async_standby_node
recovery_target_timeline = 'latest'
recovery_target_action = 'promote'
primary_conninfo = '"$PRIMARY_ADDR"  port=5432 user=replicator password="${REPLICATOR_PASS}" application_name=async_standby_node'
    
FOE

touch  "${PGDATA}/standby.signal"

# Reload configuration
psql -U postgres -c "SELECT pg_reload_conf();"
