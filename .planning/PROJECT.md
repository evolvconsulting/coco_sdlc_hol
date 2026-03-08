# COCO SDLC HOL — Credit Card Transaction Analytics Portal

## What This Is

A complete hands-on lab (HOL) delivery package demonstrating AI-assisted software development with Snowflake Cortex Code. Includes a self-serve analytics portal (the lab environment), a Snowflake provisioning script, a participant lab guide, live Atlassian project artifacts (Jira + Confluence), and an instructor facilitation guide. Participants experience the full SDLC cycle — reading a ticket, making code changes across dbt/semantic layer/frontend, and committing a PR — guided by Cortex Code throughout.

## Core Value

A self-contained lab that runs end-to-end — participants walk away having made real code changes to a real data pipeline with AI assistance, across the full SDLC from ticket to PR.

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

- ✓ `hol_setup.sql` — single idempotent Snowflake provisioning script (12 sections: infra + dbt DDL + Cortex Agent) — v2.0
- ✓ `HANDS_ON_LAB.md` — complete participant lab guide (625 lines, 2 tasks, full SDLC walkthrough) — v2.0
- ✓ Live Atlassian project — EPA-1 epic, EPA-2/EPA-3 stories, 3 backlog items, Confluence data dictionary (6 domain pages) — v2.0
- ✓ `INSTRUCTOR_GUIDE.md` — facilitation reference with sequenced prompts, timing cues, 13 callouts, troubleshooting table — v2.0

### Active

(Next milestone — to be defined via `/gsd:new-milestone`)

### Out of Scope

- Authentication/authorization — RLS + CLNT_ID filter handles data isolation; auth adds significant scope
- Automated test suite — manual UAT only for v1.0
- Rate limiting — not in scope for v1.0
- Server-side query result caching — not in scope for v1.0
- Mobile / responsive breakpoints below desktop — web-first; desktop use case only

## Context

- v1.0 analytics portal deployed to SPCS: `https://b6b4qiky-aovnged-ennovate.snowflakecomputing.app` (Snowflake OAuth gate active)
- v2.0 HOL content shipped 2026-03-08 — lab is delivery-ready
- Portal: ~7,900 LOC TypeScript; Next.js standalone; linux/amd64 Docker image (329MB); SPCS with RSA secret injection
- HOL content: `hol_setup.sql` (12 sections), `HANDS_ON_LAB.md` (625 lines), `INSTRUCTOR_GUIDE.md`, Atlassian artifacts (EPA-1 through EPA-6, 6 Confluence pages)
- Atlassian URLs in HANDS_ON_LAB.md use instructor-provided placeholders — must be substituted before delivery
- Tech stack: Next.js, Snowflake Node.js SDK, Snowflake Cortex Agent, dbt, Ant Design, Recharts

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

| All prompts framed as suggestions (not directives) | Participants need agency; over-scripting breaks Cortex Code exploration | ✓ Good — natural conversational flow |
| Jira/Confluence MCP changed to read-only | API tokens in lab context; scoped tokens safer and avoids accidental mutations | ✓ Good — no side effects during facilitation |
| Atlassian artifacts via direct REST API (not bash script) | Faster than env setup for bash; no dependency on instructor's local toolchain | ✓ Good — portable and reliable |
| Confluence split into 6 domain pages + index | Single page was too long for navigation; domain split mirrors portal structure | ✓ Good — matches participant's mental model |
| Steps 4.10a/b/c/d as separate INSTRUCTOR_GUIDE entries | Per-verification tracking granularity for instructor; one entry per testable output | ✓ Good — instructors can track exactly where participants are |

---
*Last updated: 2026-03-08 after v2.0 HOL Content milestone*
