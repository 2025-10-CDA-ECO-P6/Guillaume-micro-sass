# Expression du besoin
## [ NOM APP ] — Anime & Manga Tracker

---

## 1. Problématique

Les fans d'anime et manga francophones n'ont pas d'outil dédié en **français** pour suivre leur progression. Les plateformes existantes comme MyAnimeList ou AniList sont :

- entièrement en anglais, ce qui les rend inaccessibles aux débutants
- surchargées de fonctionnalités inutiles pour un usage quotidien simple
- non pensées pour les spécificités de la communauté francophone

**Résultat concret :** les utilisateurs oublient où ils en sont, se font spoiler, ou abandonnent faute d'outil adapté.

---

## 2. Pour qui ?

| Profil | Besoin principal |
|---|---|
| **Lucas, 17 ans** — Fan casual, lycéen | Interface simple en français, mise à jour rapide depuis son téléphone |
| **Camille, 26 ans** — Collectionneuse de mangas | Suivi tome + chapitre, séparation claire anime / manga |
| **Théo, 23 ans** — Otaku confirmé | Dashboard avec stats, recommandations pertinentes, profil public |
| **Alex, 29 ans** — Admin / créateur | Interface admin claire, gestion du catalogue et des utilisateurs |

**Public cible principal :** fans d'anime et manga francophones, 15–35 ans, toutes plateformes.

---

## 3. La réponse apportée

**[ NOM APP ]** est une application web Micro-SaaS responsive qui permet à chaque utilisateur francophone de :

- **Suivre sa progression** sur chaque anime et manga (statut, épisode/tome actuel, score, notes)
- **Organiser sa liste** par statut : En cours / Terminé / Abandonné / À voir
- **Découvrir de nouveaux contenus** via des recommandations basées sur ses genres préférés
- **Partager sa liste** via un profil public consultable par tous

L'application se distingue par sa **simplicité volontaire** : une fonctionnalité principale forte, une interface en français, sans publicité, sans surcharge.

---

## 4. Fonctionnalité principale

> Permettre à un utilisateur de suivre sa progression sur un anime ou un manga : statut, épisode ou tome actuel, score personnel et notes.

C'est cette fonctionnalité qui répond directement à la problématique — ne plus perdre le fil — et qui constitue le cœur du MVP.

---

## 5. Valeur apportée

| Problème identifié | Solution apportée |
|---|---|
| Oublient à quel épisode ils en sont | Tracking précis épisode / tome par utilisateur |
| Interfaces en anglais | Application 100% en français |
| Trop de fonctionnalités inutiles | Périmètre Micro-SaaS volontairement limité |
| Se font spoiler | Gestion des statuts et de la progression |
| Pas de recommandations pertinentes | Algo basé sur les genres les mieux notés |

---

## 6. Périmètre — Ce que l'application ne fait PAS

- ❌ Forum ou communauté
- ❌ Système de follows / amis
- ❌ Commentaires publics sur les profils
- ❌ Application mobile native
- ❌ Recommandations par intelligence artificielle
- ❌ Notifications push
