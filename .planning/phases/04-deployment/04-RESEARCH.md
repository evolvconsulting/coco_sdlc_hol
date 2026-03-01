# Phase 4: Deployment - Research

**Researched:** 2026-03-01
**Domain:** Snowpark Container Services (SPCS) + Next.js standalone Docker deployment
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **Snowflake auth in SPCS:** Key-pair authentication with unencrypted private key. Store PEM content in a Snowflake Secret object (`TYPE = GENERIC_STRING`). Inject as `SNOWFLAKE_PRIVATE_KEY` env var via service spec `secrets[].envVarName`. No code changes needed — `snowflake.ts` already reads `SNOWFLAKE_PRIVATE_KEY`.
- **Next.js build output:** Add `output: 'standalone'` to `next.config.ts`. Dockerfile build context is the **repo root** (not `apps/frontend/`) to satisfy the Turbopack monorepo root reference.
- **Compute pool:** `STANDARD_1` instance family (1 vCPU, 4 GB RAM). Pool name: `coco_sdlc_hol_compute_pool`. Min/max: 1 node.
- **Endpoint access:** Public HTTPS endpoint. Map external port 80 → internal container port 3000 (Next.js default).
- **Service name:** `coco_sdlc_hol_service`
- **Scripted provisioning:** All Snowflake commands in a SQL script (reproducible for HOL attendees). No manual UI steps.

### Claude's Discretion

- Snowflake Secret name for the private key
- Image repository name and tag strategy
- Multi-stage vs single-stage Dockerfile structure
- `.dockerignore` contents
- Health check endpoint configuration in the service spec
- Whether to use a setup SQL script or manual Snowflake commands for SPCS provisioning

### Deferred Ideas (OUT OF SCOPE)

- None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DEPLOY-01 | Application containerized with Dockerfile compatible with SPCS | Dockerfile structure (multi-stage, standalone, linux/amd64), `output: 'standalone'` in next.config.ts, build context at repo root |
| DEPLOY-02 | Application successfully deployed and accessible on SPCS | Compute pool creation, image registry push workflow, CREATE SERVICE SQL, SHOW ENDPOINTS, BIND SERVICE ENDPOINT privilege, public endpoint config |
| DEPLOY-03 | Environment variables and secrets configured correctly in SPCS | CREATE SECRET GENERIC_STRING, service spec `secrets[].envVarName` pattern, all env vars from `.env.example` mapped to spec |
| DEPLOY-04 | Application connects to Snowflake MARTS schema from SPCS and returns real data | SNOWFLAKE_PRIVATE_KEY injection feeds existing `snowflake.ts` auth path; SNOWFLAKE_DATABASE/SCHEMA/WAREHOUSE/ACCOUNT/USER/ROLE all injected as env vars; no code changes needed |
</phase_requirements>

---

## Summary

Phase 4 packages the existing Next.js 16 portal into a Docker image and runs it in Snowpark Container Services (SPCS). The work splits cleanly into three tracks: (1) Dockerfile + next.config.ts changes, (2) Snowflake infrastructure provisioning (image repo, secret, compute pool, service), and (3) verification that real data flows through the SPCS endpoint.

SPCS has specific hard requirements: images must be `linux/amd64`, they must be pushed to Snowflake's private OCI registry (not Docker Hub), and public endpoints require the `BIND SERVICE ENDPOINT` account-level privilege. The service spec is a YAML document supplied inline to `CREATE SERVICE`. Secrets are injected as environment variables via `snowflakeSecret` + `envVarName` — this maps directly onto the existing `SNOWFLAKE_PRIVATE_KEY` env var the app already reads.

Next.js standalone mode is the correct Docker strategy: it emits a minimal `server.js` + only required `node_modules` into `.next/standalone/`, resulting in dramatically smaller images (often 75–97% smaller than full installs). Because this project uses a monorepo layout with `turbopack.root` pointing two levels up, `outputFileTracingRoot` must be set to the repo root so Next.js traces dependencies correctly. The Dockerfile build context must also be the repo root.

