#!/bin/bash
docker exec primary /bin/bash -c "echo \"SELECT 'CREATE DATABASE pgbench' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'pgbench')\gexec\" | psql -U postgres"
docker exec --user postgres primary pgbench -i -s 50 pgbench
docker exec --user postgres primary pgbench -c 10 -j 2 -t 10000 pgbench

