# Planning & Milestones
## [ NOM APP ] — Anime & Manga Tracker

---

## Roadmap — 8 Milestones

| Milestone | Objectif | Contenu |
|---|---|---|
| **M1 — Cadrage** | Toute la conception validée | CDC, MCD, MLD, UML, Wireframes desktop + mobile, Personas, Charte, Architecture |
| **M2 — Setup** | Environnement de développement prêt | Docker Compose, PostgreSQL + Flyway, Angular 20 init, Spring Boot init, CI/CD |
| **M3 — Auth** | Authentification end-to-end fonctionnelle | Register, Login, Logout, JWT, Guards Angular, BCrypt |
| **M4 — Catalogue** | Catalogue consultable et administrable | CRUD Admin, recherche, filtres, page détail |
| **M5 — Tracking** | Suivi de progression fonctionnel | ANIME_TRACKING, MANGA_TRACKING, Dashboard, filtres par statut |
| **M6 — Profils** | Profils utilisateurs complets | Profil public, Settings, toggle is_public, suppression de compte |
| **M7 — Recommandations** | Algorithme de recommandation | Logique SQL par genre, page recommandations, onboarding |
| **M8 — Finalisation** | Qualité & déploiement | Tests unitaires, corrections, documentation API Swagger, déploiement Docker |

---

## M1 — Cadrage (✅ Terminé)

| Livrable | Statut |
|---|---|
| Expression du besoin | ✅ |
| Cahier des charges (MoSCoW, parcours, règles métier) | ✅ |
| MCD MERISE | ✅ |
| MLD | ✅ |
| UML (cas d'utilisation) | ✅ |
| Dictionnaire de données + MPD SQL | ✅ |
| Architecture technique | ✅ |
| Sécurité (JWT, BCrypt, RGPD) | ✅ |
| Wireframes desktop (8 écrans) | ✅ |
| Wireframes mobile (8 écrans) | ✅ |
| Personas (4) | ✅ |
| Charte graphique + Logo | ✅ |
| Slides de présentation | ✅ |
| README.md | ✅ |

---

## M2 — Setup

| Tâche | Priorité |
|---|---|
| Initialiser le projet Spring Boot 3.4 | Must Have |
| Initialiser le projet Angular 20 | Must Have |
| Configurer Docker + Docker Compose | Must Have |
| Initialiser PostgreSQL avec Flyway (V1__create_tables.sql) | Must Have |
| Configurer ESLint + Prettier (frontend) | Must Have |
| Configurer les environnements dev / prod | Must Have |
| Configurer Springdoc OpenAPI / Swagger UI | Should Have |
| Configurer GitHub Actions CI/CD | Could Have |

---

## M3 — Authentification

| Tâche | Priorité |
|---|---|
| Endpoint POST /auth/register | Must Have |
| Endpoint POST /auth/login → retour JWT | Must Have |
| Endpoint POST /auth/logout | Must Have |
| Hachage BCrypt des mots de passe | Must Have |
| JwtFilter Spring Security | Must Have |
| Guard Angular (AuthGuard, AdminGuard) | Must Have |
| Intercepteur HTTP pour le token | Must Have |
| Gestion des erreurs 401/403 côté frontend | Must Have |

---

## M4 — Catalogue

| Tâche | Priorité |
|---|---|
| GET /api/catalogue/animes (liste paginée) | Must Have |
| GET /api/catalogue/animes/:id (détail) | Must Have |
| GET /api/catalogue/mangas (liste paginée) | Must Have |
| GET /api/catalogue/mangas/:id (détail) | Must Have |
| GET /api/catalogue/search?q=&type=&genre= | Must Have |
| POST /api/admin/animes (créer) | Must Have |
| PUT /api/admin/animes/:id (modifier) | Must Have |
| DELETE /api/admin/animes/:id (supprimer) | Must Have |
| CRUD identique pour mangas et genres | Must Have |
| Page Search (frontend) | Must Have |
| Page Détail (frontend) | Must Have |
| Page Admin Catalogue (frontend) | Must Have |

---

## M5 — Tracking

| Tâche | Priorité |
|---|---|
| POST /api/tracking/anime (ajouter à la liste) | Must Have |
| PUT /api/tracking/anime/:id (mettre à jour) | Must Have |
| DELETE /api/tracking/anime/:id (supprimer) | Must Have |
| CRUD identique pour manga tracking | Must Have |
| GET /api/dashboard (stats + listes par statut) | Must Have |
| Modale de mise à jour (frontend) | Must Have |
| Dashboard complet (frontend) | Must Have |
| Filtres par statut | Should Have |
| Toggle is_favorite | Should Have |

---

## M6 — Profils

| Tâche | Priorité |
|---|---|
| GET /api/profile/:pseudo (profil public) | Must Have |
| PUT /api/profile (modifier son profil) | Should Have |
| PATCH /api/profile/visibility (toggle is_public) | Should Have |
| DELETE /api/profile (supprimer son compte) | Must Have |
| Page Profil public (frontend) | Must Have |
| Page Settings (frontend) | Should Have |

---

## M7 — Recommandations

| Tâche | Priorité |
|---|---|
| GET /api/recommendations (algo SQL par genre) | Should Have |
| Logique : genres des contenus scorés ≥ 7 | Should Have |
| Exclusion des contenus déjà dans la liste | Should Have |
| Page Recommandations (frontend) | Should Have |
| Message d'onboarding si < 3 contenus scorés | Should Have |

---

## M8 — Finalisation

| Tâche | Priorité |
|---|---|
| Tests unitaires backend (JUnit + Mockito) | Should Have |
| Tests unitaires frontend (Jasmine) | Should Have |
| Correction des bugs identifiés | Must Have |
| Documentation API Swagger UI complète | Should Have |
| Déploiement Docker en production | Must Have |
| Revue de sécurité finale | Must Have |
