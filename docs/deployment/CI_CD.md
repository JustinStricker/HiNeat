# CI/CD Pipelines — Deployment

Two independent GitHub Actions workflows.

## App CI (Server → OKE)

**File:** `.github/workflows/app-ci.yml`
**Trigger:** workflow_dispatch

### Jobs

**`test`** — `./gradlew :app:server:build :app:server:test`

**`deploy`** (needs: test):
1. `./gradlew :app:server:installDist`
2. Create OCIR repo (self-healing)
3. OCIR registry + docker login
4. `docker/build-push-action` → OCIR (`linux/arm64`)
5. Generate kubeconfig via OCI CLI
6. `kubectl apply` deployment.yaml + service.yaml
7. Wait for rollout + show LoadBalancer IP

## Web Deploy (Client → Cloudflare Pages)

**File:** `.github/workflows/web-deploy.yml`
**Trigger:** push to `main` (path-filtered)

### Path Filters

| Path | Rationale |
|------|-----------|
| `app/composeApp/**` | Web UI source, resources, build config |
| `app/shared/**` | Shared data models & API clients |
| `gradle/**` | Version catalog, wrapper, plugin changes |
| `.github/workflows/web-deploy.yml` | Self-trigger |

### Single Job

```yaml
- run: ./gradlew :app:composeApp:wasmJsBrowserDistribution --no-daemon
- uses: cloudflare/wrangler-action@v3
  with:
    command: pages deploy ... --project-name=notable-web
```

## Required Secrets

| Secret | Used By | Source |
|--------|---------|--------|
| `OCI_AUTH_TOKEN` | App CI | OCI Console → User Settings → Auth Tokens |
| `OCIR_USER_NAME` | App CI | Your OCI username |
| `CLOUDFLARE_API_TOKEN` | Web Deploy | Cloudflare Dashboard → API Tokens |
| `CLOUDFLARE_ACCOUNT_ID` | Web Deploy | Cloudflare Dashboard → Account ID |
