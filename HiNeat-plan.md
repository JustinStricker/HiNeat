# HiNeat Plan

> Generated: 2026-06-10
> Codebase: HiNeat (KMP client + Ktor server + OCI infra)
> Vision: Notion + Twitter hybrid — note-centric social platform with multi-account, multi-server support

---

## Current State Summary

| Component | Status |
|-----------|--------|
| KMP Client (Android/iOS/Desktop/Web) | Working — notes + tasks CRUD, 3-tier visibility, offline-first sync |
| Ktor Server | Working — single hardcoded user, notes/tasks CRUD, public posts, JWT auth |
| Infrastructure | Production — OKE + CloudNativePG on OCI, 19 CI/CD workflows |
| Multi-user | None — hardcoded admin credentials + hardcoded JWT secret |
| Social features | None — only public post browsing |
| Multi-account | None — single token + single server URL |

---

## Phase 0: Security Fix + Repo Restructure

**Goal:** Fix critical security issues, then clean module boundaries.

### 0a: Critical Security Fix (do first, 30 min)

This is not in the original plan but is a prerequisite for anything public-facing.

**Files to modify:**

| File | Change |
|------|--------|
| `app/server/src/main/kotlin/com/hineat/auth/JwtConfig.kt` | Read `secret`, `issuer`, `audience` from env vars with fallback defaults |
| `app/server/src/main/kotlin/com/hineat/auth/AuthService.kt` | Remove hardcoded `VALID_USERNAME`/`VALID_PASSWORD`; read from env vars (`ADMIN_USERNAME`, `ADMIN_PASSWORD`) |
| `infrastructure/k8s/app/deployment.yaml` | Add `JWT_SECRET`, `ADMIN_USERNAME`, `ADMIN_PASSWORD` env vars from K8s secrets |
| `app/server/Dockerfile` | No change needed (env vars pass through) |

**JwtConfig.kt target state:**
```kotlin
object JwtConfig {
    val secret: String = System.getenv("JWT_SECRET") ?: "dev-only-secret-change-in-prod"
    val issuer: String = System.getenv("JWT_ISSUER") ?: "com.hineat"
    val audience: String = System.getenv("JWT_AUDIENCE") ?: "com.hineat"
    val expirationMillis: Long = 3600000L
}
```

**AuthService.kt target state:**
```kotlin
private val validUsername: String = System.getenv("ADMIN_USERNAME") ?: "admin"
private val validPassword: String = System.getenv("ADMIN_PASSWORD") ?: "changeme"
```

**K8s secret to create:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: hineat-server-secrets
type: Opaque
stringData:
  JWT_SECRET: "<generated-64-char-hex>"
  ADMIN_USERNAME: "admin"
  ADMIN_PASSWORD: "<strong-password>"
```

**Validation:** Server starts, login with new env-configured credentials works, old hardcoded values no longer compile.

### 0b: Repo Restructure

**Goal:** Split `:app:shared` → `:shared:core` + `:shared:ui`, rename `:app:composeApp` → `:app`.

**Target structure:**
```
tidynet/
  settings.gradle.kts
  :shared:core       ← models, API clients, settings, sync engine
  :shared:ui         ← common composables (AppTheme, MarkdownText, AppDrawer)
  :app               ← KMP client (was :app:composeApp)
  :server            ← Ktor server (was :app:server)
  infrastructure/    ← unchanged
