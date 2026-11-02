# Architecture technique
## Nakama — Anime & Manga Tracker

---

## 1. Vue d'ensemble

L'application suit une architecture **client-serveur découplée** en trois couches distinctes :

```
┌─────────────────────┐        HTTP/REST       ┌──────────────────────┐        JDBC       ┌──────────────────┐
│      FRONTEND       │ ─────────────────────► │       BACKEND        │ ────────────────► │    BASE DE       │
│    Angular 20       │       JSON (DTO)        │   Spring Boot 4.0    │   Hibernate/JPA   │    DONNÉES       │
│    Port 4200        │ ◄───────────────────── │      Port 8080       │ ◄──────────────── │  PostgreSQL 17   │
└─────────────────────┘                        └──────────────────────┘                   │    Port 5432     │
                                                   │            │                         └──────────────────┘
                                            Spring Security     │  Lettuce
                                            JWT Validation      ▼
                                            Role-based Access  ┌──────────────────┐
                                                               │      REDIS 7     │
                                                               │ liste noire JWT  │
                                                               │ (réseau interne) │
                                                               └──────────────────┘
```

Une quatrième brique, **Redis** (base NoSQL clé/valeur), stocke les tokens révoqués au logout. Elle n'est joignable que par le backend.

---

## 2. Frontend — Angular 20

### Rôle
Interface utilisateur responsive (desktop + mobile), consomme l'API REST du backend via `HttpClient`.

### Structure des modules
```
src/
├── app/
│   ├── core/              # Services singleton, intercepteurs, guards
│   │   ├── auth/          # AuthService, JwtInterceptor
│   │   ├── guards/        # AuthGuard, AdminGuard
│   │   └── interceptors/  # TokenInterceptor
│   ├── shared/            # Composants et pipes réutilisables
│   │   ├── components/    # Card, Modal, Button...
│   │   └── pipes/         # StatusPipe, ScorePipe
│   ├── features/          # Modules fonctionnels
│   │   ├── auth/          # Login, Register
│   │   ├── dashboard/     # Dashboard utilisateur
│   │   ├── catalogue/     # Search, Detail
│   │   ├── tracking/      # Formulaire de progression
│   │   ├── profile/       # Profil public, Settings
│   │   └── admin/         # Admin catalogue, users, genres
│   └── app.routes.ts      # Routing principal
```

### Choix techniques justifiés
| Choix | Justification |
|---|---|
| Angular 20 (LTS) | Version stable avec Signals, TypeScript natif, utilisée en entreprise |
| Signals | Gestion d'état réactive sans librairie tierce |
| Standalone components | Architecture moderne, suppression des NgModules |
| TailwindCSS 4 | Productivité UI, responsive facilité, pas de CSS custom à gérer |
| Angular Router | Routing natif avec lazy loading par feature |

---

## 3. Backend — Spring Boot 4.0

### Rôle
API REST stateless, gestion des règles métier, authentification JWT, accès base de données via Hibernate/JPA.

### Architecture en couches
```
Controller (REST)
     │
     ▼
Service (métier)
     │
     ▼
Repository (JPA)
     │
     ▼
Entity (Hibernate) → PostgreSQL
```

### Structure des packages
```
src/main/java/com/nakama/backend/
├── config/           # SecurityConfig, JwtConfig, SwaggerConfig
├── controller/       # REST controllers
│   ├── AuthController
│   ├── AnimeController
│   ├── MangaController
│   ├── TrackingController
│   ├── ProfileController
│   └── AdminController
├── service/          # Logique métier
├── repository/       # Interfaces JPA
├── entity/           # Entités Hibernate
├── dto/              # Data Transfer Objects
│   ├── request/      # DTOs entrants (CreateAnimeDto...)
│   └── response/     # DTOs sortants (AnimeResponseDto...)
├── mapper/           # MapStruct : Entity ↔ DTO
├── security/         # JwtUtil, JwtFilter, UserDetailsService
└── exception/        # GlobalExceptionHandler
```

### Choix techniques justifiés
| Choix | Justification |
|---|---|
| Spring Boot 4.0 | Standard industrie, auto-configuration, démarrage rapide |
| Java 21 LTS | Version LTS stable, Virtual Threads disponibles |
| Spring Security + JWT | Authentification stateless, gestion fine des rôles |
| Hibernate / JPA | ORM standard Java, intégré à Spring Boot |
| MapStruct | Mapping Entity ↔ DTO rapide et typé |
| Lombok | Réduction du boilerplate (getters, setters, constructeurs) |
| Springdoc OpenAPI | Documentation API auto-générée, interface Swagger UI |

---

## 4. Base de données — PostgreSQL 17

