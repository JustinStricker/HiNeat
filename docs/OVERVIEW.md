# HiNeat Overview

> Vision: Notion + Twitter hybrid — note-centric social platform with multi-account, multi-server support

## Components

| Component | Tech | Status |
|-----------|------|--------|
| **KMP Client** | Compose Multiplatform, Room 3.0, Ktor client | Working — notes + tasks CRUD, 3-tier visibility, offline-first sync |
| **Ktor Server** | Ktor 3.5, Exposed ORM, SQLite, JWT | Working — single hardcoded user, CRUD, public posts |
| **Infrastructure** | OKE + CloudNativePG on OCI, OpenTofu | Production — 19 CI/CD workflows |

## Targets

- **Android** — min SDK 24
- **iOS** — arm64 + simulator
- **Desktop** — JVM (DMG/MSI/DEB)
- **Web** — WasmJS + Cloudflare Pages

## Key Features

- Offline-first sync with 3-tier visibility (LOCAL / PRIVATE / PUBLIC)
- Markdown note editor with task list toggle
- Cross-platform: shared UI via Compose Multiplatform
- Multi-server Explore: browse public posts from any server
- JWT authentication with server-authoritative sync

## Quick Links

- [Architecture](ARCHITECTURE.md)
- [Product Roadmap](plans/ROADMAP.md)
- [Infrastructure Docs](infrastructure/README.md)
