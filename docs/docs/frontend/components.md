---
title: Composants et navigation Vue
sidebar_position: 1
---

# Composants et navigation Vue

L’interface est une application Vue 3 montée depuis `frontend/src/main.js`. `App.vue` fournit la structure partagée; `router/index.js` utilise l’historique hash et sélectionne l’écran.

## Composants par fonctionnalité

| Fichier | Responsabilité |
| --- | --- |
| `Authentication.vue`, `AuthShell.vue` | Connexion et présentation des écrans d’authentification. |
| `ChangePassword.vue`, `Profile.vue`, `OnboardingWizard.vue` | Mot de passe, profil et parcours de première connexion. |
| `User.vue`, `Dashboard.vue`, `HeroSection.vue` | Vue utilisateur et tableaux de bord. |
| `ClockManager.vue` | Déclenchement et affichage du pointage courant. |
| `WorkingTimes.vue`, `WorkingTime.vue` | Liste des périodes et opérations sur une période. |
| `ChartManager.vue`, `NightChart.vue` | Calcul et affichage de graphiques. |
| `ManageDashboard.vue` | Écrans de gestionnaire et vues d’équipe. |
| `AdminDashboard.vue` | Opérations réservées à l’administration. |
| `Notifications.vue` | Liste et lecture des notifications. |
| `Unauthorized.vue` | Page d’accès refusé côté interface. |

## Routage et rôles

Les routes principales sont `/sign_in`, `/dashboard`, `/employee`, `/manager`, `/admin`, `/notifications`, `/profile`, `/workingTimes/:userID`, `/clock/:userID` et `/chartManager/:userID`. Le guard `beforeEach` lit l’utilisateur local, redirige les visiteurs vers la connexion et compare les métadonnées `roles`.

Ce guard améliore la navigation, mais **ne remplace pas l’autorisation backend**. Le backend doit vérifier chaque action même si un écran n’est pas visible.

## Cycle d’un composant

Un composant appelle les méthodes exposées par `frontend/src/services/api.js`, transforme la réponse pour son affichage et met à jour son état Vue. Les composants de pointage peuvent aussi utiliser le cache local et les services de synchronisation décrits dans [Services frontend](/docs/frontend/services).

Les tests de composants se trouvent dans `frontend/test/unit/components/`.