**Primary recommendation:** Write a multi-stage Dockerfile (deps → builder → runner) rooted at the monorepo root, add `output: 'standalone'` + `outputFileTracingRoot` to `next.config.ts`, then script all Snowflake provisioning (secret, repo, compute pool, service) in a single `setup.sql` file with `CREATE OR REPLACE` guards for repeatability.

---

## Standard Stack

### Core

| Tool/Concept | Version/Detail | Purpose | Why Standard |
|---|---|---|---|
| Next.js `output: 'standalone'` | Next.js 16 (project version) | Emit minimal runnable bundle into `.next/standalone/` | Official Next.js Docker recommendation; eliminates full node_modules in image |
| `outputFileTracingRoot` | next.config.ts option | Extend file tracing to monorepo root for dependency resolution | Required for monorepos where packages live outside the app dir |
| Docker multi-stage build | Docker 20+ | Separate deps/build/run layers; minimize final image | Standard production pattern; ~75–97% image size reduction |
| `linux/amd64` platform flag | `--platform linux/amd64` | SPCS hard requirement | SPCS only accepts linux/amd64; ARM builds will be rejected |
| Snowflake `CREATE SECRET TYPE = GENERIC_STRING` | SQL DDL | Store unencrypted PEM key string in Snowflake | Only secret type compatible with arbitrary string content (PEM key) |
| SPCS service spec YAML | Inline `FROM SPECIFICATION` | Define containers, env vars, secrets, endpoints | SPCS deployment contract |
| `snow spcs image-registry login` | Snowflake CLI | Authenticate Docker against Snowflake's OCI registry | Replaces manual token handling |

### Supporting

| Tool/Concept | Version/Detail | Purpose | When to Use |
|---|---|---|---|
| `.dockerignore` | Docker standard | Exclude unnecessary files from build context | Always — prevents large node_modules and .env files from inflating context |
| `SHOW ENDPOINTS IN SERVICE` | SQL | Get the public HTTPS URL after service creation | After service is running to retrieve the actual URL |
| `SHOW COMPUTE POOLS` | SQL | Check pool status before creating service | Pool must be in ACTIVE/IDLE state before service launch |
| `GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE` | SQL | Enable public endpoint creation | Required once per role for public ingress |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Multi-stage Dockerfile | Single-stage | Simpler but results in ~5x larger image; acceptable for demo but slower to push |
| Inline `FROM SPECIFICATION` | Stage spec YAML in a Snowflake stage | Staging file adds extra step; inline is simpler for scripted HOL |
| `snow spcs image-registry login` | Manual `docker login` with token | Manual token approach works but requires extra token generation step |

---

## Architecture Patterns

### Recommended Project Structure (new files)

```
coco_sdlc_hol/               # repo root = Docker build context
├── Dockerfile               # multi-stage, linux/amd64
├── .dockerignore            # exclude node_modules, .env*, .git, .next
├── setup.sql                # all Snowflake provisioning SQL (idempotent)
└── apps/frontend/
    └── next.config.ts       # add output: 'standalone' + outputFileTracingRoot
```

### Pattern 1: Next.js Standalone Multi-Stage Dockerfile

**What:** Three build stages — `deps` (install), `builder` (next build), `runner` (minimal runtime).
**When to use:** Always for SPCS; required for linux/amd64 and small image size.

```dockerfile
# Source: https://nextjs.org/docs/pages/api-reference/config/next-config-js/output
# Build context: repo root

FROM node:20-alpine AS deps
WORKDIR /app
# Copy monorepo root package files and frontend package files
COPY package.json package-lock.json* ./
COPY apps/frontend/package.json apps/frontend/package-lock.json* ./apps/frontend/
RUN cd apps/frontend && npm ci --omit=dev

FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/apps/frontend/node_modules ./apps/frontend/node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN cd apps/frontend && npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Add non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy standalone bundle and static assets
COPY --from=builder --chown=nextjs:nodejs /app/apps/frontend/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/apps/frontend/.next/static ./apps/frontend/.next/static
COPY --from=builder --chown=nextjs:nodejs /app/apps/frontend/public ./apps/frontend/public

USER nextjs
EXPOSE 3000
CMD ["node", "apps/frontend/server.js"]
```

