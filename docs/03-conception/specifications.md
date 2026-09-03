# Spécifications techniques — Dictionnaire de données & MPD
## [ NOM APP ] — Anime & Manga Tracker

---

## 1. Dictionnaire de données

### Table USER

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `user_id` | `SERIAL` | PK, NOT NULL | Identifiant unique auto-incrémenté |
| `pseudo` | `VARCHAR(30)` | NOT NULL, UNIQUE | Nom d'utilisateur affiché publiquement |
| `email` | `VARCHAR(255)` | NOT NULL, UNIQUE | Adresse email — utilisée pour la connexion |
| `password` | `VARCHAR(255)` | NOT NULL | Mot de passe haché avec BCrypt |
| `profile_picture` | `VARCHAR(500)` | NULL | URL de l'image de profil |
| `bio` | `TEXT` | NULL | Description courte visible sur le profil public |
| `role` | `VARCHAR(10)` | NOT NULL, DEFAULT 'USER' | Rôle de l'utilisateur : `USER` ou `ADMIN` |
| `is_public` | `BOOLEAN` | NOT NULL, DEFAULT TRUE | Profil visible publiquement |
| `is_banned` | `BOOLEAN` | NOT NULL, DEFAULT FALSE | Compte banni — accès bloqué |
| `created_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date de création du compte |
| `updated_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date de dernière modification du profil |

---

### Table ANIME

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `anime_id` | `SERIAL` | PK, NOT NULL | Identifiant unique auto-incrémenté |
| `title` | `VARCHAR(255)` | NOT NULL | Titre en français ou international |
| `original_title` | `VARCHAR(255)` | NULL | Titre original en japonais/romanisé |
| `nb_episodes` | `INTEGER` | NULL | Nombre total d'épisodes (null si inconnu) |
| `status` | `VARCHAR(20)` | NOT NULL | Statut de diffusion : `EN_COURS`, `TERMINE`, `ANNULE` |
| `release_year` | `INTEGER` | NULL | Année de première diffusion |
| `studio` | `VARCHAR(100)` | NULL | Studio d'animation (ex: MAPPA, Bones, Toei) |
| `image_url` | `VARCHAR(500)` | NULL | URL de l'affiche/cover |
| `synopsis` | `TEXT` | NULL | Résumé de l'anime |
| `created_by` | `INTEGER` | FK → USER.user_id, NOT NULL | Admin ayant créé l'entrée |
| `created_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date de création dans la BDD |
| `updated_by` | `INTEGER` | FK → USER.user_id, NULL | Admin ayant effectué la dernière modification |
| `updated_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date de dernière modification |

---

### Table MANGA

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `manga_id` | `SERIAL` | PK, NOT NULL | Identifiant unique auto-incrémenté |
| `title` | `VARCHAR(255)` | NOT NULL | Titre en français ou international |
| `original_title` | `VARCHAR(255)` | NULL | Titre original en japonais/romanisé |
| `nb_volumes` | `INTEGER` | NULL | Nombre total de tomes (null si en cours) |
| `nb_chapters` | `INTEGER` | NULL | Nombre total de chapitres (null si en cours) |
| `author` | `VARCHAR(100)` | NULL | Auteur du manga (mangaka) |
| `publisher` | `VARCHAR(100)` | NULL | Éditeur original japonais (ex: Shueisha, Kodansha) |
| `local_publisher` | `VARCHAR(100)` | NULL | Éditeur francophone (ex: Kazé, Glénat) |
| `status` | `VARCHAR(20)` | NOT NULL | Statut de publication : `EN_COURS`, `TERMINE`, `ANNULE` |
| `release_year` | `INTEGER` | NULL | Année de première publication |
| `image_url` | `VARCHAR(500)` | NULL | URL de la couverture |
| `synopsis` | `TEXT` | NULL | Résumé du manga |
| `created_by` | `INTEGER` | FK → USER.user_id, NOT NULL | Admin ayant créé l'entrée |
| `created_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date de création dans la BDD |
| `updated_by` | `INTEGER` | FK → USER.user_id, NULL | Admin ayant effectué la dernière modification |
| `updated_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date de dernière modification |

---

### Table GENRE

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `genre_id` | `SERIAL` | PK, NOT NULL | Identifiant unique auto-incrémenté |
| `name` | `VARCHAR(50)` | NOT NULL, UNIQUE | Nom du genre (ex: Action, Romance, Shonen) |
| `created_by` | `INTEGER` | FK → USER.user_id, NOT NULL | Admin ayant créé le genre |
| `created_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date de création |
| `updated_by` | `INTEGER` | FK → USER.user_id, NULL | Admin ayant modifié le genre |
| `updated_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date de dernière modification |

---

