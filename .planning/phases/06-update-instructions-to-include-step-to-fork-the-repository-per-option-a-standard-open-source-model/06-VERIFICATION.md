---
phase: 06-update-instructions-to-include-step-to-fork-the-repository-per-option-a-standard-open-source-model
verified: 2026-03-11T00:00:00Z
status: passed
score: 6/6 must-haves verified
re_verification: false
---

# Phase 6: Update Instructions to Fork Repository — Verification Report

**Phase Goal:** Update the hands-on lab documentation so participants fork the public repo before cloning, following the standard open-source model (fork → clone fork → work → PR).
**Verified:** 2026-03-11
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | LAB_INSTRUCTIONS.md Section 2, Step 0 requires participants to fork on GitHub before cloning | VERIFIED | Line 99: `### Step 0: Fork and Clone the Lab Repository`; sub-steps 0a (lines 101-105) and 0b (lines 107-118) both present |
| 2  | Step 0 clone URL uses `<your-username>` placeholder, not the upstream evolvconsulting URL | VERIFIED | Line 110: `git clone https://github.com/<your-username>/coco_sdlc_hol.git`; grep for `git clone.*evolvconsulting` in LAB_INSTRUCTIONS.md returns no results |
| 3  | README.md Prerequisites §5 Git describes fork-then-clone instead of direct clone | VERIFIED | Line 109: "Fork and clone the lab repository:" with numbered sequence; line 115: `<your-username>/coco_sdlc_hol.git` |
| 4  | INSTRUCTOR_GUIDE.md Step 0 watch-for block includes two fork-related failure patterns with diagnostic and fix commands | VERIFIED | Line 29: upstream-clone failure with `git remote set-url` fix; line 30: skipped-fork failure with same fix; `git remote set-url` present |
| 5  | Steps 4.11, 6.6 (push to origin) and 6.7 (PR creation) are unchanged and remain correct under fork model | VERIFIED | Step 4.11 (line 417-423) uses "push to origin"; Step 6.6 (line 585-589) uses "push to origin"; Step 6.7 (line 591-597) creates PR — all reference `origin`, which now correctly points to participant's fork |
| 6  | No new prerequisite tools (e.g., gh CLI) are introduced | VERIFIED | README Prerequisites lists 5 tools (Snowflake Account, Snow CLI, Cortex Code CLI, Node.js 20.x, Git); no gh CLI or new tool added; fork is accomplished via GitHub browser UI |

**Score:** 6/6 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `LAB_INSTRUCTIONS.md` | Fork-then-clone Step 0 with 0a/0b sub-steps, `<your-username>` placeholder, and "Why fork?" callout | VERIFIED | Contains "Fork and Clone", "0a. Fork", "0b. Clone YOUR fork", `<your-username>`, "Why fork?" callout (line 116) |
| `README.md` | Fork-first clone snippet in Prerequisites §5 Git | VERIFIED | Contains "Fork and clone the lab repository:" numbered sequence and `<your-username>/coco_sdlc_hol` |
| `INSTRUCTOR_GUIDE.md` | Fork-failure watch-fors in Step 0 block | VERIFIED | Contains `git remote set-url origin` at line 29, three watch-for lines total |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| LAB_INSTRUCTIONS.md Step 0b | clone URL | participant substitutes `<your-username>` | VERIFIED | Line 110 shows `https://github.com/<your-username>/coco_sdlc_hol.git`; line 114 has explicit "Replace `<your-username>` with your GitHub username." instruction |
| INSTRUCTOR_GUIDE.md Step 0 | LAB_INSTRUCTIONS.md Step 0 | step numbers mirror exactly — Step 0 content expands, number stays 0 | VERIFIED | Both documents use "Step 0" as the identifier; INSTRUCTOR_GUIDE line 119 references "Step 0" as the clone step when describing Step 1 context; no step number drift |

---

### Requirements Coverage

