---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: completed
stopped_at: "Completed 06-01: fork-then-clone instructions updated in LAB_INSTRUCTIONS.md, README.md, INSTRUCTOR_GUIDE.md — human-approved"
last_updated: "2026-03-11T15:28:24.252Z"
last_activity: "2026-03-11 — Completed 06-01: fork-then-clone instructions updated across all three lab documents"
progress:
  total_phases: 2
  completed_phases: 2
  total_plans: 2
  completed_plans: 2
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-01 after v1.0 milestone)

**Core value:** Merchants can independently answer questions about their transaction performance without calling support — seeing approvals, fees, chargebacks, and funding in one place with their own data.
**Current focus:** Phase 3 - Generate reference content for Jira tickets and Confluence documentation

## Current Position

Phase: 06-update-instructions-to-include-step-to-fork-the-repository-per-option-a-standard-open-source-model — Plan 01 of 1 complete (ALL PLANS COMPLETE)
Status: All plans complete. Fork-then-clone workflow introduced in LAB_INSTRUCTIONS.md, README.md, and INSTRUCTOR_GUIDE.md — human-approved and committed.
Last activity: 2026-03-11 — Completed 06-01: fork-then-clone instructions updated across all three lab documents

Progress: [██████████] 100% (11/11 plans complete) — 1/1 Phase 6 plans complete

## Accumulated Context

### Roadmap Evolution

- Phase 1 added: Generate hands on lab setup script
- Phase 2 added: Create the Hands on Lab instruction guide
- Phase 3 added: Generate reference content for Jira tickets and Confluence documentation
- Phase 4 added: Instructor reference sheet with prompt by prompt sequence
- Phase 5 added: Instructor Claude Skill
- Phase 6 added: Update instructions to include step to fork the repository per Option A Standard open-source model
- Phase 7 added: Separate out all SPCS components from the lab (leave SPCS setup in project, exclude from lab setup)

### Decisions

All milestone decisions logged in PROJECT.md Key Decisions table.

**01-01 (2026-03-01):** COMPUTE_WH creation and GRANT USAGE placed in ACCOUNTADMIN section before role switch; GRANT CREATE IMAGE REPOSITORY included in bootstrap; USE SCHEMA fully qualified as COCO_SDLC_HOL.RAW; GENERATE_SYNTHETIC_DATA call guarded by EXECUTE IMMEDIATE idempotency check.

**01-02 (2026-03-01):** Marts compiled SQL schema references corrected from COCO_SDLC_HOL.STAGING.int_* to COCO_SDLC_HOL.INTERMEDIATE.int_* (Pitfall 6 from RESEARCH.md); dynamic table DDL does not use parentheses around AS body; stg_clx_auth confirmed clean — no risk_score removal needed.

**01-03 (2026-03-06):** Duplicate GRANT USAGE ON AGENT removed (kept only in Section 12 Final Grants); RSA key placeholders use angle-bracket tokens for dataops.live substitution; Cortex Agent GRANT changed from SYSADMIN to ATTENDEE_ROLE; intermediate assembly files deleted after merge.

**02-01 (2026-03-06):** ASCII art diagrams chosen over Mermaid for portability; all 7 MARTS tables included with RAW source mapping; suggested prompts framed as starting points per locked CONTEXT.md decision.

**02-02 (2026-03-06):** Retry detection defined as window function on card_bin + card_last_four + transaction_amount within 5 min of decline; verification split into 4 sub-steps (DDL apply, semantic view rebuild, SQL query, Cortex Agent test); all prompts framed as suggestions; Jira/Confluence URLs use instructor-provided placeholders.

**02-03 (2026-03-06):** Jira/Confluence MCP interactions changed to read-only with "Beyond the lab" callouts; manual terminal steps converted to Cortex Code CLI prompts; README restructured as landing page; INFRASTRUCTURE.md created for facilitator reference; WSL requirement removed.

**03-01 (2026-03-06):** All 11 metrics from semantic view YAML included in data dictionary (not 10 as INFRASTRUCTURE.md states); data dictionary uses 5-column table format; backlog items cover settlement disputes, chargeback alerting, and funding reconciliation.

**03-02 (2026-03-06):** Artifacts created directly via API rather than bash script; Confluence data dictionary split into 6 domain pages with index homepage; API tokens in HANDS_ON_LAB.md replaced with scoped read-only tokens.

**04-01 (2026-03-07):** Section 7 (Wrap-up) omitted — no participant inputs; steps 4.6-4.9 retained as instructor tracking markers despite no participant-typed input; sub-steps 4.10a/b/c/d kept as separate entries to preserve per-verification tracking.
- [Phase 05-instructor-claude-skill]: 05-01: Skill reads source files at runtime — not inlined — so it stays in sync as source files evolve; verification steps phrased as relay prompts only
- [Phase 06-01]: Fork-then-clone adopted as sole onboarding path; no direct clone option retained; branch protection on main makes direct push impossible for non-admins; Steps 4.11, 6.6, 6.7 unchanged; no new prerequisite tools introduced

### Pending Todos

None — all planned work complete. README todo resolved in 02-03 (restructured as landing page with Cortex Code CLI as primary tool).

### Blockers/Concerns

None — all v1.0 pre-phase concerns resolved (SQL injection: CODE-04 ✓, credential exposure: CODE-03 ✓, hardcoded table names: CODE-01 ✓).

## Session Continuity

Last session: 2026-03-11T14:03:34.776Z
Stopped at: Completed 06-01: fork-then-clone instructions updated in LAB_INSTRUCTIONS.md, README.md, INSTRUCTOR_GUIDE.md — human-approved
Resume file: None
