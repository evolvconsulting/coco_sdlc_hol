# Phase 4: Deployment - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Containerize the Next.js 16 portal with a Dockerfile, push the image to Snowflake's image registry, and run it as an SPCS service with a public HTTPS endpoint backed by real Snowflake MARTS data. No new features — only packaging and infrastructure.

</domain>

<decisions>
## Implementation Decisions

### Snowflake Authentication in SPCS
- Use key-pair authentication with an unencrypted private key
- Store the private key PEM content in a Snowflake Secret object
- Inject it into the container as `SNOWFLAKE_PRIVATE_KEY` env var via the service spec
- `snowflake.ts` already reads `SNOWFLAKE_PRIVATE_KEY` (content string) — no code changes needed for auth

### Next.js Build Output
- Add `output: 'standalone'` to `next.config.ts` for Docker optimization
- Standalone output bundles only required files; avoids shipping all of `node_modules` in the image
- Dockerfile build context is the **repo root** (not `apps/frontend/`) to handle the Turbopack monorepo root reference

### Compute Pool
- STANDARD_1 instance family (1 vCPU, 4 GB RAM) — appropriate for this HOL demo
- Compute pool name: `coco_sdlc_hol_compute_pool`
- Min/max instances: 1 (no auto-scaling needed for demo)

### Endpoint Access
- Public HTTPS endpoint (accessible from any browser)
- Map external port 80 → internal container port 3000 (Next.js default)
- Service name: `coco_sdlc_hol_service`

### Naming Conventions
- Compute pool: `coco_sdlc_hol_compute_pool`
- SPCS service: `coco_sdlc_hol_service`
- Image repository: Claude's discretion (consistent with HOL naming)

### Claude's Discretion
- Snowflake Secret name for the private key
- Image repository name and tag strategy
- Multi-stage vs single-stage Dockerfile structure
- `.dockerignore` contents
- Health check endpoint configuration in the service spec
- Whether to use a setup SQL script or manual Snowflake commands for SPCS provisioning

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `apps/frontend/src/lib/snowflake.ts` line 40: already reads `SNOWFLAKE_PRIVATE_KEY` as a string env var — Snowflake Secret injection maps directly to this, no code changes needed
- `apps/frontend/.env.example`: full list of required env vars to replicate in the SPCS service spec

### Established Patterns
- All Snowflake credentials are environment-variable-driven — nothing is hardcoded; translates cleanly to SPCS secret injection
- `next.config.ts` is minimal — safe to add `output: 'standalone'` without breaking existing behavior
- Turbopack config sets monorepo root two levels above `apps/frontend/` — Dockerfile WORKDIR and COPY commands must account for this

### Integration Points
- Dockerfile goes at repo root; `COPY apps/frontend/ apps/frontend/` and install from there
- All env vars from `.env.example` become SPCS service spec `env` or Snowflake Secret references
- `SNOWFLAKE_PRIVATE_KEY_PATH` is NOT used in SPCS — replace with `SNOWFLAKE_PRIVATE_KEY` (content)

</code_context>

<specifics>
## Specific Ideas

- No specific design references — standard SPCS deployment pattern
- Service should be fully scripted (SQL commands) so it's reproducible for HOL attendees

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-deployment*
*Context gathered: 2026-03-01*
