# Local-First CMS — Implementation Plan (Phases 1–5)

## Current State

All foundational work complete:
- Navigation drawer with 4 items (Notes, Tasks, Explore, Settings)
- Room 3.0 local persistence for notes and tasks (3 visibility tiers)
- Ktor backend with JWT auth, sync endpoints, and public post browsing
- Client sync engine (bidirectional merge, LWW on `updatedAt`)
- Multi-server Explore screen with URL history and pagination

## Phase 1: Polish & Quick Fixes

| Step | Description | Est. Time |
|------|-------------|-----------|
| 1A | Mask password field in login | 5 min |
| 1B | Refresh button triggers server sync | 20 min |
| 1C | Visibility filter chips for Tasks | 30 min |
| 1D | Note snippet preview in list (max 200 chars) | 15 min |
| 1E | Task tags support + filtering | 1 hr |

## Phase 2: Explore Enhancements

| Step | Description | Est. Time |
|------|-------------|-----------|
| 2A | Client-side search over fetched posts | 30 min |
| 2B | HTTP fetch test coverage | 45 min |

## Phase 3: Dark Mode Toggle

User-facing toggle in Settings: `AppSettings.isDarkMode`, light color scheme, Switch in SettingsScreen.

**Est. Time:** 45 min

## Phase 4: Trash / Recently Deleted

Soft-delete notes and tasks visible in a dedicated Trash screen with restore and permanent delete.

**New files:** `TrashViewModel.kt`, `TrashScreen.kt`
**Modified:** DAOs, repositories, navigation, drawer

**Est. Time:** 2-3 hrs

## Phase 5: Data Export

Export all notes + tasks as downloadable JSON. Platform-specific save/share via `expect/actual`.

**Est. Time:** 1.5 hrs

## Implementation Order

| Priority | Phase | Est. Time |
|----------|-------|-----------|
| 1 | 1A — Mask password | 5 min |
| 2 | 1B — Refresh = Sync | 20 min |
| 3 | 1C — Task visibility filters | 30 min |
| 4 | 1D — Note snippets | 15 min |
| 5 | 4 — Trash view | 2-3 hrs |
| 6 | 3 — Dark mode toggle | 45 min |
| 7 | 1E — Task tags | 1 hr |
| 8 | 2A — Explore search | 30 min |
| 9 | 2B — Explore tests | 45 min |
| 10 | 5 — Data export | 1.5 hrs |

**Total:** ~8-10 hours

## Target State (After Phase 5)

- Password field masked during input
- Refresh button triggers server sync (with loading spinner)
- Tasks have visibility filter chips
- Notes list shows content snippets
- Tasks support tags with tag-chip filtering
- Explore screen has client-side search
- Explore HTTP fetch logic has test coverage
- Dark mode toggle with light color scheme
- Trash screen with restore and permanent delete
- Data export as downloadable JSON
- All deletes go to Trash first (soft delete)


