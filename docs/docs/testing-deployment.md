---
title: Tests, conteneurs et déploiement
sidebar_position: 9
---

# Tests, conteneurs et déploiement

## Tests

### Backend

Depuis `time_manager/` :

```bash
mix test
```

L’alias de test crée/migre la base de test. PostgreSQL doit être disponible. Les tests couvrent les contextes de comptes, pointage et périodes, ainsi que plusieurs contrôleurs.

### Frontend

Depuis `frontend/` :

```bash
npm test
npm run build
```

Vitest exécute les tests sous `frontend/test/unit/`. Le script `lint` configure les linters avec `--fix`; il peut modifier des fichiers.

### Documentation

Depuis `docs/`, `npm run build` compile le site Docusaurus et échoue sur les liens de docs brisés.

## Conteneurs

`docker-compose.yml` définit trois services :

- `db` : PostgreSQL 15, persistance nommée `pgdata`;
- `api` : release Phoenix, dépend de la santé de la base et expose le port 4000 au réseau interne;
- `front` : frontend statique servi par Nginx sur le port hôte 8080.

Les Dockerfiles se trouvent dans `time_manager/Dockerfile` et `frontend/Dockerfile`. Nginx route les appels `/api` vers le service backend.

## CI Travis

`.travis.yml` déclare les jobs de tests backend et frontend, puis des étapes de construction/publication des images et de déploiement sur push de `main`. Les secrets de CI doivent être configurés dans Travis, jamais committés. La présence de la configuration ne garantit pas qu’une exécution récente ait réussi.

## Démarrer en production

Le runtime Phoenix exige ses variables de configuration (URL DB, clés de signature/secrets). L’entrypoint du conteneur applique les migrations avant la release. Vérifier TLS, reverse proxy et sauvegardes PostgreSQL dans l’environnement cible; ils ne sont pas tous décrits par Compose.