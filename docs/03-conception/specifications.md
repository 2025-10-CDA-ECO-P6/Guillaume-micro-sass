# Spécifications techniques — Dictionnaire de données & MPD
## Nakama — Anime & Manga Tracker

---

Modèle v2 : 9 tables, PostgreSQL 17. Il couvre les trois types de relations exigés : **1-1** (`users` ↔ `user_profiles`), **1-N** (`users` → `anime_tracking`, `manga_tracking`), **N-N** (`animes` ↔ `genres` via `anime_genres`, `mangas` ↔ `genres` via `manga_genres`).

Diagrammes : `docs/03-conception/mcd/MCD-v2.png` et `MLD-v2.png`.

---

## 1. Règles de nommage

- Tables : anglais, pluriel, snake_case (`users`, `anime_tracking`). `user` est un mot réservé PostgreSQL, d'où le pluriel.
- Tables de jonction : les deux noms accolés (`anime_genres`).
- Colonnes : snake_case ; clé primaire `id` ; clé étrangère `<table au singulier>_id` ; booléens préfixés `is_` ; audit `created_at` / `updated_at`, `created_by` / `updated_by`.
- Contraintes et objets nommés : `pk_`, `fk_<table>_<colonne>`, `uk_`, `ck_`, `idx_`, `fn_` (fonctions), `trg_` (triggers). Un nom lisible rend l'erreur lisible : « violates uk_users_email » se comprend sans chercher.
- Valeurs d'énumération : majuscules sans accent (`EN_COURS`, `A_VOIR`), identiques aux enums Java (`@Enumerated(EnumType.STRING)`).

---

## 2. Dictionnaire de données

### Table `users`

Compte de connexion, chargé par Spring Security.

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `id` | `BIGSERIAL` | PK | Identifiant auto-incrémenté |
| `username` | `VARCHAR(30)` | NOT NULL, UNIQUE | Pseudo affiché publiquement (URL du profil) |
| `email` | `VARCHAR(255)` | NOT NULL, UNIQUE | Identifiant de connexion |
| `password_hash` | `VARCHAR(60)` | NOT NULL | Mot de passe haché BCrypt (coût 12), jamais en clair |
| `role` | `VARCHAR(20)` | NOT NULL, DEFAULT 'USER', CHECK (USER, MODERATOR, ADMIN) | Rôle Spring Security |
| `is_banned` | `BOOLEAN` | NOT NULL, DEFAULT FALSE, CHECK (un ADMIN ne peut pas être banni) | Compte bloqué : connexion refusée en 403 |
| `created_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date d'inscription (« Membre depuis ») |
| `updated_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW(), trigger | Dernière modification |

---

### Table `user_profiles`

