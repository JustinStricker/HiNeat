# Product Roadmap

> Generated: 2026-06-10

**Vision:** Notion + Twitter hybrid — note-centric social platform with multi-account, multi-server support.

## Current State

| Component | Status |
|-----------|--------|
| KMP Client (Android/iOS/Desktop/Web) | Working — notes + tasks CRUD, 3-tier visibility, offline-first sync |
| Ktor Server | Working — single hardcoded user, notes/tasks CRUD, public posts, JWT auth |
| Infrastructure | Production — OKE + CloudNativePG on OCI, 19 CI/CD workflows |
| Multi-user | None — hardcoded admin credentials + hardcoded JWT secret |
| Social features | None — only public post browsing |
| Multi-account | None — single token + single server URL |

## Phase 0: Security Fix + Repo Restructure

**Goal:** Fix critical security issues, then clean module boundaries.

### 0a: Security Fix (30 min)

Move JWT secret and admin credentials from hardcoded values to environment variables.

**Files:**
- `app/server/.../auth/JwtConfig.kt` — read `secret`, `issuer`, `audience` from env
- `app/server/.../auth/AuthService.kt` — read credentials from `ADMIN_USERNAME`/`ADMIN_PASSWORD` env vars
- `infrastructure/k8s/app/deployment.yaml` — add env vars from K8s secrets
- Create `hineat-server-secrets` K8s Secret

### 0b: Repo Restructure

Split `:app:shared` → `:shared:core` + `:shared:ui`, rename `:app:composeApp` → `:app`, rename `:app:server` → `:server`.

## Phase 1: Server — Multi-User Auth

Replace single hardcoded user with proper registration + login.

**New:** `UserService`, bcrypt password hashing, `users` table, `/auth/register`, `/auth/login`, `/auth/me`

## Phase 2: Server — Social Data Model

Add tables for follows, likes, comments, notifications. Add `FOLLOWERS` visibility.

## Phase 3: Server — Social API

- **3a:** Follows + user profiles
- **3b:** Likes + comments
- **3c:** Feed + notifications

## Phase 4: Client — Multi-Account Profiles

Support multiple accounts on different servers. `AccountManager` with JSON-serialized profile storage.

## Phase 5: Client — Feed Screen

Home timeline showing posts from followed users. Cursor-based pagination, PostCard composable.

## Phase 6: Client — Social Interactions

Like, comment, follow, notify in the UI. ProfileScreen, CommentSheet, NotificationsScreen.

## Phases 7–8: Deferred

- **7:** Ad/Sponsored system
- **8:** Workspace/Org features

## Phase 9: Deployment & Distribution

K8s secrets, PostgreSQL migration decision, signing configs for release.

## Build Order

```
Phase 0a (security)  ───────┐
                             ├─→ MVP
Phase 0b (restructure) ─────┤
                             │
Phase 1 (multi-user auth) ──┘
                             │
Phase 4 (multi-account) ─────┤
                             │
Phase 2 (social data model) ─┤
                             │
Phase 3a (follows) ─────────┤
Phase 3b (likes/comments) ──┤
Phase 3c (feed/notif) ─────┤
                             │
Phase 5 (feed screen) ─────┤
Phase 6 (social UX) ───────┘
```

**MVP = Phases 0a + 0b + 1 + 4** — multi-user auth + multi-account client.
**Social Release = Phases 2 + 3 + 5 + 6** — feed, likes, comments, follows, notifications.

## Open Decisions

1. PostgreSQL vs SQLite on server?
2. Open registration vs invite-only?
3. Chronological vs ranked feed? (Start chronological)
4. In-app only or push notifications?
5. License: Apache 2.0 for client, what for server?


