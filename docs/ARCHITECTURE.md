# Architecture

## Overview

Monorepo with two major components: a Kotlin Multiplatform client app ("Notable") and a Ktor backend server, with OCI infrastructure provisioned via OpenTofu.

## Module Structure

```
hineat/
├── settings.gradle.kts          # root: :app:composeApp, :app:shared, :app:server
├── app/
│   ├── composeApp/              # KMP client (Android, iOS, JVM, WasmJS)
│   │   └── src/
│   │       ├── commonMain/      # Shared UI + business logic
│   │       ├── androidMain/     # MainActivity, DB constructor
│   │       ├── iosMain/         # MainViewController, DB constructor
│   │       ├── jvmMain/         # Desktop entry point
│   │       └── wasmJsMain/      # Web entry point, index.html
│   ├── shared/                  # Data layer (models, API clients, settings)
│   ├── server/                  # Ktor backend
│   └── iosApp/                  # iOS Swift entry point
└── infrastructure/              # OpenTofu + K8s manifests
```

## App Architecture: MVVM + Repository + Decorator

```
┌────────────────────────────────────────────────────────────┐
│                   composeApp (UI Layer)                     │
│  Screens (Composables) → ViewModels → Repositories         │
│  NotesListScreen         NotesViewModel SyncingNotesRepo   │
│  TasksScreen             TasksViewModel SyncingTasksRepo   │
│  NoteEditorScreen        SyncViewModel                     │
│  ExploreScreen           ExploreViewModel                  │
│  ExplorePostDetailScreen                                   │
├────────────────────────────────────────────────────────────┤
│                   shared Module (Data Layer)                │
│  Models: Note, Task, Visibility, SyncResponse              │
│  Clients: NoteClient, TaskClient (extends BaseClient)      │
│  Settings: AppSettings (multiplatform-settings)            │
├────────────────────────────────────────────────────────────┤
│              composeApp/src (Local Persistence)             │
│  Room 3.0: AppDatabase, NoteDao, TaskDao                   │
│  Entities: NoteEntity, TaskEntity                          │
│  Repos: RoomNotesRepository, RoomTasksRepository           │
├────────────────────────────────────────────────────────────┤
│                    server (Ktor Backend)                    │
│  Application.kt → Module config, DI, routing               │
│  AuthService/Routes → JWT login (hardcoded admin)          │
│  NotesService/Routes → CRUD + toggle-task                  │
│  TasksService/Routes → CRUD                                │
│  SyncRoutes → GET /sync/notes, /sync/tasks                 │
│  PublicRoutes → GET /public/posts (no auth)                │
│  DatabaseFactory/Tables → Exposed ORM, SQLite              │
└────────────────────────────────────────────────────────────┘
```

## Key Patterns

| Pattern | Usage |
|---------|-------|
| **Repository** | Interfaces define contract; Room-backed + network-aware implementations |
| **Decorator** | `Syncing*Repository` wraps local Room repos with network-aware behavior |
| **MVVM** | ViewModels with `MutableStateFlow`/`StateFlow` + `collectAsState()` |
| **Type-safe Navigation** | Sealed class `Screen` hierarchy with `@Serializable` |
| **expect/actual** | Platform-specific DB construction, server URL defaults |

## Sync Engine

Server-authoritative, one-way pull (no merge):

1. **LOCAL** items never leave the device
2. **PRIVATE/PUBLIC** items: server is source of truth, Room is cache
3. Writes go to server first, then cache locally
4. `sync()` pulls from server, overwrites local cache
5. Dirty fallback: if server is unreachable, cache locally flagged `isDirty = true`

## Visibility Model

| Visibility | Stored Locally | Synced to Server | Publicly Visible |
|------------|:---:|:---:|:---:|
| LOCAL | Yes | Never | No |
| PRIVATE | Yes | Yes (JWT) | No |
| PUBLIC | Yes | Yes (JWT) | Yes (no auth) |

## Navigation Routes

```kotlin
sealed class Screen {
    object NotesList : Screen()
    data class NoteEditor(val noteId: String?) : Screen()
    object TasksList : Screen()
    object Settings : Screen()
    object Explore : Screen()
    data class ExplorePostDetail(val slug: String) : Screen()
}
```

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Language | Kotlin | 2.3.21 |
| UI | Compose Multiplatform | 1.11.0 |
| HTTP Client | Ktor | 3.5.0 |
| Local DB | Room | 3.0.0-alpha04 |
| Server | Ktor + Netty | 3.5.0 |
| Server ORM | Exposed | 1.3.0 |
| Server DB | SQLite | — |
| Auth | JWT (auth0-java-jwt) | — |
| KSP | Kotlin Symbol Processing | 2.3.7 |
| AGP | Android Gradle Plugin | 8.13.2 |
| Infra | OpenTofu / OCI | — |
| Postgres Operator | CloudNativePG | — |