Vitrine publique du compte. Relation 1-1 avec users : user_id est à la fois PK et FK.

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `user_id` | `BIGINT` | PK, FK → users.id ON DELETE CASCADE | Compte propriétaire ; garantit un seul profil par user |
| `avatar_url` | `VARCHAR(500)` | NULL | Chemin ou URL de l'avatar |
| `bio` | `TEXT` | NULL | Présentation libre |
| `is_public` | `BOOLEAN` | NOT NULL, DEFAULT TRUE | Profil visible par les visiteurs |
| `favorite_genre_id` | `BIGINT` | NULL, FK → genres.id ON DELETE SET NULL | Genre préféré affiché sur le profil |
| `updated_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW(), trigger | Dernière modification |

---

### Table `animes`

Catalogue des animes, géré par les modérateurs.

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `id` | `BIGSERIAL` | PK | Identifiant auto-incrémenté |
| `title` | `VARCHAR(255)` | NOT NULL, index trigrammes | Titre français ou international |
| `original_title` | `VARCHAR(255)` | NULL | Titre japonais |
| `synopsis` | `TEXT` | NULL | Résumé |
| `image_url` | `VARCHAR(500)` | NULL | Affiche |
| `trailer_url` | `VARCHAR(500)` | NULL | Lien vers le trailer (Could Have) |
| `nb_episodes` | `INTEGER` | NULL, CHECK > 0 | Nombre d'épisodes ; NULL si inconnu |
| `status` | `VARCHAR(20)` | NOT NULL, DEFAULT 'A_VENIR', CHECK (A_VENIR, EN_COURS, TERMINE, ANNULE) | État de diffusion |
| `release_year` | `SMALLINT` | NULL, CHECK 1900 à 2100 | Année de première diffusion |
| `studio` | `VARCHAR(100)` | NULL | Studio d'animation |
| `created_by` | `BIGINT` | NULL, FK → users.id ON DELETE SET NULL, non modifiable (trigger) | Modérateur qui a créé la fiche |
| `created_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date de création |
| `updated_by` | `BIGINT` | NULL, FK → users.id ON DELETE SET NULL | Dernier modérateur à l'avoir modifiée |
| `updated_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW(), trigger | Dernière modification |
| `version` | `INTEGER` | NOT NULL, DEFAULT 0 | Verrou optimiste (@Version JPA) |

---

### Table `mangas`

Catalogue des mangas, géré par les modérateurs.

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `id` | `BIGSERIAL` | PK | Identifiant auto-incrémenté |
| `title` | `VARCHAR(255)` | NOT NULL, index trigrammes | Titre français ou international |
| `original_title` | `VARCHAR(255)` | NULL | Titre japonais |
| `synopsis` | `TEXT` | NULL | Résumé |
| `image_url` | `VARCHAR(500)` | NULL | Couverture |
| `trailer_url` | `VARCHAR(500)` | NULL | Lien vers une bande-annonce (Could Have) |
| `nb_volumes` | `INTEGER` | NULL, CHECK > 0 | Nombre de tomes ; NULL si en cours |
| `nb_chapters` | `INTEGER` | NULL, CHECK > 0 | Nombre de chapitres ; NULL si en cours |
| `author` | `VARCHAR(150)` | NULL | Mangaka |
| `publisher` | `VARCHAR(150)` | NULL | Éditeur japonais |
| `local_publisher` | `VARCHAR(150)` | NULL | Éditeur français |
| `status` | `VARCHAR(20)` | NOT NULL, DEFAULT 'A_VENIR', CHECK (A_VENIR, EN_COURS, TERMINE, ANNULE) | État de publication |
| `release_year` | `SMALLINT` | NULL, CHECK 1900 à 2100 | Année de première publication |
| `created_by` | `BIGINT` | NULL, FK → users.id ON DELETE SET NULL, non modifiable (trigger) | Modérateur qui a créé la fiche |
| `created_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date de création |
| `updated_by` | `BIGINT` | NULL, FK → users.id ON DELETE SET NULL | Dernier modérateur à l'avoir modifiée |
| `updated_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW(), trigger | Dernière modification |
| `version` | `INTEGER` | NOT NULL, DEFAULT 0 | Verrou optimiste (@Version JPA) |

---

### Table `genres`

Liste des genres, partagée par les animes et les mangas.

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `id` | `BIGSERIAL` | PK | Identifiant auto-incrémenté |
| `name` | `VARCHAR(50)` | NOT NULL, UNIQUE | Nom affiché (« Slice of Life ») |
| `slug` | `VARCHAR(60)` | NOT NULL, UNIQUE | Version URL (« slice-of-life ») pour les filtres |
| `created_by` | `BIGINT` | NULL, FK → users.id ON DELETE SET NULL, non modifiable (trigger) | Créateur |
| `created_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date de création |
| `updated_by` | `BIGINT` | NULL, FK → users.id ON DELETE SET NULL | Dernier éditeur |
| `updated_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW(), trigger | Dernière modification |
| `version` | `INTEGER` | NOT NULL, DEFAULT 0 | Verrou optimiste (@Version JPA) |

---

### Table `anime_genres`

Table de jonction : relation N-N entre animes et genres.

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `anime_id` | `BIGINT` | PK (avec genre_id), FK → animes.id ON DELETE CASCADE | L'anime |
| `genre_id` | `BIGINT` | PK (avec anime_id), FK → genres.id ON DELETE CASCADE | Le genre lié |

---

### Table `manga_genres`

Table de jonction : relation N-N entre mangas et genres.

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `manga_id` | `BIGINT` | PK (avec genre_id), FK → mangas.id ON DELETE CASCADE | Le manga |
| `genre_id` | `BIGINT` | PK (avec manga_id), FK → genres.id ON DELETE CASCADE | Le genre lié |

---

### Table `anime_tracking`

Suivi d'un anime par un user. Relation 1-N depuis users. Contrainte unique (user_id, anime_id).

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `id` | `BIGSERIAL` | PK | Identifiant de l'entrée de suivi |
| `user_id` | `BIGINT` | NOT NULL, FK → users.id ON DELETE CASCADE | Qui suit |
| `anime_id` | `BIGINT` | NOT NULL, FK → animes.id ON DELETE CASCADE | Ce qui est suivi |
| `status` | `VARCHAR(20)` | NOT NULL, DEFAULT 'A_VOIR', CHECK (EN_COURS, TERMINE, ABANDONNE, A_VOIR) | Statut de visionnage |
| `current_episode` | `INTEGER` | NOT NULL, DEFAULT 0, CHECK ≥ 0, ≤ nb_episodes (trigger) | Dernier épisode vu |
| `score` | `SMALLINT` | NULL, CHECK 1 à 10 | Note personnelle ; NULL si pas notée |
| `notes` | `TEXT` | NULL | Impressions personnelles |
| `is_favorite` | `BOOLEAN` | NOT NULL, DEFAULT FALSE | Coup de cœur |
| `started_date` | `DATE` | NULL | Début du visionnage |
| `ending_date` | `DATE` | NULL, CHECK ≥ started_date | Fin du visionnage |
| `created_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Ajout à la liste |
| `updated_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW(), trigger | Dernière mise à jour |
| `version` | `INTEGER` | NOT NULL, DEFAULT 0 | Verrou optimiste (@Version JPA) |

---

### Table `manga_tracking`

Suivi d'un manga par un user. Relation 1-N depuis users. Contrainte unique (user_id, manga_id).

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `id` | `BIGSERIAL` | PK | Identifiant de l'entrée de suivi |
| `user_id` | `BIGINT` | NOT NULL, FK → users.id ON DELETE CASCADE | Qui suit |
| `manga_id` | `BIGINT` | NOT NULL, FK → mangas.id ON DELETE CASCADE | Ce qui est suivi |
| `status` | `VARCHAR(20)` | NOT NULL, DEFAULT 'A_VOIR', CHECK (EN_COURS, TERMINE, ABANDONNE, A_VOIR) | Statut de lecture |
| `current_volume` | `INTEGER` | NOT NULL, DEFAULT 0, CHECK ≥ 0, ≤ nb_volumes (trigger) | Dernier tome lu |
| `current_chapter` | `INTEGER` | NOT NULL, DEFAULT 0, CHECK ≥ 0, ≤ nb_chapters (trigger) | Dernier chapitre lu |
| `score` | `SMALLINT` | NULL, CHECK 1 à 10 | Note personnelle ; NULL si pas noté |
| `notes` | `TEXT` | NULL | Impressions personnelles |
| `is_favorite` | `BOOLEAN` | NOT NULL, DEFAULT FALSE | Coup de cœur |
| `started_date` | `DATE` | NULL | Début de la lecture |
| `ending_date` | `DATE` | NULL, CHECK ≥ started_date | Fin de la lecture |
| `created_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Ajout à la liste |
| `updated_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW(), trigger | Dernière mise à jour |
| `version` | `INTEGER` | NOT NULL, DEFAULT 0 | Verrou optimiste (@Version JPA) |

---

## 3. Règles vérifiées par la base

Les services Java valident chaque règle (message clair pour l'utilisateur). La base les revérifie, pour qu'une donnée invalide soit refusée même si un contrôle Java est oublié.

| Règle du cahier des charges | Garantie en base |
|---|---|
| Un user ne suit un anime/manga qu'une fois | `UNIQUE (user_id, anime_id)`, `UNIQUE (user_id, manga_id)` |
| Score entre 1 et 10 | `CHECK` |
| `ending_date` ≥ `started_date` | `CHECK` |
| `current_episode` ≤ `nb_episodes`, `current_volume` ≤ `nb_volumes` | Triggers `trg_anime_tracking_progress`, `trg_manga_tracking_progress` (un CHECK ne compare pas deux tables) |
| `updated_at` mis à jour à chaque modification | Trigger `fn_set_updated_at` sur les 7 tables concernées |
| `created_by` jamais modifié | Trigger `fn_protect_created_by` (seul le passage à NULL, à la suppression du créateur, est permis) |
| Un admin ne peut pas être banni | `CHECK (NOT (role = 'ADMIN' AND is_banned))` |
| Suppression de compte (RGPD) | `ON DELETE CASCADE` sur profil et suivis, `ON DELETE SET NULL` sur le catalogue |

Restent dans les services Java, car elles dépendent de l'utilisateur connecté ou de plusieurs lignes : au moins un genre par œuvre, un admin ne se supprime pas lui-même, minimum 3 contenus pour les recommandations.

---

## 4. Index

| Index | Pourquoi |
|---|---|
| PK et UNIQUE (automatiques) | Recherche par id, unicité email/pseudo, et `user_id` en tête des UNIQUE de suivi |
| `idx_anime_tracking_anime`, `idx_manga_tracking_manga` | Jointure œuvre → suivis (stats, recommandations) |
| `idx_anime_genres_genre`, `idx_manga_genres_genre` | Recherche par genre (filtres, recommandations) |
| `idx_animes_title_trgm`, `idx_mangas_title_trgm` (GIN, `pg_trgm`) | Recherche « contient » `ILIKE '%titan%'`, qu'un index B-tree ne sait pas accélérer |

---

## 5. MPD — Script SQL

Le script ci-dessous est la copie de `backend/src/main/resources/db/migration/V1__create_tables.sql`, exécuté par Flyway. Les triggers sont dans `V2__create_triggers.sql`.

```sql
-- =============================================================================
-- Nakama — V1__create_tables.sql
-- Migration Flyway initiale : crée les 9 tables du modèle de données v2.
--
-- Ordre de création : une table doit exister avant qu'une autre la référence.
--   1. users            (référencée par presque tout)
--   2. genres           (référencée par user_profiles et les jonctions)
--   3. user_profiles    (1-1 avec users)
--   4. animes, mangas   (catalogue)
--   5. anime_genres, manga_genres     (N-N)
--   6. anime_tracking, manga_tracking (1-N depuis users)
--
-- Conventions :
--   - tables au pluriel en snake_case (« user » est un mot réservé PostgreSQL)
--   - ENUM Java stockés en VARCHAR + CHECK (compatible @Enumerated(EnumType.STRING)),
--     valeurs du cahier des charges (EN_COURS, TERMINE, ABANDONNE, A_VOIR ; score 1 à 10)
--   - created_at rempli par la base, updated_at mis à jour par trigger (voir V2)
--   - version : verrou optimiste. Deux modifications simultanées de la même
--     ligne ne s'écrasent pas : la seconde échoue (HTTP 409) au lieu de perdre
--     silencieusement la première.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. users : ce qui sert à se connecter (chargé par Spring Security)
-- -----------------------------------------------------------------------------
CREATE TABLE users (
    id              BIGSERIAL       PRIMARY KEY,
    username        VARCHAR(30)     NOT NULL,
    email           VARCHAR(255)    NOT NULL,
    password_hash   VARCHAR(60)     NOT NULL,              -- BCrypt = 60 caractères
    role            VARCHAR(20)     NOT NULL DEFAULT 'USER',
    is_banned       BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_users_username UNIQUE (username),
    CONSTRAINT uk_users_email    UNIQUE (email),
    CONSTRAINT ck_users_role     CHECK (role IN ('USER', 'MODERATOR', 'ADMIN')),
    -- Règle du CDC : un admin ne peut pas être banni (donc pas par un autre admin)
    CONSTRAINT ck_users_admin_not_banned CHECK (NOT (role = 'ADMIN' AND is_banned))
);