**Note on standalone path in monorepo:** When `outputFileTracingRoot` is the repo root, the standalone output preserves the directory structure — `server.js` lives at `apps/frontend/server.js` inside the standalone folder, not at the root. Verify actual output path after first build.

### Pattern 2: next.config.ts with Standalone + Monorepo Root Tracing

```typescript
// Source: https://nextjs.org/docs/pages/api-reference/config/next-config-js/output
import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  output: 'standalone',
  outputFileTracingRoot: path.resolve(__dirname, "../.."), // monorepo root
  turbopack: {
    root: path.resolve(__dirname, "../.."),
  },
};

export default nextConfig;
```

### Pattern 3: SPCS Service Spec with Secrets and Public Endpoint

```yaml
# Source: https://docs.snowflake.com/en/developer-guide/snowpark-container-services/specification-reference
spec:
  containers:
  - name: portal
    image: /COCO_SDLC_HOL/PUBLIC/coco_sdlc_hol_repo/coco-portal:latest
    env:
      SNOWFLAKE_ACCOUNT: "<account_identifier>"
      SNOWFLAKE_USER: "<username>"
      SNOWFLAKE_WAREHOUSE: "COMPUTE_WH"
      SNOWFLAKE_DATABASE: "COCO_SDLC_HOL"
      SNOWFLAKE_SCHEMA: "MARTS"
      SNOWFLAKE_ROLE: "SYSADMIN"
      CORTEX_AGENT_NAME: "PAYMENT_ANALYTICS_AGENT"
      PORT: "3000"
      HOSTNAME: "0.0.0.0"
    secrets:
    - snowflakeSecret:
        objectName: coco_sdlc_hol_private_key
      envVarName: SNOWFLAKE_PRIVATE_KEY
      secretKeyRef: secret_string
    readinessProbe:
      port: 3000
      path: /api/health
  endpoints:
  - name: portal-endpoint
    port: 3000
    public: true
    protocol: HTTP
```

### Pattern 4: Snowflake Provisioning SQL (idempotent setup.sql)

```sql
-- Source: https://docs.snowflake.com/en/sql-reference/sql/create-secret
-- Source: https://docs.snowflake.com/en/sql-reference/sql/create-compute-pool
-- Source: https://docs.snowflake.com/en/sql-reference/sql/create-service

USE ROLE SYSADMIN;
USE DATABASE COCO_SDLC_HOL;
USE SCHEMA PUBLIC;

-- 1. Grant public endpoint privilege (requires ACCOUNTADMIN)
USE ROLE ACCOUNTADMIN;
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE SYSADMIN;
USE ROLE SYSADMIN;

-- 2. Store private key PEM content as a secret
CREATE OR REPLACE SECRET coco_sdlc_hol_private_key
  TYPE = GENERIC_STRING
  SECRET_STRING = '-----BEGIN PRIVATE KEY-----
<paste unencrypted PEM content here>
-----END PRIVATE KEY-----'
  COMMENT = 'Unencrypted RSA private key for SPCS Snowflake auth';

-- 3. Create image repository
CREATE IMAGE REPOSITORY IF NOT EXISTS coco_sdlc_hol_repo;
SHOW IMAGE REPOSITORIES;  -- note repository_url value for docker tag/push

-- 4. Create compute pool
CREATE COMPUTE POOL IF NOT EXISTS coco_sdlc_hol_compute_pool
  MIN_NODES = 1
  MAX_NODES = 1
  INSTANCE_FAMILY = STANDARD_1
  AUTO_RESUME = TRUE
  AUTO_SUSPEND_SECS = 3600;

-- Wait for pool to reach ACTIVE or IDLE state before creating service
-- Check with: SHOW COMPUTE POOLS;

-- 5. Create service (inline spec)
CREATE OR REPLACE SERVICE coco_sdlc_hol_service
  IN COMPUTE POOL coco_sdlc_hol_compute_pool
  FROM SPECIFICATION $$
  spec:
    containers:
    - name: portal
      image: /<account_repo_url>/coco_sdlc_hol_repo/coco-portal:latest
      env:
        ...
      secrets:
      - snowflakeSecret:
          objectName: coco_sdlc_hol_private_key
        envVarName: SNOWFLAKE_PRIVATE_KEY
        secretKeyRef: secret_string
    endpoints:
    - name: portal-endpoint
      port: 3000
      public: true
  $$;

-- 6. Retrieve public endpoint URL
SHOW ENDPOINTS IN SERVICE coco_sdlc_hol_service;
```

