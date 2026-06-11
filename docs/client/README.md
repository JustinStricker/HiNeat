# KMP Client — HiNeat

A full-stack Kotlin Multiplatform application for managing notes and tasks, featuring a shared UI across Android, iOS, Desktop (JVM), and Web (WasmJS), with a centralized Ktor backend.

## Features

- **JWT Authentication** — secure login and session management
- **Note Management** — create, read, update, delete notes with Markdown rendering
- **Task Tracking** — organize tasks with visibility tiers and tags
- **3-Tier Visibility** — LOCAL (device only), PRIVATE (synced), PUBLIC (browsable)
- **Offline-First Sync** — server-authoritative bidirectional sync with dirty fallback
- **Multi-Server Explore** — browse public posts from any server
- **Cross-Platform** — one codebase for Android, iOS, Desktop, Web

## Architecture

MVVM + Repository + Decorator pattern:

```
Screens (Compose) → ViewModels → SyncingRepos → RoomRepos (local cache)
                                              → Clients (remote API)
```

See [Client Architecture](ARCHITECTURE.md) for details.

## Build & Run

Quick start commands:

| Platform | Command |
|----------|---------|
| Android | `./gradlew :app:composeApp:assembleDebug` |
| Desktop | `./gradlew :app:composeApp:run` |
| Web (Wasm) | `./gradlew :app:composeApp:wasmJsBrowserDevelopmentRun` |
| iOS | Open `app/iosApp/` in Xcode |

See [Build Guide](BUILD.md) for detailed instructions.

## Project Structure

```
app/composeApp/src/
├── commonMain/kotlin/com/hineat/
│   ├── App.kt                     # Root composable + NavHost
│   ├── Navigation.kt              # Type-safe navigation routes
│   ├── auth/                      # Login, auth repository, auth VM
│   ├── core/                      # AppDrawer, AppTheme, Explore, Settings
│   ├── local/                     # Room DB, DAOs, entities, converters
│   ├── notes/                     # Notes list/editor, repos, VM
│   ├── sync/                      # Sync engine + VM
│   └── tasks/                     # Tasks screen, repos, VM
├── androidMain/                   # Android-specific code
├── iosMain/                       # iOS-specific code
├── jvmMain/                       # Desktop entry point
└── wasmJsMain/                    # Web entry point
```
