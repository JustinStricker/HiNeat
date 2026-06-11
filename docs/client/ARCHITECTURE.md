# Client Architecture

## MVVM + Repository + Decorator

```
┌──────────────────────────────────────────────────────────────────┐
│                     Composable Screens                           │
│  NotesListScreen  TasksScreen  NoteEditor  Explore  Settings    │
└──────────────────────────▲───────────────────────────────────────┘
                           │ collectAsState()
┌──────────────────────────┴───────────────────────────────────────┐
│                       ViewModels                                 │
│  NotesViewModel  TasksViewModel  SyncViewModel  ExploreViewModel │
└──────────────────────────▲───────────────────────────────────────┘
                           │ suspend calls
┌──────────────────────────┴───────────────────────────────────────┐
│                  Syncing*Repository (Decorator)                   │
│  SyncingNotesRepository → server-first writes, dirty fallback    │
│  SyncingTasksRepository → one-way sync pull, server authoritative │
├──────────────────────────────────────────────────────────────────┤
│              ┌─────────────────┐    ┌──────────────────┐         │
│              │ RoomNotesRepo   │    │ NoteClient       │         │
│              │ Room DB (cache) │    │ Ktor HTTP Client │         │
│              └─────────────────┘    └──────────────────┘         │
└──────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Reads
1. Screen observes `StateFlow` from ViewModel
2. ViewModel reads from `Syncing*Repository`
3. `Syncing*Repository` delegates to Room (fast local cache)
4. UI updates immediately

### Writes (PRIVATE/PUBLIC)
1. User action → ViewModel → `Syncing*Repository.save()`
2. Try server first via `NoteClient`/`TaskClient`
3. On success: cache server response in Room
4. On failure: cache locally with `isDirty = true`

### Writes (LOCAL)
1. User action → ViewModel → `Syncing*Repository.save()`
2. Saved directly to Room, never sent to server

### Sync (Pull)
1. `sync()` → `pullAllServerNotes()` — paginated fetch from `/sync/notes` and `/sync/tasks`
2. `replaceServerNotesInCache()` — overwrite all server-backed local notes
3. LOCAL notes are never touched

## Sync Engine Details

- **Server-authoritative**: server wins on conflict (LWW on `updatedAt` not implemented yet)
- **One-way pull**: sync() fetches all server notes/tasks and replaces local cache
- **Pagination**: pulls 50 items per page until exhausted
- **Dirty tracking**: offline writes are flagged `isDirty = true`, pushed on next write attempt
- **LOCAL isolation**: LOCAL visibility items never participate in sync

## Room Database

```kotlin
// AppDatabase (expect/actual pattern per platform)
expect fun createAppDatabase(): AppDatabase

// Entities
NoteEntity(id, title, content, tags, visibility, serverId, ownerId, ...)
TaskEntity(id, title, description, completed, tags, visibility, ...)

// DAOs
NoteDao — getAll(), getById(), save(), update(), delete(), reorder()
TaskDao — getAll(), getById(), save(), update(), delete(), reorder()
```

## Navigation

Type-safe sealed class hierarchy:

```kotlin
sealed class Screen {
    object NotesList           // /notes
    data class NoteEditor(val noteId: String?)
    object TasksList           // /tasks
    object Settings            // /settings
    object Explore             // /explore
    data class ExplorePostDetail(val slug: String)
}
```

## Network Layer

```
BaseClient (abstract)
├── NoteClient — notes CRUD, sync, toggle-task, reorder, public posts
└── TaskClient — tasks CRUD, sync, reorder
```

- `setToken(token)` / `clearToken()` — JWT management
- `updateServerUrl(url)` — multi-server support
- All authenticated requests carry `Authorization: Bearer <token>` header

## AppSettings

Uses `multiplatform-settings` for persistent key-value storage:

| Key | Type | Purpose |
|-----|------|---------|
| `auth_token` | String? | JWT token |
| `base_url` | String | Server URL |
