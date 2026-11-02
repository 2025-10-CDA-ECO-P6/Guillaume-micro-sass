# Nakama — Anime & Manga Tracker 🎌

> *"Ne perds plus le fil, suis ta passion."*

---

## 📋 Présentation du projet

**Nakama** est un Micro-SaaS de suivi de progression anime et manga, entièrement en français. Il permet à chaque utilisateur de gérer sa liste personnelle, suivre sa progression épisode par épisode ou tome par tome, et organiser ses contenus par statut.

Contrairement aux solutions existantes (MyAnimeList, AniList), Nakama est pensé pour la **communauté francophone** : interface en français, simple, sans surcharge de fonctionnalités.

---

## 🎯 Problème identifié

Les fans d'anime et manga francophones n'ont pas d'outil dédié en français pour suivre leur progression. Les plateformes existantes sont en anglais, peu accessibles aux débutants, et surchargées de fonctionnalités inutiles.

**Résultat :** les utilisateurs perdent le fil, oublient où ils en sont, et se retrouvent spoilés ou découragés.

---

## 👥 Public cible

- Fans d'anime et manga **francophones** (15–35 ans)
- Débutants dans la culture japonaise cherchant un outil simple
- Collectionneurs souhaitant tracker leur progression de lecture physique

---

## ⭐ Fonctionnalité principale

> Suivre sa progression sur chaque anime/manga : statut (En cours / Terminé / Abandonné / À voir), épisode ou tome en cours, score et notes.

---

## ➕ Fonctionnalités secondaires

| Fonctionnalité | Description |
|---|---|
| Recherche & ajout | Rechercher un anime/manga et l'ajouter à sa liste |
| Dashboard personnel | Vue d'ensemble avec stats (nb épisodes vus, terminés...) |
| Filtres | Filtrer par statut, type (anime/manga), genre |
| **Recommandations** | **Suggestions personnalisées basées sur les genres les mieux notés par l'utilisateur** |
| Profil public | Chaque profil est consultable en lecture par n'importe quel visiteur |
| Confidentialité | Option `is_public` (table `user_profiles`) pour passer son profil en privé |

> 💡 **Logique de recommandation :** à partir des genres des animes/mangas auxquels l'utilisateur a attribué un score élevé, le système suggère d'autres contenus bien notés des mêmes genres, absents de sa liste. Pas de machine learning — une logique métier SQL ciblée et efficace.

> 🔒 **Modèle de visibilité :** tous les champs d'un profil (statut, progression, score, notes) sont publics en lecture par défaut. Seul le propriétaire peut modifier ses données. Un booléen `is_public` sur `user_profiles` permet de masquer entièrement son profil si l'utilisateur le souhaite.

### Ce que l'application ne fait PAS (périmètre Micro-SaaS)
- ❌ Forum / communauté
- ❌ Fonctionnalités sociales avancées (follows, likes, commentaires sur les profils)
- ❌ Recommandations par intelligence artificielle

---

## 🛠️ Stack technique

| Couche | Technologie | Justification |
|---|---|---|
| **Frontend** | Angular 20 | Version LTS stable, TypeScript natif, composants réutilisables, Signals stables |
| **Backend** | Java 21 · Spring Boot 4.0 | Robuste, API REST, très utilisé en entreprise |
| **Base de données** | PostgreSQL 17 + Flyway | Modèle relationnel normalisé, migrations versionnées |
| **Cache NoSQL** | Redis 7 | Liste noire des JWT révoqués au logout (clé/valeur avec expiration) |
| **Authentification** | Spring Security + JWT + BCrypt | Gestion des rôles USER / MODERATOR / ADMIN |
| **ORM** | Hibernate / JPA | Mapping objet-relationnel avec Spring Boot |
| **Conteneurs** | Docker Compose | 4 services : frontend, backend, database, redis |

---

## 🗃️ Modélisation des données

### MCD (Modèle Conceptuel de Données — MERISE)

Le MCD comporte **5 entités** et **8 associations** :

| Entité | Rôle |
|---|---|
| `USER` | Compte de connexion (pseudo, email, mot de passe haché, rôle, banni) |
| `PROFILE` | Vitrine publique du compte (avatar, bio, is_public, genre favori) |
| `ANIME` | Catalogue des animes |
| `MANGA` | Catalogue des mangas |
| `GENRE` | Liste des genres partagés |

