#!/bin/bash
echo "Replication mode: sync"

for ((i=0;i<2;i++)); do

   query=$(docker exec primary psql -U postgres -d play -c "
      EXPLAIN ANALYZE INSERT INTO dates_series(date, value)
      SELECT generate_series('2008-03-01 00:00'::timestamp, '2008-03-04 12:00', '10 hours'), generate_series(100, 7243, 1);
   ")

    echo "$query" | grep -oP 'Execution Time: .* ms'

done

docker exec primary psql -U postgres -c 'SELECT client_addr, application_name, state, sync_state, write_lag, flush_lag, replay_lag, sent_lsn, write_lsn, flush_lsn, replay_lsn FROM pg_stat_replication';