---
title: Domaines et modules backend
sidebar_position: 1
---

# Domaines et modules backend

Le code backend est une application Phoenix/Elixir. Les contrôleurs HTTP vivent dans `time_manager/lib/time_manager_web/controllers/`; les règles métier sont séparées dans les contextes `time_manager/lib/time_manager/`.

## Contextes métier

| Module | Rôle | Schémas principaux |
| --- | --- | --- |
| `TimeManager.Accounts` | Recherche, création, mise à jour, authentification et changement de mot de passe. | `Accounts.User` |
| `TimeManager.Clocking` | Enregistrement des arrivées/départs, état courant et corrections. | `Clocking.Clock`, `Clocking.ClockCorrection` |
| `TimeManager.WorkingTimes` | Création, mise à jour, filtres temporels et recherche de périodes ouvertes. | `WorkingTimes.WorkingTime` |
| `TimeManager.Teams` | Équipes, adhésions et tâches d’équipe. | `Teams.Team`, `TeamMembership`, `TeamTask` |
| `TimeManager.LeaveRequests` | Demandes de congé et décisions. | `LeaveRequests.LeaveRequest` |
| `TimeManager.PayrollRules` | Règles de paie configurables. | `PayrollRules.PayrollRule` |
| `TimeManager.WorkPolicies` | Politiques de travail et affectations à des utilisateurs. | `WorkPolicy`, `UserWorkPolicy` |
| `TimeManager.Notifications` | Création métier, liste et marquage comme lu des notifications. | `Notifications.Notification` |

Les modules `TimeManager.Repo`, `TimeManager.Token` et `TimeManager.Release` concernent respectivement la persistance, la signature/validation JWT et les opérations de release.

## Frontière HTTP

- `router.ex` associe méthodes/chemins aux actions et compose les pipelines de plugs.
- `RequireAuth` vérifie un JWT et charge l’utilisateur courant.
- `RequireRole` limite certaines actions à des rôles donnés.
- `RequireUserAccess` vérifie l’accès aux ressources sous un identifiant utilisateur.
- `ValidateCsrf` compare l’en-tête CSRF au claim du JWT pour les méthodes de modification lorsque le plug est dans le pipeline.
- Les contrôleurs appellent les contextes plutôt que de contenir la logique de persistance.
- Les vues `*_json.ex` définissent le rendu de certaines ressources; `ChangesetJSON` rend les erreurs de validation.

## Démarrer depuis la source

Depuis `time_manager/`, `mix setup` initialise dépendances et base; `mix phx.server` lance l’API. Les migrations sont dans `time_manager/priv/repo/migrations/` et les fixtures/tests dans `time_manager/test/`.

Pour la liste HTTP exacte, consulter [Référence API](/docs/backend/api). Pour les associations et champs, consulter [Modèle de données](/docs/data-model).