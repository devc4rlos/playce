#!/bin/bash
set -e

# shellcheck disable=SC2155
export HOST_UID=$(id -u)
# shellcheck disable=SC2155
export HOST_GID=$(id -g)

COMMAND=${1:-up}

DC="docker compose -f docker-compose.prod.yml -f docker-compose.local.prod.yml"

if [ "$COMMAND" = "down" ]; then
    echo "==> Stopping and removing containers and volumes..."
    $DC down -v
    echo "==> Local environment stopped."

elif [ "$COMMAND" = "up" ]; then
    echo "==> Starting local environment (this may take a while on the first run)..."
    $DC down -v

    $DC up -d --build mysql nginx_playce app_playce

    echo "==> Waiting for the database to be ready..."
    # shellcheck disable=SC1083
    while [ "$(docker inspect -f {{.State.Health.Status}} mysql_playce)" != "healthy" ]; do
        echo -n "."
        sleep 3
    done
    echo

    echo "==> Running migrations..."
    $DC exec app_playce php artisan migrate --force

    echo "==> Starting the worker..."
    $DC up -d --build worker_playce

    echo "==> Local environment is ready at http://localhost"

else
    echo "Unknown command: $COMMAND"
    echo "Usage: ./local.sh [up|down]"
    exit 1
fi
