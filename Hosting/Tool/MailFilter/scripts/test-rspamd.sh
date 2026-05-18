#!/bin/sh
# Script pour tester la connexion Rspamd

RSPAMD_HOST=${RSPAMD_HOST:-localhost}
RSPAMD_PORT=${RSPAMD_PORT:-11333}

echo "Test de connexion à Rspamd..."

result=$(curl -s -X GET "http://$RSPAMD_HOST:$RSPAMD_PORT/stat" 2>/dev/null || echo "{}")

if echo "$result" | grep -q "scanned"; then
    echo "✓ Rspamd est accessible"
    echo "$result" | head -c 200
    exit 0
else
    echo "✗ Erreur de connexion à Rspamd"
    echo "Tentative de ping..."
    nc -zv "$RSPAMD_HOST" "$RSPAMD_PORT" 2>&1 || echo "Port fermé"
    exit 1
fi
