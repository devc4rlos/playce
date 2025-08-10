#!/bin/bash
set -e

# shellcheck disable=SC2155
export HOST_UID=$(id -u)
# shellcheck disable=SC2155
export HOST_GID=$(id -g)

docker compose -f docker-compose.prod.yml -f docker-compose.local.prod.yml down -v

docker compose -f docker-compose.prod.yml -f docker-compose.local.prod.yml up -d --build

echo "Waiting for the database to be healthy..."

# shellcheck disable=SC1083
while [ "$(docker inspect -f {{.State.Health.Status}} mysql_playce)" != "healthy" ]; do
    echo -n "."
    sleep 3
done

docker compose -f docker-compose.prod.yml -f docker-compose.local.prod.yml \
    exec app_playce php artisan migrate
