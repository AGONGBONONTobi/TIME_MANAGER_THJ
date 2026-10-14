---
title: Application mobile Cordova
sidebar_position: 7
---

# Application mobile Cordova

Le projet mobile est un conteneur Android Cordova qui embarque le bundle Vue. La configuration native se trouve dans `mobile/config.xml`; les composants métier sont majoritairement partagés dans `frontend/src/`.

## Plugins déclarés

`config.xml` inclut les plugins SQLite, Secure Storage, réseau, vibration et notifications locales. Il configure aussi le splash screen, le schéma HTTPS `localhost` et les préférences Android.

## Générer le bundle mobile

Depuis `frontend/` :

```bash
npm install
npm run build:mobile
```

Ce script lance Vite en mode mobile, ajoute le script Cordova et remplace le contenu de `mobile/www/` par le build généré. `mobile/www/assets/` est une sortie compilée, pas la source de l’interface.

## Hors-ligne et reprise

1. `ClockManager.vue` déclenche un événement avec un identifiant client unique.
2. `syncService.js` le place dans la file de `localDatabase.js`.
3. SQLite est utilisé si le plugin est disponible; sinon le navigateur utilise `localStorage`.
4. Au retour du réseau, `networkService.js` signale l’état et la synchronisation réessaie les événements de l’utilisateur courant.
5. L’API déduplique les événements clients, puis l’application retire les éléments synchronisés.

Les périodes mises en cache peuvent s’afficher avec un indicateur en attente. Le stockage hors-ligne reste une copie locale; le serveur et PostgreSQL restent la source de vérité.

## Credentials

Le flux mobile utilise Secure Storage pour les credentials JWT/CSRF plutôt que `localStorage`. Les options réseau et plugins doivent être revérifiés lors de toute mise à jour Cordova ou Android.