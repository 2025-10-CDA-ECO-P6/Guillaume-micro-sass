# Spécifications de sécurité
## Nakama — Anime & Manga Tracker

---

## 1. Authentification

### JWT (JSON Web Token)
L'authentification est stateless : aucune session côté serveur.

**Fonctionnement :**
1. L'utilisateur envoie ses identifiants (email + mot de passe)
2. Le backend vérifie, génère un token JWT signé
3. Le frontend stocke le token et l'envoie à chaque requête via le header `Authorization: Bearer <token>`
4. Le backend valide la signature du token à chaque requête

**Configuration :**
- Algorithme de signature : `HS256`
- Expiration : `24h`
- Payload : `jti` (UUID unique du token), `user_id`, `role`, `email`, `iat`, `exp`

**Librairie utilisée :** `jjwt` (Java JWT)

### Déconnexion : révocation du token avec Redis
Un JWT est sans état : sans mesure particulière, il reste valide jusqu'à son expiration (24 h), même après le logout ou s'il est volé. Au logout, son `jti` est donc placé dans une liste noire Redis :

| Élément | Valeur |
|---|---|
| Clé | `jwt:blacklist:<jti>` |
| Valeur | `<user_id>` (audit) |
| Durée de vie (TTL) | temps restant avant l'expiration du token |
| Logout | `SET jwt:blacklist:<jti> <user_id> EX <ttl>` |
| Chaque requête | `JwtFilter` : `EXISTS jwt:blacklist:<jti>` → si 1, réponse `401` |

Redis supprime seul les clés expirées : la liste noire ne grossit jamais. Redis est protégé par mot de passe, n'expose aucun port hors du réseau Docker, et persiste sur disque (AOF) pour qu'un redémarrage ne réactive pas un token révoqué.

---

## 2. Hachage des mots de passe

Les mots de passe ne sont **jamais stockés en clair**. Ils sont hachés avec **BCrypt** avant tout stockage.

```java
// Hachage à l'inscription
String hashedPassword = passwordEncoder.encode(rawPassword);

// Vérification à la connexion
boolean valid = passwordEncoder.matches(rawPassword, storedHash);
```

**Facteur de coût BCrypt :** `12` (bon compromis sécurité/performance)

---

## 3. Autorisation — Contrôle d'accès par rôle (RBAC)

### Rôles définis
| Rôle | Description |
|---|---|
| `USER` | Utilisateur standard — gère sa propre liste |
| `MODERATOR` | Actions User + gestion du catalogue (animes, mangas, genres) |
| `ADMIN` | Actions Modérateur + gestion des utilisateurs (rôles, bannissement) |

### Règles d'accès
| Ressource | Visiteur | User | Modérateur | Admin |
|---|---|---|---|---|
| Lire un profil public | ✅ | ✅ | ✅ | ✅ |
| Lire un profil privé | ❌ | ❌ (sauf soi-même) | ❌ (sauf soi-même) | ✅ |
| Modifier sa liste | ❌ | ✅ (la sienne uniquement) | ✅ | ✅ |
| Modifier la liste d'un autre | ❌ | ❌ | ❌ | ❌ |
| Lire le catalogue | ✅ | ✅ | ✅ | ✅ |
| Modifier le catalogue et les genres | ❌ | ❌ | ✅ | ✅ |
| Gérer les utilisateurs et les rôles | ❌ | ❌ | ❌ | ✅ |
| Bannir un user (jamais un admin) | ❌ | ❌ | ❌ | ✅ |

### Implémentation Spring Security
```java
@PreAuthorize("hasAnyRole('MODERATOR', 'ADMIN')")
public void deleteEntry(Long id) { ... }

@PreAuthorize("@securityService.isOwner(#trackingId, principal.id)")
public void updateTracking(Long trackingId, TrackingDto dto) { ... }
```

---

## 4. Gestion des utilisateurs bannis

Un utilisateur banni (`is_banned = true`) se voit retourner une erreur `403 Forbidden` à chaque tentative de connexion, même si ses identifiants sont corrects.

```java
if (user.isBanned()) {
    throw new ForbiddenException("Compte banni");
}
```

---

## 5. Validation des données entrantes

Toutes les données reçues par l'API sont validées via **Spring Validation** avant traitement.

