---
phase: 02-create-the-hands-on-lab-instruction-guide
plan: 01
subsystem: docs
tags: [markdown, hands-on-lab, cortex-code, medallion-architecture, mcp]

# Dependency graph
requires:
  - phase: 01-generate-hands-on-lab-setup-script
    provides: Pre-configured Snowflake environment (hol_setup.sql) that participants verify against
provides:
  - HANDS_ON_LAB.md foundation sections (header, architecture overview, setup verification, Cortex Code primer)
  - Participant baseline knowledge of medallion architecture, environment, and CLI tools
affects: [02-02-PLAN, 02-03-PLAN]

# Tech tracking
tech-stack:
  added: []
  patterns: [third-person-instructional-voice, copy-paste-ready-commands, time-estimates-per-section]

key-files:
  created: [HANDS_ON_LAB.md]
  modified: []

key-decisions:
  - "Included all 7 MARTS tables with RAW source mapping and key measures in reference table"
  - "Used ASCII art for diagrams (medallion layers and data flow) for maximum portability"
  - "Framed suggested prompts as starting points per locked decision in CONTEXT.md"

patterns-established:
  - "Section structure: title with time estimate, intro explaining why, then step-by-step content"
  - "Verification pattern: command -> expected output -> explanation of what it confirms"
  - "Windows WSL callout as blockquote note at section start"

requirements-completed: [HOL-01, HOL-02, HOL-03]

# Metrics
duration: 2min
completed: 2026-03-06
---

# Phase 02 Plan 01: Foundation Sections Summary

**HANDS_ON_LAB.md with medallion architecture diagram, 7-table MARTS reference, 3-step environment verification, and Cortex Code CLI primer with slash commands and MCP skill setup**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-06T18:58:13Z
- **Completed:** 2026-03-06T19:00:25Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Created HANDS_ON_LAB.md (233 lines) with complete foundation sections covering ~25 min of lab time
- Architecture overview with ASCII medallion diagram, all 7 MARTS tables, Cortex Agent/Semantic View explanation, and end-to-end data flow
- Environment setup verification with 3 copy-paste-ready steps and expected outputs
- Cortex Code primer with slash command reference table, Jira/Confluence MCP installation, and context verification test

## Task Commits

Each task was committed atomically:

1. **Task 1: Write header, architecture overview, and setup verification sections** - `25951b1` (feat)
2. **Task 2: Write Cortex Code primer section with MCP skill setup** - `9df97d4` (feat)

**Plan metadata:** pending (docs: complete foundation sections plan)

## Files Created/Modified
- `HANDS_ON_LAB.md` - Foundation sections of the hands-on lab guide (header, Sections 1-3)

## Decisions Made
- Used ASCII art diagrams instead of Mermaid for maximum portability across rendering environments
- Included all 7 MARTS tables with RAW source mapping to give participants full domain context
- Framed all suggested prompts as "starting points" per the locked decision that variations work
- Referenced AGENTS.md auto-loading to avoid participants needing manual context configuration

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- HANDS_ON_LAB.md foundation is complete and ready for Task 1 content (02-02-PLAN)
- All section numbering and structure established for appending Task 1 and Task 2 sections
- Architecture context and Cortex Code primer provide the baseline knowledge needed for development tasks

---
*Phase: 02-create-the-hands-on-lab-instruction-guide*
*Completed: 2026-03-06*
