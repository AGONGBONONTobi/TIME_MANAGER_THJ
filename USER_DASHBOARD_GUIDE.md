# Guide de la vue utilisateur — Time Manager

## Périmètre

<<<<<<< HEAD
Cette branche contient les parcours **Utilisateur** et **RH / Administration**. La vue Manager n'est pas intégrée ici : elle pourra avoir sa propre page et sa propre navigation plus tard.
=======
Cette branche contient trois parcours frontend : **Utilisateur**, **Manager** et **Admin/RH**. Les parcours Manager et Admin/RH sont actuellement des prototypes locaux ; leurs actions seront connectées au backend avec l'authentification.
>>>>>>> f7e66514d42a420eacf40b4387aeb9989e4b2d78

L'utilisateur peut :

- consulter son tableau de bord ;
- faire `Clock In` et `Clock Out` ;
- voir son chronomètre uniquement pendant une session active ;
- consulter son quota et ses statistiques hebdomadaires ;
- consulter ses dix derniers pointages en lecture seule.
- consulter ses graphiques personnels.

<<<<<<< HEAD
Le profil **RH / Administration** est accessible depuis `Administration RH`. Il peut :

- consulter les collaborateurs retournés par `GET /api/users` ;
- suivre les heures de la semaine, les sessions actives et les heures de nuit ;
- repérer les collaborateurs dont le seuil hebdomadaire ou nocturne nécessite une vérification ;
- rechercher et filtrer les collaborateurs ;
- exporter le tableau courant au format CSV ;
- consulter le journal des dernières activités en lecture seule.

Cette première vue RH réutilise `GET /api/workingtime/:userID` pour charger les pointages de chaque collaborateur. Les workflows de validation, de paie, de congés, de permissions et d'audit détaillé nécessiteront des endpoints dédiés avant d'être ajoutés à l'interface.

La page de formulaire « Gestion du temps de travail » visible dans l'ancienne capture n'est donc plus accessible depuis l'application. Les anciennes URLs `/workingTime/...`, `/clock/...` et `/chartManager/...` sont redirigées vers `/user`.
=======
La page de formulaire « Gestion du temps de travail » visible dans l'ancienne capture n'est donc plus accessible depuis le parcours employé. Le pointage passe uniquement par `Clock In` et `Clock Out`.
>>>>>>> f7e66514d42a420eacf40b4387aeb9989e4b2d78

## Fichiers principaux

### `frontend/src/App.vue`

C'est le layout global :

- barre latérale sombre ;
- marque `Time Manager` ;
- lien vers `Tableau de bord` ;
- lien vers `Historique` ;
- en-tête avec le nom `Joseph William` et le rôle `Utilisateur` ;
- menu mobile et petit menu de profil.

Il contient la navigation employé et le centre d'aide mobile. Les parcours Manager et Admin/RH ne sont pas présentés comme des permissions réelles tant que l'authentification backend n'est pas disponible.

### `frontend/src/components/User.vue`

C'est le dashboard utilisateur. Le `<script>` contient :

- `loadWorkingTimes()` : charge les sessions avec `GET /api/workingtime/1` ;
- `toggleClock()` : appelle `POST /api/clocks/1`, puis recharge les sessions ;
- `activeSession` : trouve la session sans date de fin ;
- `elapsedLabel` : calcule le chronomètre actif ;
- `quotaPercentage` : compare les heures de la semaine à une base de 35 heures ;
- `quotaColor` : rouge sous 50 %, jaune sous 70 %, vert à partir de 70 % ;
- `chartWorked` et `chartNight` : préparent les séries du graphe à partir des données API ;
- `recentSessions` : limite l'affichage aux 10 derniers pointages.

Le template est organisé en quatre blocs :

1. accueil et date du jour ;
2. présence et horloge locale ;
3. quota et graphe d'activité ;
4. statistiques et tableau des derniers pointages.

Le bloc `.session-timer` est rendu avec `v-if="isClockedIn"`. Il disparaît donc réellement lorsque l'utilisateur n'a pas de session ouverte.

### `frontend/src/components/WorkingTimes.vue`

Cette page est une vue **lecture seule** de l'historique. Les boutons de création, modification et suppression ne sont pas exposés au parcours employé. Le pointage se fait depuis le bouton du dashboard, pas depuis un formulaire manuel.

### Parcours Manager et Admin/RH

