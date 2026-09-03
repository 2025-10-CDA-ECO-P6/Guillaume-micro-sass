# Cahier des charges fonctionnel & technique
## [ NOM APP ] — Anime & Manga Tracker

> *"Ne perds plus le fil, suis ta passion."*

---

## Partie 1 — Cadre fonctionnel

### 1. Présentation du projet

**Nom :** [ NOM APP ]
**Slogan :** "Ne perds plus le fil, suis ta passion."
**Type :** Application web Micro-SaaS responsive (desktop + mobile)

**Problématique :**
Les fans d'anime et manga francophones n'ont pas d'outil dédié en français pour suivre leur progression. Les solutions existantes (MyAnimeList, AniList) sont en anglais, peu accessibles aux débutants, et surchargées de fonctionnalités inutiles.

**Valeur principale :**
Permettre à chaque utilisateur francophone de gérer sa liste personnelle d'animes et mangas, suivre sa progression, et découvrir de nouveaux contenus via des recommandations personnalisées — le tout dans une interface simple et en français.

**Fonctionnalité centrale du MVP :**
Le suivi de progression : statut (En cours / Terminé / Abandonné / À voir), épisode ou tome actuel, score et notes personnelles.

---

### 2. Public cible

| Persona | Profil | Besoin principal |
|---|---|---|
| **Lucas, 17 ans** | Fan casual, lycéen, mobile-first | Interface simple en français, mise à jour rapide |
| **Camille, 26 ans** | Collectionneuse de mangas physiques | Suivi tome + chapitre, séparation anime/manga |
| **Théo, 23 ans** | Otaku confirmé, dev junior | Stats, recommandations pertinentes, profil public |
| **Alex, 29 ans** | Admin / créateur de l'app | Interface admin claire, CRUD catalogue, gestion users |

---

### 3. Périmètre fonctionnel — Méthode MoSCoW

#### Must Have — Indispensable au MVP

| Fonctionnalité | Description |
|---|---|
| Inscription / Connexion / Déconnexion | Authentification sécurisée par JWT |
| Suivi de progression anime | Statut, épisode actuel, score, notes, dates |
| Suivi de progression manga | Statut, tome + chapitre actuels, score, notes, dates |
| Dashboard personnel | Vue d'ensemble avec stats et listes par statut |
| Recherche de contenu | Recherche anime/manga par titre avec filtres |
| Ajout à la liste | Ajouter un anime/manga depuis le catalogue |
| Profil public | Profil consultable en lecture par tout visiteur |
| Admin — Gestion catalogue | CRUD complet sur les animes et mangas |
| Admin — Gestion utilisateurs | Consulter, bannir, modifier le rôle des users |
| Admin — Gestion genres | CRUD sur les genres |

#### Should Have — Important mais non bloquant

| Fonctionnalité | Description |
|---|---|
| Recommandations personnalisées | Suggestions basées sur les genres les mieux notés |
| Filtres avancés | Filtrer par statut, type (anime/manga), genre |
| Toggle profil privé/public | `is_public` pour masquer son profil |
| Favoris | `is_favorite` pour marquer un contenu |
| Mise à jour profil | Modifier pseudo, bio, avatar, mot de passe |

#### Could Have — Amélioration facultative

| Fonctionnalité | Description |
|---|---|
| Stats avancées | Temps total estimé, genres préférés, graphiques |
| Trailer URL | Lien vers le trailer d'un anime/manga |
| Pagination avancée | Tri par score, date d'ajout, alphabétique |

#### Won't Have — Hors périmètre actuel

| Fonctionnalité | Raison |
|---|---|
| Forum / communauté | Hors scope Micro-SaaS |
| Système de follows / amis | Trop complexe pour le MVP |
| Commentaires publics sur les profils | Modération complexe |
| App mobile native | Hors compétences actuelles |
| Recommandations par IA/ML | Over-engineering pour le MVP |
| Notifications push | Hors scope MVP |

---

### 4. Parcours utilisateurs

#### Parcours 1 — Inscription
**Acteur :** Visiteur
1. Accède à la page `/register`
2. Renseigne pseudo, email, mot de passe, confirmation
3. Soumet le formulaire
4. Compte créé → redirigé vers le dashboard
5. **Résultat :** Compte actif avec profil public par défaut

#### Parcours 2 — Connexion
**Acteur :** Utilisateur inscrit
1. Accède à `/login`
2. Saisit email + mot de passe
3. Reçoit un token JWT
4. Redirigé vers le dashboard
5. **Résultat :** Session active, accès à toutes les fonctionnalités User

