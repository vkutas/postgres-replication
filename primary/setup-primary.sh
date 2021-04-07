#!/usr/bin/env bash

# Wait until Postgres will be ready to accept connections 
# and then create the role to connect from s stand by server
while :; do
   pg_ready=$(pg_isready -U postgres)
   if [ "$pg_ready" -eq 0 ]; then
     psql -U postgres -c "CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD '${REPLICATOR_PASS}';"
	 break
   fi
done

echo "host replication replicator ${STAND_BY_ADDR} md5" >> "$PGDATA/pg_hba.conf"

cat << FOE >> /var/lib/postgres/data/postgresql.conf

cat timezone = 'UTC'
log_timezone = 'UTC'
log_statement = 'all'
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
logging_collector = on
log_min_error_statement = error
log_min_duration_statement = 0
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0
log_autovacuum_min_duration = 0
log_error_verbosity = default

# Sync Replica Cluster Name
synchronous_standby_names = sync_standby_node   
synchronous_commit = on      
FOE

psql -U postgres -c "SELECT pg_reload_conf();"