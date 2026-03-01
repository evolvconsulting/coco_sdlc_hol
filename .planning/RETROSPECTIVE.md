# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — HOL Baseline Application

**Shipped:** 2026-03-01
**Phases:** 4 | **Plans:** 14 | **Timeline:** 2 days (2026-02-28 → 2026-03-01)

### What Was Built
- UAT walkthrough: all 6 payment domain pages and AI chat verified against real Snowflake MARTS data — 8 pre-existing bugs found and fixed
- UX/UI polish: KPICard component adoption across all domain pages, Skeleton chart loading, canonical formatters.ts, controlled sidebar navigation
- Code quality hardening: config.ts centralizing all DB/schema/table references, parameterized SQL binds on all 22 routes, sanitized error responses
- SPCS deployment: linux/amd64 Docker image, idempotent setup.sql, RSA private key via GENERIC_STRING Secret, live public HTTPS endpoint

### What Worked
- Phase-first execution: starting with UAT (Phase 1) before polish or hardening meant bugs were found in the context of real data — fixes were targeted and correct
- Yolo mode for code quality and deployment phases: well-defined, low-ambiguity work executed faster without gate prompts
- Pre-flight check pattern (env verification → connectivity → date range discovery) eliminated guesswork in subsequent plans
- 3-stage Docker build with monorepo `outputFileTracingRoot`: got standalone build right on first attempt with no trial-and-error
- Idempotent setup.sql with placeholder markers: clear handoff artifact for HOL attendees requiring only 4 substitutions

### What Was Inefficient
- Phase 3 had 4 plans instead of the original 3 — a gap in CODE-01 coverage (cortex/chat inline process.env) was missed in the initial plan and required an inserted Plan 04; better pre-plan grep would have caught it
- GaugeChartProps TypeScript error was a pre-existing issue that surfaced in every Phase 3 TypeScript check, adding noise to verification output; it was correctly deferred but the repeated noise was friction
- SPCS instance family fallback (CPU_X64_XS vs STANDARD_1) wasn't discoverable before provisioning — account-specific limitations require a "try and fallback" pattern that can't be fully scripted

### Patterns Established
- `config.ts` as single source of truth: all DB/schema/table references import from `@/lib/config` — no hardcoded strings in route files
- Three-change pattern for route hardening: (1) FULL_TABLE_* import, (2) binds array + ? placeholders, (3) remove `details: String(error)`
- SPCS deployment pattern: `docker build --platform linux/amd64` → push to Snowflake OCI registry → run idempotent setup.sql → `SHOW ENDPOINTS`
- Health route without DB dependency: avoids cold-start readiness probe failures in SPCS

### Key Lessons
1. **Start with data verification (UAT first).** Running the domain walkthrough before polish or hardening surfaced 8 bugs against real data — far cheaper to fix before downstream work depends on correct behavior.
2. **Grep-verify plan scope before starting code quality phases.** A targeted search for `process.env.SNOWFLAKE_DATABASE` across the codebase before writing the Phase 3 plan would have prevented the Plan 04 insertion.
3. **SPCS CPU instance families are account-specific.** Always document a CPU_X64_XS fallback in setup scripts; STANDARD_1 is not universally available.
4. **Per-request connections over pooling is the right starting point.** For a demo/HOL portal, pooling adds complexity with no observable benefit; defer until performance data justifies it.
5. **Yolo mode shines for well-defined technical work.** Phases 3 and 4 had clear, auditable success criteria (zero grep matches, RUNNING status) that made gate prompts unnecessary overhead.

### Cost Observations
- Model mix: primarily Sonnet 4.6 throughout
- Sessions: ~4-5 sessions across 2 days
- Notable: Phase 2 (UX) executed in ~31 min total for 4 plans — KPICard/Skeleton pattern was highly parallelizable once formatters.ts was established

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 4 | 14 | First milestone — established UAT-first ordering and SPCS deployment pattern |

### Top Lessons (Verified Across Milestones)

1. UAT-first ordering surfaces real-data bugs before downstream work depends on correct behavior
2. Grep-verify plan coverage before executing code quality phases to avoid plan insertions