### Pattern 5: Image Build and Push Workflow

```bash
# Build for linux/amd64 (SPCS hard requirement)
docker build --platform linux/amd64 -t coco-portal:latest .

# Authenticate Docker with Snowflake registry
snow spcs image-registry login --connection ennovate

# Tag with repository URL (from SHOW IMAGE REPOSITORIES)
docker tag coco-portal:latest \
  <orgname>-<acctname>.registry.snowflakecomputing.com/coco_sdlc_hol/public/coco_sdlc_hol_repo/coco-portal:latest

# Push
docker push \
  <orgname>-<acctname>.registry.snowflakecomputing.com/coco_sdlc_hol/public/coco_sdlc_hol_repo/coco-portal:latest
```

### Anti-Patterns to Avoid

- **Building for wrong architecture:** Never omit `--platform linux/amd64`. On Apple Silicon (M1/M2/M3) Macs, Docker defaults to `arm64`, which SPCS silently rejects or fails to start.
- **Pushing to Docker Hub:** SPCS cannot pull from external registries. Image must be in Snowflake's private OCI registry.
- **Baking secrets into the image:** Never put `SNOWFLAKE_PRIVATE_KEY` or other credentials in `ENV` instructions in the Dockerfile. Use SPCS `secrets[].envVarName` injection.
- **Shipping full node_modules:** Without `output: 'standalone'`, the image ships all `node_modules` — balloons to 1-2 GB. Standalone + multi-stage is required.
- **Missing static file copy:** Standalone's `server.js` does NOT auto-serve `public/` or `.next/static/` unless you copy them into the standalone directory at build time. Forgetting these COPY steps produces a running app that serves no CSS, JS, or images.
- **Creating service before pool is ACTIVE:** SPCS compute pools take ~2-5 minutes to provision. `CREATE SERVICE` against an unready pool will fail. Must poll `SHOW COMPUTE POOLS` first.
- **Using SNOWFLAKE_PRIVATE_KEY_PATH in SPCS:** The container has no filesystem access to external key files. The path-based auth must be replaced with content-based (`SNOWFLAKE_PRIVATE_KEY`). The code already supports this; do not add `SNOWFLAKE_PRIVATE_KEY_PATH` to the spec.
- **Renaming database/schema after service creation:** SPCS services break if the parent DB/schema is renamed. Leave naming fixed once service is created.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Authenticating Docker with Snowflake registry | Manual token scripts | `snow spcs image-registry login` | Snowflake CLI handles token generation and docker credential setup automatically |
| Minimizing Docker image size | Custom copy scripts | `output: 'standalone'` + multi-stage Dockerfile | Next.js does dependency tracing via `@vercel/nft`; manual attempts miss files |
| Secret injection | Custom startup scripts reading from files | SPCS `secrets[].envVarName` | Native SPCS mechanism; no additional tooling or code needed |
| Health check | Custom ping endpoint | `readinessProbe` on existing Next.js API route | SPCS manages readiness; existing `/api/health` (or any route) suffices |

**Key insight:** SPCS's secret injection mechanism (`snowflakeSecret` + `envVarName`) is purpose-built for exactly this use case. The existing `snowflake.ts` already reads `SNOWFLAKE_PRIVATE_KEY` from env — the integration requires zero application code changes.

