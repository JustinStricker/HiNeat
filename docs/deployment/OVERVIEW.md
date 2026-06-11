# Deployment Strategy

| Component | Where | How |
|-----------|-------|-----|
| **Ktor Server** (API) | OCI OKE | Docker → OCIR → K8s manifests |
| **Compose Web Client** (Wasm/JS) | Cloudflare Pages | Static file deploy via Wrangler |

## Architecture

```
┌─ Browser ──────────────────────────────────────────────┐
│  cloudflare.pages.dev                                   │
│  ┌──────────────────────────────────────────────────┐  │
│  │ index.html → composeApp.js → composeApp.wasm      │  │
│  │     └── App() ──┬── Compose UI                    │  │
│  │                  └── Ktor HTTP Client ────────────┼──┼──► OCI OKE LoadBalancer
│  └──────────────────────────────────────────────────┘  │   (Ktor server :8080)
└────────────────────────────────────────────────────────┘
```

## Server → OKE

### Docker Build

Multi-stage ARM64 Dockerfile (`app/server/Dockerfile`):

1. **Stage 1:** `gradle:8.9.0-jdk21` — `./gradlew :app:server:installDist`
2. **Stage 2:** `eclipse-temurin:21-jre` — run `/app/server/bin/server`

### K8s Manifests

- **`deployment.yaml`** — 1 replica, port 8080, liveness/readiness probes, 1Gi PVC (oci-bv) for SQLite
- **`service.yaml`** — LoadBalancer, port 80 → 8080

### CI/CD Pipeline

1. Build & test server
2. Build Docker image → push to OCIR (Oracle Container Image Registry)
3. Generate kubeconfig via OCI CLI
4. `kubectl apply` manifests
5. Wait for rollout, show LoadBalancer IP

## Web Client → Cloudflare Pages

### Build

```sh
./gradlew :app:composeApp:wasmJsBrowserDistribution
```

Output: `app/composeApp/build/dist/wasmJs/productionExecutable/`

### SPA Routing

A `_redirects` file serves `index.html` for all routes:

```
/*  /index.html  200
```

### Deploy

```sh
npx wrangler pages deploy \
  app/composeApp/build/dist/wasmJs/productionExecutable/ \
  --project-name=notable-web
```

### CORS

Already configured on the Ktor server: `install(CORS) { anyHost() }`.

## Teardown Order

1. Web — `[Web] Destroy` workflow
2. App — `[App] Destroy` workflow
3. PostgreSQL — `make postgres-destroy`
4. Backups — `make backups-destroy`
5. Infrastructure — `make destroy`
