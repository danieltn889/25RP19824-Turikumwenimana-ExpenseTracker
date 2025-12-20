#!/bin/bash

PROJECT_ID="25RP19824-Turikumwenimana"

if [ -z "$1" ]; then
  echo "Usage: ./logs.sh [api|frontend|db|all]"
  exit 1
fi

case $1 in
  api)
    docker-compose logs -f 25rp19824-turikumwenimana-api
    ;;
  frontend)
    docker-compose logs -f 25rp19824-turikumwenimana-frontend
    ;;
  db)
    docker-compose logs -f 25rp19824-turikumwenimana-db
    ;;
  all)
    docker-compose logs -f
    ;;
  *)
    echo "Unknown service: $1"
    exit 1
    ;;
esac
