# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-28)

**Core value:** Merchants can independently answer questions about their transaction performance without calling support — seeing approvals, fees, chargebacks, and funding in one place with their own data.
**Current focus:** Phase 2 — UX/UI Polish

## Current Position

Phase: 2 of 4 (UX/UI Polish) — IN PROGRESS
Plan: 1 of 3 in current phase — COMPLETE
Status: Phase 2 in progress — Plan 02-01 complete
Last activity: 2026-02-28 — Plan 02-01 complete (sidebar fix + formatter module created)

Progress: [████░░░░░░] 33% (4/9 plans total complete)

## Performance Metrics

**Velocity:**
- Total plans completed: 3
- Average duration: ~60 min
- Total execution time: ~3 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. UAT Walkthrough | 3/3 | ~180 min | ~60 min |
| 2. UX/UI Polish | 1/3 | ~7 min | ~7 min |

**Recent Trend:**
- Last 5 plans: 01-01, 01-02, 01-03, 02-01
- Trend: 02-01 took ~7 min (targeted fixes, no blockers)

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Init]: Skip auth for this milestone — RLS + CLNT_ID filter handles data isolation for demo
- [Init]: SPCS deployment target — keeps everything within Snowflake ecosystem
- [Init]: Manual UAT over automated tests — 2-day timeline constraint
- [01-01]: Key-pair auth via SNOWFLAKE_PRIVATE_KEY_PATH=c:/Users/TrentFoley/Keys/ennovate-trent-foley.p8
- [01-01]: CORTEX_AGENT_DATABASE/SCHEMA removed — consolidated into SNOWFLAKE_DATABASE=COCO_SDLC_HOL / SNOWFLAKE_SCHEMA=MARTS
- [01-01]: CORTEX_AGENT_NAME=PAYMENT_ANALYTICS_AGENT
- [01-01]: Snowflake CLI connection name "ennovate" for all diagnostic SQL
- [01-01]: Plan 02 test window: 2026-01-13 to 2026-02-22 (all 6 MARTS tables have data)
- [01-02]: MARTS tables use *_key naming convention for primary keys (not *_id) — affects all domain details routes
- [01-02]: Retrieval primary date column is retrieval_received_date (original_sale_date range is ~3 months earlier, outside test window)
- [01-02]: Turbopack requires turbopack.root = monorepo root in next.config.ts to resolve lightningcss in multi-lockfile workspace
- [01-02]: All 7 UAT domains (UAT-01 through UAT-07) verified PASS — no outstanding bugs entering Plan 03
- [01-03]: Phase 1 UAT sign-off PASS — all 8 requirements (UAT-01 through UAT-08) satisfied
- [01-03]: AI chat (UAT-08) verified — Snowflake Cortex Agent PAYMENT_ANALYTICS_AGENT returns contextually relevant streaming SSE responses with JWT key-pair auth
- [02-01]: defaultOpenKeys changed to controlled openKeys prop — uncontrolled only applies at mount, controlled responds to pathname changes
- [02-01]: formatCompactCurrency uses explicit threshold logic (not Intl compact) for predictable, testable output
- [02-01]: SaveOutlined import removed alongside Saved Reports menu item — no orphaned imports

### Pending Todos

None yet.

### Blockers/Concerns

- [Pre-Phase 1]: Codebase has SQL injection risk (string interpolation in queries) — addressed in Phase 3 (CODE-04)
- [Pre-Phase 1]: Error responses may expose Snowflake credentials — addressed in Phase 3 (CODE-03)
- [Pre-Phase 1]: Hardcoded table/schema names scattered across route files — addressed in Phase 3 (CODE-01)

## Session Continuity

Last session: 2026-02-28
Stopped at: Completed 02-01-PLAN.md — sidebar openKeys fix + formatters.ts created, ready for 02-02
Resume file: None