#### Parcours 3 — Ajouter un anime à sa liste
**Acteur :** User connecté
1. Accède à la page Recherche
2. Tape le titre de l'anime
3. Clique sur la fiche de l'anime
4. Sur la page détail, clique sur "Mettre à jour"
5. Dans la modale : choisit le statut, l'épisode actuel, le score
6. Sauvegarde
7. **Résultat :** Entrée créée dans `ANIME_TRACKING`, visible sur le dashboard

#### Parcours 4 — Mettre à jour sa progression
**Acteur :** User connecté
1. Depuis le dashboard, clique sur une card "En cours"
2. Accède à la page détail
3. Clique sur "Mettre à jour"
4. Modifie l'épisode actuel dans la modale
5. Sauvegarde
6. **Résultat :** `ANIME_TRACKING.current_episode` mis à jour, `updated_at` rafraîchi

#### Parcours 5 — Consulter un profil public
**Acteur :** Visiteur ou User connecté
1. Accède à `/profile/:pseudo`
2. Si `is_public = true` → affichage de la liste, scores, notes
3. Si `is_public = false` → page "Profil privé"
4. **Résultat :** Consultation en lecture seule

#### Parcours 6 — Admin ajoute un anime au catalogue
**Acteur :** Admin connecté
1. Accède au panel admin `/admin/catalogue`
2. Clique sur "+ Ajouter entrée"
3. Remplit le formulaire (titre, studio, genres, synopsis...)
4. Valide
5. **Résultat :** Entrée créée dans `ANIME`, `created_by` = user_id de l'admin

#### Parcours 7 — Admin bannit un utilisateur
**Acteur :** Admin connecté
1. Accède à `/admin/users`
2. Recherche l'utilisateur
3. Clique sur 🚫
4. Confirme l'action
5. **Résultat :** `is_banned = true`, l'utilisateur ne peut plus se connecter

---

### 5. Règles métier

#### Authentification & Sécurité
- Un utilisateur banni (`is_banned = true`) ne peut pas se connecter → retour `403 Forbidden`
- Le token JWT expire après 24h
- Les mots de passe sont hashés avec **BCrypt**
- Un utilisateur ne peut modifier que ses propres données
- Seul un admin peut modifier le catalogue et les rôles

#### Profil & Visibilité
- Par défaut, un nouveau compte a `is_public = true`
- Si `is_public = false`, le profil est invisible pour tout autre utilisateur
- Tous les champs de tracking (statut, score, notes) sont publics en lecture si le profil est public
- Seul le propriétaire peut modifier ses données de tracking

#### Tracking
- Le `status` est un enum : `EN_COURS`, `TERMINE`, `ABANDONNE`, `A_VOIR`
- Le `score` est un entier entre **1 et 10** (null si non noté)
- `current_episode` ne peut pas dépasser `nb_episodes` de l'anime
- `current_volume` ne peut pas dépasser `nb_volumes` du manga
- `ending_date` ne peut pas être antérieure à `started_date`
- À la création d'un tracking, `created_at` est défini automatiquement
- À chaque modification, `updated_at` est mis à jour automatiquement

#### Catalogue
- Un anime/manga doit avoir **au moins un genre**
- `created_by` est défini à la création et **ne peut jamais être modifié**
- `updated_by` est mis à jour à chaque modification par un admin
- Un admin ne peut pas se supprimer lui-même
- Un admin ne peut pas bannir un autre admin

#### Recommandations
- L'algorithme se base sur les genres des contenus scorés ≥ 7 par l'utilisateur
- Les recommandations excluent les contenus déjà dans la liste de l'utilisateur
- Minimum 3 contenus pour générer des recommandations, sinon message d'onboarding

---

### 6. Contraintes du projet

#### Contraintes techniques
| Contrainte | Détail |
|---|---|
| **Responsive** | Compatible desktop et mobile (breakpoints à définir) |
| **Authentification** | JWT avec expiration 24h |
| **Sécurité** | BCrypt pour les mots de passe, HTTPS en production |
| **RGPD** | Possibilité de supprimer son compte et toutes ses données |
| **Performances** | Pagination sur toutes les listes (20 items par page) |
| **Base de données** | PostgreSQL 17 — modèle relationnel normalisé |

#### Contraintes projet
| Contrainte | Détail |
|---|---|
| **Périmètre** | Micro-SaaS — une fonctionnalité principale forte |
| **Réalisme** | MVP réalisable sur une année académique |
| **Maintenabilité** | Code documenté, architecture en couches |
| **Hébergement** | Docker pour la portabilité |