```

**Step-by-step:**

1. **Create `shared/core/` module:**
   - Move `app/shared/src/` → `shared/core/src/`
   - Move `app/shared/build.gradle.kts` → `shared/core/build.gradle.kts`
   - Package stays `com.hineat`

2. **Create `shared/ui/` module:**
   - Create `shared/ui/build.gradle.kts` (KMP library, depends on `:shared:core` + Compose)
   - Move from `app/composeApp/src/commonMain/kotlin/com/hineat/core/`:
     - `AppTheme.kt` → `shared/ui/src/commonMain/kotlin/com/hineat/ui/AppTheme.kt`
     - `MarkdownText.kt` → `shared/ui/src/commonMain/kotlin/com/hineat/ui/MarkdownText.kt`
     - `AppDrawer.kt` → `shared/ui/src/commonMain/kotlin/com/hineat/ui/AppDrawer.kt`
   - Update package declarations from `com.hineat.core` → `com.hineat.ui`

3. **Rename `app/composeApp/` → `app/`:**
   - Move `app/composeApp/build.gradle.kts` → `app/build.gradle.kts`
   - Move `app/composeApp/src/` → `app/src/`
   - Remove old `app/composeApp/` directory
   - Update imports in all files: `com.hineat.core.AppTheme` → `com.hineat.ui.AppTheme`, etc.

4. **Rename `app/server/` → `server/`:**
   - Move `app/server/build.gradle.kts` → `server/build.gradle.kts`
   - Move `app/server/src/` → `server/src/`
   - Remove old `app/server/` directory

5. **Update `settings.gradle.kts`:**
```kotlin
rootProject.name = "HiNeat"
include(":shared:core", ":shared:ui", ":app", ":server")
```

6. **Update build dependencies:**

   `app/build.gradle.kts`:
   ```kotlin
   implementation(project(":shared:core"))
   implementation(project(":shared:ui"))
   ```
   (was `implementation(project(":app:shared"))`)

   `server/build.gradle.kts`:
   ```kotlin
   implementation(project(":shared:core"))
   ```
   (was `implementation(project(":app:shared"))`)

   `shared/ui/build.gradle.kts`:
   ```kotlin
   implementation(project(":shared:core"))
   implementation(compose.runtime)
   implementation(compose.foundation)
   implementation(compose.material3)
   ```

7. **Update `app/build.gradle.kts` root-level dependencies block:**
   The `dependencies { }` block at the bottom with KSP entries needs path updates since the module moved.

**Validation:** Full build passes (`./gradlew build`), all tests pass, app runs on all targets.

**Files touched:** ~15 (build files + moved source files with package updates)

**Risk:** Medium — this is mechanical but touches many files. Do it in one commit. Use IDE refactoring where possible.

---

## Phase 1: Server — Multi-User Auth

**Goal:** Replace single hardcoded user with proper multi-user registration + login.

### New Dependencies

`server/build.gradle.kts`:
```kotlin
implementation("at.favre.lib:bcrypt:0.10.4")
```

### New Table: `users`

Add to `server/src/main/kotlin/com/hineat/core/Tables.kt`:

```kotlin
object Users : Table("users") {
    val id = varchar("id", 36)
    val username = varchar("username", 64).uniqueIndex()
    val displayName = varchar("display_name", 128)
    val email = varchar("email", 255).nullable()
    val passwordHash = varchar("password_hash", 255)
    val bio = text("bio").default("")
    val avatarUrl = varchar("avatar_url", 512).nullable()
    val createdAt = long("created_at")
    val deletedAt = long("deleted_at").nullable()

