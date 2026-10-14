---
slug: /
title: Vue d’ensemble
sidebar_position: 1
---

# Documentation technique du code

Cette documentation décrit **l’implémentation présente dans le dépôt** : où se trouvent les modules, comment les requêtes et données circulent, et quelles commandes permettent de tester chaque couche. Les comportements annoncés mais absents du code sont signalés comme tels.

## Les couches du projet

| Dossier | Responsabilité |
| --- | --- |
| `time_manager/lib/time_manager/` | Règles métier et accès aux données via les contextes Elixir et Ecto. |
| `time_manager/lib/time_manager_web/` | API Phoenix, contrôleurs, routes et plugs d’authentification/autorisation. |
| `frontend/src/` | Interface Vue, routage, clients API et services navigateur/mobile. |
| `mobile/` | Conteneur Android Cordova et plugins natifs. |
| `docker-compose.yml` | Assemblage local du frontend, de l’API et de PostgreSQL. |
| `security/` | Scripts et comptes rendus de contrôles de sécurité historiques. |

## Parcours de lecture

1. [Installer et démarrer le projet](/docs/getting-started)
2. [Suivre l’architecture et les flux](/docs/architecture)
3. Comprendre les [domaines backend](/docs/backend/domains) et les [routes API](/docs/backend/api)
4. Lire les [composants Vue](/docs/frontend/components) et les [services frontend](/docs/frontend/services)
5. Consulter le [modèle de données](/docs/data-model), le [mobile](/docs/mobile), la [sécurité](/docs/security) et les [tests/déploiement](/docs/testing-deployment)

## Repères rapides

- Backend : Elixir, Phoenix, Ecto, PostgreSQL et Bandit.
- Web : Vue 3, Vue Router, Vite et Axios.
- Mobile : Cordova Android, avec la même application Vue empaquetée.
- Contrats générés : Swagger UI à `/swagger`, schéma OpenAPI à `/api/openapi` (serveur backend en fonctionnement).

:::caution Source de vérité
Les fichiers et routes décrits ici sont vérifiés dans le dépôt. Certains anciens documents décrivent des intentions ou des routes qui ne sont plus implémentées. En cas d’écart, le code courant fait foi.
:::