#!/bin/bash

# Create DB for tests
docker exec primary /bin/bash -c "echo \"SELECT 'CREATE DATABASE play' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'play')\gexec\" | psql -U postgres"

docker exec primary psql -U postgres -d play -c "

CREATE TABLE IF NOT EXISTS dates_series (
   id serial PRIMARY KEY,
   date timestamp,
   value int
);
"
echo "Replication mode: async"
echo "############################"

echo "Rough replication lag: "

for ((i=0;i<30;i++)); do

   query=$(docker exec primary psql -U postgres -d play -c "
      EXPLAIN ANALYZE INSERT INTO dates_series(date, value)
      SELECT generate_series('2008-03-01 00:00'::timestamp, '2008-03-04 12:00', '10 hours'), generate_series(100, 7243, 1);
   ")

   replication_lag=$(docker exec standby psql -U postgres -t -c "SELECT now()-pg_last_xact_replay_timestamp();")
   echo "----------------------------"
   printf "%s\nReplication lag: %s\n" "$(echo "$query" | grep -oP 'Execution Time: .* ms')" "$replication_lag"

done

echo
echo "pg_stat_replication"
echo

docker exec primary psql -U postgres -c 'SELECT client_addr, application_name, state, sync_state, write_lag, flush_lag, replay_lag, sent_lsn, write_lsn, flush_lsn, replay_lsn FROM pg_stat_replication';