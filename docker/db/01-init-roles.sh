#!/bin/bash
# =============================================================================
# Nakama — création des comptes PostgreSQL (principe du moindre privilège)
#
# Monté par docker-compose.yml dans le conteneur database (docker-entrypoint-initdb.d)
# Exécuté UNE seule fois, au premier démarrage du volume de données.
#
# 3 comptes, 3 usages :
#   - POSTGRES_USER (superuser) : administration, sauvegardes. Jamais utilisé par l'appli.
#   - nakama_migration : propriétaire du schéma, utilisé par Flyway pour créer/modifier les tables.
#   - nakama_app       : utilisé par Spring Boot à l'exécution. Lit et écrit des lignes,
#                        mais ne peut ni créer, ni modifier, ni supprimer une table.
# Si l'API est compromise (injection SQL par exemple), l'attaquant ne peut pas faire
# DROP TABLE ni lire d'autres bases : il n'a que les droits de nakama_app.
#
# Les mots de passe viennent des variables d'environnement (fichier .env, jamais commité).
# =============================================================================
set -euo pipefail

: "${NAKAMA_MIGRATION_PASSWORD:?Variable NAKAMA_MIGRATION_PASSWORD manquante}"
: "${NAKAMA_APP_PASSWORD:?Variable NAKAMA_APP_PASSWORD manquante}"

psql -v ON_ERROR_STOP=1 \
     --username "$POSTGRES_USER" \
     --dbname "$POSTGRES_DB" \
     -v db="$POSTGRES_DB" \
     -v migration_pwd="$NAKAMA_MIGRATION_PASSWORD" \
     -v app_pwd="$NAKAMA_APP_PASSWORD" <<'EOSQL'

-- Comptes de connexion (mots de passe stockés en SCRAM-SHA-256, défaut PostgreSQL 14+)
CREATE ROLE nakama_migration LOGIN PASSWORD :'migration_pwd';
CREATE ROLE nakama_app       LOGIN PASSWORD :'app_pwd';

-- Personne d'autre que les comptes prévus ne se connecte à la base
REVOKE ALL ON DATABASE :"db" FROM PUBLIC;
GRANT CONNECT ON DATABASE :"db" TO nakama_migration, nakama_app;

-- Flyway devient propriétaire de la base : il peut créer les tables dans public
ALTER DATABASE :"db" OWNER TO nakama_migration;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO nakama_app;

-- Droits par défaut : chaque table que Flyway créera sera accessible à l'appli
-- en lecture/écriture de lignes uniquement (pas de TRUNCATE, ALTER, DROP).
ALTER DEFAULT PRIVILEGES FOR ROLE nakama_migration IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO nakama_app;
ALTER DEFAULT PRIVILEGES FOR ROLE nakama_migration IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO nakama_app;

EOSQL

echo "Comptes nakama_migration et nakama_app créés."