### Rôle
Stockage relationnel normalisé. 9 tables dérivées du MLD, couvrant les trois types de relations : 1-1 (`users` ↔ `user_profiles`), 1-N (`users` → `anime_tracking`), N-N (`animes` ↔ `genres` via `anime_genres`).

### Schéma simplifié
```
user_profiles ── users ──┬── anime_tracking ── animes ── anime_genres ── genres
      (1-1)              │                                                │
                         └── manga_tracking ── mangas ── manga_genres ────┘
```

### Migrations Flyway
```
resources/db/
├── migration/
│   ├── V1__create_tables.sql     # 9 tables, contraintes, index
│   └── V2__create_triggers.sql   # updated_at auto, progression ≤ total, created_by figé
└── seed/
    └── R__seed_test_data.sql     # jeu d'essai, chargé seulement avec le profil dev
```

### Choix techniques justifiés
| Choix | Justification |
|---|---|
| PostgreSQL 17 | Robuste, open-source, excellente gestion des relations complexes |
| Flyway | Versioning du schéma, traçabilité des migrations, intégré à Spring Boot |
| Triggers PL/pgSQL ciblés | Les règles métier sont dans les services Java ; la base les revérifie (défense en profondeur) pour 3 règles qu'un CHECK ne peut pas exprimer |
| Verrou optimiste (`version`) | Deux modifications simultanées d'une même ligne : la seconde échoue en `409` au lieu d'écraser la première |
| Deux comptes PostgreSQL | Flyway (`nakama_migration`) crée le schéma, l'appli (`nakama_app`) ne lit et n'écrit que des lignes |
| Redis 7 | Liste noire des JWT révoqués, avec expiration automatique |

---

## 5. Infrastructure — Docker

### Docker Compose (développement)
```yaml
services:
  frontend:     # Angular, port 4200
  backend:      # Spring Boot, port 8080
  database:     # PostgreSQL 17, port 5432 (127.0.0.1 uniquement)
  redis:        # Redis 7, non exposé (réseau interne)
```

### Avantages
- Reproductibilité : même environnement sur toutes les machines
- Isolation : pas de conflit entre versions installées localement
- Démarrage en une commande : `docker compose up`

---

## 6. Sécurité — Architecture JWT

```
Client Angular                  Backend Spring Boot
     │                                  │
     │── POST /auth/login ─────────────►│
     │                          Vérifie email + mdp (BCrypt)
     │◄── { token: "eyJ..." } ─────────│
     │                                  │
     │── GET /api/dashboard ───────────►│
     │   Header: Authorization: Bearer eyJ...
     │                          JwtFilter valide le token
     │                          + vérifie qu'il n'est pas dans Redis
     │                          Spring Security vérifie le rôle
     │◄── { data: [...] } ─────────────│
     │                                  │
     │── POST /auth/logout ────────────►│
     │                          jti du token → Redis (TTL = temps restant)
     │◄── 204 No Content ──────────────│
```

### Règles d'accès par endpoint
| Pattern | Accès |
|---|---|
| `/auth/**` | Public |
| `/api/catalogue/**` (GET) | Public |
| `/api/profile/:pseudo` (GET) | Public si `is_public=true` |
| `/api/dashboard/**` | Authentifié |
| `/api/tracking/**` | Authentifié (propriétaire uniquement) |
| `/api/admin/catalogue/**`, `/api/admin/genres/**` | Modérateur ou Admin |
| `/api/admin/users/**` | Admin uniquement |

---

## 7. Communication Frontend ↔ Backend

### Format des échanges
- **Format :** JSON
- **Authentification :** Bearer Token (JWT) dans le header `Authorization`
- **Codes HTTP utilisés :**

| Code | Usage |
|---|---|
| 200 | Succès |
| 201 | Création réussie |
| 400 | Données invalides |
| 401 | Non authentifié |
| 403 | Non autorisé (rôle insuffisant ou is_banned) |
| 404 | Ressource introuvable |
| 409 | Conflit (email déjà utilisé, modification concurrente...) |
| 500 | Erreur serveur |

---

## 8. Variables d'environnement

Toutes les valeurs sont dans `.env` (modèle : `.env.example`, seul fichier commité).

```env
# PostgreSQL
POSTGRES_DB=nakama
POSTGRES_USER=****               # superuser, admin et sauvegardes
POSTGRES_PASSWORD=****
NAKAMA_MIGRATION_PASSWORD=****   # compte Flyway
NAKAMA_APP_PASSWORD=****         # compte de l'application

# Redis
REDIS_PASSWORD=****

# JWT
JWT_SECRET=****                  # openssl rand -base64 48
JWT_EXPIRATION=86400000          # 24 h

# Profil Spring : dev (avec jeu d'essai) ou prod
SPRING_PROFILES_ACTIVE=dev

# Frontend
API_URL=http://localhost:8080/api
```