Requirements are defined in the RESEARCH.md validation map for this phase. No separate REQUIREMENTS.md file exists for this project's documentation phase.

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| HOL-FORK-01 | 06-01-PLAN.md | Step 0 in LAB_INSTRUCTIONS.md describes fork-then-clone | SATISFIED | Step 0 heading changed to "Fork and Clone"; sub-steps 0a and 0b added; `<your-username>` in clone URL |
| HOL-FORK-02 | 06-01-PLAN.md | README.md Getting Started clone snippet updated | SATISFIED | §5 Git updated from placeholder `git clone <repo-url>` to numbered fork-then-clone sequence with `<your-username>` |
| HOL-FORK-03 | 06-01-PLAN.md | INSTRUCTOR_GUIDE.md Step 0 watch-for includes fork failure pattern | SATISFIED | Two fork-specific watch-fors added: upstream-clone failure and skipped-fork failure, both with `git remote set-url` fix |
| HOL-FORK-04 | 06-01-PLAN.md | All push steps (4.11, 6.6) and PR step (6.7) remain functionally correct under fork model | SATISFIED | Steps 4.11, 6.6, 6.7 verified unchanged; all push steps use "origin" which correctly points to participant's fork |
| HOL-FORK-05 | 06-01-PLAN.md | No new prerequisite tools added beyond existing list | SATISFIED | README Prerequisites contains exactly 5 tools (same as before phase); fork is GitHub web UI action only |

No orphaned requirements: ROADMAP.md lists exactly HOL-FORK-01 through HOL-FORK-05 for Phase 6, all claimed by 06-01-PLAN.md.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | None found |

Scanned LAB_INSTRUCTIONS.md, README.md, and INSTRUCTOR_GUIDE.md for TODO/FIXME, placeholder text, empty implementations, and incomplete stubs. None found in the modified sections.

---

### Human Verification Required

#### 1. Fork flow readability — LAB_INSTRUCTIONS.md Step 0

**Test:** Read Step 0 (lines 99-118) as a first-time participant. Follow the 0a and 0b sequence mentally.
**Expected:** The two-step sequence (fork on GitHub, then clone your fork) is unambiguous. The `<your-username>` placeholder is obvious enough that participants replace it rather than copy it literally.
**Why human:** Instruction clarity and likelihood of participant error cannot be assessed programmatically.

#### 2. PR target behavior — Step 6.7

**Test:** Confirm that when Cortex Code creates a PR from a participant fork branch, GitHub defaults to targeting `evolvconsulting/coco_sdlc_hol:main` rather than the participant's own fork main.
**Expected:** GitHub automatically suggests the upstream repo as the PR target when creating a PR from a fork. The PR prompt in Step 6.7 does not need additional guidance.
**Why human:** Requires a live GitHub fork environment to confirm the default PR target behavior.

---

### Commit Verification

All three task commits documented in SUMMARY.md were verified to exist in git history:

| Commit | Task | Message |
|--------|------|---------|
| `585177c` | Task 1 | feat(06-01): update LAB_INSTRUCTIONS.md Step 0 to fork-then-clone |
| `22d1179` | Task 2 | feat(06-01): update README.md Prerequisites §5 Git to fork-then-clone |
| `a457e8d` | Task 3 | feat(06-01): update INSTRUCTOR_GUIDE.md Step 0 with fork-failure diagnostics |

---

### Summary

All six observable truths are verified. All three artifacts contain the required content. Both key links are wired correctly. All five requirement IDs are satisfied. No anti-patterns were found. The two human verification items are informational — they do not block goal achievement and were already gate-approved via the checkpoint task in the plan.

The phase goal is achieved: participants following LAB_INSTRUCTIONS.md Section 2 Step 0 will fork the repository on GitHub before cloning, use a fork-specific clone URL, and understand why the fork is required. README.md Prerequisites and INSTRUCTOR_GUIDE.md are consistent with this workflow.

---

_Verified: 2026-03-11_
_Verifier: Claude (gsd-verifier)_