---

## Partie 2 — Cadre technique

### 7. Architecture envisagée

```
┌─────────────────┐         ┌──────────────────┐         ┌──────────────┐
│   FRONTEND      │  HTTP   │    BACKEND       │  JDBC   │   DATABASE   │
│   Angular 20    │ ──────► │  Spring Boot 3   │ ──────► │ PostgreSQL17 │
│   Port 4200     │  REST   │  Port 8080       │         │  Port 5432   │
└─────────────────┘         └──────────────────┘         └──────────────┘
                                     │
                              Spring Security
                                 JWT Auth
                              Hibernate / JPA
```

**Flux de communication :**
1. Le frontend Angular envoie des requêtes HTTP vers l'API REST
2. Le backend vérifie le token JWT via Spring Security
3. Spring Security applique les règles d'autorisation selon le rôle
4. Le service métier traite la requête
5. Hibernate/JPA communique avec PostgreSQL
6. La réponse JSON est retournée au frontend

---

### 8. Stack technique détaillée

#### Frontend

| Élément | Choix | Version | Justification |
|---|---|---|---|
| Framework | Angular | 20 (LTS) | Mature, TypeScript natif, Signals stables, utilisé en entreprise |
| Langage | TypeScript | 5.x | Typage fort, détection d'erreurs à la compilation |
| Build Tool | Angular CLI | 20.x | Intégré à Angular, build optimisé |
| CSS | TailwindCSS | 4.x | Productivité UI, responsive facilité |
| HTTP Client | Angular HttpClient | natif | Intégré au framework |
| Routing | Angular Router | natif | Intégré au framework |
| Auth Guard | CanActivate | natif | Protection des routes privées |

#### Backend

| Élément | Choix | Version | Justification |
|---|---|---|---|
| Langage | Java | 21 (LTS) | Stabilité, performance, maîtrisé en entreprise |
| Framework | Spring Boot | 3.4.x | Standard industrie, API REST rapide à mettre en place |
| Auth | Spring Security + JWT | dernière stable | Gestion des rôles et sécurisation des endpoints |
| Validation | Spring Validation | natif | Validation des DTOs |
| Documentation API | Springdoc OpenAPI | 2.x | Génération automatique Swagger UI |

#### Base de données

| Élément | Choix | Version | Justification |
|---|---|---|---|
| SGBD | PostgreSQL | 17 | Robuste, modèle relationnel, compatible avec notre MLD normalisé |
| ORM | Hibernate / JPA | 6.x | Intégré à Spring Boot, mapping objet-relationnel |
| Migration | Flyway | 10.x | Gestion des versions du schéma SQL |

#### Infrastructure & Outils

| Élément | Choix | Version | Justification |
|---|---|---|---|
| Conteneurisation | Docker + Docker Compose | dernière stable | Reproductibilité des environnements |
| Versioning | Git | dernière stable | Gestion du code source |
| Dépôt | GitHub | — | Hébergement du code + GitHub Projects |
| IDE | VS Code / IntelliJ | dernière stable | Dev frontend (VS Code) + backend (IntelliJ) |
| Tests backend | JUnit 5 + Mockito | natif Spring | Tests unitaires et d'intégration |
| Tests frontend | Jasmine + Karma | natif Angular | Tests unitaires composants |

#### Librairies importantes

| Librairie | Rôle |
|---|---|
| `jjwt` (Java JWT) | Génération et validation des tokens JWT |
| `spring-boot-starter-mail` | Envoi d'emails (récupération mdp) |
| `lombok` | Réduction du boilerplate Java |
| `mapstruct` | Mapping Entity ↔ DTO |

---

## Partie 3 — Organisation projet

### 9. Kanban — Tableau de suivi

**Outil :** GitHub Projects

**Colonnes :**
| Colonne | Description |
|---|---|
| Backlog | Toutes les tâches identifiées non planifiées |
| Sprint en cours | Tâches du sprint actuel |
| En cours | Tâches en cours de développement |
| À tester | Tâches développées, en attente de test |
| Terminé | Tâches validées |

---

### 10. EPICs, User Stories & Technical Stories

#### EPIC 1 — Authentification