```java
public class RegisterDto {
    @NotBlank
    @Size(min = 3, max = 30)
    private String pseudo;

    @NotBlank
    @Email
    private String email;

    @NotBlank
    @Size(min = 8)
    private String password;
}
```

**Règles de validation métier :**
- `current_episode` ≤ `nb_episodes` de l'anime
- `current_volume` ≤ `nb_volumes` du manga
- `score` entre 1 et 10 (null accepté)
- `ending_date` ≥ `started_date`

**Défense en profondeur :** ces règles sont vérifiées dans les services Java (message clair pour l'utilisateur) **et** dans la base (contraintes `CHECK` et triggers de `V2__create_triggers.sql`). Si un contrôle Java est oublié, la base refuse quand même la donnée.

---

## 6. Protection contre les attaques courantes

### Injection SQL
→ **Prévention :** Hibernate/JPA avec requêtes paramétrées. Aucune concaténation de chaînes SQL.

### XSS (Cross-Site Scripting)
→ **Prévention :** Angular échappe automatiquement les données dans les templates. Les réponses JSON ne sont pas interprétées comme du HTML.

### CORS
→ **Configuration :** CORS restreint aux origines autorisées uniquement (domaine de l'application en production).

```java
@Configuration
public class CorsConfig {
    @Bean
    public CorsFilter corsFilter() {
        // Autorise uniquement l'URL du frontend Angular
        source.registerCorsConfiguration("/api/**", config);
    }
}
```

### CSRF
→ **Non applicable :** L'API est stateless (JWT). Pas de cookies de session, donc pas de risque CSRF.

### Moindre privilège sur la base de données
L'application ne se connecte jamais en superuser. Trois comptes PostgreSQL, créés par `docker/db/01-init-roles.sh` :

| Compte | Utilisé par | Droits |
|---|---|---|
| superuser (`POSTGRES_USER`) | Administration, sauvegardes | Tous — jamais utilisé par l'appli |
| `nakama_migration` | Flyway | Propriétaire du schéma : crée et modifie les tables |
| `nakama_app` | Spring Boot | `SELECT`, `INSERT`, `UPDATE`, `DELETE` sur les lignes uniquement |

Même en cas d'injection SQL, `nakama_app` ne peut ni supprimer une table (`DROP`), ni la vider (`TRUNCATE`), ni en créer une. Testé : les trois commandes sont refusées.

### Sauvegarde et restauration
`scripts/backup-db.sh` produit une sauvegarde compressée (`pg_dump -Fc`), vérifie qu'elle se relit, et garde les 7 dernières. `scripts/restore-db.sh` restaure en une seule transaction (tout ou rien). Testé : suppression des données puis restauration complète, droits et triggers compris.

### Force brute
→ **Mesure recommandée (Could Have)** : Rate limiting sur `/auth/login` — max 5 tentatives par IP par minute.

---

## 7. RGPD — Droit à l'oubli

L'application respecte le droit à l'oubli prévu par le RGPD.

**Suppression de compte :**
- Suppression de toutes les données personnelles de l'utilisateur
- Suppression en cascade de tous ses trackings (ANIME_TRACKING, MANGA_TRACKING)
- Les `created_by`/`updated_by` du catalogue passent à `NULL` (`ON DELETE SET NULL`) : le contenu reste, l'auteur n'est plus identifiable
- Son profil (`user_profiles`) est supprimé en cascade

**Données conservées :**
- Aucune donnée personnelle identifiable n'est conservée après suppression

---

## 8. Sécurité en production

| Mesure | Statut |
|---|---|
| HTTPS obligatoire | ✅ Prévu |
| Variables d'environnement (pas de secrets dans le code) | ✅ Prévu |
| `.env` hors du dépôt Git (`.gitignore`) | ✅ Prévu |
| Images Docker non exposées directement | ✅ Prévu |
| Logs sans données sensibles (pas de mots de passe) | ✅ Prévu |
| Comptes PostgreSQL à droits minimaux | ✅ Fait (`01-init-roles.sh`) |
| Redis protégé par mot de passe, non exposé | ✅ Fait (`docker-compose.yml`) |
| Ports base de données limités à `127.0.0.1` | ✅ Fait (`docker-compose.yml`) |
