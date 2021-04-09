# PostgreSQL Physical Streaming Replication
Репозиторий содержит практически всё необходимое для запуска нескольких docker контейнеров c СУБД PostgreSQL в режиме physical streaming replication (синхронном или асинхронном) 

### Primary

В директории [/primary](/primary) содержаться Dockerfile для создания PostgreSQL Primary Node и различные вспомогательные скрипты:

`setup-primary.sh` - этот сценарий копируется в образ при сборке и запускается во время старта контейнера. В нём выполняется создание роли для подключения сервера, работающего в режиме standby, добавляются параметры логирования в `postgresql.conf` и включается (если указано при запуске) синхронная репликация с сервером с именем `replica`. 

### Standby

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

4. C помомью скрипта [test-replication-lag.sh](/test-replication-lag.sh) можно примерно оценить задержку репликации.

В нем создаётся база данных `play` с таблицей `dates_series`, которая заполняется с помощью [generate_series](https://www.postgresql.org/docs/12/functions-srf.html). При каждой вствка выводится время выполения запроса и примерное время задержки репликации, которое вычисляется по формуле `now()-pg_last_xact_replay_timestamp()` на стороне standby сервера.



