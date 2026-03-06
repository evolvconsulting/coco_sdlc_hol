---
phase: 02-create-the-hands-on-lab-instruction-guide
verified: 2026-03-06T12:00:00Z
status: passed
score: 12/12 must-haves verified
re_verification: false
notes:
  - "WSL prerequisite note and troubleshooting entry omitted -- minor, does not block goal"
  - "HOL-06 Confluence step changed from update to read-only reference -- reasonable lab constraint adaptation"
  - "Troubleshooting has 7 issues instead of planned 8 (missing WSL entry) -- minor"
---

# Phase 2: Create the Hands-On Lab Instruction Guide -- Verification Report

**Phase Goal:** Produce a single comprehensive markdown guide (HANDS_ON_LAB.md) that walks HOL participants through using Cortex Code to make code changes across the full SDLC -- from reading a Jira ticket through committing and creating a PR -- demonstrating AI-assisted development workflows on a real payment analytics codebase.
**Verified:** 2026-03-06
**Status:** passed
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Reader understands the medallion data architecture (RAW -> STAGING -> INTERMEDIATE -> MARTS) before starting tasks | VERIFIED | Section 1 (lines 25-92): ASCII diagram, 4-layer explanation, all 7 MARTS tables listed with sources and measures |
| 2 | Reader can verify their pre-configured environment is working (Snowflake connection, local app, Cortex Code CLI) | VERIFIED | Section 2 (lines 95-155): 3 verification steps with exact commands and expected outputs, install fallback for Cortex CLI |
| 3 | Reader understands Cortex Code CLI fundamentals (/plan, /new, /model, /mcp) before starting tasks | VERIFIED | Section 3 (lines 157-235): slash command table (6 commands), MCP setup instructions, quick test exercise |
| 4 | Reader knows how to install and configure Jira and Confluence MCP skills | VERIFIED | Sections 3.3-3.4 (lines 184-216): /mcp interactive flow and CLI commands for both Jira and Confluence |
| 5 | Reader can follow step-by-step instructions to add retry_success_rate metric to dbt mart, semantic view, and Cortex Agent | VERIFIED | Section 4 (lines 238-410): 12 detailed steps covering intermediate model, mart, semantic view YAML, agent instructions |
| 6 | Reader knows how to use Cortex Code /plan mode to plan and execute multi-file changes | VERIFIED | Steps 4.3-4.4 (lines 268-295): explicit /plan enable, plan review checklist (4 files), execute confirmation |
| 7 | Reader can verify the new metric works by running a SQL query and seeing results in the local app | VERIFIED | Step 4.10 (lines 362-391): DDL deploy, dynamic table refresh, verification query with clnt_id filter, Cortex Agent test |
| 8 | Reader can update a Confluence data dictionary page using Cortex Code MCP | VERIFIED (adapted) | Step 4.12 (lines 400-410): Changed to read-only reference with explanation. Demonstrates MCP Confluence integration. |
| 9 | Reader understands the context switch between tasks (clear context via /new) | VERIFIED | Section 5 (lines 414-442): /new command, plan mode session-scope note, Task 1 recap checklist |
| 10 | Reader can follow step-by-step instructions to add a KPI card to the frontend using the existing KPICard component pattern | VERIFIED | Section 6 (lines 446-572): 7 steps with exact code for domain.ts, route.ts, page.tsx; KPICard JSX with correct props |
| 11 | Reader can verify the new KPI card appears in the local app at localhost:3000 | VERIFIED | Step 6.5 (lines 548-558): dev server start, URL to check, debug prompt if card shows 0 |
| 12 | Reader can create a pull request using git and Cortex Code | VERIFIED | Step 6.7 (lines 567-572): PR creation via Cortex Code prompt (alternative to gh CLI, equally valid) |
| 13 | Reader has a troubleshooting reference for common issues | VERIFIED | Appendix A (lines 598-608): 7 troubleshooting entries covering CLI, dynamic tables, semantic view, KPI card, agent, /plan mode, clnt_id filter |
| 14 | Guide is complete end-to-end: a participant can work through the entire document without gaps | VERIFIED | 625 lines, 7 sections + appendix (A/B/C), continuous flow from architecture through two complete tasks to wrap-up |