    override val primaryKey = PrimaryKey(id)
}
```

**Migration strategy:** Add `SchemaUtils.createMissingTablesAndColumns(Users)` in `DatabaseFactory.init()`. Exposed handles idempotent table creation.

### New File: `UserService.kt`

`server/src/main/kotlin/com/hineat/auth/UserService.kt`:

```kotlin
class UserService {
    fun createUser(username: String, displayName: String, email: String?, password: String): User
    fun findByUsername(username: String): User?
    fun findById(id: String): User?
    fun verifyPassword(password: String, hash: String): Boolean
    fun updateProfile(userId: String, displayName: String?, bio: String?, avatarUrl: String?): User
}
```

Password hashing: `BCrypt.withDefaults().hashToString(12, password.toCharArray())`
Verification: `BCrypt.verifyer().verify(password.toCharArray(), hash)`

### Modified: `AuthService.kt`

Remove hardcoded credentials entirely. New methods:
- `register(request: RegisterRequest): Pair<String, User>?` — creates user, returns JWT + user
- `login(request: LoginRequest): Pair<String, User>?` — verifies credentials, returns JWT + user
- `generateToken(username: String): String` — stays the same

### Modified: `AuthRoutes.kt`

New endpoints:
```
POST /auth/register    — { username, displayName?, email?, password } → { token, user }
POST /auth/login       — { username, password } → { token, user }
GET  /auth/me          — (authenticated) → { user }
```

**Note:** The plan says `POST /login` stays. For backward compatibility, keep `POST /login` as an alias for `POST /auth/login` during transition.

### Modified: `Application.kt`

- Add `UserService` initialization
- Pass `UserService` to `authRoutes`
- Update JWT verifier to also store `userId` claim (not just `username`)
- Add `/auth/me` to authenticated routes

### Data Classes

`server/src/main/kotlin/com/hineat/auth/AuthModels.kt`:
```kotlin
@Serializable data class RegisterRequest(val username: String, val displayName: String? = null, val email: String? = null, val password: String)
@Serializable data class LoginRequest(val username: String, val password: String)
@Serializable data class UserResponse(val id: String, val username: String, val displayName: String, val email: String?, val bio: String, val avatarUrl: String?, val createdAt: Long)
```

### Validation
- Register new user → get JWT → access authenticated endpoints
- Login with registered user → get JWT
- `/auth/me` returns current user profile
- Duplicate username → 409 Conflict
- Wrong password → 401 Unauthorized

**Files created:** 2 (`UserService.kt`, `AuthModels.kt`)
**Files modified:** 4 (`Tables.kt`, `AuthService.kt`, `AuthRoutes.kt`, `Application.kt`)
**Estimated effort:** 2-3 hours

---

## Phase 2: Server — Social Data Model

**Goal:** Add database tables for follows, likes, comments, notifications. Extend visibility.

### New Tables in `Tables.kt`

```kotlin
object Follows : Table("follows") {
    val followerId = varchar("follower_id", 36) references Users.id
    val followeeId = varchar("followee_id", 36) references Users.id
    val createdAt = long("created_at")

    override val primaryKey = PrimaryKey(followerId, followeeId)
}

object Likes : Table("likes") {
    val userId = varchar("user_id", 36) references Users.id
    val noteId = varchar("note_id", 36) references Notes.id
    val createdAt = long("created_at")

    override val primaryKey = PrimaryKey(userId, noteId)
}

object Comments : Table("comments") {
    val id = varchar("id", 36)
    val noteId = varchar("note_id", 36) references Notes.id
    val authorId = varchar("author_id", 36) references Users.id
    val content = text("content")
    val createdAt = long("created_at")
    val updatedAt = long("updated_at")
    val deletedAt = long("deleted_at").nullable()

    override val primaryKey = PrimaryKey(id)
}

object Notifications : Table("notifications") {
    val id = varchar("id", 36)
    val userId = varchar("user_id", 36) references Users.id  // recipient
    val type = varchar("type", 32)  // follow, like, comment, mention
    val actorId = varchar("actor_id", 36) references Users.id
    val noteId = varchar("note_id", 36).nullable() references Notes.id
    val read = bool("read").default(false)
    val createdAt = long("created_at")