| ID | Type | Story | Priorité |
|---|---|---|---|
| US-01 | User Story | En tant que visiteur, je veux créer un compte afin d'accéder à l'application | Must Have |
| US-02 | User Story | En tant qu'utilisateur, je veux me connecter avec mon email et mot de passe afin d'accéder à ma liste | Must Have |
| US-03 | User Story | En tant qu'utilisateur connecté, je veux me déconnecter afin de sécuriser mon compte | Must Have |
| US-04 | User Story | En tant qu'utilisateur, je veux réinitialiser mon mot de passe afin de récupérer l'accès à mon compte | Should Have |
| TS-01 | Technical Story | Configurer Spring Security avec JWT | Must Have |
| TS-02 | Technical Story | Implémenter le hash BCrypt des mots de passe | Must Have |
| TS-03 | Technical Story | Configurer les guards Angular pour les routes privées | Must Have |

#### EPIC 2 — Gestion du profil

| ID | Type | Story | Priorité |
|---|---|---|---|
| US-05 | User Story | En tant qu'utilisateur, je veux modifier mon pseudo, bio et avatar afin de personnaliser mon profil | Should Have |
| US-06 | User Story | En tant qu'utilisateur, je veux changer mon mot de passe afin de sécuriser mon compte | Should Have |
| US-07 | User Story | En tant qu'utilisateur, je veux rendre mon profil privé afin de contrôler ma visibilité | Should Have |
| US-08 | User Story | En tant que visiteur, je veux consulter le profil public d'un utilisateur afin de voir sa liste | Must Have |
| US-09 | User Story | En tant qu'utilisateur, je veux supprimer mon compte afin d'exercer mon droit à l'oubli (RGPD) | Must Have |

#### EPIC 3 — Catalogue

| ID | Type | Story | Priorité |
|---|---|---|---|
| US-10 | User Story | En tant qu'utilisateur, je veux rechercher un anime par titre afin de le trouver rapidement | Must Have |
| US-11 | User Story | En tant qu'utilisateur, je veux filtrer les résultats par type et genre afin d'affiner ma recherche | Should Have |
| US-12 | User Story | En tant qu'utilisateur, je veux consulter la fiche détail d'un anime/manga afin d'avoir toutes les informations | Must Have |
| US-13 | User Story | En tant qu'admin, je veux ajouter un anime/manga au catalogue afin d'enrichir la base de données | Must Have |
| US-14 | User Story | En tant qu'admin, je veux modifier une entrée du catalogue afin de corriger des informations erronées | Must Have |
| US-15 | User Story | En tant qu'admin, je veux supprimer une entrée du catalogue afin de retirer un contenu incorrect | Must Have |
| US-16 | User Story | En tant qu'admin, je veux gérer les genres afin de maintenir une liste cohérente | Must Have |

#### EPIC 4 — Tracking (Progression)

| ID | Type | Story | Priorité |
|---|---|---|---|
| US-17 | User Story | En tant qu'utilisateur, je veux ajouter un anime à ma liste afin de commencer à le tracker | Must Have |
| US-18 | User Story | En tant qu'utilisateur, je veux mettre à jour mon épisode actuel afin de garder ma progression à jour | Must Have |
| US-19 | User Story | En tant qu'utilisateur, je veux changer le statut d'un anime (En cours, Terminé...) afin d'organiser ma liste | Must Have |
| US-20 | User Story | En tant qu'utilisateur, je veux attribuer un score à un anime afin d'évaluer mon ressenti | Must Have |
| US-21 | User Story | En tant qu'utilisateur, je veux ajouter une note personnelle afin de me souvenir de mes impressions | Must Have |
| US-22 | User Story | En tant qu'utilisateur, je veux marquer un anime comme favori afin de le retrouver facilement | Should Have |
| US-23 | User Story | En tant qu'utilisateur, je veux suivre ma progression sur un manga (tome + chapitre) afin de tracker ma lecture | Must Have |

#### EPIC 5 — Dashboard

| ID | Type | Story | Priorité |
|---|---|---|---|
| US-24 | User Story | En tant qu'utilisateur, je veux voir mes animes en cours sur mon dashboard afin d'avoir une vue rapide | Must Have |
| US-25 | User Story | En tant qu'utilisateur, je veux voir mes statistiques (total, terminés, en cours, abandonnés) afin de suivre mon activité | Must Have |
| US-26 | User Story | En tant qu'utilisateur, je veux filtrer ma liste par statut afin de naviguer facilement | Should Have |

#### EPIC 6 — Recommandations

