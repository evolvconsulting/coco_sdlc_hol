---
phase: 02-create-the-hands-on-lab-instruction-guide
plan: 03
subsystem: docs
tags: [markdown, hands-on-lab, cortex-code, kpi-card, frontend, typescript, troubleshooting, wrap-up]

# Dependency graph
requires:
  - phase: 02-create-the-hands-on-lab-instruction-guide
    plan: 02
    provides: Task 1 walkthrough (Sections 4-5) covering retry success rate metric end-to-end
provides:
  - Complete HANDS_ON_LAB.md with all 7 sections plus appendix (625 lines)
  - Task 2 KPI card walkthrough (Section 6) with 7-step SDLC cycle
  - Wrap-up with 5 key takeaways (Section 7)
  - Appendix with troubleshooting table, resources, and glossary
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns: [read-only-mcp-interactions, cortex-code-driven-workflow, beyond-the-lab-callouts]

key-files:
  created: [INFRASTRUCTURE.md]
  modified: [HANDS_ON_LAB.md, README.md]

key-decisions:
  - "Jira/Confluence MCP interactions changed to read-only with 'Beyond the lab' callouts for write operations"
  - "Manual terminal/worksheet steps converted to Cortex Code CLI prompts for consistency"
  - "README.md restructured as landing page with prerequisites; INFRASTRUCTURE.md created for facilitator reference"
  - "WSL requirement removed from guide"

patterns-established:
  - "Beyond the lab callout pattern: blockquote notes for advanced/optional MCP write operations"
  - "Cortex Code-first workflow: all steps driven through CLI prompts rather than manual terminal commands"

requirements-completed: [HOL-07, HOL-08, HOL-09]

# Metrics
duration: 5min
completed: 2026-03-06
---

# Phase 02 Plan 03: Task 2 Walkthrough and Guide Completion Summary

**KPI card frontend walkthrough with 7-step SDLC cycle, wrap-up with 5 key takeaways, and troubleshooting appendix -- completing the 625-line HANDS_ON_LAB.md guide**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-06T19:10:00Z
- **Completed:** 2026-03-06T19:15:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Section 6: Task 2 walkthrough with 7 steps covering KPI card addition to authorization dashboard (TypeScript interface, API route, page component)
- Section 7: Wrap-up summarizing both SDLC cycles with 5 key takeaways about Cortex Code, plan mode, MCP skills, pattern extension, and context hygiene
- Appendix with troubleshooting table (8 common issues), resource links, and glossary of key terms
- Post-checkpoint revisions: read-only MCP interactions, Cortex Code-driven workflow, README restructured, INFRASTRUCTURE.md created, WSL requirement removed

## Task Commits

Each task was committed atomically:

1. **Task 1: Write Task 2 walkthrough, wrap-up, and appendix** - `d30a8ce` (feat)
2. **Task 2: Human verification of complete HANDS_ON_LAB.md guide** - checkpoint approved (no code commit)

Post-checkpoint revisions committed as `b351994` (docs: revise lab guide).

**Plan metadata:** pending

## Files Created/Modified
- `HANDS_ON_LAB.md` - Complete 625-line hands-on lab guide with all 7 sections plus appendix
- `README.md` - Restructured as landing page with prerequisites
- `INFRASTRUCTURE.md` - Created for facilitator reference (extracted from README)

## Decisions Made
- Changed Jira/Confluence MCP interactions to read-only with "Beyond the lab" callouts for write operations, keeping the lab focused on core development flow
- Converted manual terminal/worksheet steps to Cortex Code CLI prompts for a consistent AI-first workflow experience
- Restructured README.md as a landing page and created separate INFRASTRUCTURE.md for facilitator setup reference
- Removed WSL requirement to simplify prerequisites

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Post-checkpoint revisions for workflow consistency**
- **Found during:** Post-Task 1, pre-approval review
- **Issue:** MCP write operations (Jira comments, Confluence updates) were presented as required steps but may not be available in all lab environments; manual terminal steps were inconsistent with Cortex Code-first approach
- **Fix:** Changed MCP writes to read-only with "Beyond the lab" callouts; converted manual steps to CLI prompts; restructured docs; removed WSL requirement
- **Files modified:** HANDS_ON_LAB.md, README.md, INFRASTRUCTURE.md
- **Verification:** Human review and approval of complete guide
- **Committed in:** b351994

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Revision improved guide quality and consistency. No scope creep -- all changes within existing sections.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- HANDS_ON_LAB.md is complete and human-verified, ready for use in lab sessions
- Phase 2 is fully complete -- all 3 plans delivered
- No subsequent phases currently planned

## Self-Check: PASSED

- FOUND: HANDS_ON_LAB.md (625 lines)
- FOUND: README.md
- FOUND: INFRASTRUCTURE.md
- FOUND: 02-03-SUMMARY.md
- FOUND: d30a8ce (Task 1 commit)
- FOUND: b351994 (post-checkpoint revision commit)

---
*Phase: 02-create-the-hands-on-lab-instruction-guide*
*Completed: 2026-03-06*