    override val primaryKey = PrimaryKey(id)
}
```

### Extend Visibility Enum

`shared/core/src/commonMain/kotlin/com/hineat/core/Visibility.kt`:
```kotlin
@Serializable
enum class Visibility(val displayName: String) {
    LOCAL("Local"),
    PRIVATE("Private"),
    FOLLOWERS("Followers"),
    PUBLIC("Public")
}
```

**Breaking change analysis:**
- JSON serialization: `@Serializable` uses name strings, not ordinals → safe
- Room TypeConverter: uses `Visibility.valueOf()` string lookup → safe if migration handles it
- Exposed on server: stored as `varchar` → safe
- Sync engine: filters `visibility != LOCAL` → `FOLLOWERS` would be synced, which is correct
- **Risk:** Client-side Room database version bump needed if any existing data references visibility as ordinal. Check `Converters.kt`.

### Visibility Access Rules

| Visibility | Who can see |
|-----------|-------------|
| LOCAL | Only the device owner (never leaves device) |
| PRIVATE | Only the note owner (synced to server) |
| FOLLOWERS | Owner + their followers |
| PUBLIC | Everyone |

### Validation
- All new tables created successfully
- Existing notes with `PRIVATE`/`PUBLIC` visibility still work
- `FOLLOWERS` visibility can be assigned to new notes

**Files modified:** 2 (`Tables.kt`, `Visibility.kt`)
**Estimated effort:** 1-2 hours

---

## Phase 3: Server — Social API

**Goal:** Endpoints for feed, follows, likes, comments, notifications, profiles.

**Recommended split:** Do this in 3 sub-phases to manage complexity.

### Phase 3a: Follows + User Profiles (do first)

**New files:**

| File | Purpose |
|------|---------|
| `server/src/main/kotlin/com/hineat/social/UserRoutes.kt` | Profile viewing, profile updates |
| `server/src/main/kotlin/com/hineat/social/FollowRoutes.kt` | Follow/unfollow, follower/following lists |
| `server/src/main/kotlin/com/hineat/social/SocialModels.kt` | Request/response data classes |

**Endpoints:**
```
GET    /users/{username}              — public profile
GET    /users/{username}/followers    — paginated follower list
GET    /users/{username}/following    — paginated following list
POST   /users/{username}/follow       — follow (authenticated)
POST   /users/{username}/unfollow     — unfollow (authenticated)
PUT    /users/me/profile              — update own profile
```

### Phase 3b: Likes + Comments

**New files:**

| File | Purpose |
|------|---------|
| `server/src/main/kotlin/com/hineat/social/LikeRoutes.kt` | Like/unlike notes |
| `server/src/main/kotlin/com/hineat/social/CommentRoutes.kt` | CRUD comments |

**Endpoints:**
```
POST   /notes/{id}/like          — like (authenticated)
DELETE /notes/{id}/like          — unlike (authenticated)
GET    /notes/{id}/likes         — who liked (paginated)
POST   /notes/{id}/comments      — add comment (authenticated)
GET    /notes/{id}/comments      — list comments (paginated)
PUT    /comments/{id}            — edit own comment
DELETE /comments/{id}            — delete own comment (soft delete)
```

### Phase 3c: Feed + Notifications

**New files:**

| File | Purpose |
|------|---------|
| `server/src/main/kotlin/com/hineat/social/FeedRoutes.kt` | Home timeline |
| `server/src/main/kotlin/com/hineat/social/FeedService.kt` | Feed query logic |
| `server/src/main/kotlin/com/hineat/social/NotificationRoutes.kt` | Notification list + mark read |
| `server/src/main/kotlin/com/hineat/social/NotificationService.kt` | Notification creation + delivery |

**Endpoints:**
```
GET    /feed                      — paginated (own posts + followed users' PUBLIC/FOLLOWERS posts)
GET    /notifications             — paginated, unread count
POST   /notifications/read        — mark all as read
```

**Feed query logic:**
```sql
SELECT * FROM notes
WHERE owner_id = :userId  -- own posts
   OR (
     owner_id IN (SELECT followee_id FROM follows WHERE follower_id = :userId)
     AND visibility IN ('PUBLIC', 'FOLLOWERS')
   )
ORDER BY updated_at DESC
LIMIT :limit OFFSET :offset
```

### Register all social routes in `Application.kt`

```kotlin
authenticate("auth-jwt") {
    // existing routes...
    userRoutes(userService)
    followRoutes(followService)
    likeRoutes(likeService)
    commentRoutes(commentService)
    feedRoutes(feedService)
    notificationRoutes(notificationService)
}
```

### Validation
- Follow a user → their FOLLOWERS posts appear in your feed
- Like a note → like count increments, notification created for owner
- Comment on a note → comment appears, notification created
- Notifications endpoint returns unread count

**Files created:** ~8
**Files modified:** 2 (`Application.kt`, `Tables.kt` if anything was missed)
**Estimated effort:** 6-8 hours (across 3 sub-phases)

---

## Phase 4: Client — Multi-Account Profiles

**Goal:** Client supports multiple accounts on different servers.

### New File: `AccountManager.kt`

`shared/core/src/commonMain/kotlin/com/hineat/core/AccountManager.kt`:

```kotlin
@Serializable
data class AccountProfile(
    val id: String,           // UUID
    val serverUrl: String,
    val username: String,
    val displayName: String,
    val token: String,
    val avatarUrl: String? = null
)

class AccountManager(private val settings: Settings) {
    val accounts: StateFlow<List<AccountProfile>>
    val activeAccount: StateFlow<AccountProfile?>

    fun addAccount(serverUrl: String, username: String, token: String, displayName: String)
    fun removeAccount(id: String)
    fun switchAccount(id: String)
    fun getAccount(id: String): AccountProfile?
}
```

**Storage:** Serialize account list as JSON string in `multiplatform-settings`. Key: `"account_profiles"`.

### Modified: `AppSettings.kt`

`AppSettings` becomes a thin wrapper that delegates to `AccountManager`:
```kotlin
object AppSettings {
    private val accountManager = AccountManager(Settings())

    val authToken: String? get() = accountManager.activeAccount.value?.token
    val baseUrl: String get() = accountManager.activeAccount.value?.serverUrl ?: ""
    // ... delegate to accountManager
}
```

**Migration:** Existing single-token login → auto-create an `AccountProfile` from the saved token + server URL. One-time migration on app start.

### Modified: `BaseClient.kt`

`BaseClient` already has `setToken()` and `updateServerUrl()`. When `AccountManager.activeAccount` changes, all clients need to be updated. Add a listener:

```kotlin
// In App.kt or a dedicated initializer
collectAsState(accountManager.activeAccount) { account ->
    account?.let {
        noteClient.updateServerUrl(it.serverUrl)
        noteClient.setToken(it.token)
        taskClient.updateServerUrl(it.serverUrl)
        taskClient.setToken(it.token)
    }
}
```

### Modified: `App.kt`

- Initialize `AccountManager` in `remember {}`
- Pass `AccountManager` to ViewModels that need it
- Add account switcher in the drawer or top bar

### Modified: All ViewModels

Each ViewModel currently gets repos via constructor. No change needed if repos are already injected — the `AccountManager` listener on `BaseClient` handles server URL + token switching.

**Exception:** `SyncViewModel` and `AuthViewModel` need to know about accounts for login/logout flows.

### UI: Account Switcher

Add to `AppDrawer.kt` (or new `AccountSwitcher.kt`):
- List of saved accounts with avatar + username + server
- Active account highlighted
- "Add Account" button → navigates to login screen
- Swipe-to-delete or long-press to remove
- Tap to switch

### UI: First Launch

On first launch (no accounts):
- Show server URL entry field (default: flagship instance URL)
- Then login/register flow
- On success, save as first account

### Validation
- Add account on Server A → see Server A's notes
- Switch to Server B → see Server B's notes
- Both accounts persist across app restarts
- Removing an account clears its local data

**Files created:** 2 (`AccountManager.kt`, `AccountSwitcher.kt`)
**Files modified:** 5-6 (`AppSettings.kt`, `App.kt`, `AuthViewModel.kt`, `SyncViewModel.kt`, `AppDrawer.kt`)
**Estimated effort:** 4-6 hours

---

## Phase 5: Client — Feed Screen

**Goal:** Home timeline showing posts from followed users.

### New Files

| File | Purpose |
|------|---------|
| `app/src/commonMain/kotlin/com/hineat/feed/FeedScreen.kt` | Feed UI composable |
| `app/src/commonMain/kotlin/com/hineat/feed/FeedViewModel.kt` | Feed state management |
| `app/src/commonMain/kotlin/com/hineat/feed/FeedRepository.kt` | API calls to `/feed` |
| `app/src/commonMain/kotlin/com/hineat/feed/PostCard.kt` | Reusable post card composable |

### FeedScreen Design

```
┌─────────────────────────────────────┐
│  Feed                          🔔   │  ← Top bar with notification bell
├─────────────────────────────────────┤
│  ┌─ PostCard ─────────────────────┐ │
│  │ 🖼 Avatar  Username  ·  2h ago │ │
│  │ Note content rendered as        │ │
│  │ markdown...                     │ │
│  │                                 │ │
│  │ ❤️ 12  💬 3  ↗ Share           │ │
│  └─────────────────────────────────┘ │
│  ┌─ PostCard ─────────────────────┐ │
│  │ ...                             │ │
│  └─────────────────────────────────┘ │
│           ↓ Loading more...          │
└─────────────────────────────────────┘
```

### PostCard Composable

```kotlin
@Composable
fun PostCard(
    post: FeedPost,
    onLike: () -> Unit,
    onComment: () -> Unit,
    onProfileClick: () -> Unit,
    onContentClick: () -> Unit
)
```

**FeedPost model:**
```kotlin
data class FeedPost(
    val note: Note,
    val author: UserResponse,
    val likeCount: Int,
    val commentCount: Int,
    val isLikedByMe: Boolean
)
```

### FeedViewModel

```kotlin
class FeedViewModel(private val feedRepository: FeedRepository) : ViewModel() {
    val feed: StateFlow<PagingData<FeedPost>>
    val isLoading: StateFlow<Boolean>
    val error: StateFlow<String?>

    fun refresh()
    fun loadMore()
    fun like(postId: String)
    fun unlike(postId: String)
}
```

**Pagination:** Use cursor-based pagination (server returns `nextCursor` with each page). Client fetches 20 posts per page.

### Navigation Updates

`Navigation.kt` — add:
```kotlin
@Serializable object Feed : Screen()
```

Update `App.kt` NavHost:
- Default screen: `Feed` if user is logged in and has social features; otherwise `NotesList`
- Add Feed to drawer

### Validation
- Feed loads posts from followed users
- Pull-to-refresh works
- Infinite scroll loads more posts
- Like button toggles optimistically

**Files created:** 4
**Files modified:** 2 (`Navigation.kt`, `App.kt`)
**Estimated effort:** 4-6 hours

---

## Phase 6: Client — Social Interactions

**Goal:** Like, comment, follow, notify in the UI.

### New/Modified Files

| File | Purpose |
|------|---------|
| `shared/core/.../SocialClient.kt` | API calls for likes, comments, follows |
| `app/.../ProfileScreen.kt` | User profile view with follow button |
| `app/.../ProfileViewModel.kt` | Profile state |
| `app/.../CommentSheet.kt` | Bottom sheet with comments + input |
| `app/.../NotificationsScreen.kt` | Notification list |
| `app/.../NotificationsViewModel.kt` | Notification state |

### SocialClient.kt

```kotlin
class SocialClient(httpClient: HttpClient) : BaseClient(httpClient) {
    suspend fun follow(username: String)
    suspend fun unfollow(username: String)
    suspend fun like(noteId: String)
    suspend fun unlike(noteId: String)
    suspend fun getComments(noteId: String, cursor: String?): PaginatedResponse<Comment>
    suspend fun addComment(noteId: String, content: String): Comment
    suspend fun getNotifications(cursor: String?): PaginatedResponse<Notification>
    suspend fun markNotificationsRead()
    suspend fun getUserProfile(username: String): UserResponse
    suspend fun getUserPosts(username: String, cursor: String?): PaginatedResponse<Note>
}
```

### UI Additions

1. **Heart/like button** on every `PostCard` — animated toggle
2. **Comment icon** on `PostCard` → opens `CommentSheet`
3. **Follow button** on `ProfileScreen` — toggles follow/unfollow
4. **Notification bell** in top bar with unread count badge
5. **Avatar tappable** → navigate to `ProfileScreen`

### ProfileScreen

```
┌─────────────────────────────────────┐
│  ←  User Profile                    │
├─────────────────────────────────────┤
│         🖼 Large Avatar              │
│         Display Name                │
│         @username                   │
│         Bio text here...            │
│                                     │
│         [Follow] / [Following]      │
│                                     │
│    12 Following  ·  34 Followers   │
├─────────────────────────────────────┤
│  User's Posts:                      │
│  ┌─ PostCard ─────────────────────┐ │
│  │ ...                             │ │
│  └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### CommentSheet

Bottom sheet with:
- List of comments (avatar + username + content + timestamp)
- Text input at bottom
- Send button

### Validation
- Tap heart → like count increments, heart fills
- Open comments → see existing comments, add new one
- Visit profile → see user info + posts, follow/unfollow
- Bell icon shows unread count, tapping marks as read

**Files created:** 6
**Files modified:** 3 (`App.kt`, `Navigation.kt`, `PostCard.kt` — add navigation callbacks)
**Estimated effort:** 6-8 hours

---

## Phase 7: Server — Ad/Sponsored System (deferred)

**Not building now.** Design considerations for when this ships:

- `sponsored_posts` table with budget tracking
- Feed endpoint accepts `adsEnabled` config flag
- Client `PostCard` renders `isSponsored` badge
- Self-hosters: `ads.enabled=false` by default
- Flagship: `ads.enabled=true`, `ads.ratio=10`

No code changes needed now. The feed architecture (cursor-based pagination, `PostCard` abstraction) should accommodate this cleanly.

---

## Phase 8: Workspace/Org Features (deferred)

**Not building now.** Depends on Phase 3 (social API). Key decisions needed:

- Workspace-scoped visibility: add `WORKSPACE` to `Visibility` enum?
- Or: workspace membership controls access, visibility stays the same?
- Invitation flow: email-based vs. link-based?

---

## Phase 9: Deployment & Distribution

### Server Deployment Updates

After Phase 1, update K8s deployment:
- Add secrets for `JWT_SECRET`, `ADMIN_USERNAME`, `ADMIN_PASSWORD`
- Server reads from PostgreSQL instead of SQLite (config decision)

**Decision needed:** Stay on SQLite for self-hosters, PostgreSQL for flagship? Or migrate entirely?

If staying on SQLite:
- Current PVC mount works fine
- No changes needed

If migrating to PostgreSQL:
- Add `postgresql-jdbc` dependency to server
- Change `DatabaseFactory` to read `DATABASE_URL` env var
- Remove `sqlite-jdbc` dependency
- Update K8s deployment to connect to CloudNativePG

### App Distribution

Already configured in `app/build.gradle.kts`:
- Android: `applicationId = "com.hineat"`, min SDK 24
- Desktop: DMG/MSI/DEB targets configured
- iOS: Framework build configured
- Web: WasmJS + Cloudflare Pages

**Missing:** No signing configs for Android release, no iOS provisioning. These are manual setup steps.

---

## Build Order & Dependencies

```
Phase 0a (security fix)  ─────────────────────┐
                                                ├─→ MVP
Phase 0b (restructure)   ─────────────────────┤
                                                │
Phase 1 (multi-user auth) ────────────────────┘
                                                │
Phase 4 (multi-account client) ────────────────┤
                                                │
Phase 2 (social data model) ──────────────────┤
                                                │
Phase 3a (follows + profiles) ────────────────┤
Phase 3b (likes + comments) ──────────────────┤
Phase 3c (feed + notifications) ──────────────┤
                                                │
Phase 5 (feed screen) ────────────────────────┤
Phase 6 (social interactions) ────────────────┘
```

**MVP = Phases 0a + 0b + 1 + 4.** Ships multi-user auth + multi-account client.
**Social Release = Phases 2 + 3 + 5 + 6.** Ships feed, likes, comments, follows, notifications.

---

## Testing Strategy

| Phase | What to test | How |
|-------|-------------|-----|
| 0a | Env var loading | Unit test: `JwtConfig.secret` reads from env |
| 0b | Module dependencies | `./gradlew build` — compilation proves deps resolve |
| 1 | Register, login, me | Integration test with `ktor-server-test-host` |
| 2 | Table creation | Exposed `SchemaUtils.createMissingTablesAndColumns` + query test |
| 3 | Each endpoint group | Integration tests per route file |
| 4 | Account add/switch/remove | Unit test `AccountManager` with test `Settings` |
| 5 | Feed pagination | Integration test with seeded data |
| 6 | Social interactions | Integration test: follow → feed contains, like → count |

---

## Open Decisions

1. **PostgreSQL vs SQLite on server:** Stay dual (SQLite for self-host, PG for flagship) or migrate entirely?
2. **Open registration vs invite-only:** Flagship instance needs anti-spam. Options: captcha, invite codes, email verification, or just rate limiting.
3. **Feed algorithm:** Chronological (simple) vs. ranked (complex)? Start chronological.
4. **Notification delivery:** In-app only, or also push notifications (FCM/APNs)?
5. **FOLLOWERS visibility migration:** Existing notes stay PRIVATE. FOLLOWERS is opt-in for new notes only.
6. **License:** Apache 2.0 for client, what for server? Decide before first public release.