**Associations :**
- `USER` (1,1) — **owns** — (1,1) `PROFILE` → relation **1-1**
- `USER` (0,n) — **tracks** — (0,n) `ANIME` *(porteuse : status, current_episode, score, notes, is_favorite, dates)* → table `anime_tracking`, relation **1-N** depuis `users`
- `USER` (0,n) — **tracks** — (0,n) `MANGA` *(porteuse : status, current_volume, current_chapter, score, notes, is_favorite, dates)*
- `ANIME` (1,n) — **has** — (0,n) `GENRE` → relation **N-N**, table `anime_genres`
- `MANGA` (1,n) — **has** — (0,n) `GENRE` → table `manga_genres`
- `PROFILE` (0,1) — **prefers** — (0,n) `GENRE`
- `USER` (0,n) — **manages** — (0,1) `ANIME` / `MANGA` / `GENRE` → `created_by`, `updated_by`

📎 *Voir `docs/03-conception/mcd/MCD-v2.png`*

### MLD / MPD (Modèle Logique et Physique)

Le MLD comporte **9 tables** :

`users` · `user_profiles` · `animes` · `mangas` · `genres` · `anime_genres` · `manga_genres` · `anime_tracking` · `manga_tracking`

- Le script de création est `backend/src/main/resources/db/migration/V1__create_tables.sql` (Flyway).
- Les triggers (updated_at automatique, progression ≤ nombre d'épisodes/tomes, created_by non modifiable) sont dans `V2__create_triggers.sql`.
- Le jeu d'essai (profil dev uniquement) est dans `db/seed/R__seed_test_data.sql`.
- Le dictionnaire de données complet est dans `docs/03-conception/specifications.md`.

📎 *Voir `docs/03-conception/mcd/MLD-v2.png`*

---

## 📐 Diagramme de cas d'utilisation (UML)

Quatre acteurs liés par généralisation : chacun hérite des actions du précédent.

| Acteur | Actions propres |
|---|---|
| **Visiteur** (non connecté) | Rechercher, consulter une fiche, consulter un profil public, s'inscrire, se connecter |
| **User** (`ROLE_USER`) | Suivre un anime/manga, mettre à jour sa progression, dashboard, recommandations, modifier son profil, rendre son profil privé, supprimer son compte |
| **Modérateur** (`ROLE_MODERATOR`) | CRUD catalogue animes/mangas, gestion des genres |
| **Admin** (`ROLE_ADMIN`) | Gestion des utilisateurs (rôle, bannissement), statistiques |

📎 *Voir `docs/03-conception/mcd/UML.png`*

---

## 🖼️ Wireframes

8 écrans desktop et 8 écrans mobile, dans `docs/03-conception/maquettes/`. Les principaux :

| Écran | Fichier |
|---|---|
| Login / Register | `wireframe-login.svg` |
| Dashboard | `wireframe-dashboard.svg` |
| Recherche | `wireframe-search.svg` |
| Détail + modale progression | `wireframe-detail-v5.svg` |

📎 *Voir `docs/03-conception/maquettes/desktop` et `mobile`*

---

## 🎨 Charte graphique

| Élément | Valeur |
|---|---|
| **Couleur principale** | `#5B4FE9` — Violet |
| **Couleur accent** | `#FF6B35` — Orange |
| **Texte** | `#1A1A2E` — Nuit |
| **Surface** | `#F5F5F5` — Gris clair |
| **Background** | `#FFFFFF` — Blanc |
| **Typographie** | Inter (Regular 400, SemiBold 600, Bold 700) |
| **Style** | Flat · Minimaliste · Aéré |
| **Icônes** | Outline (Lucide / Tabler) |

📎 *Voir `docs/design/charte-graphique.pdf`*

---

## 📁 Structure du repository

```
/
├── README.md
├── docker-compose.yml          # 4 services : frontend, backend, database, redis
├── .env.example                # variables à copier dans .env (jamais commité)
├── backend/                    # Spring Boot (com.nakama.backend)
│   └── src/main/resources/
│       ├── application.yaml
│       └── db/
│           ├── migration/      # V1__create_tables.sql, V2__create_triggers.sql
│           └── seed/           # R__seed_test_data.sql (profil dev)
├── frontend/                   # Angular
├── docker/db/                  # 01-init-roles.sh (comptes PostgreSQL)
├── scripts/                    # backup-db.sh, restore-db.sh
└── docs/
    ├── 01-contexte/            # cahier des charges, expression du besoin
    ├── 02-gestion-projet/      # organisation, planning
    ├── 03-conception/          # architecture, spécifications, maquettes, mcd/
    ├── 04-securite/
    ├── 05-tests/
    ├── 06-deploiement/
    ├── 07-ecoconception/
    └── design/                 # charte graphique, logos
```

## 🚀 Lancer le projet

```bash
cp .env.example .env            # puis remplacer chaque valeur
docker compose up -d --build    # Flyway crée le schéma au démarrage du backend
./scripts/backup-db.sh          # sauvegarde de la base
```

---

## 👤 Auteur

Projet réalisé dans le cadre du titre **Concepteur Développeur d'Applications (CDA)** — 2025
