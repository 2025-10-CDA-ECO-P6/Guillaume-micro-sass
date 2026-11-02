#!/bin/bash
# =============================================================================
# Nakama — sauvegarde de la base (pg_dump, format custom compressé)
# Usage : ./scripts/backup-db.sh            -> backups/nakama_AAAAMMJJ_HHMMSS.dump
# Lancé depuis la racine du projet, conteneur "database" démarré (docker compose up -d database).
# =============================================================================
set -euo pipefail
source .env

mkdir -p backups
FILE="backups/nakama_$(date +%Y%m%d_%H%M%S).dump"

# -Fc : format custom (compressé, restauration sélective possible avec pg_restore)
docker compose exec -T database pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc > "$FILE"

# Une sauvegarde vide ou illisible ne vaut rien : on vérifie qu'elle se relit.
docker compose exec -T database pg_restore --list < "$FILE" > /dev/null
echo "Sauvegarde OK : $FILE ($(du -h "$FILE" | cut -f1))"

# On garde les 7 dernières sauvegardes
ls -1t backups/nakama_*.dump | tail -n +8 | xargs -r rm --