### Table ANIME_TRACKING

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `id` | `SERIAL` | PK, NOT NULL | Identifiant unique auto-incrémenté |
| `user_id` | `INTEGER` | FK → USER.user_id, NOT NULL | Utilisateur propriétaire du tracking |
| `anime_id` | `INTEGER` | FK → ANIME.anime_id, NOT NULL | Anime suivi |
| `status` | `VARCHAR(20)` | NOT NULL | Statut de visionnage : `EN_COURS`, `TERMINE`, `ABANDONNE`, `A_VOIR` |
| `current_episode` | `INTEGER` | NULL, DEFAULT 0 | Épisode actuel (0 si A_VOIR) |
| `score` | `INTEGER` | NULL, CHECK (score BETWEEN 1 AND 10) | Note personnelle de 1 à 10 |
| `notes` | `TEXT` | NULL | Notes et impressions personnelles |
| `is_favorite` | `BOOLEAN` | NOT NULL, DEFAULT FALSE | Marqué comme favori |
| `started_date` | `DATE` | NULL | Date de début de visionnage |
| `ending_date` | `DATE` | NULL | Date de fin de visionnage |
| `created_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date d'ajout à la liste |
| `updated_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date de dernière mise à jour |

**Contrainte unique :** `(user_id, anime_id)` — un utilisateur ne peut avoir qu'un tracking par anime.

---

### Table MANGA_TRACKING

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `id` | `SERIAL` | PK, NOT NULL | Identifiant unique auto-incrémenté |
| `user_id` | `INTEGER` | FK → USER.user_id, NOT NULL | Utilisateur propriétaire du tracking |
| `manga_id` | `INTEGER` | FK → MANGA.manga_id, NOT NULL | Manga suivi |
| `status` | `VARCHAR(20)` | NOT NULL | Statut de lecture : `EN_COURS`, `TERMINE`, `ABANDONNE`, `A_VOIR` |
| `current_volume` | `INTEGER` | NULL, DEFAULT 0 | Tome actuel (0 si A_VOIR) |
| `current_chapter` | `INTEGER` | NULL, DEFAULT 0 | Chapitre actuel |
| `score` | `INTEGER` | NULL, CHECK (score BETWEEN 1 AND 10) | Note personnelle de 1 à 10 |
| `notes` | `TEXT` | NULL | Notes et impressions personnelles |
| `is_favorite` | `BOOLEAN` | NOT NULL, DEFAULT FALSE | Marqué comme favori |
| `started_date` | `DATE` | NULL | Date de début de lecture |
| `ending_date` | `DATE` | NULL | Date de fin de lecture |
| `created_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date d'ajout à la liste |
| `updated_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Date de dernière mise à jour |

**Contrainte unique :** `(user_id, manga_id)` — un utilisateur ne peut avoir qu'un tracking par manga.

---

### Table ANIME_GENRE

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `anime_id` | `INTEGER` | FK → ANIME.anime_id, NOT NULL | Référence à l'anime |
| `genre_id` | `INTEGER` | FK → GENRE.genre_id, NOT NULL | Référence au genre |

**Clé primaire composite :** `(anime_id, genre_id)`

---

### Table MANGA_GENRE

| Champ | Type SQL | Contraintes | Description |
|---|---|---|---|
| `manga_id` | `INTEGER` | FK → MANGA.manga_id, NOT NULL | Référence au manga |
| `genre_id` | `INTEGER` | FK → GENRE.genre_id, NOT NULL | Référence au genre |

**Clé primaire composite :** `(manga_id, genre_id)`

---

## 2. MPD — Script SQL (CREATE TABLE)

