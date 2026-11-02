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
