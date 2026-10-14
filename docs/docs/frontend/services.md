---
title: Services et appels frontend
sidebar_position: 2
---

# Services et appels frontend

## `services/api.js`

Crée une instance Axios avec `baseURL` égal à `VITE_API_URL` ou `/api`, `withCredentials: true` et des intercepteurs. Ceux-ci ajoutent le jeton CSRF et, pour Cordova, le Bearer JWT. Le fichier regroupe les helpers des endpoints d’authentification, utilisateurs, pointages, équipes, congés, paie et notifications.

## `utils/auth.js`

Gère le profil utilisé par les guards dans `localStorage`. En mode Cordova, les fonctions de stockage du jeton et du CSRF utilisent le plugin SecureStorage; dans le web, l’authentification s’appuie sur les cookies du serveur.

## Stockage local et synchronisation

- `services/localDatabase.js` : file d’événements de pointage dans SQLite Cordova, avec fallback `localStorage` pour le navigateur; maintient aussi un cache des périodes et applique les événements en attente à une vue optimiste.
- `services/syncService.js` : crée des événements avec identifiant client, les transmet quand l’application est en ligne, supprime les succès et garde l’état/erreur en cas d’échec.
- `services/networkService.js` : suit les événements navigateur `online`/`offline` et l’état réseau Cordova, puis prévient les abonnés.
- `services/nativeFeatures.js` : vibration, notification locale de synchronisation et bouton retour Android.

## Intercepteurs HTTP

Les réponses `401` font nettoyer la session locale et redirigent vers `/sign_in`. Axios transmet les cookies; le service mobile lit ses credentials sécurisés puis ajoute `Authorization: Bearer …`.

## Tests associés

`frontend/test/unit/services/` vérifie notamment l’authentification HTTP et la synchronisation. Lancer `npm test` depuis `frontend/`.