```sql
-- ============================================================
-- [ NOM APP ] — Modèle Physique de Données
-- PostgreSQL 17
-- ============================================================

-- Table USER
CREATE TABLE "user" (
    user_id         SERIAL          PRIMARY KEY,
    pseudo          VARCHAR(30)     NOT NULL UNIQUE,
    email           VARCHAR(255)    NOT NULL UNIQUE,
    password        VARCHAR(255)    NOT NULL,
    profile_picture VARCHAR(500),
    bio             TEXT,
    role            VARCHAR(10)     NOT NULL DEFAULT 'USER',
    is_public       BOOLEAN         NOT NULL DEFAULT TRUE,
    is_banned       BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_role CHECK (role IN ('USER', 'ADMIN'))
);

-- Table ANIME
CREATE TABLE anime (
    anime_id        SERIAL          PRIMARY KEY,
    title           VARCHAR(255)    NOT NULL,
    original_title  VARCHAR(255),
    nb_episodes     INTEGER,
    status          VARCHAR(20)     NOT NULL,
    release_year    INTEGER,
    studio          VARCHAR(100),
    image_url       VARCHAR(500),
    synopsis        TEXT,
    created_by      INTEGER         NOT NULL REFERENCES "user"(user_id),
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_by      INTEGER         REFERENCES "user"(user_id),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_anime_status CHECK (status IN ('EN_COURS', 'TERMINE', 'ANNULE'))
);

-- Table MANGA
CREATE TABLE manga (
    manga_id        SERIAL          PRIMARY KEY,
    title           VARCHAR(255)    NOT NULL,
    original_title  VARCHAR(255),
    nb_volumes      INTEGER,
    nb_chapters     INTEGER,
    author          VARCHAR(100),
    publisher       VARCHAR(100),
    local_publisher VARCHAR(100),
    status          VARCHAR(20)     NOT NULL,
    release_year    INTEGER,
    image_url       VARCHAR(500),
    synopsis        TEXT,
    created_by      INTEGER         NOT NULL REFERENCES "user"(user_id),
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_by      INTEGER         REFERENCES "user"(user_id),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_manga_status CHECK (status IN ('EN_COURS', 'TERMINE', 'ANNULE'))
);

-- Table GENRE
CREATE TABLE genre (
    genre_id    SERIAL          PRIMARY KEY,
    name        VARCHAR(50)     NOT NULL UNIQUE,
    created_by  INTEGER         NOT NULL REFERENCES "user"(user_id),
    created_at  TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_by  INTEGER         REFERENCES "user"(user_id),
    updated_at  TIMESTAMP       NOT NULL DEFAULT NOW()
);

-- Table ANIME_GENRE
CREATE TABLE anime_genre (
    anime_id    INTEGER     NOT NULL REFERENCES anime(anime_id) ON DELETE CASCADE,
    genre_id    INTEGER     NOT NULL REFERENCES genre(genre_id) ON DELETE CASCADE,
    PRIMARY KEY (anime_id, genre_id)
);

-- Table MANGA_GENRE
CREATE TABLE manga_genre (
    manga_id    INTEGER     NOT NULL REFERENCES manga(manga_id) ON DELETE CASCADE,
    genre_id    INTEGER     NOT NULL REFERENCES genre(genre_id) ON DELETE CASCADE,
    PRIMARY KEY (manga_id, genre_id)
);

-- Table ANIME_TRACKING
CREATE TABLE anime_tracking (
    id              SERIAL          PRIMARY KEY,
    user_id         INTEGER         NOT NULL REFERENCES "user"(user_id) ON DELETE CASCADE,
    anime_id        INTEGER         NOT NULL REFERENCES anime(anime_id) ON DELETE CASCADE,
    status          VARCHAR(20)     NOT NULL,
    current_episode INTEGER         DEFAULT 0,
    score           INTEGER         CHECK (score BETWEEN 1 AND 10),
    notes           TEXT,
    is_favorite     BOOLEAN         NOT NULL DEFAULT FALSE,
    started_date    DATE,
    ending_date     DATE,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_anime_tracking UNIQUE (user_id, anime_id),
    CONSTRAINT chk_anime_tracking_status CHECK (status IN ('EN_COURS', 'TERMINE', 'ABANDONNE', 'A_VOIR')),
    CONSTRAINT chk_anime_dates CHECK (ending_date IS NULL OR started_date IS NULL OR ending_date >= started_date)
);

-- Table MANGA_TRACKING
CREATE TABLE manga_tracking (
    id              SERIAL          PRIMARY KEY,
    user_id         INTEGER         NOT NULL REFERENCES "user"(user_id) ON DELETE CASCADE,
    manga_id        INTEGER         NOT NULL REFERENCES manga(manga_id) ON DELETE CASCADE,
    status          VARCHAR(20)     NOT NULL,
    current_volume  INTEGER         DEFAULT 0,
    current_chapter INTEGER         DEFAULT 0,
    score           INTEGER         CHECK (score BETWEEN 1 AND 10),
    notes           TEXT,
    is_favorite     BOOLEAN         NOT NULL DEFAULT FALSE,
    started_date    DATE,
    ending_date     DATE,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_manga_tracking UNIQUE (user_id, manga_id),
    CONSTRAINT chk_manga_tracking_status CHECK (status IN ('EN_COURS', 'TERMINE', 'ABANDONNE', 'A_VOIR')),
    CONSTRAINT chk_manga_dates CHECK (ending_date IS NULL OR started_date IS NULL OR ending_date >= started_date)
);

-- ============================================================
-- Index pour optimiser les requêtes fréquentes
-- ============================================================
CREATE INDEX idx_anime_tracking_user ON anime_tracking(user_id);
CREATE INDEX idx_manga_tracking_user ON manga_tracking(user_id);
CREATE INDEX idx_anime_title ON anime(title);
CREATE INDEX idx_manga_title ON manga(title);
CREATE INDEX idx_user_pseudo ON "user"(pseudo);
```
