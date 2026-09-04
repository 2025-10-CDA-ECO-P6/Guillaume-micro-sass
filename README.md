# [ NOM APP ] — Anime & Manga Tracker 🎌

> *"Ne perds plus le fil, suis ta passion."*

---

## 📋 Présentation du projet

**[ NOM APP ]** est un Micro-SaaS de suivi de progression anime et manga, entièrement en français. Il permet à chaque utilisateur de gérer sa liste personnelle, suivre sa progression épisode par épisode ou tome par tome, et organiser ses contenus par statut.

Contrairement aux solutions existantes (MyAnimeList, AniList), [ NOM APP ] est pensé pour la **communauté francophone** : interface en français, simple, sans surcharge de fonctionnalités.

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
| Confidentialité | Option `is_public` pour passer son profil en privé si souhaité |

> 💡 **Logique de recommandation :** à partir des genres des animes/mangas auxquels l'utilisateur a attribué un score élevé, le système suggère d'autres contenus bien notés des mêmes genres, absents de sa liste. Pas de machine learning — une logique métier SQL ciblée et efficace.

> 🔒 **Modèle de visibilité :** tous les champs d'un profil (statut, progression, score, notes) sont publics en lecture par défaut. Seul le propriétaire peut modifier ses données. Un booléen `is_public` sur `USER` permet de masquer entièrement son profil si l'utilisateur le souhaite.

### Ce que l'application ne fait PAS (périmètre Micro-SaaS)
- ❌ Forum / communauté
- ❌ Fonctionnalités sociales avancées (follows, likes, commentaires sur les profils)
- ❌ Recommandations par intelligence artificielle

---

## 🛠️ Stack technique

| Couche | Technologie | Justification |
|---|---|---|
| **Frontend** | Angular 20 | Version LTS stable, TypeScript natif, composants réutilisables, Signals stables |
| **Backend** | Java Spring Boot | Robuste, API REST, très utilisé en entreprise |
| **Base de données** | PostgreSQL | Parfait pour notre modèle relationnel normalisé |
| **Authentification** | Spring Security + JWT | Gestion des rôles user / admin |
| **ORM** | Hibernate / JPA | Mapping objet-relationnel avec Spring Boot |

---

## 🗃️ Modélisation des données

### MCD (Modèle Conceptuel de Données — MERISE)

Le MCD comporte **4 entités** et **4 associations** :

| Entité | Rôle |
|---|---|
| `USER` | Compte utilisateur (role : user / admin, is_public : boolean) |
| `ANIME` | Catalogue des animes |
| `MANGA` | Catalogue des mangas |
| `GENRE` | Liste des genres partagés |

**Associations :**
- `USER` (0,n) — **tracks** — (0,n) `ANIME` *(porteuse : status, current_episode, score, notes)*
- `USER` (0,n) — **tracks** — (0,n) `MANGA` *(porteuse : status, current_volume, current_chapter, score, notes)*
- `ANIME` (1,n) — **has** — (0,n) `GENRE`
- `MANGA` (1,n) — **has** — (0,n) `GENRE`

📎 *Voir fichier `MCD.png` dans le dossier `/docs`*

### MLD (Modèle Logique de Données)

Le MLD dérive du MCD et comporte **8 tables** :

`USER` · `ANIME` · `MANGA` · `GENRE` · `ANIME_TRACKING` · `MANGA_TRACKING` · `ANIME_GENRE` · `MANGA_GENRE`

> Note : le champ `is_public (boolean)` est ajouté sur `USER` pour gérer la visibilité du profil.

📎 *Voir fichier `MLD.png` dans le dossier `/docs`*

---

## 📐 Diagramme de cas d'utilisation (UML)

Deux acteurs : **User** et **Admin** (relation de généralisation — Admin hérite de toutes les actions User).

**Actions User :** Register · Login · Logout · Edit profile · Search content · Add to list · Update progress · View dashboard · Get recommendations · Toggle profile visibility

**Actions visiteur (non connecté) :** View public profile

**Actions Admin (exclusives) :** Add to catalog · Edit catalog entry · Delete entry · Manage genres · Manage users

📎 *Voir fichier `UML.png` dans le dossier `/docs`*

---

## 🖼️ Wireframes

4 écrans principaux modélisés :

| Écran | Fichier |
|---|---|
| Login / Register | `wireframe-login.svg` |
| Dashboard | `wireframe-dashboard.svg` |
| Recherche | `wireframe-search.svg` |
| Détail + modale progression | `wireframe-detail-v5.svg` |

📎 *Voir dossier `/wireframes`*

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

📎 *Voir fichier `charte-graphique.pdf` dans le dossier `/design`*

---

## 📁 Structure du repository

```
/
├── README.md
├── docs/
│   ├── MCD.png
│   ├── MLD.png
│   └── UML.png
├── wireframes/
│   ├── wireframe-login.svg
│   ├── wireframe-dashboard.svg
│   ├── wireframe-search.svg
│   └── wireframe-detail-v5.svg
├── design/
│   ├── charte-graphique.svg
│   ├── charte-graphique.pdf
│   ├── logo-dark.svg
│   └── logo-icon.svg
└── slides/
    └── presentation.pdf
```

---

## 👤 Auteur

Projet réalisé dans le cadre du titre **Concepteur Développeur d'Applications (CDA)** — 2026/2027
