# API Reference

All endpoints are served under the configured server URL. Authenticated endpoints require `Authorization: Bearer <jwt-token>` header.

## Authentication

### POST `/login`

Authenticate with admin credentials.

**Request:**
```json
{ "username": "admin", "password": "<password>" }
```

**Response `200`:**
```json
{ "token": "jwt-token-string" }
```

**Response `401`:**
```
Invalid credentials
```

## Public (No Auth)

### GET `/public/posts`

Paginated list of PUBLIC notes.

**Query params:** `limit` (default 20), `offset` (default 0)

**Response `200`:**
```json
{
  "posts": [{ "id": "...", "title": "...", "content": "...", ... }],
  "total": 42,
  "offset": 0
}
```

### GET `/public/posts/{slug}`

Get a single public note by slug or ID.

**Response `200`:**
```json
{ "post": { "id": "...", "title": "...", ... } }
```

**Response `404`:** `Not found`

## Notes (Authenticated)

### GET `/notes`

List all notes.

**Response `200`:** `[{ "id": "...", "title": "...", ... }]`

### POST `/notes`

Create a new note.

**Request:** Full `Note` object (ownerId is overridden from JWT)

**Response `201`:** Created `Note`

### PUT `/notes/{id}`

Update an existing note. `{id}` in path must match `id` in body.

**Response `200`:** Updated `Note`

**Response `400`:** `ID mismatch`

**Response `404`:** `Not found`

### DELETE `/notes/{id}`

Delete a note.

**Response `200`:** `Deleted`

**Response `404`:** `Not found`

### DELETE `/notes/all`

Delete all notes.

**Response `200`:** `{ "deleted": 5 }`

### POST `/notes/reorder`

Reorder notes.

**Request:** `[{ "id": "...", "position": 0 }, ...]`

**Response `200`**

### PATCH `/notes/{id}/toggle-task`

Toggle a task checkbox line in a note.

**Request:** `{ "lineIndex": 3 }`

**Response `200`:** Updated `Note`

**Response `400`:** `Not found or not a task line`

## Tasks (Authenticated)

### GET `/tasks`

List all tasks.

**Response `200`:** `[{ "id": "...", "title": "...", ... }]`

### POST `/tasks`

Create a new task.

**Response `201`:** Created `Task`

### PUT `/tasks/{id}`

Update a task.

**Response `200`:** Updated `Task`

### DELETE `/tasks/{id}`

Delete a task.

**Response `200`:** `Deleted`

### DELETE `/tasks/all`

Delete all tasks.

**Response `200`:** `{ "deleted": 5 }`

### POST `/tasks/reorder`

Reorder tasks.

**Request:** `[{ "id": "...", "position": 0 }, ...]`

**Response `200`**

## Sync (Authenticated)

### GET `/sync/notes`

Paginated sync pull for notes.

**Query params:** `limit` (default 50), `offset` (default 0)

**Response `200`:**
```json
{
  "items": [{ ... }],
  "hasNextPage": true,
  "nextOffset": 50
}
```

### GET `/sync/tasks`

Paginated sync pull for tasks.

**Response `200`:**
```json
{
  "items": [{ ... }],
  "hasNextPage": false,
  "nextOffset": 0
}
```

## Health

### GET `/`

**Response `200`:** `Notes server is running`
