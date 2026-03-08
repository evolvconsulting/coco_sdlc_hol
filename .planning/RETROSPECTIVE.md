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

## Milestone: v2.0 — HOL Content

**Shipped:** 2026-03-08
**Phases:** 4 | **Plans:** 9 | **Timeline:** 8 days (2026-02-28 → 2026-03-07)

### What Was Built
- `hol_setup.sql` — 12-section idempotent Snowflake provisioning script covering infra, dbt DDL (11 staging views + 6 intermediate + 7 marts dynamic tables), service user, image repo, semantic view, and Cortex Agent
- `HANDS_ON_LAB.md` — 625-line participant guide: architecture overview, Cortex Code primer, Task 1 (retry success rate metric end-to-end), Task 2 (KPI card frontend), wrap-up, troubleshooting appendix
- Live Atlassian project: EPA-1 through EPA-6 in Jira, Confluence data dictionary split across 6 domain pages — all created via REST API
- `INSTRUCTOR_GUIDE.md` — sequenced prompt-by-prompt facilitation reference with timing, 13 "Watch for:" callouts, 6 "Call out to group:" notes, troubleshooting table

### What Worked
- Sequential phase ordering (SQL → lab guide → Atlassian → instructor guide) meant each phase had real artifacts to reference — no placeholder dependencies
- Human verification checkpoints on hol_setup.sql (01-03) and INSTRUCTOR_GUIDE.md (04-01) caught real issues before completion; worth the interruption
- REST API approach for Atlassian artifacts was cleaner than bash script — no local env dependencies, portable for any instructor
- Suggested-prompt framing in HANDS_ON_LAB.md was the right call — Cortex Code exploration requires participant agency, not scripted commands

### What Was Inefficient
- 02-03 required a late pivot: Jira/Confluence MCP interactions changed to read-only "Beyond the lab" callouts after discovering API tokens would be exposed during facilitation — should have been caught in planning
- hol_setup.sql had 3 plans (01-01, 01-02, 01-03) with intermediate assembly files that had to be cleaned up; a 2-plan structure (build + assemble) might have been simpler
- HANDS_ON_LAB.md Atlassian URLs are still placeholders — requires instructor substitution before every delivery run; a pre-flight templating step would eliminate this friction

### Patterns Established
- HOL content ordering: SQL setup → participant guide → supporting artifacts → instructor guide — each layer references previous
- REST API artifact creation pattern: store `.wiki` reference files first, then create via API — enables regeneration without re-running the full HOL
- Instructor guide as last deliverable: requires complete participant guide to extract sequencing from

### Key Lessons
1. **Scope Jira/Confluence MCP interactions in planning, not mid-execution.** The read-only pivot in 02-03 added a revision cycle; "what API permissions will be live during facilitation?" is a planning question.
2. **Participant guides need real ticket IDs, not placeholders.** EPA-2 and EPA-3 being live artifacts rather than `[TICKET_ID]` strings meaningfully improves the participant experience — worth the dependency on Phase 3.
3. **Human verification checkpoints at content completion are high-value.** The 04-01 checkpoint caught edge cases (expected output placement, sub-step granularity) that automated checks missed.
4. **Confluence page structure should mirror the product's domain structure.** The 6-domain split for the data dictionary was discovered during execution — should be a default for domain-oriented content.

### Cost Observations
- Model mix: primarily Sonnet 4.6 throughout
- Sessions: ~6-8 sessions across 8 days (intermittent work)
- Notable: Phase 4 (Instructor Guide) was the most iterative despite being 1 plan — content quality work benefits from human review gates

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 4 | 14 | First milestone — established UAT-first ordering and SPCS deployment pattern |
| v2.0 | 4 | 9 | Content-focused milestone — REST API artifacts, human verification gates on deliverables |

### Top Lessons (Verified Across Milestones)

1. UAT-first ordering surfaces real-data bugs before downstream work depends on correct behavior
2. Grep-verify plan coverage before executing code quality phases to avoid plan insertions
3. Human verification checkpoints on content deliverables catch quality issues automated checks miss
4. Scope API/MCP permissions in planning — discovering access constraints mid-execution causes rework
