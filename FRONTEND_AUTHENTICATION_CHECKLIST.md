# Checklist validée — Authentification frontend

## Conclusion

La checklist initiale couvre bien les fonctionnalités attendues côté frontend, mais
certains noms et endpoints doivent être adaptés à l’API actuelle du projet.
L’authentification frontend n’est pas encore finalisée dans `frontend/` : le routeur
ne contient pas de routes de connexion et `App.vue` utilise encore un utilisateur
statique (`Joseph William`, identifiant `1`).

## État du projet

| Élément | État | Décision frontend |
| --- | --- | --- |
| Vue, Axios et Vue Router | Déjà installés | Aucun nouvel `npm install` nécessaire |
| Service Axios | Présent dans `src/services/api.js` | Ajouter `withCredentials` et les intercepteurs |
| Routeur | Présent dans `src/router/index.js` | Modifier ce fichier, plutôt que créer `src/router.js` |
| Login / inscription | Absents | Créer les vues et les routes correspondantes |
| Dashboard authentifié | Absent | Créer `Dashboard.vue` et protéger la route |
| Déconnexion | Absente | Ajouter une action partagée dans le header |
| Header dynamique | Présent mais statique | Lire l’utilisateur connecté depuis l’état/localStorage |
| Documentation frontend | Partielle | Compléter `frontend/README.md` ou référencer ce document |

## Adaptations obligatoires par rapport à la checklist initiale

### Endpoints API réels

Le backend expose les endpoints suivants :

| Action | Endpoint | Corps JSON |
| --- | --- | --- |
| Inscription | `POST /api/auth/sign_up` | `{ username, email, password }` |
| Connexion | `POST /api/auth/sign_in` | `{ email, password }` |
| Déconnexion | `POST /api/auth/sign_out` | aucun |

Il faut donc utiliser `/auth/...` et non `/users/...`. Le proxy Vite ajoute déjà
`http://localhost:4000` aux requêtes commençant par `/api`.

Le backend n’attend pas `name` et `surname` : il attend un seul champ `username`.
Si le produit exige réellement un prénom et un nom séparés, le schéma et l’API
backend devront d’abord être modifiés.

### Réponse de connexion

La réponse est de la forme suivante :

```json
{
  "user": {
    "id": 1,
    "username": "Auth User",
    "email": "auth@example.com",
    "role": "employee"
  }
}
```

Il ne faut donc pas chercher `xsrf_token`, `user_id` et `role` au niveau racine
de la réponse JSON.

### Cookies et XSRF

Le backend pose automatiquement :

- `auth_token` : cookie HTTP-only, à ne jamais copier dans `localStorage` ;
- `c-xsrf-token` : cookie lisible par JavaScript.

Le frontend doit envoyer les cookies avec `withCredentials: true` et lire
`c-xsrf-token` pour le header attendu par l’API. Le nom du header est
`x-xsrf-token`, tandis que le nom du cookie est `c-xsrf-token`.

La consigne « stocker `xsrfToken` dans `localStorage` » ne correspond donc pas au
contrat actuel et affaiblirait la séparation voulue entre cookie HTTP-only et
token CSRF. À conserver côté `localStorage` uniquement si nécessaire pour le
routeur : `userId`, `role` et éventuellement les informations publiques de profil.

## Travail frontend à réaliser

### 1. Service Axios

- Configurer `withCredentials: true` dans l’instance Axios.
- Ajouter `x-xsrf-token` depuis le cookie `c-xsrf-token` à chaque requête mutante
  (`POST`, `PUT`, `PATCH`, `DELETE`) ou à chaque requête si le backend l’exige.
- Ajouter un intercepteur de réponse : sur `401`, nettoyer l’état local puis
  rediriger vers `/sign_in`.
- Ne jamais ajouter de header `Authorization` avec le JWT : il reste HTTP-only.

### 2. Routes et garde de navigation

Modifier `frontend/src/router/index.js` et ajouter :

- `/sign_in` → `Authentication.vue`, `meta: { guestOnly: true }` ;
- `/sign_up` → `Register.vue`, `meta: { guestOnly: true }` ;
- `/dashboard` → `Dashboard.vue`, `meta: { requiresAuth: true }` ;
- `/employee` → `requiresAuth: true`, rôles `employee`, `manager`, `admin` ;
- `/manager` → `requiresAuth: true`, rôles `manager`, `admin` ;
- `/admin` → `requiresAuth: true`, rôle `admin` ;
- `/unauthorized` → `Unauthorized.vue`.