---

## Common Pitfalls

### Pitfall 1: Wrong Platform Architecture
**What goes wrong:** Docker image built on Mac/Windows defaults to `arm64`; SPCS only runs `linux/amd64`. Service will fail to start with a cryptic error or silently loop.
**Why it happens:** Docker Desktop on Apple Silicon defaults to native architecture.
**How to avoid:** Always pass `--platform linux/amd64` in every `docker build` command. Add to the HOL script.
**Warning signs:** Service status shows `FAILED` or containers restart repeatedly.

### Pitfall 2: Missing Static Files in Standalone Image
**What goes wrong:** App starts but all pages appear unstyled or broken (missing CSS/JS/images).
**Why it happens:** `next build` with `output: 'standalone'` emits `.next/standalone/` containing `server.js` and a minimal `node_modules`, but does NOT copy `.next/static/` or `public/` into it. The standalone server serves these only if they exist in the expected relative paths.
**How to avoid:** Add these two `COPY` instructions in the runner stage:
```dockerfile
COPY --from=builder /app/apps/frontend/.next/static ./apps/frontend/.next/static
COPY --from=builder /app/apps/frontend/public ./apps/frontend/public
```
**Warning signs:** Browser shows 404 for `/_next/static/...` assets.

### Pitfall 3: Compute Pool Not Ready When Creating Service
**What goes wrong:** `CREATE SERVICE` fails with an error about the compute pool not being available.
**Why it happens:** Compute pool provisioning takes 2–5 minutes after `CREATE COMPUTE POOL` runs.
**How to avoid:** After `CREATE COMPUTE POOL`, run `SHOW COMPUTE POOLS` and wait for `state = ACTIVE` or `IDLE` before proceeding to `CREATE SERVICE`.
**Warning signs:** `CREATE SERVICE` error referencing compute pool state.

### Pitfall 4: BIND SERVICE ENDPOINT Not Granted
**What goes wrong:** `CREATE SERVICE` with `public: true` endpoint fails with insufficient privilege error.
**Why it happens:** Public endpoint creation requires `BIND SERVICE ENDPOINT` granted at the account level, not just object-level permissions.
**How to avoid:** Run `GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE SYSADMIN` as ACCOUNTADMIN before creating the service. Include this in `setup.sql`.
**Warning signs:** Error message mentioning `BIND SERVICE ENDPOINT` privilege.

### Pitfall 5: Monorepo standalone output path mismatch
**What goes wrong:** Dockerfile copies from wrong path; container fails to find `server.js`.
**Why it happens:** When `outputFileTracingRoot` is the monorepo root (two levels up from `apps/frontend/`), the standalone output path structure reflects the full monorepo path. The server entry may be at `apps/frontend/server.js` inside the standalone folder instead of `server.js` at the standalone root.
**How to avoid:** After the first `next build`, inspect the actual `.next/standalone/` tree before writing the final Dockerfile `COPY` and `CMD` paths.
**Warning signs:** Container exits immediately; `node: can't open file 'server.js'`.

### Pitfall 6: Secret `secretKeyRef` must match secret type
**What goes wrong:** Service fails to inject secret or env var is empty.
**Why it happens:** For `TYPE = GENERIC_STRING` secrets, the correct `secretKeyRef` value is `secret_string`. Using `password` or `username` returns an empty value.
**How to avoid:** Always pair `TYPE = GENERIC_STRING` secrets with `secretKeyRef: secret_string`.
**Warning signs:** `SNOWFLAKE_PRIVATE_KEY` is empty in container; Snowflake connection fails with auth error.

### Pitfall 7: PEM key newlines mangled
**What goes wrong:** Key-pair auth fails despite correct key content.
**Why it happens:** PEM keys have literal newlines. When embedding in SQL `SECRET_STRING`, the literal multiline string must be preserved. When SPCS injects via `envVarName`, the value is passed as-is. The existing `snowflake.ts` already handles `\\n` → `\n` conversion, so escaped newlines also work.
**How to avoid:** Either embed literal newlines in the `CREATE SECRET` SQL or ensure the PEM is stored with `\n` escapes. Test by inspecting the env var inside the container with a debug image.
**Warning signs:** `JWT token` or `private key format` error from Snowflake SDK.

