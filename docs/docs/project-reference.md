---
title: Index des sources
sidebar_position: 10
---

# Index des sources

Cette page sert de carte du dépôt pour passer rapidement d’une fonctionnalité à son implémentation.

## Backend

- `time_manager/lib/time_manager/accounts.ex` et `accounts/user.ex` : utilisateurs, authentification et changements de mot de passe.
- `time_manager/lib/time_manager/clocking.ex` et `clocking/` : pointages et corrections.
- `time_manager/lib/time_manager/working_times.ex` et `working_times/` : périodes de travail.
- `time_manager/lib/time_manager/teams.ex`, `leave_requests.ex`, `payroll_rules.ex`, `work_policies.ex`, `notifications.ex` : domaines de gestion.
- `time_manager/lib/time_manager_web/router.ex` : contrat HTTP effectif.
- `time_manager/lib/time_manager_web/controllers/` : adaptation HTTP par domaine.
- `time_manager/priv/repo/migrations/` : évolution de la base.
- `time_manager/test/` : tests Elixir/Phoenix.

## Frontend et mobile

- `frontend/src/main.js`, `App.vue`, `router/index.js` : initialisation, cadre et navigation.
- `frontend/src/components/` : composants d’écran.
- `frontend/src/services/api.js` : appels backend; `utils/auth.js` : état/credentials; `localDatabase.js` et `syncService.js` : persistance/synchronisation.
- `frontend/test/unit/` : tests Vitest.
- `mobile/config.xml` : identité, préférences et plugins Cordova.
- `mobile/www/` : bundle généré; modifier la source dans `frontend/`, puis reconstruire.

## Documentation et documents de projet

- `docs/docs/` : pages Docusaurus versionnées avec le code.
- `STAKEHOLDERS.md` et `COMMUNICATION_CHOICES.md` : analyse et propositions de communication; ce ne sont pas des fonctionnalités de l’application.
- `security/reports/` : rapports historiques; ils doivent être datés et reproduits avant toute conclusion actuelle.