- `/manager-dashboard` affiche le suivi d'équipe et les validations en mode démonstration local.
- `/admin-dashboard` prépare les écrans de droits, congés, paie et fatigue en mode démonstration local.
- Ces vues ne constituent pas une protection d'accès : les permissions devront être imposées par le backend.

### `frontend/src/components/HR.vue`

C'est le tableau de bord RH / Administration. Il agrège les utilisateurs et leurs pointages pour afficher les indicateurs hebdomadaires, les statuts d'activité, les alertes de seuil, la recherche, les filtres et l'export CSV. Les données sont actuellement en lecture seule.

### `frontend/src/router/index.js`

<<<<<<< HEAD
Le router expose :

- `/user` : dashboard ;
- `/workingTimes/:userID` : historique en lecture seule ;
- `/hr` : dashboard RH / Administration ;
- toutes les autres URLs : redirection vers `/user`.
=======
Le router expose les parcours suivants :

- `/user` : dashboard employé ;
- `/workingTimes/:userID` : historique employé en lecture seule ;
- `/clock/:userID` : pointage employé ;
- `/chartManager/:userID` : graphiques personnels ;
- `/manager-dashboard` : prototype manager ;
- `/admin-dashboard` : prototype Admin/RH ;
- les anciennes routes `/workingTime/...` de création manuelle redirigent vers `/user`.
>>>>>>> f7e66514d42a420eacf40b4387aeb9989e4b2d78

Les composants `ClockManager.vue`, `ChartManager.vue` et `WorkingTime.vue` restent séparés pour respecter l'architecture Vue. `WorkingTime.vue` n'est pas exposé dans le parcours employé : il pourra être réutilisé plus tard par un parcours manager/admin protégé.

### `frontend/src/services/api.js`

Le service expose aussi `getUsers()`, utilisé par la vue RH pour charger la liste des collaborateurs avant de récupérer leurs pointages individuels.

## Styles et direction visuelle

Les styles sont principalement scoped dans `User.vue` et `WorkingTimes.vue`. Le layout général est dans `App.vue`.

### Palette

- fond de l'application : `#f7f8fb` ;
- navigation : `#1d2430` ;
- cartes : `#ffffff` ;
- accent utilisateur : violet doux `#8a7cf0` ;
- succès / Clock In : vert `#47ad79` ;
- actif / Clock Out : rouge `#e85d65` ;
- quota intermédiaire : jaune `#f0ad32` ;
- graphe : fond `#171717`, bleu, orange et gris ardoise.

Le jaune est réservé aux accents et aux informations d'objectif. Il n'est pas utilisé comme couleur dominante, afin d'éviter un rendu trop artificiel ou trop chargé.

### Graphe

Le graphe est un SVG local, sans nouvelle dépendance :

- lignes horizontales en pointillés ;
- axe du temps du lundi au dimanche ;
- courbe bleue pour les heures travaillées ;
- courbe orange pour l'objectif journalier ;
- courbe ardoise pour les heures de nuit.

La méthode `chartLine()` transforme les heures en coordonnées SVG. Le graphe reste donc synchronisé avec la base de données après un `Clock In` ou un `Clock Out`.

## Données de démonstration

Le fichier `time_manager/priv/repo/seeds.exs` crée ou retrouve :

- utilisateur : `Joseph William` ;
- email : `joseph.william@example.com` ;
- trois sessions terminées ;
- une session de nuit ;
- les clocks d'entrée et de sortie correspondants.

Le seed supprime d'abord les anciennes sessions de cet utilisateur afin de pouvoir être rejoué sans créer de doublons.

Pour régénérer les données depuis le conteneur API, le script peut être exécuté après démarrage du dépôt Ecto. En environnement Docker, les migrations sont lancées automatiquement par `time_manager/entrypoint.sh`.

## Vérification locale

Depuis `frontend/` :

- `npm run build` compile la production ;
- `npm run lint` lance Oxlint et ESLint.

Depuis la racine :

- `docker-compose up -d --build` reconstruit et démarre PostgreSQL, l'API Phoenix et le frontend ;
- frontend : `http://localhost` ;
- API : `http://localhost:4000`.

## Pourquoi le formulaire a été retiré

Un utilisateur ne doit pas modifier manuellement les horaires enregistrés. Cela contournerait le mécanisme de pointage et rendrait les statistiques moins fiables. Le dashboard est donc le seul endroit où l'utilisateur déclenche une entrée ou une sortie ; l'historique sert uniquement à vérifier les données enregistrées.