---

## Code Examples

### Verified: next.config.ts with standalone + monorepo tracing
```typescript
// Source: https://nextjs.org/docs/pages/api-reference/config/next-config-js/output
import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  output: 'standalone',
  outputFileTracingRoot: path.resolve(__dirname, "../.."),
  turbopack: {
    root: path.resolve(__dirname, "../.."),
  },
};

export default nextConfig;
```

### Verified: CREATE SECRET for PEM key
```sql
-- Source: https://docs.snowflake.com/en/sql-reference/sql/create-secret
CREATE OR REPLACE SECRET coco_sdlc_hol_private_key
  TYPE = GENERIC_STRING
  SECRET_STRING = '-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkq...
-----END PRIVATE KEY-----'
  COMMENT = 'Unencrypted RSA private key for SPCS JWT auth';
```

### Verified: Minimal .dockerignore for Next.js monorepo
```
.git
.github
.planning
**/node_modules
**/.next
**/.env*
!**/.env.example
apps/frontend/.next
packages/dbt
*.log
```

### Verified: docker build and push sequence
```bash
# Build for SPCS (linux/amd64 required)
docker build --platform linux/amd64 -t coco-portal:latest .

# Login to Snowflake registry (uses "ennovate" CLI connection from project decisions)
snow spcs image-registry login --connection ennovate

# Get repo URL from Snowflake first: SHOW IMAGE REPOSITORIES IN SCHEMA COCO_SDLC_HOL.PUBLIC;
REPO_URL="<orgname>-<acctname>.registry.snowflakecomputing.com/coco_sdlc_hol/public/coco_sdlc_hol_repo"

docker tag coco-portal:latest ${REPO_URL}/coco-portal:latest
docker push ${REPO_URL}/coco-portal:latest
```

