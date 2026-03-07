---
phase: 04-instructor-reference-sheet-with-prompt-by-prompt-sequence
plan: 01
subsystem: docs
tags: [instructor-guide, lab, cortex-code, snowflake, dbt, facilitation]

# Dependency graph
requires:
  - phase: 02-create-the-hands-on-lab-instruction-guide
    provides: LAB_INSTRUCTIONS.md with full participant step sequence and appendix
  - phase: 03-generate-reference-content-for-jira-tickets-and-confluence-documentation
    provides: EPA-2 and EPA-3 confirmed ticket IDs for use in guide

provides:
  - INSTRUCTOR_GUIDE.md — standalone live-use instructor reference at repo root

affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Step entry format: label + fenced code block + optional callout (no prose between steps)"
    - "Conditional/fallback prompts use bracketed label before code block"
    - "Expected outputs only at explicit verification steps (4.10a/b/c/d, 6.5)"

key-files:
  created:
    - INSTRUCTOR_GUIDE.md
  modified: []

key-decisions:
  - "Section 7 (Wrap-up) omitted — no participant inputs; 'Lab complete.' closes document cleanly"
  - "Steps 4.6-4.9 retained as instructor tracking markers despite having no participant-typed input"
  - "Sub-steps 4.10a/b/c/d kept as separate entries — not collapsed into a single Step 4.10"
  - "Quick-reference troubleshooting table placed at end, not as appendix"

patterns-established:
  - "Instructor guide pattern: no explanatory prose; every line is a step label, code block, or callout"
  - "Callout discipline: Watch for: only at known sticking points; Call out to group: only at key transitions"

requirements-completed: [CONTEXT-04]

# Metrics
duration: 45min
completed: 2026-03-07
---

# Phase 4 Plan 01: Instructor Reference Sheet Summary

**Instructor-only live-use reference with all 30+ participant-typed inputs in step-sequence order, 12 Watch for: callouts, 6 Call out to group: notes, and a 7-row troubleshooting table**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-03-07
- **Completed:** 2026-03-07
- **Tasks:** 3 auto + 1 checkpoint (human approved)
- **Files modified:** 1

## Accomplishments

- INSTRUCTOR_GUIDE.md written at repo root — sections 1 through 6 covering the full 90-minute lab
- All participant-typed inputs from LAB_INSTRUCTIONS.md present verbatim, step numbers matching exactly (2.1-2.3, 3.3-3.5, 4.1-4.12 with sub-steps 4.10a/b/c/d, Section 5, 6.1-6.7)
- Conditional/fallback prompts at all 4 known failure modes (4.3 scope expansion, 4.5 retry logic, 4.6 materialization, 6.5 KPI card debug)
- Human reviewer approved document via checkpoint

## Task Commits

Each task was committed atomically:

1. **Task 1: Write document header and Sections 1-3** - `1781c56` (feat)
2. **Task 2: Write Section 4 and Section 5** - `5feadcb` (feat)
3. **Task 3: Write Section 6 and troubleshooting table** - `5998f79` (feat)

## Files Created/Modified

- `INSTRUCTOR_GUIDE.md` — standalone instructor reference; 6 sections, all participant inputs verbatim, timing cues at section headers, 12 sticking-point callouts, 6 transition call-outs, 7-row troubleshooting table

## Decisions Made

- Section 7 (Wrap-up) omitted — it has no participant inputs; "Lab complete." after Step 6.7 closes the document without participant-facing prose
- Steps 4.6, 4.7, 4.8, 4.9 retained as italicized one-liner markers even though they have no participant-typed input, so the instructor can track the sequence during plan execution without losing their place
- Sub-steps 4.10a/b/c/d kept as separate labeled entries — collapsing them into a single Step 4.10 would break the instructor's ability to track which verification the participant is on
- Quick-reference troubleshooting table placed inline at end of document (not as appendix) for fast scanning during a live session

## Deviations from Plan

None - plan executed exactly as written. Human reviewer approved without requesting changes.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 4 is the final planned phase. INSTRUCTOR_GUIDE.md is ready for live use at the next HOL event. No blockers or open concerns.

---
*Phase: 04-instructor-reference-sheet-with-prompt-by-prompt-sequence*
*Completed: 2026-03-07*
