#!/bin/bash

# Répertoire contenant les fichiers docker-compose.yml
COMPOSE_DIR="./"

# Vérifiez si le répertoire existe
if [ ! -d "$COMPOSE_DIR" ]; then
  echo "Erreur : le répertoire $COMPOSE_DIR n'existe pas."
  exit 1
fi

# Parcourir tous les fichiers docker-compose.yml dans le répertoire
for COMPOSE_FILE in "$COMPOSE_DIR"/*/docker-compose.yml; do
  if [ -f "$COMPOSE_FILE" ]; then
    echo "Lancement de Docker Compose dans : $(dirname "$COMPOSE_FILE")"

    # Se déplacer dans le dossier du fichier docker-compose.yml
    pushd "$(dirname "$COMPOSE_FILE")" > /dev/null

    # Lancer docker-compose
    docker compose up -d

    # Revenir au répertoire précédent
    popd > /dev/null
  else
    echo "Aucun fichier docker-compose.yml trouvé dans $COMPOSE_DIR."
  fi
done

echo "Tous les conteneurs Docker ont été lancés."