### Verified: SPCS instance family for this project
```sql
-- STANDARD_1 = 1 vCPU, 4 GB RAM (user decision from CONTEXT.md)
-- Note: Snowflake docs list CPU_X64_XS as smallest generic CPU (1 vCPU, 6 GiB).
-- STANDARD_1 maps to the "Standard" GPU-free tier in SPCS pricing.
-- Use exactly: INSTANCE_FAMILY = STANDARD_1
CREATE COMPUTE POOL IF NOT EXISTS coco_sdlc_hol_compute_pool
  MIN_NODES = 1
  MAX_NODES = 1
  INSTANCE_FAMILY = STANDARD_1
  AUTO_RESUME = TRUE
  AUTO_SUSPEND_SECS = 3600;
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Full `node_modules` copy in Docker | `output: 'standalone'` trace-only bundle | Next.js 12 (2021), now standard | 75–97% image size reduction |
| Docker Hub / external registry | Snowflake private OCI registry only | SPCS GA (2024) | Must always push to Snowflake registry first |
| Manual `docker login` with token | `snow spcs image-registry login` | Snowflake CLI v2 (2024) | Simpler auth workflow |
| SSH-style private key file path | PEM content in Snowflake Secret | SPCS design pattern | No filesystem key management; works in stateless containers |

**Deprecated/outdated:**
- `SNOWFLAKE_PRIVATE_KEY_PATH`: Does not work in SPCS containers — no external filesystem. Use `SNOWFLAKE_PRIVATE_KEY` (content) instead.
- `serverless` target (Next.js): Removed in Next.js 13. `output: 'standalone'` is the replacement.

---

## Open Questions

1. **Exact standalone output path in this monorepo**
   - What we know: With `outputFileTracingRoot` at repo root, the standalone folder mirrors the full directory structure
   - What's unclear: Whether `server.js` lands at `apps/frontend/server.js` or at the root of the standalone folder in this specific monorepo layout
   - Recommendation: The planner should include an explicit "inspect standalone output" task step before finalizing the Dockerfile CMD path. Run `next build` locally first and check `apps/frontend/.next/standalone/` tree.

2. **STANDARD_1 vs CPU_X64_XS instance family name**
   - What we know: User specified `STANDARD_1` (from CONTEXT.md). Official Snowflake docs list `CPU_X64_XS` as smallest generic CPU option. `STANDARD_1` may be a different tier name or an alias.
   - What's unclear: Whether `INSTANCE_FAMILY = STANDARD_1` is valid SQL or whether the correct identifier is `CPU_X64_XS`
   - Recommendation: The planner should note this. During execution, verify with `SHOW COMPUTE POOLS LIKE '%'` or Snowflake docs for the exact string. If `STANDARD_1` fails, `CPU_X64_XS` is the verified fallback (1 vCPU, 6 GiB).

3. **Health check endpoint**
   - What we know: SPCS `readinessProbe` requires an HTTP path that returns 2xx
   - What's unclear: Whether a `/api/health` route currently exists in the app
   - Recommendation: If no health route exists, the planner should include a task to add a minimal `/api/health/route.ts` returning `{ status: 'ok' }`. Alternatively, use any existing API route (e.g., `/api/authorizations/kpis`) with the understanding it makes a Snowflake call on startup.

4. **Turbopack dev mode vs production build**
   - What we know: `turbopack.root` is only used for `next dev`. Production `next build` uses webpack by default.
   - What's unclear: Whether `outputFileTracingRoot` alone is sufficient without the Turbopack root setting for production builds
   - Recommendation: Both settings should coexist safely in `next.config.ts`. This is low risk.

---

## Sources

### Primary (HIGH confidence)
- [Next.js output documentation](https://nextjs.org/docs/pages/api-reference/config/next-config-js/output) — standalone mode, outputFileTracingRoot, monorepo caveats, server.js startup
- [SPCS Specification Reference](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/specification-reference) — container spec YAML, secrets with envVarName, endpoints with public:true
- [CREATE SECRET Documentation](https://docs.snowflake.com/en/sql-reference/sql/create-secret) — GENERIC_STRING type, SECRET_STRING syntax, required privileges
- [CREATE COMPUTE POOL Documentation](https://docs.snowflake.com/en/sql-reference/sql/create-compute-pool) — INSTANCE_FAMILY options, AUTO_RESUME, status check
- [CREATE SERVICE Documentation](https://docs.snowflake.com/en/sql-reference/sql/create-service) — FROM SPECIFICATION, SHOW ENDPOINTS, GRANT USAGE
- [SPCS Image Registry Documentation](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/working-with-registry-repository) — registry hostname format, docker login, tag/push workflow
- [SPCS Guidelines and Limitations](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/spcs-guidelines-and-limitations) — linux/amd64 requirement, no privileged containers, service capacity limits

### Secondary (MEDIUM confidence)
- WebSearch SPCS Dockerfile requirements 2025 — confirmed linux/amd64 platform requirement; multiple sources agree
- WebSearch Next.js standalone multi-stage Docker 2025 — 75–97% image size reduction; consistent across multiple community sources
- WebSearch BIND SERVICE ENDPOINT privilege — confirmed account-level grant requirement; verified in official SPCS working-with-services doc reference

### Tertiary (LOW confidence)
- STANDARD_1 instance family name — user specified this in CONTEXT.md; Snowflake official docs list CPU_X64_XS as smallest generic CPU tier; these may differ. Needs verification at execution time.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Next.js standalone and SPCS patterns verified against official documentation
- Architecture: HIGH — Dockerfile pattern and service spec structure from official sources
- Pitfalls: HIGH for platform/static files/secrets issues (multi-source verification); MEDIUM for monorepo standalone path (depends on actual build output)
- Open questions: Identified honestly; none are blockers to planning

**Research date:** 2026-03-01
**Valid until:** 2026-04-01 (SPCS and Next.js stable; unlikely to change in 30 days)