| ID | Type | Story | Priorité |
|---|---|---|---|
| US-27 | User Story | En tant qu'utilisateur, je veux recevoir des recommandations basées sur mes genres préférés afin de découvrir de nouveaux contenus | Should Have |
| US-28 | User Story | En tant qu'utilisateur, je veux que les recommandations excluent les contenus déjà dans ma liste afin d'avoir des suggestions pertinentes | Should Have |

#### EPIC 7 — Administration

| ID | Type | Story | Priorité |
|---|---|---|---|
| US-29 | User Story | En tant qu'admin, je veux voir la liste de tous les utilisateurs afin de gérer la communauté | Must Have |
| US-30 | User Story | En tant qu'admin, je veux bannir un utilisateur afin de modérer les abus | Must Have |
| US-31 | User Story | En tant qu'admin, je veux modifier le rôle d'un utilisateur afin de promouvoir un modérateur | Must Have |
| US-32 | User Story | En tant qu'admin, je veux voir des statistiques globales de l'application afin de suivre la croissance | Could Have |

#### EPIC 8 — Infrastructure

| ID | Type | Story | Priorité |
|---|---|---|---|
| TS-04 | Technical Story | Initialiser le projet Spring Boot avec les dépendances | Must Have |
| TS-05 | Technical Story | Initialiser le projet Angular 20 | Must Have |
| TS-06 | Technical Story | Configurer Docker + Docker Compose (frontend, backend, db) | Must Have |
| TS-07 | Technical Story | Initialiser PostgreSQL avec Flyway | Must Have |
| TS-08 | Technical Story | Configurer ESLint + Prettier (frontend) | Must Have |
| TS-09 | Technical Story | Configurer Checkstyle (backend) | Should Have |
| TS-10 | Technical Story | Mettre en place les tests unitaires backend (JUnit + Mockito) | Should Have |
| TS-11 | Technical Story | Mettre en place les tests unitaires frontend (Jasmine) | Should Have |
| TS-12 | Technical Story | Configurer CI/CD GitHub Actions | Could Have |
| TS-13 | Technical Story | Configurer Springdoc OpenAPI / Swagger UI | Should Have |
| TS-14 | Technical Story | Configurer les environnements (dev / prod) | Must Have |

---

### 11. Roadmap & Milestones

| Milestone | Description | Contenu |
|---|---|---|
| **M1** — Cadrage | Validation de toute la conception | CDC, MCD, MLD, UML, Wireframes, Personas |
| **M2** — Setup | Environnement de développement prêt | Docker, BDD initialisée, projets Angular + Spring créés |
| **M3** — Auth MVP | Authentification fonctionnelle | Register, Login, Logout, JWT, Guards Angular |
| **M4** — Catalogue MVP | Catalogue consultable | CRUD admin, recherche, page détail |
| **M5** — Tracking MVP | Suivi de progression fonctionnel | ANIME_TRACKING, MANGA_TRACKING, Dashboard |
| **M6** — Profils | Profils publics | Profil public, settings, toggle visibilité |
| **M7** — Recommandations | Algo de recommandation | Logique SQL par genre, page recommandations |
| **M8** — Finitions | Qualité & déploiement | Tests, corrections, déploiement Docker |

---

## Récapitulatif des livrables

```
/
├── README.md
├── CAHIER_DES_CHARGES.md         ← ce fichier
├── docs/
│   ├── MCD.png
│   ├── MLD.png
│   └── UML.png
├── personas/
│   ├── persona-01-casual.svg
│   ├── persona-02-collector.svg
│   ├── persona-03-otaku.svg
│   └── persona-04-admin.svg
├── wireframes/
│   ├── wireframe-login.svg
│   ├── wireframe-dashboard.svg
│   ├── wireframe-search.svg
│   ├── wireframe-detail-v5.svg
│   ├── wireframe-profile.svg
│   ├── wireframe-settings.svg
│   ├── wireframe-admin-catalogue.svg
│   ├── wireframe-admin-users.svg
│   └── mobile/
│       ├── mobile-login.svg
│       ├── mobile-dashboard.svg
│       ├── mobile-search.svg
│       ├── mobile-detail.svg
│       ├── mobile-profile.svg
│       ├── mobile-settings.svg
│       ├── mobile-admin-catalogue.svg
│       └── mobile-admin-users.svg
├── design/
│   ├── charte-graphique.svg
│   ├── charte-graphique.pdf
│   ├── logo-dark.svg
│   └── logo-icon.svg
└── slides/
    └── presentation.pdf
```

---

*Document réalisé dans le cadre du titre **Concepteur Développeur d'Applications (CDA)** — 2025*
