# Authentication

## Current State

JWT-based authentication with a single hardcoded admin user.

### Auth Flow

```
Client                          Server
  │                               │
  │  POST /login                  │
  │  { username, password }       │
  │ ─────────────────────────────>│
  │                               │  Verify against hardcoded credentials
  │                               │  Generate JWT (HMAC256, 1hr expiry)
  │  { "token": "eyJ..." }       │
  │ <─────────────────────────────│
  │                               │
  │  GET /notes                   │
  │  Authorization: Bearer <jwt>  │
  │ ─────────────────────────────>│
  │                               │  Verify JWT signature
  │                               │  Extract username claim
  │                               │  Route to handler
  │ <─────────────────────────────│
```

### Security Concerns

| Issue | Severity | File |
|-------|----------|------|
| Hardcoded JWT secret `"my-super-secret-key-that-should-be-in-env-vars"` | Critical | `JwtConfig.kt:13` |
| Hardcoded admin credentials `VALID_USERNAME = "admin"`, `VALID_PASSWORD = "password"` | Critical | `AuthService.kt:7-8` |

### Target State (from Product Plan)

```
JwtConfig.kt →
    val secret: String = System.getenv("JWT_SECRET") ?: "dev-only-secret-change-in-prod"
    val issuer: String = System.getenv("JWT_ISSUER") ?: "com.hineat"
    val audience: String = System.getenv("JWT_AUDIENCE") ?: "com.hineat"

AuthService.kt →
    private val validUsername: String = System.getenv("ADMIN_USERNAME") ?: "admin"
    private val validPassword: String = System.getenv("ADMIN_PASSWORD") ?: "changeme"
```

### JWT Configuration

| Setting | Current Value | Target |
|---------|--------------|--------|
| Algorithm | HMAC256 | HMAC256 |
| Secret | Hardcoded string | `System.getenv("JWT_SECRET")` |
| Issuer | `"com.hineat"` | `System.getenv("JWT_ISSUER")` |
| Audience | `"com.hineat"` | `System.getenv("JWT_AUDIENCE")` |
| Expiry | 1 hour (3600000ms) | 1 hour |

### Auth Extensions

```kotlin
// Extracts the "username" claim from JWT principal
fun ApplicationCall.ownerId(): String
```

Used by notes and tasks routes to associate resources with the authenticated user.
