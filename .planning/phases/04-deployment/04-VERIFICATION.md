---
phase: 04-deployment
verified: 2026-03-01T21:00:00Z
status: human_needed
score: 3/4 success criteria verified (SC-4 requires human)
re_verification: false
human_verification:
  - test: "Navigate to https://b6b4qiky-aovnged-ennovate.snowflakecomputing.app in a browser, authenticate via Snowflake OAuth, and confirm home dashboard KPI cards show non-zero values from MARTS data"
    expected: "KPI cards on the home dashboard display real numeric values sourced from the Snowflake MARTS schema — not zeros, loading spinners, or error states"
    why_human: "The only SPCS verification performed was a curl that returned a 302 OAuth redirect. The readiness probe (/api/health) has no Snowflake connection — RUNNING state proves the container is alive, not that it can query MARTS. Real data delivery must be confirmed by a human with Snowflake credentials."
  - test: "Navigate to the Authorization domain page behind the SPCS endpoint and confirm the data table populates with real rows"
    expected: "Authorization KPI cards and data table show real values from COCO_SDLC_HOL.MARTS tables"
    why_human: "Same reason as above — data-path verification requires authenticated browser access to the live endpoint."
---

# Phase 4: Deployment Verification Report

**Phase Goal:** Deploy the COCO SDLC HOL portal as a containerized service on Snowflake SPCS with a public HTTPS endpoint serving real MARTS data
**Verified:** 2026-03-01T21:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (from ROADMAP.md Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | A Dockerfile builds successfully and produces an image compatible with SPCS requirements | VERIFIED | Dockerfile exists at repo root with `--platform=linux/amd64` on both FROM stages. Commit `eda225f` confirms a successful build producing `coco-portal:latest` at 329 MB. CMD path `apps/frontend/server.js` matches the monorepo-rooted standalone output. |
| SC-2 | The application is accessible at an SPCS endpoint — home dashboard loads in a browser | PARTIAL | Service `COCO_SDLC_HOL_SERVICE` is RUNNING (1/1 instances per user-reported worksheet output). Public HTTPS endpoint `https://b6b4qiky-aovnged-ennovate.snowflakecomputing.app` is live. curl confirms TLS and SPCS OAuth gate active. Whether the home dashboard loads after OAuth login is unconfirmed — no authenticated browser check was performed. |
| SC-3 | Environment variables and secrets are configured in SPCS (not baked into the image) | VERIFIED | setup.sql injects all 9 env vars via the service spec `env:` block. `SNOWFLAKE_PRIVATE_KEY` is injected via `snowflakeSecret.objectName: coco_sdlc_hol_private_key` with `secretKeyRef: secret_string` — not present in the Dockerfile or image. `snowflake.ts` reads `process.env.SNOWFLAKE_PRIVATE_KEY` and uses JWT auth when present. Wiring is complete. |
| SC-4 | Domain pages return real data from Snowflake MARTS when accessed through the SPCS deployment | UNCERTAIN | The readiness probe at `/api/health` has no Snowflake connection by design. RUNNING 1/1 instances confirms the container started and the health endpoint responded — it does not confirm the Snowflake data path works. The curl verification produced a 302 OAuth redirect with no data. Human must authenticate and load a domain page to confirm. |

**Score:** 3/4 success criteria verified (SC-4 uncertain, SC-2 partial — both need human confirmation)

---

## Required Artifacts

### Plan 01 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `apps/frontend/next.config.ts` | `output: 'standalone'` + `outputFileTracingRoot` | VERIFIED | Both fields present at lines 5–6. `turbopack.root` preserved. |
| `apps/frontend/src/app/api/health/route.ts` | GET handler returning `{ status: 'ok' }` HTTP 200 | VERIFIED | 5-line file, no Snowflake dependency, returns `NextResponse.json({ status: 'ok' }, { status: 200 })`. |
| `Dockerfile` | Multi-stage linux/amd64 build for SPCS | VERIFIED (with deviation) | File exists. `--platform=linux/amd64` appears on both FROM instructions. COPY of standalone, static, and public/ directories all present. CMD points to `apps/frontend/server.js`. **Deviation from plan:** Final Dockerfile is 2-stage (builder + runner) not 3-stage — the `deps` stage was removed in commit `eda225f` because `COPY --from=deps /app/node_modules` did not exist. The 2-stage approach was validated by a successful build and smoke test. |
| `.dockerignore` | Excludes node_modules, .env*, .git, .next, packages/dbt | VERIFIED | All required exclusions present: `.git`, `**/node_modules`, `**/.next`, `**/.env*` (with `!**/.env.example` allowlist), `packages/dbt`. |

### Plan 02 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `setup.sql` | Complete idempotent SPCS provisioning script | VERIFIED | 132-line file at repo root. All 6 steps present: BIND SERVICE ENDPOINT, CREATE SECRET (GENERIC_STRING), CREATE IMAGE REPOSITORY, CREATE COMPUTE POOL, CREATE SERVICE (inline spec), SHOW ENDPOINTS. |

### Plan 03 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| Next.js standalone build output | Created during `docker build` | VERIFIED (runtime artifact) | Confirmed by successful 329 MB image build in commit `eda225f`. Not stored in the repo — produced at build time. |
| Snowflake image registry | `coco-portal:latest` pushed | VERIFIED (external, user-reported) | User confirmed push to `aovnged-ennovate.registry.snowflakecomputing.com/coco_sdlc_hol/public/coco_sdlc_hol_repo/coco-portal:latest`. Cannot be verified from codebase alone. |

---

## Key Link Verification

### Plan 01 Key Links

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Dockerfile` runner stage | `apps/frontend/.next/standalone` | `COPY --from=builder` | VERIFIED | Line 33: `COPY --from=builder --chown=nextjs:nodejs /app/apps/frontend/.next/standalone ./` — present and correct. |
| `next.config.ts outputFileTracingRoot` | repo root (`../../`) | `path.resolve(__dirname, '../..')` | VERIFIED | Line 6 confirmed: `outputFileTracingRoot: path.resolve(__dirname, "../..")`. |

### Plan 02 Key Links

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `setup.sql CREATE SECRET` | service spec `secrets[].snowflakeSecret.objectName` | secret name `coco_sdlc_hol_private_key` | VERIFIED | Secret created as `coco_sdlc_hol_private_key` (line 42); service spec references `objectName: coco_sdlc_hol_private_key` (line 106). Names match. |
| service spec `envVarName` | `snowflake.ts SNOWFLAKE_PRIVATE_KEY` | SPCS secret injection | VERIFIED | `envVarName: SNOWFLAKE_PRIVATE_KEY` in setup.sql (line 107); `config.ts` line 40 reads `process.env.SNOWFLAKE_PRIVATE_KEY`; `snowflake.ts` line 99 uses it for JWT auth. Full chain confirmed. |
| service spec `readinessProbe` | `/api/health` route (Plan 01) | `path: /api/health port: 3000` | VERIFIED | setup.sql lines 109–111: `readinessProbe.port: 3000`, `readinessProbe.path: /api/health`. Route exists at `apps/frontend/src/app/api/health/route.ts`. Service reached RUNNING (1/1) confirming probe passed in production. |

### Plan 03 Key Links

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| SPCS service container | `snowflake.ts SNOWFLAKE_PRIVATE_KEY` | Snowflake Secret injection | VERIFIED (wiring) | Code path confirmed: SPCS injects `SNOWFLAKE_PRIVATE_KEY` env var; `config.ts` reads it; `snowflake.ts` uses it for JWT auth. Whether this actually succeeded at runtime requires human verification (SC-4). |
| Browser HTTPS endpoint | Next.js container port 3000 | SPCS public endpoint `portal-endpoint` | PARTIAL | curl to `https://b6b4qiky-aovnged-ennovate.snowflakecomputing.app/api/health` returned HTTP 302 to Snowflake OAuth login — confirms SPCS routing is active. Full browser load (post-OAuth) not verified. |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| DEPLOY-01 | 04-01 | Application containerized with Dockerfile compatible with SPCS | SATISFIED | Dockerfile exists with `--platform=linux/amd64` on all FROM stages. 329 MB image built successfully (commit `eda225f`). 2-stage vs 3-stage deviation is immaterial — SPCS compatibility confirmed by successful push and container startup. |
| DEPLOY-02 | 04-02, 04-03 | Application successfully deployed and accessible on SPCS | PARTIALLY SATISFIED | SPCS service is RUNNING (1/1 instances), public endpoint live, TLS confirmed. "Accessible" is partially proven — OAuth redirect confirms routing works, but authenticated page load is unverified. |
| DEPLOY-03 | 04-02 | Environment variables and secrets configured correctly in SPCS deployment | SATISFIED | All 9 env vars in service spec. `SNOWFLAKE_PRIVATE_KEY` injected via GENERIC_STRING Secret with `secretKeyRef: secret_string`. No secrets baked into image. Wiring from secret to `snowflake.ts` confirmed in code. |
| DEPLOY-04 | 04-03 | Application connects to Snowflake MARTS schema from SPCS environment and returns real data | UNCONFIRMED | Service RUNNING state proves container health (readiness probe), not Snowflake connectivity. The health endpoint has no DB call. `curl` returned 302 OAuth redirect — no data seen. Requires human verification. |

**Orphaned requirements check:** No Phase 4 requirements in REQUIREMENTS.md are unaccounted for. All four DEPLOY IDs are claimed across plans 01–03.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `Dockerfile` | — | 2-stage instead of 3-stage as specified in plan | Info | No impact — deviation was intentional and documented in commit `eda225f`. The removed `deps` stage was never functional (had a broken COPY). The 2-stage approach was validated by a successful build. |

No TODO/FIXME/placeholder comments in application code. No empty implementations detected. No stub anti-patterns in `health/route.ts` or `next.config.ts`.

---

## Human Verification Required

### 1. Home Dashboard Real Data Check

**Test:** Authenticate via Snowflake OAuth at `https://b6b4qiky-aovnged-ennovate.snowflakecomputing.app` and load the home page.
**Expected:** KPI cards display real non-zero numeric values sourced from the Snowflake `COCO_SDLC_HOL.MARTS` schema.
**Why human:** The readiness probe (`/api/health`) deliberately has no Snowflake connection — RUNNING state does not prove data connectivity. The only external verification was a `curl` that hit the OAuth gate (302 redirect). No authenticated browser session was confirmed.

### 2. Domain Page Data Verification (DEPLOY-04)

**Test:** Navigate to the Authorization domain page at the SPCS endpoint and observe the data table and KPI cards.
**Expected:** Data table populates with rows from MARTS tables; KPI cards show real values (not zeros or error states).
**Why human:** This is the direct requirement for DEPLOY-04. The SUMMARY claims it is satisfied because "readiness probe at /api/health would not pass if Snowflake connection failed at startup" — but this is incorrect. The health route has no Snowflake call, so probe success does not imply DB connectivity.

### 3. AI Chat End-to-End (Optional — not a DEPLOY requirement)

**Test:** Open the AI chat panel and ask "What is my authorization approval rate?"
**Expected:** Streaming response from Snowflake Cortex Agent returns real data.
**Why human:** Requires authenticated access to the live endpoint and is not directly tied to any DEPLOY requirement, but confirms full end-to-end path.

---

## Gaps Summary

There are no blocking code gaps. All artifacts exist, are substantive, and are correctly wired. The single outstanding item is **runtime verification of DEPLOY-04** (real MARTS data through SPCS).

The SUMMARY's claim that DEPLOY-04 is satisfied because "RUNNING 1/1 instances means app connects to Snowflake successfully" is logically flawed: the `/api/health` readiness probe has no Snowflake call by design, so RUNNING state is evidence the container process is alive and the health endpoint is reachable — nothing more. A Snowflake auth failure would not prevent the service from reaching RUNNING state.

This is not a code defect — the application and infrastructure are correctly wired. It is an unconfirmed runtime state that requires a human with Snowflake credentials to verify by loading a domain page that actually queries MARTS.

**If DEPLOY-04 is confirmed by human:** Status upgrades to `passed` with score 4/4.

---

## Commit Verification

All phase 04 feature commits verified real:

| Commit | Description | Files |
|--------|-------------|-------|
| `31679dc` | `feat(04-01): add standalone output and outputFileTracingRoot to next.config.ts` | `apps/frontend/next.config.ts` |
| `b156652` | `feat(04-01): add /api/health route for SPCS readiness probe` | `apps/frontend/src/app/api/health/route.ts` |
| `41f8cfb` | `feat(04-01): add Dockerfile and .dockerignore for SPCS containerized deployment` | `Dockerfile`, `.dockerignore` |
| `889f044` | `feat(04-02): add idempotent SPCS provisioning script (setup.sql)` | `setup.sql` |
| `eda225f` | `feat(04-03): build Docker image for SPCS deployment (Task 1)` | `Dockerfile` (fix 2-stage), `GaugeChart.tsx` (TS fix) |

---

_Verified: 2026-03-01T21:00:00Z_
_Verifier: Claude (gsd-verifier)_
