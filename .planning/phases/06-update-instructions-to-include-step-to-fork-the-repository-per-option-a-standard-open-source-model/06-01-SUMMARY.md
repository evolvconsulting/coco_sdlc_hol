---
phase: 06-update-instructions-to-include-step-to-fork-the-repository-per-option-a-standard-open-source-model
plan: "01"
subsystem: docs

tags: [git, fork, github, lab-instructions, instructor-guide]

# Dependency graph
requires: []
provides:
  - Fork-then-clone Step 0 in LAB_INSTRUCTIONS.md with sub-steps 0a/0b and "Why fork?" callout
  - Fork-first clone snippet in README.md Prerequisites §5 Git
  - Fork-failure watch-fors in INSTRUCTOR_GUIDE.md Step 0 with git remote set-url fix commands
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Fork-then-clone workflow as the standard participant onboarding pattern for branch-protected repositories

key-files:
  created: []
  modified:
    - LAB_INSTRUCTIONS.md
    - README.md
    - INSTRUCTOR_GUIDE.md

key-decisions:
  - "Fork-then-clone adopted as the sole onboarding path — no direct clone option retained — because branch protection on main makes direct push impossible for non-admins"
  - "Steps 4.11, 6.6, and 6.7 (push and PR steps) left unchanged; they work correctly because origin now points to participant's fork rather than the upstream"
  - "No new prerequisite tools (e.g., gh CLI) introduced — GitHub web UI fork is sufficient"
  - "INSTRUCTOR_GUIDE.md watch-for block expanded with two fork-specific failure patterns and their fix commands rather than a separate troubleshooting section"

patterns-established:
  - "Step 0 pattern: fork on GitHub web UI first (0a), then clone fork URL with <your-username> placeholder (0b)"
  - "Instructor diagnostics pattern: git remote -v to diagnose wrong-remote clone, git remote set-url to fix without re-cloning"

requirements-completed: [HOL-FORK-01, HOL-FORK-02, HOL-FORK-03, HOL-FORK-04, HOL-FORK-05]

# Metrics
duration: ~15min
completed: 2026-03-11
---

# Phase 06 Plan 01: Update Instructions to Fork Repository Summary

**Fork-then-clone workflow introduced across LAB_INSTRUCTIONS.md (0a/0b sub-steps with "Why fork?" callout), README.md (numbered fork-then-clone sequence), and INSTRUCTOR_GUIDE.md (two fork-failure watch-fors with git remote set-url diagnostics)**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-11T00:02:30Z
- **Completed:** 2026-03-11T00:17:00Z
- **Tasks:** 4 (3 auto + 1 checkpoint, human-approved)
- **Files modified:** 3

## Accomplishments

- LAB_INSTRUCTIONS.md Step 0 expanded to sub-steps 0a (fork on GitHub) and 0b (clone fork URL with `<your-username>` placeholder), plus a "Why fork?" callout explaining the branch-protection reason
- README.md Prerequisites §5 Git updated from a placeholder `git clone <repo-url>` to a numbered two-step fork-then-clone sequence with the fork link and username-specific clone URL
- INSTRUCTOR_GUIDE.md Step 0 watch-for block expanded from one item to three: the original skip-step warning plus two fork-specific failure patterns (cloned upstream instead of fork; skipped forking entirely) each with `git remote -v` diagnosis and `git remote set-url` fix

## Task Commits

Each task was committed atomically:

1. **Task 1: Update LAB_INSTRUCTIONS.md Step 0 to fork-then-clone** - `585177c` (feat)
2. **Task 2: Update README.md Prerequisites §5 Git to fork-then-clone** - `22d1179` (feat)
3. **Task 3: Update INSTRUCTOR_GUIDE.md Step 0 with fork-failure diagnostics** - `a457e8d` (feat)
4. **Task 4: Checkpoint — human verification (approved)** - no separate commit (approval recorded in SUMMARY)

## Files Created/Modified

- `LAB_INSTRUCTIONS.md` - Step 0 replaced with fork-then-clone (sub-steps 0a/0b, "Why fork?" callout, `<your-username>` placeholder)
- `README.md` - Prerequisites §5 Git updated with numbered fork-then-clone sequence
- `INSTRUCTOR_GUIDE.md` - Step 0 watch-for block expanded with two fork-failure failure modes and recovery commands

## Decisions Made

- Fork-then-clone adopted as the sole onboarding path — no direct clone option retained — because branch protection on main makes direct push impossible for non-admins.
- Steps 4.11, 6.6, and 6.7 (push and PR steps) left unchanged; they work correctly because `origin` now points to the participant's fork rather than the upstream.
- No new prerequisite tools (e.g., gh CLI) introduced — GitHub web UI fork is sufficient and keeps the prerequisite list stable.
- INSTRUCTOR_GUIDE.md watch-for block expanded with two fork-specific failure patterns and their fix commands rather than creating a separate troubleshooting section.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

All three participant- and instructor-facing documents consistently describe the fork-then-clone workflow. No further doc changes are needed to support the fork model. The project is complete.

---
*Phase: 06-update-instructions-to-include-step-to-fork-the-repository-per-option-a-standard-open-source-model*
*Completed: 2026-03-11*
