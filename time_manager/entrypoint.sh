#!/bin/sh
set -e

echo "Application des migrations..."
/app/bin/time_manager eval "TimeManager.Release.migrate()"

echo "Démarrage du serveur Phoenix..."
exec /app/bin/time_manager start