-- -----------------------------------------------------------------------------
-- 2. genres : liste partagée par les animes et les mangas
-- -----------------------------------------------------------------------------
CREATE TABLE genres (
    id              BIGSERIAL       PRIMARY KEY,
    name            VARCHAR(50)     NOT NULL,
    slug            VARCHAR(60)     NOT NULL,              -- ex. "slice-of-life", pour les URL
    created_by      BIGINT,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version         INTEGER         NOT NULL DEFAULT 0,      -- verrou optimiste (@Version JPA)

    CONSTRAINT uk_genres_name UNIQUE (name),
    CONSTRAINT uk_genres_slug UNIQUE (slug),
    CONSTRAINT fk_genres_created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT fk_genres_updated_by FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL
);


-- -----------------------------------------------------------------------------
-- 3. user_profiles : relation 1-1 avec users
--    user_id est à la fois PK et FK : un user ne peut avoir qu'un seul profil.
-- -----------------------------------------------------------------------------
CREATE TABLE user_profiles (
    user_id             BIGINT          CONSTRAINT pk_user_profiles PRIMARY KEY,
    avatar_url          VARCHAR(500),
    bio                 TEXT,
    is_public           BOOLEAN         NOT NULL DEFAULT TRUE,
    favorite_genre_id   BIGINT,
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_user_profiles_user           FOREIGN KEY (user_id)           REFERENCES users (id)  ON DELETE CASCADE,
    CONSTRAINT fk_user_profiles_favorite_genre FOREIGN KEY (favorite_genre_id) REFERENCES genres (id) ON DELETE SET NULL
);


