# HiNeat Documentation

**HiNeat** is a note-centric social platform (Notion + Twitter hybrid) with multi-account, multi-server support. A Kotlin Multiplatform monorepo with a Ktor backend and OCI infrastructure.

## Contents

| Section | Description |
|---------|-------------|
| [Project Overview](OVERVIEW.md) | What is HiNeat — vision, status, tech stack |
| [Architecture](ARCHITECTURE.md) | Full system architecture review |
| |
| **Client** | Kotlin Multiplatform (Compose) app |
| → [Overview & Build](client/README.md) | Build & run on Android, iOS, Desktop, Web |
| → [Build Guide](client/BUILD.md) | Detailed build instructions per platform |
| → [Architecture](client/ARCHITECTURE.md) | MVVM, sync engine, Room, navigation |
| |
| **Server** | Ktor backend |
| → [Overview](server/README.md) | Server architecture, dependencies, config |
| → [API Reference](server/API.md) | All API endpoints |
| → [Auth Flow](server/AUTH.md) | JWT authentication, security |
| |
| **Infrastructure** | OCI OKE cluster |
| → [Overview](infrastructure/README.md) | OKE provisioning, networking, PostgreSQL |
| → [Security](infrastructure/SECURITY.md) | Security audit & credential hygiene |
| → [CI/CD](infrastructure/CI_CD.md) | GitHub Actions workflows |
| |
| **Deployment** | Server & web client deployment |
| → [Strategy](deployment/OVERVIEW.md) | Deployment architecture |
| → [CI/CD](deployment/CI_CD.md) | Pipeline reference |
| |
| **Plans** | Roadmap & implementation plans |
| → [Product Roadmap](plans/ROADMAP.md) | 9-phase product plan |
| → [Phase 1–5 Plan](plans/PHASE_1_5.md) | Local-first CMS features |
