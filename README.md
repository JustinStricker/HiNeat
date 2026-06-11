# HiNeat

Content, commerce, CRM — all built-in, no plugins. Multi-server, offline-first, cross-platform.

Kotlin Multiplatform monorepo: Compose Multiplatform client + Ktor backend + OCI OKE infrastructure.

```
   ┌────────────────────────────────────────────────┐
   │                 KMP Client                     │
   │  Android · iOS · Desktop · Web (Wasm)          │
   │                                                │
   │  Screens → ViewModels → SyncingRepos           │
   │              ├── Room DB (offline cache)       │
   │              └── Ktor Client (multi-server)    │
   └────────────────────┬───────────────────────────┘
                        │ HTTPS
   ┌────────────────────▼───────────────────────────┐
   │                 Ktor Server                    │
   │  Routes → Services → Exposed ORM → Postgres    │
   │  Auth · Notes · Tasks · Sync · Public          │
   └────────────────────┬───────────────────────────┘
                        │
   ┌────────────────────▼───────────────────────────┐
   │           OCI OKE Infrastructure               │
   │  OpenTofu · CloudNativePG · Object Storage     │
   └────────────────────────────────────────────────┘
```

## Features

- **Notes & Tasks** — CRUD with Markdown rendering and task list toggle
- **3-Tier Visibility** — LOCAL (device only), PRIVATE (synced), PUBLIC (browsable)
- **Offline-First Sync** — server-authoritative with dirty fallback when offline
- **Multi-Server Explore** — browse public notes from any server
- **Cross-Platform** — one UI codebase for Android, iOS, Desktop, Web
- **Social** (in development) — follows, likes, comments, feed, notifications

## Quick Start

```sh
# Server
./gradlew :app:server:run

# Desktop
./gradlew :app:composeApp:run

# Web (Wasm)
./gradlew :app:composeApp:wasmJsBrowserDevelopmentRun

# Android
./gradlew :app:composeApp:assembleDebug
```

## Project Structure

```
app/                          # KMP client
├── composeApp/src/           # Compose Multiplatform UI
│   ├── commonMain/           # Shared UI + business logic
│   ├── androidMain/          # Android platform code
│   ├── iosMain/              # iOS platform code
│   ├── jvmMain/              # Desktop entry point
│   └── wasmJsMain/           # Web entry point
├── shared/src/               # Data models, API clients, settings
└── server/src/               # Ktor backend
    ├── auth/                 # JWT authentication
    ├── core/                 # Database, tables, public routes
    ├── notes/                # Notes CRUD + sync
    └── tasks/                # Tasks CRUD + sync

infrastructure/               # OpenTofu + K8s manifests
├── networking.tf             # VCN, subnets, security lists
├── oke.tf                    # OKE cluster + node pool
├── k8s/app/                  # Server deployment + service
└── k8s/postgres/             # CloudNativePG cluster
```

## Documentation

→ [Motivation](docs/MOTIVATION.md) — why HiNeat exists, competitive landscape, design principles
→ [Browse full docs](docs/README.md) — architecture, API reference, deployment, roadmap