-- -----------------------------------------------------------------------------
-- 4a. animes : catalogue
-- -----------------------------------------------------------------------------
CREATE TABLE animes (
    id              BIGSERIAL       PRIMARY KEY,
    title           VARCHAR(255)    NOT NULL,
    original_title  VARCHAR(255),
    synopsis        TEXT,
    image_url       VARCHAR(500),
    trailer_url     VARCHAR(500),                          -- Could Have du CDC
    nb_episodes     INTEGER,                               -- NULL = inconnu (anime en cours)
    status          VARCHAR(20)     NOT NULL DEFAULT 'A_VENIR',
    release_year    SMALLINT,
    studio          VARCHAR(100),
    created_by      BIGINT,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version         INTEGER         NOT NULL DEFAULT 0,      -- verrou optimiste (@Version JPA)

    CONSTRAINT ck_animes_status       CHECK (status IN ('A_VENIR', 'EN_COURS', 'TERMINE', 'ANNULE')),
    CONSTRAINT ck_animes_nb_episodes  CHECK (nb_episodes IS NULL OR nb_episodes > 0),
    CONSTRAINT ck_animes_release_year CHECK (release_year IS NULL OR release_year BETWEEN 1900 AND 2100),
    CONSTRAINT fk_animes_created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT fk_animes_updated_by FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL
);


