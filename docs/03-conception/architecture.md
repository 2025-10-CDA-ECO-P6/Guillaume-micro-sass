# Architecture technique
## [ NOM APP ] — Anime & Manga Tracker

---

## 1. Vue d'ensemble

L'application suit une architecture **client-serveur découplée** en trois couches distinctes :

```
┌─────────────────────┐        HTTP/REST       ┌──────────────────────┐        JDBC       ┌──────────────────┐
│      FRONTEND       │ ─────────────────────► │       BACKEND        │ ────────────────► │    BASE DE       │
│    Angular 20       │       JSON (DTO)        │   Spring Boot 3.4   │   Hibernate/JPA   │    DONNÉES       │
│    Port 4200        │ ◄───────────────────── │      Port 8080       │ ◄──────────────── │  PostgreSQL 17   │
└─────────────────────┘                        └──────────────────────┘                   │    Port 5432     │
                                                        │                                  └──────────────────┘
                                                 Spring Security
                                                 JWT Validation
                                                 Role-based Access
```

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

## 3. Backend — Spring Boot 3.4

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
src/main/java/com/nomapp/
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
| Spring Boot 3.4 | Standard industrie, auto-configuration, démarrage rapide |
| Java 21 LTS | Version LTS stable, Virtual Threads disponibles |
| Spring Security + JWT | Authentification stateless, gestion fine des rôles |
| Hibernate / JPA | ORM standard Java, intégré à Spring Boot |
| MapStruct | Mapping Entity ↔ DTO rapide et typé |
| Lombok | Réduction du boilerplate (getters, setters, constructeurs) |
| Springdoc OpenAPI | Documentation API auto-générée, interface Swagger UI |

---

## 4. Base de données — PostgreSQL 17

### Rôle
Stockage relationnel normalisé. 8 tables dérivées du MLD.

### Schéma simplifié
```
USER ──────────────┬──── ANIME_TRACKING ──── ANIME ──── ANIME_GENRE ──── GENRE
                   │                                                         │
                   └──── MANGA_TRACKING ──── MANGA ──── MANGA_GENRE ─────────┘
```

### Migrations Flyway
```
resources/db/migration/
├── V1__create_tables.sql       # Création des 8 tables
├── V2__insert_genres.sql       # Données initiales genres
└── V3__insert_sample_data.sql  # Données de test (dev uniquement)
```

### Choix techniques justifiés
| Choix | Justification |
|---|---|
| PostgreSQL 17 | Robuste, open-source, excellente gestion des relations complexes |
| Flyway | Versioning du schéma, traçabilité des migrations, intégré à Spring Boot |
| Pas de triggers | Simplicité : la logique est dans les services Java |

---

## 5. Infrastructure — Docker

### Docker Compose (développement)
```yaml
services:
  frontend:     # Angular, port 4200
  backend:      # Spring Boot, port 8080
  database:     # PostgreSQL, port 5432
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
     │                          Spring Security vérifie le rôle
     │◄── { data: [...] } ─────────────│
```

### Règles d'accès par endpoint
| Pattern | Accès |
|---|---|
| `/auth/**` | Public |
| `/api/catalogue/**` (GET) | Public |
| `/api/profile/:pseudo` (GET) | Public si `is_public=true` |
| `/api/dashboard/**` | Authentifié |
| `/api/tracking/**` | Authentifié (propriétaire uniquement) |
| `/api/admin/**` | Admin uniquement |

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
| 409 | Conflit (email déjà utilisé...) |
| 500 | Erreur serveur |

---

## 8. Variables d'environnement

```env
# Backend
DB_URL=jdbc:postgresql://localhost:5432/nomapp
DB_USERNAME=nomapp_user
DB_PASSWORD=****
JWT_SECRET=****
JWT_EXPIRATION=86400000

# Frontend
API_URL=http://localhost:8080/api
```
