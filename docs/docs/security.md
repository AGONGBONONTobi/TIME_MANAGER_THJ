---
title: Authentification et sécurité
sidebar_position: 8
---

# Authentification et sécurité

## Connexion

`POST /api/auth/sign_in` vérifie email et mot de passe dans `Accounts`, refuse les comptes inactifs, génère un JWT Joken et un secret CSRF. Pour le web, le backend pose `auth_token` en cookie HttpOnly et `c-xsrf-token` en cookie lisible par le frontend. Pour l’origine Cordova `https://localhost`, la réponse inclut également les credentials afin de les conserver avec Secure Storage.

`RequireAuth` accepte le cookie JWT ou un en-tête Bearer, valide le jeton et charge `current_user`. Les plugs `RequireRole`, `RequireUserAccess` et `ValidateCsrf` fournissent des contrôles complémentaires lorsque le routeur les applique.

## Rôles et accès

Les rôles autorisés par le schéma sont `employee`, `manager` et `admin`. Les contrôles de routes Vue sont une aide d’interface, pas une barrière de sécurité. Le premier administrateur est initialisé par seed/provisionnement, et non par une inscription publique.

## Points de vigilance visibles dans le routeur

- La validation CSRF n’est appliquée qu’aux scopes qui incluent le plug; certaines opérations qui modifient des données n’y passent pas.
- Les routes historiques `/api/workingtime/...` et `/api/clocks/:userID` n’ont pas toutes le plug de contrôle de propriété utilisé par `/api/users/:userID/...`.
- `GET /api/users/:userID` n’utilise pas ce plug dans le routeur.
- Il faut vérifier et corriger ces pipelines avant de considérer les contrôles d’accès comme uniformes. La protection du frontend ne suffit pas.

## Tests de sécurité

Les tests applicatifs sont dans `time_manager/test/` et `frontend/test/`. Les scripts et rapports sous `security/` sont historiques : ne les interprétez pas comme certification actuelle. `full_pentest.sh` peut créer/modifier des données distantes; ne l’exécutez pas comme test local sans audit et environnement isolé.

Les changements de sécurité doivent être vérifiés par des tests négatifs explicites (utilisateur A accédant aux ressources de B, CSRF absent/invalide, permissions par rôle), puis par un test d’intégration contrôlé.