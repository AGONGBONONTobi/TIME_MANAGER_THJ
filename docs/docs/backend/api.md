---
title: Référence API
sidebar_position: 2
---

# Référence API

Les routes sont déclarées dans `time_manager/lib/time_manager_web/router.ex` sous le préfixe `/api`. L’URL locale directe est généralement `http://localhost:4000/api`; le client web utilise `/api` via le proxy Vite/Nginx.

Le schéma généré se trouve à `/api/openapi` et Swagger UI à `/swagger`.

## Authentification et comptes

| Méthode | Chemin | Accès / usage |
| --- | --- | --- |
| `POST` | `/auth/sign_in` | Public; corps avec `email` et `password`. |
| `GET` | `/auth/me` | Utilisateur connecté. |
| `POST` | `/auth/sign_out` | Connecté + CSRF. |
| `POST` | `/auth/complete_onboarding` | Connecté + CSRF. |
| `PUT` | `/auth/password` | Connecté + CSRF; `current_password`, `new_password`. |
| `GET` | `/users` | Connecté; liste filtrable par `email` et `username`. |
| `GET` | `/users/:userID` | Connecté. |
| `POST` | `/users` | Admin + CSRF; corps enveloppé dans `user`; génère un mot de passe temporaire. |
| `PUT`, `DELETE` | `/users/:userID` | Connecté, contrôle d’accès utilisateur + CSRF. |
| `PATCH` | `/users/:userID/role` | Admin + CSRF; champ `role` (`employee`, `manager` ou `admin`). |

Il n’existe pas de route publique `/auth/register` ou `/auth/sign_up` dans le routeur.

## Temps et pointages

| Méthode | Chemin | Remarques |
| --- | --- | --- |
| `GET` | `/users/:userID/clocks` | Route avec contrôle d’accès utilisateur. |
| `POST` | `/users/:userID/clocks` | Événement de pointage; le client peut fournir `client_event_id`, `event_type` et `occurred_at`. |
| `GET` | `/users/:userID/working-times?start=…&end=…` | Liste avec contrôle d’accès utilisateur. |
| `POST` | `/users/:userID/working-times` | Crée une période; corps `workingtime` contenant `start`, `end` et éventuellement `break_duration`. |
| `GET` | `/users/:userID/working-times/:id` | Lecture d’une période pour l’utilisateur. |
| `PUT`, `DELETE` | `/workingtime/:id` | Routes historiques sans le même contrôle d’accès utilisateur que les routes imbriquées. |
| `GET`, `POST` | `/workingtime/:userID` | Routes historiques; un POST sans attributs de période peut créer un événement de pointage. |
| `GET` | `/workingtime/:userID/:id` | Lecture historique d’une période. |

Exemple de corps de création de période :

```json
{
  "workingtime": {
    "start": "2026-10-14T08:00:00Z",
    "end": "2026-10-14T17:00:00Z",
    "break_duration": 30
  }
}
```

Le schéma Ecto autorise `end` à être nul pour une période encore ouverte; `start` et `user_id` sont requis lors de la persistance.

## Gestion, notifications et équipe

| Méthode | Chemin | Accès |
| --- | --- | --- |
| `GET`, `PATCH` | `/notifications`, `/notifications/:id/read` | Authentifié; la lecture modifie `read_at`. Aucun POST HTTP de création n’est déclaré. |
| `GET` | `/manager/team` | Manager ou admin. |
| `POST` | `/manager/users/:userID/reminders` | Manager ou admin. |
| `GET` | `/teams`, `/teams/:id`, `/teams/:team_id/tasks` | Manager ou admin. |
| `POST`, `PATCH`, `DELETE` | Routes `/teams/.../tasks...` | Manager ou admin selon la route. |
| `POST`, `PUT`, `DELETE` | `/teams...` (gestion des équipes) | Admin pour créer, modifier ou supprimer une équipe. |
| `POST`, `DELETE` | `/teams/:id/members/:user_id` | Manager ou admin. |
| `GET`, `POST` | `/leave-requests` | Authentifié. |
| `POST` | `/leave-requests/:id/approve` ou `/reject` | Manager ou admin. |
| `GET`, `POST`, `PUT`, `DELETE` | `/payroll-rules...`, `/work-policies...` | Admin. |
| `GET`, `POST` | `/clock-corrections` | Authentifié. |
| `GET` | `/clock-corrections/pending` | Manager ou admin. |
| `POST` | `/clock-corrections/:id/approve` ou `/reject` | Manager ou admin. |

:::warning Les préfixes d’accès ne sont pas uniformes
Le niveau de protection dépend précisément du pipeline de chaque route dans `router.ex`. Des routes historiques de pointage/périodes et `GET /users/:userID` n’utilisent pas toutes les mêmes plugs de propriété/CSRF que les routes imbriquées. Ne déduisez pas qu’un endpoint est sûr uniquement parce que le frontend le masque.
:::