# Milestones

## v2.0 HOL Content (Shipped: 2026-03-08)

**Phases completed:** 4 phases, 9 plans
**Timeline:** 2026-02-28 → 2026-03-07 (8 days)
**Files changed:** 150 | **Lines added:** ~22,439

**Delivered:** Complete HOL delivery package — Snowflake provisioning script, hands-on lab guide, live Atlassian project artifacts, and instructor facilitation guide covering the full AI-assisted SDLC workflow with Cortex Code.

**Key accomplishments:**
1. `hol_setup.sql` — single 12-section idempotent Snowflake script provisioning database, schemas, RAW tables, dbt DDL (11 staging views + 6 intermediate + 7 marts dynamic tables), service user, image repo, semantic view, and Cortex Agent
2. `HANDS_ON_LAB.md` — 625-line lab guide: full SDLC cycle with Cortex Code across Task 1 (retry success rate metric: dbt → semantic view → Cortex Agent) and Task 2 (KPI card frontend change), with troubleshooting appendix
3. Live Atlassian project — EPA-1 epic, EPA-2/EPA-3 stories, 3 backlog items, and Confluence data dictionary (6 domain pages + index) created via REST API; `create-atlassian-artifacts.sh` script included
4. `INSTRUCTOR_GUIDE.md` — standalone facilitation guide with all ~30 participant prompts sequenced, timing cues at every section, 13 "Watch for:" callouts, 6 "Call out to group:" notes, conditional/fallback prompts, 7-row troubleshooting table

**Archive:** `.planning/milestones/v2.0-ROADMAP.md`

---

## v1.0 HOL Baseline Application (Shipped: 2026-03-01)

**Phases completed:** 4 phases, 14 plans
**Timeline:** 2026-02-28 → 2026-03-01 (2 days)
**Files changed:** 82 | **Lines of code:** ~7,900 TypeScript
**Live endpoint:** https://b6b4qiky-aovnged-ennovate.snowflakecomputing.app

**Delivered:** Full-stack self-serve analytics portal deployed to Snowpark Container Services — all 6 payment domains verified with real Snowflake MARTS data, polished UX, hardened API security, and live SPCS endpoint with RSA key secret injection.

**Key accomplishments:**
1. All 6 payment domains (authorization, settlement, funding, chargeback, retrieval, adjustment) and AI chat verified against real Snowflake MARTS data — Phase 1 UAT PASS across all 8 requirements
2. Unified UX across all domain pages: KPICard components, Skeleton chart loading, canonical formatters, and controlled sidebar navigation — Phase 2 all 6 UX requirements satisfied
3. Hardened all 22 API routes with parameterized queries, centralized `config.ts`, and sanitized error responses — SQL injection and credential exposure eliminated
4. Portal containerized (linux/amd64, 329MB) and deployed to Snowpark Container Services with RSA private key injected via Snowflake GENERIC_STRING Secret — SPCS service RUNNING 1/1 at public HTTPS endpoint

**Archive:** `.planning/milestones/v1.0-ROADMAP.md` | `.planning/milestones/v1.0-REQUIREMENTS.md`

---
