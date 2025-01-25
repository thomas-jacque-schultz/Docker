#!/bin/bash

COMPOSE_DIR="./"

if [ ! -d "$COMPOSE_DIR" ]; then
  echo "Erreur : le répertoire $COMPOSE_DIR n'existe pas."
  exit 1
fi

function run_docker_compose {
  local dir=$1
  for COMPOSE_FILE in "$dir"/*/docker-compose.yml; do
    if [ -f "$COMPOSE_FILE" ]; then
      echo "Lancement de Docker Compose dans : $(dirname "$COMPOSE_FILE")"
      pushd "$(dirname "$COMPOSE_FILE")" > /dev/null
      docker compose up -d
      popd > /dev/null
    else
      echo "Aucun fichier docker-compose.yml trouvé dans $dir."
    fi
  done

  for subdir in "$dir"/*/; do
    if [ -d "$subdir" ]; then
      run_docker_compose "$subdir"
    fi
  done
}

run_docker_compose "$COMPOSE_DIR"

echo "Tous les conteneurs Docker ont été lancés."