-- -----------------------------------------------------------------------------
-- 4b. mangas : catalogue
-- -----------------------------------------------------------------------------
CREATE TABLE mangas (
    id              BIGSERIAL       PRIMARY KEY,
    title           VARCHAR(255)    NOT NULL,
    original_title  VARCHAR(255),
    synopsis        TEXT,
    image_url       VARCHAR(500),
    trailer_url     VARCHAR(500),                          -- Could Have du CDC
    nb_volumes      INTEGER,
    nb_chapters     INTEGER,
    author          VARCHAR(150),
    publisher       VARCHAR(150),                          -- éditeur japonais
    local_publisher VARCHAR(150),                          -- éditeur français
    status          VARCHAR(20)     NOT NULL DEFAULT 'A_VENIR',
    release_year    SMALLINT,
    created_by      BIGINT,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version         INTEGER         NOT NULL DEFAULT 0,      -- verrou optimiste (@Version JPA)

    CONSTRAINT ck_mangas_status       CHECK (status IN ('A_VENIR', 'EN_COURS', 'TERMINE', 'ANNULE')),
    CONSTRAINT ck_mangas_nb_volumes   CHECK (nb_volumes IS NULL OR nb_volumes > 0),
    CONSTRAINT ck_mangas_nb_chapters  CHECK (nb_chapters IS NULL OR nb_chapters > 0),
    CONSTRAINT ck_mangas_release_year CHECK (release_year IS NULL OR release_year BETWEEN 1900 AND 2100),
    CONSTRAINT fk_mangas_created_by FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT fk_mangas_updated_by FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE SET NULL
);


