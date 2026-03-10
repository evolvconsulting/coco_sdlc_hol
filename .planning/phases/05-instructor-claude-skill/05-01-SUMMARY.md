---
phase: 05-instructor-claude-skill
plan: 01
subsystem: infra
tags: [claude-code, skill, facilitation, instructor-tool]

# Dependency graph
requires:
  - phase: 04-instructor-reference-sheet-with-prompt-by-prompt-sequence
    provides: INSTRUCTOR_GUIDE.md — primary coaching content source for the skill
provides:
  - /facilitate Claude Code skill that delivers INSTRUCTOR_GUIDE.md interactively during live sessions
affects: []

# Tech tracking
tech-stack:
  added: [Claude Code skill file (.claude/skills/facilitate.md)]
  patterns:
    - Runtime file loading (skill reads source files on invocation rather than inlining content)
    - Sequential state machine with explicit instructor-controlled advancement
    - Relay-prompt verification pattern (never raw SQL)

key-files:
  created:
    - .claude/skills/facilitate.md
    - .claude/skills/ (directory)
  modified: []

key-decisions:
  - "Skill reads INSTRUCTOR_GUIDE.md, AGENTS.md, LAB_INSTRUCTIONS.md at runtime — not inlined — so it stays in sync as source files evolve"
  - "Section delivery is instructor-paced: skill waits after each section, never auto-advances"
  - "Verification steps phrased as instructor relay prompts only — no SQL execution"
  - "Ad hoc questions answered from loaded context; 'I don't know' is not acceptable when answer is in loaded files"

patterns-established:
  - "Pattern: Runtime-loaded skill — content lives in source files, skill provides delivery instructions only"
  - "Pattern: Relay-prompt verification — all verification steps phrased as 'Ask participants to...' not raw SQL"

requirements-completed: [SKILL-FILE, DIR-SETUP]

# Metrics
duration: 7min
completed: 2026-03-10
---

# Phase 5 Plan 01: Instructor Claude Skill Summary

**`/facilitate` Claude Code skill that delivers INSTRUCTOR_GUIDE.md interactively — section-by-section, instructor-paced, with relay-prompt verification and ad hoc Q&A from loaded context**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-03-10T23:20:58Z
- **Completed:** 2026-03-10T23:28:00Z
- **Tasks:** 1 of 2 complete (Task 2 is a human-verify checkpoint — awaiting)
- **Files modified:** 1

## Accomplishments

- Created `.claude/skills/` directory structure (did not previously exist in the project)
- Wrote `facilitate.md` skill file with all required behavioral instructions
- Skill passes automated verification: YAML frontmatter, all three file load instructions, state machine rules, relay-prompt constraint, and no-SQL constraint all present

## Task Commits

1. **Task 1: Create .claude/skills/ directories and write the facilitate skill file** - `19e4b18` (feat)

## Files Created/Modified

- `.claude/skills/facilitate.md` — The `/facilitate` skill definition: YAML frontmatter, on-invocation file loading, sequential state machine, section delivery rules, ad hoc Q&A routing, and hard constraints

## Decisions Made

- Skill kept to ~100 lines by not inlining any content from INSTRUCTOR_GUIDE.md — content stays in the source file, skill only instructs Claude how to deliver it
- Section 7 (Wrap-up) is discussion-only and not in INSTRUCTOR_GUIDE.md; skill mirrors this by offering a brief wrap-up note when Section 6 completes rather than tracking a formal Section 7

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Skill file written and committed. Human verification (Task 2) required to confirm all 9 VALIDATION.md behaviors before plan is fully complete.
- Once Task 2 is approved, run `node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" state advance-plan` to update STATE.md.

---
*Phase: 05-instructor-claude-skill*
*Completed: 2026-03-10*
