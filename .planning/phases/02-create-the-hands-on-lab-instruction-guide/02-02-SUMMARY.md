---
phase: 02-create-the-hands-on-lab-instruction-guide
plan: 02
subsystem: docs
tags: [markdown, hands-on-lab, cortex-code, dbt, retry-success-rate, semantic-view, cortex-agent, mcp]

# Dependency graph
requires:
  - phase: 02-create-the-hands-on-lab-instruction-guide
    plan: 01
    provides: Foundation sections (header, architecture overview, setup verification, Cortex Code primer)
provides:
  - HANDS_ON_LAB.md Task 1 walkthrough (retry success rate metric end-to-end across 12 steps)
  - HANDS_ON_LAB.md context switch section with /new command and plan mode reminder
affects: [02-03-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns: [step-numbered-walkthrough, suggested-prompt-pattern, verification-sub-steps, placeholder-tokens]

key-files:
  created: []
  modified: [HANDS_ON_LAB.md]

key-decisions:
  - "Retry detection defined as window function on card_bin + card_last_four + transaction_amount within 5 min of decline from same merchant"
  - "Verification split into 4 sub-steps: DDL apply, semantic view rebuild, SQL query with clnt_id filter, Cortex Agent test"
  - "All Cortex Code prompts framed as suggestions per locked CONTEXT.md decision"
  - "Jira ticket and Confluence URL use instructor-provided placeholder tokens"

patterns-established:
  - "Task walkthrough pattern: 12 numbered steps covering read ticket -> branch -> plan -> execute -> verify -> commit -> update docs"
  - "Verification pattern with dynamic table manual refresh before querying"
  - "Context switch pattern: /new + plan mode reminder + accomplishment recap"

requirements-completed: [HOL-04, HOL-05, HOL-06]

# Metrics
duration: 2min
completed: 2026-03-06
---

# Phase 02 Plan 02: Task 1 Walkthrough Summary

**Retry success rate metric walkthrough covering 12 steps from Jira ticket through dbt model, semantic view, Cortex Agent, Snowflake verification, git commit, and Confluence data dictionary update**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-06T19:02:47Z
- **Completed:** 2026-03-06T19:04:56Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Section 4: Task 1 walkthrough with 12 steps covering full SDLC cycle (240 lines added)
- Concrete retry detection logic using window functions on card_bin + card_last_four + transaction_amount within 5-minute window
- Four-part verification: DDL apply with dynamic table refresh, semantic view rebuild, SQL query with clnt_id filter, Cortex Agent test
- Section 5: Context switch with /new, plan mode session-scope reminder, and Task 1 accomplishment recap

## Task Commits

Each task was committed atomically:

1. **Task 1: Write Task 1 walkthrough -- Retry Success Rate metric end-to-end** - `15d2032` (feat)
2. **Task 2: Write context switch section** - `ec466fa` (feat)

**Plan metadata:** pending (docs: complete Task 1 walkthrough plan)

## Files Created/Modified
- `HANDS_ON_LAB.md` - Added Sections 4-5 (Task 1 walkthrough and context switch, ~240 lines)

## Decisions Made
- Defined retry detection as a window function approach (same card + amount + merchant within 5 min of decline) per RESEARCH.md recommendation
- Split verification into 4 sub-steps matching real workflow: DDL apply, semantic view rebuild, metric data query, Cortex Agent test
- Included dynamic table manual refresh commands per Pitfall 5 from RESEARCH.md
- Used placeholder tokens for Jira ticket ID and Confluence URL per RESEARCH.md Open Questions

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Sections 1-5 of HANDS_ON_LAB.md are complete (header through context switch)
- Ready for 02-03-PLAN to write Task 2 (KPI card), wrap-up, and appendix
- All section numbering and structure established for appending remaining sections

## Self-Check: PASSED

- FOUND: HANDS_ON_LAB.md
- FOUND: 02-02-SUMMARY.md
- FOUND: 15d2032 (Task 1 commit)
- FOUND: ec466fa (Task 2 commit)

---
*Phase: 02-create-the-hands-on-lab-instruction-guide*
*Completed: 2026-03-06*
