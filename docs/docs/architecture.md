---
title: Architecture et flux
sidebar_position: 3
---

# Architecture et flux d’exécution

## Responsabilités

1. **Vue** rend les écrans et collecte les actions dans `frontend/src/components/`.
2. **Services frontend** (`services/api.js`, synchronisation et stockage local) préparent les requêtes.
3. **Phoenix Router** choisit le contrôleur et les plugs à appliquer.
4. **Contrôleur** valide les paramètres HTTP et délègue au contexte métier.
5. **Contexte Ecto** applique les règles du domaine et lit/écrit via `TimeManager.Repo`.
6. **PostgreSQL** conserve comptes, pointages, périodes travaillées et données de gestion.

## Flux de pointage en ligne

`ClockManager.vue` déclenche une action → `api.js` envoie la requête → `ClockController` transmet au contexte `TimeManager.Clocking` → une transaction crée l’événement et met à jour la période dans PostgreSQL → le contrôleur renvoie le JSON.

## Flux de pointage hors-ligne

`syncService.js` place d’abord chaque événement dans `localDatabase.js`. Lorsque le réseau revient, le service les rejoue dans l’ordre chronologique avec un identifiant client stable. L’API traite ces événements et la couche mobile peut afficher la période en attente avant confirmation serveur.

## Démarrage backend

`TimeManager.Application` supervise le Repo Ecto, le point d’accès Phoenix et les services de télémétrie. Le conteneur backend construit une release; `time_manager/entrypoint.sh` applique les migrations avant le démarrage de la release.

## Fichiers d’entrée utiles

| Sujet | Fichier |
| --- | --- |
| Routes HTTP | `time_manager/lib/time_manager_web/router.ex` |
| Application OTP | `time_manager/lib/time_manager/application.ex` |
| Configuration/runtime | `time_manager/config/` |
| Entrée Vue | `frontend/src/main.js` |
| Racine de l’interface | `frontend/src/App.vue` |
| Proxy API local | `frontend/vite.config.js` |
| Services conteneurisés | `docker-compose.yml` |