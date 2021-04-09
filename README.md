# PostgreSQL Physical Streaming Replication
Репозиторий содержит практически всё необходимое для запуска нескольких docker контейнеров c СУБД PostgreSQL в режиме physical streaming replication (синхронном или асинхронном) 

### primary

`setup-primary.sh` - этот сценарий копируется в образ при сборке и запускается во время старта контейнера. В нём выполняется создание роли для подключения сервера, работающего в режиме standby, добавляются параметры логирования в `postgresql.conf` и включается (если указано при запуске) синхронная репликация с сервером с именем `replica`. 

### standby

`entry-point.sh` - точка запуска контейнера. Отличается от оригинального скрипта [entry-point.sh](https://github.com/docker-library/postgres/blob/a7aa19b8501df4c459dad78fd18e2b36fded9643/12/alpine/Dockerfile), взятого из официального [репозтория postgresql docker image](https://github.com/docker-library/docs/tree/master/postgres) блоком, в котором выполняется pg_basebackup и перевод кластера в режим standby.

## Step-by-step example

1. Клонируем репозиторий на локальную машину  
```sh
git clone https://github.com/vkutas/postgres-replication
cd postgres-replication
```

2. Создаём `.env` файл следующего вида:

```sh
POSTGRES_PASSWORD=yourPostgresPassword
REPLICATOR_PASS=passwordForReplicatorUser
PRIMARY_ADDR=192.168.99.2
STAND_BY_ADDR=192.168.99.3
NETWORK_MASK=8
SYNC_REPLICATION_ON=0
```
Для запуска кластеров в режиме синхронной репликации необходимо установить `SYNC_REPLICATION_ON` в 1. 

3. Запускаем контейнеры с помощью Docker Compose  

`docker-compose up -d`

Если всё загрузилось успешно, то `docker-compose ps` отобразит примерно следующее:

```sh
 Name                Command              State    Ports  
----------------------------------------------------------
primary   docker-entrypoint.sh postgres   Up      5432/tcp
standby   entry-point.sh postgres         Up      5432/tcp
```

Если какой либо из контейнеров не запустился, то смотрим логи:  
`docker-compose logs` - для обоих контейнеров
`docker logs primary` и `docker logs stanby` - для каждого в отдельности

4. C помощью скрипта [test-replication-lag.sh](/test-replication-lag.sh) можно примерно оценить задержку репликации.

В нем создаётся база данных `play` с таблицей `dates_series`, которая заполняется с помощью [generate_series](https://www.postgresql.org/docs/12/functions-srf.html). При каждой вставке выводится время выполения запроса и примерное время задержки репликации, которое вычисляется по формуле `now()-pg_last_xact_replay_timestamp()` на стороне standby сервера.


5. C помощью [pgbench.sh](pgbench.sh) можно запустить простой бенчмарк. Скрипт состоит всего из 3 команд: 

    Создание БД для запуска бенчмарка  
    `docker exec primary /bin/bash -c "echo \"SELECT 'CREATE DATABASE pgbench' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'pgbench')\gexec\" | psql -U postgres"` 

    Инициализация БД данными на 800 MB (5 000 000 записей)  
    `docker exec --user postgres primary pgbench -i -s 50 pgbench`  

    Запускаем проверку baseline performance с 12 клиентами и 2 потоками  
    `docker exec --user postgres primary pgbench -c 10 -j 2 -t 10000 pgbench`  

  Результат может выглядить так:

    
     transaction type: <builtin: TPC-B (sort of)>  
     scaling factor: 50  
     query mode: simple  
     number of clients: 10  
     number of threads: 2  
     number of transactions per client: 10000  
     number of transactions actually processed: 100000/100000  
     latency average = 3.356 ms  
     tps = 2980.141159 (including connections establishing)  
     tps = 2980.558788 (excluding connections establishing)   
     
6. Теперь, получив достатчное количесво логов, можно проанализировать их с помощью bgbadger

  ```sh
  docker cp primary:/var/lib/postgresql/data/pg_log  .
  pgbadger postgresql-2021-04-09_14* 
  ```

Пример отчёта можно увидеть в [/pgbadger_reports](/pgbadger_reports)