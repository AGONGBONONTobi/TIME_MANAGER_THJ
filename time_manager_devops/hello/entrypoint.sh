#!/bin/bash
set -e

if [ ! -f .env ]; then
  echo ".env manquant. Arrêt du conteneur."
  exit 1
fi

echo "⏳ Attente de PostgreSQL..."
until pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER"; do
  echo "PostgreSQL indisponible, nouvelle tentative dans 2s..."
  sleep 2
done
echo "✅ PostgreSQL prêt."

echo "🗄️  Création de la base si nécessaire..."
mix ecto.create || true

echo "🔄 Application des migrations..."
mix ecto.migrate

echo "🚀 Démarrage de Phoenix..."
exec mix phx.server