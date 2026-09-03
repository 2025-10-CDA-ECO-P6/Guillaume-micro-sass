# Organisation projet — EPICs & User Stories
## [ NOM APP ] — Anime & Manga Tracker

---

## Outil de suivi : GitHub Projects

**Colonnes Kanban :**
- Backlog
- Sprint en cours
- En cours
- À tester
- Terminé

---

## EPICs & User Stories

### EPIC 1 — Authentification

| ID | Type | Story | Priorité |
|---|---|---|---|
| US-01 | User Story | En tant que visiteur, je veux créer un compte afin d'accéder à l'application | Must Have |
| US-02 | User Story | En tant qu'utilisateur, je veux me connecter avec mon email et mot de passe afin d'accéder à ma liste | Must Have |
| US-03 | User Story | En tant qu'utilisateur connecté, je veux me déconnecter afin de sécuriser mon compte | Must Have |
| US-04 | User Story | En tant qu'utilisateur, je veux réinitialiser mon mot de passe afin de récupérer l'accès à mon compte | Should Have |
| TS-01 | Technical Story | Configurer Spring Security avec JWT | Must Have |
| TS-02 | Technical Story | Implémenter le hash BCrypt des mots de passe | Must Have |
| TS-03 | Technical Story | Configurer les guards Angular pour les routes privées | Must Have |

### EPIC 2 — Gestion du profil

| ID | Type | Story | Priorité |
|---|---|---|---|
| US-05 | User Story | En tant qu'utilisateur, je veux modifier mon pseudo, bio et avatar afin de personnaliser mon profil | Should Have |
| US-06 | User Story | En tant qu'utilisateur, je veux changer mon mot de passe afin de sécuriser mon compte | Should Have |
| US-07 | User Story | En tant qu'utilisateur, je veux rendre mon profil privé afin de contrôler ma visibilité | Should Have |
| US-08 | User Story | En tant que visiteur, je veux consulter le profil public d'un utilisateur afin de voir sa liste | Must Have |
| US-09 | User Story | En tant qu'utilisateur, je veux supprimer mon compte afin d'exercer mon droit à l'oubli (RGPD) | Must Have |

### EPIC 3 — Catalogue

| ID | Type | Story | Priorité |
|---|---|---|---|
| US-10 | User Story | En tant qu'utilisateur, je veux rechercher un anime par titre afin de le trouver rapidement | Must Have |
| US-11 | User Story | En tant qu'utilisateur, je veux filtrer les résultats par type et genre afin d'affiner ma recherche | Should Have |
| US-12 | User Story | En tant qu'utilisateur, je veux consulter la fiche détail d'un anime/manga afin d'avoir toutes les infos | Must Have |
| US-13 | User Story | En tant qu'admin, je veux ajouter un anime/manga au catalogue afin d'enrichir la base de données | Must Have |
| US-14 | User Story | En tant qu'admin, je veux modifier une entrée du catalogue afin de corriger des informations erronées | Must Have |
| US-15 | User Story | En tant qu'admin, je veux supprimer une entrée du catalogue afin de retirer un contenu incorrect | Must Have |
| US-16 | User Story | En tant qu'admin, je veux gérer les genres afin de maintenir une liste cohérente | Must Have |

### EPIC 4 — Tracking (Progression)

| ID | Type | Story | Priorité |
|---|---|---|---|
| US-17 | User Story | En tant qu'utilisateur, je veux ajouter un anime à ma liste afin de commencer à le tracker | Must Have |
| US-18 | User Story | En tant qu'utilisateur, je veux mettre à jour mon épisode actuel afin de garder ma progression à jour | Must Have |
| US-19 | User Story | En tant qu'utilisateur, je veux changer le statut d'un anime afin d'organiser ma liste | Must Have |
| US-20 | User Story | En tant qu'utilisateur, je veux attribuer un score à un anime afin d'évaluer mon ressenti | Must Have |
| US-21 | User Story | En tant qu'utilisateur, je veux ajouter une note personnelle afin de me souvenir de mes impressions | Must Have |
| US-22 | User Story | En tant qu'utilisateur, je veux marquer un anime comme favori afin de le retrouver facilement | Should Have |
| US-23 | User Story | En tant qu'utilisateur, je veux suivre ma progression sur un manga (tome + chapitre) afin de tracker ma lecture | Must Have |

### EPIC 5 — Dashboard

| ID | Type | Story | Priorité |
|---|---|---|---|
| US-24 | User Story | En tant qu'utilisateur, je veux voir mes animes en cours sur mon dashboard afin d'avoir une vue rapide | Must Have |
| US-25 | User Story | En tant qu'utilisateur, je veux voir mes statistiques afin de suivre mon activité | Must Have |
| US-26 | User Story | En tant qu'utilisateur, je veux filtrer ma liste par statut afin de naviguer facilement | Should Have |

### EPIC 6 — Recommandations

| ID | Type | Story | Priorité |
|---|---|---|---|
| US-27 | User Story | En tant qu'utilisateur, je veux recevoir des recommandations basées sur mes genres préférés | Should Have |
| US-28 | User Story | En tant qu'utilisateur, je veux que les recommandations excluent les contenus déjà dans ma liste | Should Have |

### EPIC 7 — Administration

| ID | Type | Story | Priorité |
|---|---|---|---|
| US-29 | User Story | En tant qu'admin, je veux voir la liste de tous les utilisateurs afin de gérer la communauté | Must Have |
| US-30 | User Story | En tant qu'admin, je veux bannir un utilisateur afin de modérer les abus | Must Have |
| US-31 | User Story | En tant qu'admin, je veux modifier le rôle d'un utilisateur afin de promouvoir un modérateur | Must Have |

### EPIC 8 — Infrastructure

| ID | Type | Story | Priorité |
|---|---|---|---|
| TS-04 | Technical Story | Initialiser le projet Spring Boot avec les dépendances | Must Have |
| TS-05 | Technical Story | Initialiser le projet Angular 20 | Must Have |
| TS-06 | Technical Story | Configurer Docker + Docker Compose | Must Have |
| TS-07 | Technical Story | Initialiser PostgreSQL avec Flyway | Must Have |
| TS-08 | Technical Story | Configurer ESLint + Prettier (frontend) | Must Have |
| TS-09 | Technical Story | Mettre en place les tests unitaires backend | Should Have |
| TS-10 | Technical Story | Mettre en place les tests unitaires frontend | Should Have |
| TS-11 | Technical Story | Configurer Springdoc OpenAPI / Swagger UI | Should Have |
| TS-12 | Technical Story | Configurer CI/CD GitHub Actions | Could Have |
| TS-13 | Technical Story | Configurer les environnements dev / prod | Must Have |
