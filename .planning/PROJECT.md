# COCO SDLC HOL — Credit Card Transaction Analytics Portal

## What This Is

A self-serve analytics portal for merchants using credit card transaction processing services, deployed to Snowpark Container Services. Merchants can view KPIs, trends, and detailed data across 6 payment domains (authorization, settlement, funding, chargebacks, retrievals, adjustments) and ask natural language questions via AI chat powered by Snowflake Cortex. Built on Next.js with real-time Snowflake data through a dbt MARTS transformation layer. Live at SPCS with RSA key-pair auth and all API routes hardened against SQL injection and credential exposure.

## Core Value

Merchants can independently answer questions about their transaction performance without calling support — seeing approvals, fees, chargebacks, and funding in one place with their own data.

## Requirements

### Validated

- ✓ Authorization analytics (KPIs, timeseries, by-brand, declines, details) — existing
- ✓ Settlement analytics (KPIs, by-merchant, timeseries, details) — existing
- ✓ Funding analytics (KPIs, timeseries, details) — existing
- ✓ Chargeback analytics (KPIs, by-reason, details) — existing
- ✓ Retrieval analytics (KPIs, details) — existing
- ✓ Adjustment analytics (KPIs, details) — existing
- ✓ AI chat / natural language queries via Snowflake Cortex — existing
- ✓ Row-level security (CLNT_ID filter) — existing
- ✓ dbt transformation pipeline (staging → intermediate → marts) — existing
- ✓ React Query client-side caching (5-minute stale time) — existing
- ✓ UAT walkthrough — all 6 domains verified with real Snowflake data — v1.0
- ✓ Bug fixes — 8 bugs resolved (SQL column names, date filter columns, turbopack config) — v1.0
- ✓ UX/UI polish — KPICard, Skeleton loading, canonical formatters, controlled sidebar — v1.0
- ✓ Code quality — config.ts, parameterized queries, sanitized errors, per-request connections — v1.0
- ✓ Deployment to Snowpark Container Services (SPCS) — containerized, live, RSA secret injection — v1.0

### Active

(Next milestone — to be defined via `/gsd:new-milestone`)

### Out of Scope

- Authentication/authorization — RLS + CLNT_ID filter handles data isolation; auth adds significant scope
- Automated test suite — manual UAT only for v1.0
- Rate limiting — not in scope for v1.0
- Server-side query result caching — not in scope for v1.0
- Mobile / responsive breakpoints below desktop — web-first; desktop use case only

## Context

- Portal shipped as part of the COCO SDLC hands-on-lab (HOL) project — v1.0 complete 2026-03-01
- Deployed to SPCS: `https://b6b4qiky-aovnged-ennovate.snowflakecomputing.app` (Snowflake OAuth gate active)
- All data in Snowflake under `COCO_SDLC_HOL.MARTS.*` — centralized via `apps/frontend/src/lib/config.ts`
- RLS hardcoded to `CLNT_ID = 'dmcl'` for single-tenant demo scenario
- Codebase: ~7,900 LOC TypeScript; Next.js standalone output; linux/amd64 Docker image (329MB)
- Tech stack: Next.js, Snowflake Node.js SDK, Snowflake Cortex Agent, dbt, Ant Design, Recharts
- All 22 v1 requirements satisfied across 4 phases and 14 plans in 2 days

## Constraints

- **Deployment**: Snowpark Container Services (SPCS) — containerization required ✓
- **Data**: Real Snowflake data via existing MARTS schema (no mocking) ✓
- **Tech Stack**: Next.js, Snowflake SDK, dbt — no stack changes ✓

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Skip auth for this milestone | RLS + CLNT_ID filter provides data isolation for demo; auth adds significant scope | ✓ Good — demo works as intended |
| SPCS deployment target | Keeps everything within Snowflake ecosystem; no external cloud infra needed | ✓ Good — live and working |
| Manual UAT over automated tests | 2-day timeline; automated tests would take longer than the milestone | ✓ Good — 2-day timeline met |
| Key-pair auth via SNOWFLAKE_PRIVATE_KEY_PATH | Required for Snowflake Cortex Agent JWT streaming; password auth not supported for SSE | ✓ Good — works in both local dev and SPCS via secret injection |
| Per-request Snowflake connections (no pool) | Simpler lifecycle; pool deferred to future performance phase | ✓ Good — no concurrency issues observed |
| Parameterized queries via binds array | Real SQL injection protection vs bypassable sanitizeSQL() regex | ✓ Good — all 22 routes use binds |
| Centralized config.ts for DB/schema/table refs | Single source of truth; eliminates scattered hardcoded strings | ✓ Good — zero hardcoded COCO_SDLC_HOL.MARTS.* in route files |
| GENERIC_STRING secret + secretKeyRef: secret_string | Only supported type for RSA PEM key injection in SPCS | ✓ Good — key injected correctly |
| CPU_X64_XS instead of STANDARD_1 | STANDARD_1 not supported in this Snowflake account | ✓ Good — functionally equivalent for HOL demo |
| outputFileTracingRoot at monorepo root | Required for Next.js standalone to trace workspace packages | ✓ Good — Docker build captures all dependencies |
| Health route at /api/health (no Snowflake dep) | Avoids cold-start probe failures during SPCS container init | ✓ Good — readiness probe passes reliably |

---
*Last updated: 2026-03-01 after v1.0 HOL Baseline Application milestone*