Le garde doit :

1. considérer l’utilisateur authentifié si `userId` et `role` sont présents ;
2. rediriger un visiteur vers `/sign_in` pour une route protégée ;
3. rediriger un utilisateur connecté loin de `/sign_in` et `/sign_up` ;
4. rediriger vers `/unauthorized` si son rôle n’est pas autorisé.

La présence du token CSRF ne doit pas être le seul critère d’authentification,
car ce token n’est pas le cookie HTTP-only qui porte la session.

### 3. Vues d’authentification

Créer `Authentication.vue` avec `email`, `password`, appel vers
`/api/auth/sign_in`, affichage d’une erreur sur `401`, puis stockage des données
publiques `user.id`, `user.role` et `user.username` avant redirection.

Créer `Register.vue` avec `username`, `email`, `password`, appel vers
`/api/auth/sign_up`, puis redirection vers `/sign_in` en cas de succès. Le mot de
passe ne doit jamais être conservé après la requête.

### 4. Dashboard et navigation

- Créer `Dashboard.vue` et afficher l’identifiant, le nom et le rôle publics.
- Rediriger depuis le dashboard vers l’espace correspondant au rôle.
- Ajouter `Unauthorized.vue` avec un lien de retour.
- Remplacer les valeurs statiques de `App.vue` par l’utilisateur connecté.
- Ajouter un bouton de déconnexion visible dans le header.
- Masquer les liens manager/admin selon `role`.
- Utiliser l’identifiant stocké uniquement pour construire les URLs de l’espace
  utilisateur, puis vérifier aussi les autorisations côté backend.

### 5. Déconnexion

La fonction `signOut()` doit appeler `POST /api/auth/sign_out` avec les cookies,
supprimer les données locales (`userId`, `role`, `username`) et rediriger vers
`/sign_in`. Le cookie `auth_token` est supprimé par le backend, pas par JavaScript.

## Sécurité à respecter

- Ne jamais stocker le mot de passe dans `localStorage`, un cookie JavaScript ou
  un store persistant.
- Ne jamais stocker le JWT `auth_token` dans `localStorage`.
- Ne jamais faire confiance au seul rôle stocké côté frontend pour sécuriser une
  opération : le backend doit contrôler le cookie de session et le rôle.
- Utiliser HTTPS en production.
- En développement, vérifier la configuration `Secure` des cookies : avec le
  backend actuel, des cookies `Secure` ne seront normalement pas envoyés sur
  `http://localhost`. Il faut soit lancer HTTPS localement, soit désactiver
  `secure` uniquement en développement.

## Prérequis backend à vérifier avant le test final

Le frontend ne peut pas compenser ces points :

- le pipeline API doit vérifier le cookie `auth_token` avant les routes protégées ;
- le backend doit valider le header `x-xsrf-token` pour les requêtes mutantes ;
- les contrôles de rôle doivent être effectués côté serveur ;
- les cookies doivent être compatibles avec l’environnement local et la
  production (`Secure`, `SameSite`, domaine et HTTPS) ;
- si le frontend est servi sur une autre origine en production, CORS doit autoriser
  l’origine exacte et les credentials.

## Scénarios de validation

1. Inscription avec un `username`, un email valide et un mot de passe de huit
   caractères minimum.
2. Connexion : vérifier la réponse `user`, le cookie `auth_token` HTTP-only et le
   cookie `c-xsrf-token`.
3. Rafraîchissement : rester sur une route protégée tant que la session cookie est
   valide et que l’état local est présent.
4. Accès à `/admin` avec un rôle `employee` : obtenir `/unauthorized`.
5. Déconnexion : vérifier l’appel API, la suppression des cookies par le serveur
   et le retour vers `/sign_in`.
6. DevTools > Network : vérifier `withCredentials` et `x-xsrf-token` sur les
   requêtes mutantes.
7. DevTools > Application : vérifier `auth_token` HTTP-only et l’absence de mot de
   passe/JWT dans `localStorage`.
8. Tester aussi un `401` et une erreur d’email déjà utilisé.

## Commandes de développement

Depuis `frontend/` :

```bash
npm install
npm run dev
npm run build
npm run lint
```

Le serveur frontend utilise le proxy `/api` vers `http://localhost:4000`.
