---
title: Installation et démarrage
sidebar_position: 2
---

# Installation et démarrage

## Prérequis

- Elixir `~> 1.14` et Erlang/OTP compatibles avec Phoenix.
- Node.js pris en charge par la version déclarée dans `frontend/package.json`.
- PostgreSQL local, ou Docker et Docker Compose.
- Pour compiler Android : outils Cordova et SDK Android configurés.

## Démarrer avec Docker

À la racine du dépôt, configurez les variables requises dans le fichier `.env` local (ne le publiez pas), puis lancez :

```bash
docker compose up --build
```

Le frontend est publié sur le port `8080`; l’API écoute sur le port `4000` dans le réseau Docker et PostgreSQL utilise le volume `pgdata`. Nginx transmet les appels `/api` à l’API.

## Démarrer séparément

### Backend

```bash
cd time_manager
mix setup
mix phx.server
```

`mix setup` récupère les dépendances, crée et migre la base, puis exécute les seeds. `mix phx.server` démarre Phoenix sur le port configuré (par défaut `4000`).

### Frontend

```bash
cd frontend
npm install
npm run dev
```

Le proxy Vite transmet `/api` à `http://localhost:4000`. Pour une autre URL d’API, définir `VITE_API_URL` dans l’environnement Vite.

## Démarrer la documentation

```bash
cd docs
npm install
npm run start
```

Le site Docusaurus est servi sur `http://localhost:8000`. Pour produire le site statique : `npm run build`.

## Configuration sensible

La configuration de production est lue depuis l’environnement par `time_manager/config/runtime.exs`; les secrets JWT, la clé Phoenix et l’URL de base de données ne doivent pas être ajoutés à Git. Les valeurs attendues dépendent du mode de démarrage et de `.env`.