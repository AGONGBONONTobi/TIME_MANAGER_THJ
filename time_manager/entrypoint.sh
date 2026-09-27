#!/bin/sh
set -e

echo "Application des migrations..."
/app/bin/migrate

echo "Démarrage du serveur Phoenix..."
exec /app/bin/server