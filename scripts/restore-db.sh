#!/bin/bash
# =============================================================================
# Nakama — restauration d'une sauvegarde
# Usage : ./scripts/restore-db.sh backups/nakama_20261102_093000.dump
# ATTENTION : remplace tout le contenu actuel de la base.
# =============================================================================
set -euo pipefail
source .env

FILE="${1:?Usage : $0 <fichier.dump>}"
[ -f "$FILE" ] || { echo "Fichier introuvable : $FILE"; exit 1; }

read -r -p "Remplacer le contenu de la base $POSTGRES_DB par $FILE ? (oui/non) " OK
[ "$OK" = "oui" ] || { echo "Annulé."; exit 0; }

# --clean --if-exists : supprime les objets existants avant de les recréer
# --single-transaction : tout ou rien, la base n'est jamais laissée à moitié restaurée
docker compose exec -T database pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
    --clean --if-exists --single-transaction --no-owner --role=nakama_migration < "$FILE"

echo "Restauration OK depuis $FILE"
