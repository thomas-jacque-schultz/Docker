#!/bin/bash

# R�pertoire contenant les fichiers docker-compose.yml
COMPOSE_DIR="./"

# V�rifiez si le r�pertoire existe
if [ ! -d "$COMPOSE_DIR" ]; then
  echo "Erreur : le r�pertoire $COMPOSE_DIR n'existe pas."
  exit 1
fi

# Parcourir tous les fichiers docker-compose.yml dans le r�pertoire
for COMPOSE_FILE in "$COMPOSE_DIR"/*/docker-compose.yml; do
  if [ -f "$COMPOSE_FILE" ]; then
    echo "Lancement de Docker Compose dans : $(dirname "$COMPOSE_FILE")"

    # Se d�placer dans le dossier du fichier docker-compose.yml
    pushd "$(dirname "$COMPOSE_FILE")" > /dev/null

    # Lancer docker-compose
    docker compose up -d

    # Revenir au r�pertoire pr�c�dent
    popd > /dev/null
  else
    echo "Aucun fichier docker-compose.yml trouv� dans $COMPOSE_DIR."
  fi
done

echo "Tous les conteneurs Docker ont �t� lanc�s."