-- -----------------------------------------------------------------------------
-- 5a. anime_genres : relation N-N animes <-> genres
--     La PK composée empêche de lier deux fois le même genre au même anime.
-- -----------------------------------------------------------------------------
CREATE TABLE anime_genres (
    anime_id        BIGINT          NOT NULL,
    genre_id        BIGINT          NOT NULL,

    CONSTRAINT pk_anime_genres PRIMARY KEY (anime_id, genre_id),
    CONSTRAINT fk_anime_genres_anime FOREIGN KEY (anime_id) REFERENCES animes (id) ON DELETE CASCADE,
    CONSTRAINT fk_anime_genres_genre FOREIGN KEY (genre_id) REFERENCES genres (id) ON DELETE CASCADE
);


-- -----------------------------------------------------------------------------
-- 5b. manga_genres : relation N-N mangas <-> genres
-- -----------------------------------------------------------------------------
CREATE TABLE manga_genres (
    manga_id        BIGINT          NOT NULL,
    genre_id        BIGINT          NOT NULL,

    CONSTRAINT pk_manga_genres PRIMARY KEY (manga_id, genre_id),
    CONSTRAINT fk_manga_genres_manga FOREIGN KEY (manga_id) REFERENCES mangas (id) ON DELETE CASCADE,
    CONSTRAINT fk_manga_genres_genre FOREIGN KEY (genre_id) REFERENCES genres (id) ON DELETE CASCADE
);


-- -----------------------------------------------------------------------------
-- 6a. anime_tracking : relation 1-N depuis users (et depuis animes)
--     UNIQUE (user_id, anime_id) : un user ne suit un anime qu'une seule fois.
-- -----------------------------------------------------------------------------
CREATE TABLE anime_tracking (
    id              BIGSERIAL       PRIMARY KEY,
    user_id         BIGINT          NOT NULL,
    anime_id        BIGINT          NOT NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'A_VOIR',
    current_episode INTEGER         NOT NULL DEFAULT 0,
    score           SMALLINT,                              -- NULL = pas encore noté
    notes           TEXT,
    is_favorite     BOOLEAN         NOT NULL DEFAULT FALSE,
    started_date    DATE,
    ending_date     DATE,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version         INTEGER         NOT NULL DEFAULT 0,      -- verrou optimiste (@Version JPA)

    CONSTRAINT uk_anime_tracking_user_anime UNIQUE (user_id, anime_id),
    CONSTRAINT ck_anime_tracking_status  CHECK (status IN ('EN_COURS', 'TERMINE', 'ABANDONNE', 'A_VOIR')),
    CONSTRAINT ck_anime_tracking_episode CHECK (current_episode >= 0),
    CONSTRAINT ck_anime_tracking_score   CHECK (score IS NULL OR score BETWEEN 1 AND 10),
    CONSTRAINT ck_anime_tracking_dates   CHECK (ending_date IS NULL OR started_date IS NULL OR ending_date >= started_date),
    CONSTRAINT fk_anime_tracking_user  FOREIGN KEY (user_id)  REFERENCES users (id)  ON DELETE CASCADE,
    CONSTRAINT fk_anime_tracking_anime FOREIGN KEY (anime_id) REFERENCES animes (id) ON DELETE CASCADE
);