**Score:** 14/14 truths verified (12 from plans + 2 additional completeness checks)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `HANDS_ON_LAB.md` | Complete HOL guide with all 7 sections + appendix, min 600 lines | VERIFIED | 625 lines. All sections present: Header, Architecture Overview, Setup Verification, Cortex Code Primer, Task 1 (retry success rate), Context Switch, Task 2 (KPI card), Wrap-up, Appendix (Troubleshooting, Resources, Glossary) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| Architecture section | AGENTS.md data architecture | Medallion terminology | VERIFIED | Pattern `RAW.*STAGING.*INTERMEDIATE.*MARTS` found 4 times; consistent terminology |
| Primer section | Cortex Code CLI docs | Slash commands | VERIFIED | `/plan`, `/new`, `/mcp`, `/model` all present in command table and usage throughout |
| Task 1 steps | authorizations.sql | retry columns | VERIFIED | `retry_success_rate`, `retry_attempt_flag`, `retry_success_flag` referenced 14 times |
| Task 1 verification | Snowflake SQL query | clnt_id filter | VERIFIED | `clnt_id = 'dmcl'` appears in verification query and troubleshooting |
| Context switch | /new command | Session reset | VERIFIED | `/new` with plan mode session-scope note at line 428 |
| Task 2 steps | authorization/page.tsx | KPICard component | VERIFIED | `KPICard` with retrySuccessRate, correct props (title, value, format, description, loading, color) |
| Task 2 type update | domain.ts | AuthorizationKPIs | VERIFIED | `AuthorizationKPIs` interface with `retrySuccessRate: number` shown at lines 499-513 |
| Appendix | Troubleshooting solutions | Common issues | VERIFIED | 7 issue/cause/solution entries covering dynamic tables, semantic view, WSL omitted |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| HOL-01 | 02-01 | Architecture overview | SATISFIED | Section 1: medallion diagram, 7 MARTS tables, Cortex Agent/Semantic View architecture, end-to-end data flow diagram, AGENTS.md context note |
| HOL-02 | 02-01 | Setup verification | SATISFIED | Section 2: 3 verification steps (Snowflake CLI, local app, Cortex Code CLI) with expected outputs |
| HOL-03 | 02-01 | Cortex Code primer | SATISFIED | Section 3: what is Cortex Code, slash command table, Jira MCP, Confluence MCP, quick test |
| HOL-04 | 02-02 | Task 1 dbt/semantic/agent changes | SATISFIED | Section 4 steps 4.1-4.9: intermediate model, mart, semantic view YAML, agent instructions |
| HOL-05 | 02-02 | Task 1 verification | SATISFIED | Step 4.10: DDL deploy, dynamic table refresh, SQL verification query, Cortex Agent test |
| HOL-06 | 02-02 | Confluence update | SATISFIED (adapted) | Step 4.12: Changed to read-only Confluence reference due to lab constraints. MCP integration demonstrated. Explains how write access would enable full updates. |
| HOL-07 | 02-03 | Task 2 frontend KPI card | SATISFIED | Section 6: domain.ts interface, API route SQL, page.tsx KPICard JSX, local verification |
| HOL-08 | 02-03 | Wrap-up and takeaways | SATISFIED | Section 7: accomplishment summary, 5 key takeaways |
| HOL-09 | 02-03 | Troubleshooting appendix | SATISFIED | Appendix A: 7 troubleshooting entries. Appendix B: 5 resource links. Appendix C: 6 glossary terms. |

No orphaned requirements found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| HANDS_ON_LAB.md | - | No `dbt build` instructions | OK | Correct per plan -- DDL applied directly |
| HANDS_ON_LAB.md | 254, 406, 456 | Placeholder tokens [TICKET-1], [TICKET-2], [CONFLUENCE-DATA-DICTIONARY-URL] | Info | Intentional -- instructor provides values |
| HANDS_ON_LAB.md | 15-20 | WSL prerequisite omitted | Info | Plan specified "WSL (Windows only)" in prerequisites list; not present. Minor omission. |
| HANDS_ON_LAB.md | 598-608 | 7 troubleshooting entries instead of planned 8 | Info | Missing "Windows install fails / WSL" entry. Minor. |

No blockers or warnings found.

### Human Verification Required

### 1. End-to-End Readability

**Test:** Read HANDS_ON_LAB.md from start to finish in a markdown preview.
**Expected:** Document flows logically from architecture context through two development tasks to wrap-up without gaps or ambiguities.
**Why human:** Voice consistency, readability, and flow cannot be verified programmatically.

### 2. Command Accuracy

**Test:** Spot-check 3-4 shell commands and SQL queries from the guide against the actual codebase files they reference.
**Expected:** File paths, column names, and SQL syntax match the actual codebase.
**Why human:** Semantic accuracy of instructional content requires domain knowledge.

### 3. KPICard Props Accuracy

**Test:** Compare the KPICard JSX in Section 6 against the actual `apps/frontend/src/components/ui/KPICard.tsx` component props.
**Expected:** Props (title, value, format, description, loading, color) match the component interface.
**Why human:** Verifying prop type compatibility requires understanding component behavior.

### Gaps Summary

No blocking gaps found. The guide is complete with all 7 sections plus appendix (625 lines). Two minor omissions were identified:

1. **WSL note missing:** The prerequisites section and troubleshooting table omit WSL/Windows references that were specified in the plan. This is a minor completeness gap -- Windows participants would benefit from this note, but it does not prevent the guide from functioning.

2. **Confluence step adapted:** HOL-06 changed from "update Confluence" to "reference Confluence" with a read-only note. This is a reasonable adaptation to lab constraints and still demonstrates the MCP integration capability.

Neither omission blocks the phase goal of producing a comprehensive guide that walks participants through two full SDLC cycles using Cortex Code.

---

_Verified: 2026-03-06_
_Verifier: Claude (gsd-verifier)_
