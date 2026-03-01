---
phase: 04-deployment
plan: 01
subsystem: infra
tags: [docker, nextjs, standalone, spcs, snowflake]

# Dependency graph
requires:
  - phase: 03-code-quality
    provides: clean API routes with parameterized queries and config.ts single source of truth
provides:
  - Next.js standalone output mode configured for Docker-optimized builds
  - /api/health route returning 200 JSON for SPCS readinessProbe
  - 3-stage linux/amd64 Dockerfile for SPCS OCI image build
  - .dockerignore excluding secrets, build artifacts, and non-app packages
affects: [04-deployment plans 02+, SPCS service spec, image registry push]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Next.js standalone output with outputFileTracingRoot for monorepo Docker builds
    - 3-stage Docker build (deps/builder/runner) for minimal production images
    - Non-root container user (nextjs:nodejs uid/gid 1001)

key-files:
  created:
    - apps/frontend/src/app/api/health/route.ts
    - Dockerfile
    - .dockerignore
  modified:
    - apps/frontend/next.config.ts

key-decisions:
  - "outputFileTracingRoot set to monorepo root (../../) so workspace packages are traced into standalone bundle"
  - "server.js CMD path is apps/frontend/server.js — outputFileTracingRoot causes standalone to mirror monorepo structure"
  - "Health route has no Snowflake connection — avoids cold-start probe failures during SPCS container init"
  - "Build context is repo root (not apps/frontend/) — required for monorepo COPY paths in Dockerfile"

patterns-established:
  - "Dockerfile: all FROM instructions must include --platform=linux/amd64 for SPCS hard requirement"
  - "Static assets and public/ must be copied separately — standalone mode does not auto-include them"

requirements-completed: [DEPLOY-01]

# Metrics
duration: 2min
completed: 2026-03-01
---

# Phase 4 Plan 1: Next.js Standalone + Dockerfile for SPCS Summary

**3-stage linux/amd64 Dockerfile with Next.js standalone output and SPCS health probe — coco-portal image ready to build**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-01T19:13:27Z
- **Completed:** 2026-03-01T19:14:36Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Added `output: 'standalone'` and `outputFileTracingRoot` to next.config.ts so Next.js emits a minimal Docker-ready bundle that correctly traces monorepo workspace dependencies
- Created `/api/health` route returning `{ status: 'ok' }` with HTTP 200 for SPCS readiness probing without triggering a Snowflake connection on cold start
- Wrote a 3-stage Dockerfile targeting `linux/amd64` (SPCS hard requirement) with correct COPY paths for the monorepo standalone structure and a `.dockerignore` excluding secrets, git history, and build artifacts

## Task Commits

Each task was committed atomically:

1. **Task 1: Update next.config.ts with standalone output and file tracing root** - `31679dc` (feat)
2. **Task 2: Create /api/health route for SPCS readiness probe** - `b156652` (feat)
3. **Task 3: Write Dockerfile and .dockerignore at repo root** - `41f8cfb` (feat)

**Plan metadata:** _(docs commit follows)_

## Files Created/Modified
- `apps/frontend/next.config.ts` - Added `output: 'standalone'` and `outputFileTracingRoot: path.resolve(__dirname, '../..')` alongside existing `turbopack.root`
- `apps/frontend/src/app/api/health/route.ts` - GET handler returning `{ status: 'ok' }` HTTP 200, no Snowflake dependency
- `Dockerfile` - 3-stage build (deps/builder/runner) for linux/amd64; copies standalone bundle, static assets, and public/ into minimal runner image
- `.dockerignore` - Excludes `.git`, `.planning`, `**/node_modules`, `**/.next`, `**/.env*`, `packages/dbt`, `.claude`

## Decisions Made
- `outputFileTracingRoot` is set to the monorepo root (`../..` from `apps/frontend/`) so that Next.js traces workspace packages (e.g., shared utils) into the standalone bundle — without this, monorepo builds silently break
- The standalone output mirrors the full monorepo directory structure because `outputFileTracingRoot` is at repo root, meaning `server.js` lives at `apps/frontend/server.js` inside the standalone folder (not the standalone root)
- Health route has no Snowflake connection — a real analytics route would attempt a DB call during container init, causing SPCS readiness probes to fail during cold start
- Build context is repo root (not `apps/frontend/`) — required because the Dockerfile must COPY both the root `package.json` and the frontend `package.json` for the `npm ci` workspace install

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required in this plan. The `docker build` and `docker run` commands are documented in the plan success criteria for manual verification when ready.

## Next Phase Readiness
- Dockerfile is ready for `docker build --platform linux/amd64 -t coco-portal:latest .` from repo root
- Image can be tested locally with `docker run -p 3000:3000 --env-file apps/frontend/.env.local coco-portal:latest`
- Next plans: push image to Snowflake image registry, write SPCS service spec with readinessProbe targeting `/api/health`

---
## Self-Check: PASSED

All files verified present:
- FOUND: apps/frontend/next.config.ts
- FOUND: apps/frontend/src/app/api/health/route.ts
- FOUND: Dockerfile
- FOUND: .dockerignore
- FOUND: .planning/phases/04-deployment/04-01-SUMMARY.md

All commits verified:
- FOUND: 41f8cfb — feat(04-01): add Dockerfile and .dockerignore
- FOUND: b156652 — feat(04-01): add /api/health route for SPCS readiness probe
- FOUND: 31679dc — feat(04-01): add standalone output and outputFileTracingRoot to next.config.ts

---
*Phase: 04-deployment*
*Completed: 2026-03-01*
