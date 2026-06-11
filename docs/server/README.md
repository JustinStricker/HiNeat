# Ktor Server — HiNeat

Backend API server built with Ktor 3.5, Exposed ORM, SQLite, and JWT authentication.

## Architecture

```
Application.kt
├── AuthService      → JWT login (hardcoded admin credentials)
├── NotesService     → CRUD, toggle-task, reorder, public posts
├── TasksService     → CRUD, reorder
├── SyncService      → paginated pull endpoints
└── Routes
    ├── POST /login               (unauthenticated)
    ├── GET  /public/posts        (unauthenticated)
    ├── GET  /notes               (authenticated)
    ├── POST /notes               ...
    ├── PUT  /notes/{id}
    ├── DELETE /notes/{id}
    ├── GET  /sync/notes
    ├── GET  /tasks
    ├── POST /tasks
    ├── PUT  /tasks/{id}
    ├── DELETE /tasks/{id}
    └── GET  /sync/tasks
```

## Tech Stack

| Component | Library | Version |
|-----------|---------|---------|
| Server | Ktor + Netty | 3.5.0 |
| ORM | Exposed | 1.3.0 |
| Database | SQLite (via JDBC) | — |
| Auth | auth0-java-jwt | — |
| Serialization | kotlinx-serialization | — |

## Configuration

| Env Var | Default | Purpose |
|---------|---------|---------|
| `SERVER_PORT` | `8080` | HTTP listen port |
| `JWT_SECRET` | `"dev-only-secret..."` | HMAC256 signing key |
| `JWT_ISSUER` | `"com.hineat"` | JWT issuer claim |
| `JWT_AUDIENCE` | `"com.hineat"` | JWT audience claim |

## Database Tables

```kotlin
Notes(id, title, content, visibility, slug, serverId, ownerId, timestamp, updatedAt, deletedAt, position, isDirty)
NoteTags(noteId, tag)                          // composite PK
Tasks(id, title, description, completed, visibility, slug, serverId, ownerId, timestamp, updatedAt, deletedAt, position, isDirty)
```

## Running Locally

```shell
./gradlew :app:server:run
# Server starts at http://localhost:8080
```

## API Reference

See [API.md](API.md) for full endpoint documentation.
