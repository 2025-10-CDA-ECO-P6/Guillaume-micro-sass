# Spécifications de sécurité
## [ NOM APP ] — Anime & Manga Tracker

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
- Payload : `user_id`, `role`, `email`, `iat`, `exp`

**Librairie utilisée :** `jjwt` (Java JWT)

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
| `ADMIN` | Accès à toutes les actions User + administration |

### Règles d'accès
| Ressource | Visiteur | User | Admin |
|---|---|---|---|
| Lire un profil public | ✅ | ✅ | ✅ |
| Lire un profil privé | ❌ | ❌ (sauf soi-même) | ✅ |
| Modifier sa liste | ❌ | ✅ (la sienne uniquement) | ✅ |
| Modifier la liste d'un autre | ❌ | ❌ | ❌ |
| Lire le catalogue | ✅ | ✅ | ✅ |
| Modifier le catalogue | ❌ | ❌ | ✅ |
| Gérer les utilisateurs | ❌ | ❌ | ✅ |
| Bannir un user | ❌ | ❌ | ✅ |

### Implémentation Spring Security
```java
@PreAuthorize("hasRole('ADMIN')")
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

### Force brute
→ **Mesure recommandée (Could Have)** : Rate limiting sur `/auth/login` — max 5 tentatives par IP par minute.

---

## 7. RGPD — Droit à l'oubli

L'application respecte le droit à l'oubli prévu par le RGPD.

**Suppression de compte :**
- Suppression de toutes les données personnelles de l'utilisateur
- Suppression en cascade de tous ses trackings (ANIME_TRACKING, MANGA_TRACKING)
- Le pseudo est anonymisé dans les `created_by`/`updated_by` du catalogue

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
