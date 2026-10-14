---
title: Modèle de données
sidebar_position: 6
---

# Modèle de données

Les structures persistées sont des schémas Ecto dans `time_manager/lib/time_manager/`; les migrations correspondantes se trouvent dans `time_manager/priv/repo/migrations/`.

## Principales entités

| Entité | Champs et relations importants |
| --- | --- |
| `User` | `username`, `email`, `password_hash`, `role`, `status`, dates de contrat, onboarding; `password` est virtuel. |
| `Clock` | Horodatage, statut arrivée/départ, `user_id`; statut `true` indique une arrivée. |
| `WorkingTime` | `start`, `end` nullable pour la période en cours, `break_duration`, `user_id`, `deleted_at`. |
| `Team` / `TeamMembership` | Équipe, responsable, association utilisateur/équipe et état d’adhésion. |
| `TeamTask` | Tâches liées à une équipe avec statut. |
| `LeaveRequest` | Demande de congé et état de traitement. |
| `WorkPolicy` / `UserWorkPolicy` | Règles de jours/heures travaillés et affectation datée à un utilisateur. |
| `PayrollRule` | Règles de paie configurables. |
| `ClockCorrection` | Demande de correction soumise à révision. |
| `Notification` | Notification destinée à un utilisateur, avec date de lecture. |

## Validation et mots de passe

`Accounts.User.changeset/2` valide l’adresse email, les valeurs de rôle/statut et la longueur minimale du mot de passe lorsqu’un mot de passe est fourni. `password_hash` utilise Bcrypt; le changeset d’inscription force le rôle initial `employee`.

## Dates

Les dates/heures backend sont des `:utc_datetime` et les réponses API sont des chaînes ISO 8601. Les filtres `start` et `end` de la liste des périodes acceptent les formats parsables par le contexte `WorkingTimes`.

Pour les détails d’écriture/lecture HTTP, voir [Référence API](/docs/backend/api).