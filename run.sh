#!/bin/bash

COMPOSE_DIR="./"

if [ ! -d "$COMPOSE_DIR" ]; then
  echo "Erreur : le répertoire $COMPOSE_DIR n'existe pas."
  exit 1
fi

for COMPOSE_FILE in "$COMPOSE_DIR"/*/docker-compose.yml; do
  if [ -f "$COMPOSE_FILE" ]; then
    echo "Lancement de Docker Compose dans : $(dirname "$COMPOSE_FILE")"
    pushd "$(dirname "$COMPOSE_FILE")" > /dev/null
    docker compose up -d
    popd > /dev/null
  else
    echo "Aucun fichier docker-compose.yml trouvé dans $COMPOSE_DIR."
  fi
done

echo "Tous les conteneurs Docker ont été lancés."