-- -----------------------------------------------------------------------------
-- 6b. manga_tracking : relation 1-N depuis users (et depuis mangas)
-- -----------------------------------------------------------------------------
CREATE TABLE manga_tracking (
    id              BIGSERIAL       PRIMARY KEY,
    user_id         BIGINT          NOT NULL,
    manga_id        BIGINT          NOT NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'A_VOIR',
    current_volume  INTEGER         NOT NULL DEFAULT 0,
    current_chapter INTEGER         NOT NULL DEFAULT 0,
    score           SMALLINT,
    notes           TEXT,
    is_favorite     BOOLEAN         NOT NULL DEFAULT FALSE,
    started_date    DATE,
    ending_date     DATE,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version         INTEGER         NOT NULL DEFAULT 0,      -- verrou optimiste (@Version JPA)

    CONSTRAINT uk_manga_tracking_user_manga UNIQUE (user_id, manga_id),
    CONSTRAINT ck_manga_tracking_status  CHECK (status IN ('EN_COURS', 'TERMINE', 'ABANDONNE', 'A_VOIR')),
    CONSTRAINT ck_manga_tracking_volume  CHECK (current_volume >= 0),
    CONSTRAINT ck_manga_tracking_chapter CHECK (current_chapter >= 0),
    CONSTRAINT ck_manga_tracking_score   CHECK (score IS NULL OR score BETWEEN 1 AND 10),
    CONSTRAINT ck_manga_tracking_dates   CHECK (ending_date IS NULL OR started_date IS NULL OR ending_date >= started_date),
    CONSTRAINT fk_manga_tracking_user  FOREIGN KEY (user_id)  REFERENCES users (id)  ON DELETE CASCADE,
    CONSTRAINT fk_manga_tracking_manga FOREIGN KEY (manga_id) REFERENCES mangas (id) ON DELETE CASCADE
);


-- -----------------------------------------------------------------------------
-- 7. Index sur les clés étrangères
--    PostgreSQL indexe automatiquement les PK et les UNIQUE, pas les FK.
--    Une FK déjà en tête d'une PK ou d'un UNIQUE (ex. anime_tracking.user_id)
--    est donc couverte ; on indexe seulement les autres, utilisées en jointure.
-- -----------------------------------------------------------------------------
CREATE INDEX idx_anime_tracking_anime ON anime_tracking (anime_id);
CREATE INDEX idx_manga_tracking_manga ON manga_tracking (manga_id);
CREATE INDEX idx_anime_genres_genre   ON anime_genres (genre_id);
CREATE INDEX idx_manga_genres_genre   ON manga_genres (genre_id);


-- -----------------------------------------------------------------------------
-- 8. Recherche par titre (US-10)
--    La recherche « contient » (ILIKE '%naruto%') ne peut pas utiliser un index
--    B-tree classique : il ne sait chercher que par le début du texte.
--    L'extension pg_trgm découpe les titres en trigrammes ("nar", "aru", ...)
--    et un index GIN sur ces trigrammes accélère ILIKE '%...%'.
--    pg_trgm est une extension « trusted » : le propriétaire de la base
--    (nakama_migration) peut l'activer sans être superuser.
-- -----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_animes_title_trgm ON animes USING gin (title gin_trgm_ops);
CREATE INDEX idx_mangas_title_trgm ON mangas USING gin (title gin_trgm_ops);
```
