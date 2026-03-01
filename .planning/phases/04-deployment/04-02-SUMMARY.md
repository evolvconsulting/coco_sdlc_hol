---
phase: 04-deployment
plan: "02"
subsystem: infra
tags: [spcs, snowflake, sql, docker, deployment, key-pair-auth]

# Dependency graph
requires:
  - phase: 04-deployment-01
    provides: Dockerfile, /api/health route, Next.js standalone output
provides:
  - "setup.sql: single idempotent SQL script to provision all SPCS infrastructure (secret, image repo, compute pool, service)"
affects: [deployment, operations, hol-attendees]

# Tech tracking
tech-stack:
  added: []
  patterns: [idempotent-sql-provisioning, spcs-inline-spec, generic-string-secret-injection]

key-files:
  created:
    - setup.sql
  modified: []

key-decisions:
  - "GENERIC_STRING secret type with secretKeyRef: secret_string used for RSA private key injection — not password/username type"
  - "BIND SERVICE ENDPOINT grant requires ACCOUNTADMIN and is included as step 1 with role switch to SYSADMIN for remaining steps"
  - "STANDARD_1 instance family chosen with CPU_X64_XS noted as fallback — 1 vCPU/~4GB RAM appropriate for HOL demo"
  - "SNOWFLAKE_PRIVATE_KEY_PATH omitted from service spec entirely — SPCS containers have no external filesystem; secret injection replaces it"

patterns-established:
  - "Idempotent SQL provisioning: CREATE OR REPLACE for stateful objects (secret, service), IF NOT EXISTS for infrastructure (repo, pool)"
  - "Inline SPCS service spec: env vars + secrets + readinessProbe + endpoints all in FROM SPECIFICATION $$ ... $$ block"
  - "Secret injection pattern: snowflakeSecret.objectName references secret name, envVarName maps to app env var, secretKeyRef: secret_string for GENERIC_STRING type"

requirements-completed: [DEPLOY-02, DEPLOY-03]

# Metrics
duration: 1min
completed: "2026-03-01"
---

# Phase 4 Plan 02: SPCS Provisioning Script Summary

**Single idempotent setup.sql with BIND ENDPOINT grant, GENERIC_STRING private key secret, image repository, STANDARD_1 compute pool, and inline SPCS service spec injecting RSA key via secret_string into the Next.js portal container**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-01T19:16:44Z
- **Completed:** 2026-03-01T19:17:46Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Complete idempotent SPCS provisioning script HOL attendees can run top-to-bottom in a Snowflake worksheet
- All 9 required env vars mapped into the service spec inline (SNOWFLAKE_ACCOUNT through HOSTNAME)
- RSA private key injected as GENERIC_STRING Snowflake Secret with correct secretKeyRef: secret_string pattern
- readinessProbe wired to /api/health on port 3000 (created in Plan 01) with public HTTPS endpoint

## Task Commits

Each task was committed atomically:

1. **Task 1: Write setup.sql — complete idempotent SPCS provisioning script** - `889f044` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `setup.sql` - Complete 131-line idempotent SPCS provisioning SQL script: ACCOUNTADMIN BIND ENDPOINT grant, SYSADMIN secret/repo/pool/service creation, SHOW ENDPOINTS

## Decisions Made
- Used `CREATE OR REPLACE` for SECRET and SERVICE (must update atomically), `IF NOT EXISTS` for IMAGE REPOSITORY and COMPUTE POOL (safe to skip if already provisioned)
- Included full deployment workflow comment block at top: docker build -> snow login -> tag -> push -> run script sequence
- Added log retrieval commands as inline SQL comments for HOL attendee troubleshooting
- Placeholder markers `<SNOWFLAKE_ACCOUNT>`, `<SNOWFLAKE_USER>`, `<REPO_URL>`, and `<PASTE YOUR UNENCRYPTED PEM KEY CONTENT HERE>` clearly marked for substitution

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

HOL attendees must substitute three values before running setup.sql:
1. `<PASTE YOUR UNENCRYPTED PEM KEY CONTENT HERE>` — RSA private key PEM content from their .p8 key file
2. `<SNOWFLAKE_ACCOUNT>` — their Snowflake account identifier
3. `<SNOWFLAKE_USER>` — their Snowflake username
4. `<REPO_URL>` — image repository URL from SHOW IMAGE REPOSITORIES output

## Next Phase Readiness

- setup.sql is complete and ready for HOL attendees
- All DEPLOY requirements satisfied: DEPLOY-01 (Dockerfile), DEPLOY-02 (service creation), DEPLOY-03 (env var config)
- No outstanding blockers — deployment phase complete

---
*Phase: 04-deployment*
*Completed: 2026-03-01*
