---
phase: 04-instructor-reference-sheet-with-prompt-by-prompt-sequence
verified: 2026-03-07T00:00:00Z
status: human_needed
score: 9/10 must-haves verified
re_verification: false
human_verification:
  - test: "Side-by-side comparison of INSTRUCTOR_GUIDE.md against LAB_INSTRUCTIONS.md participant input sequence"
    expected: "Every prompt a participant types in LAB_INSTRUCTIONS.md appears verbatim in INSTRUCTOR_GUIDE.md at the matching step number"
    why_human: "Automated checks confirm step labels and code blocks exist but cannot verify verbatim accuracy of ~30 individual prompts against the source document"
  - test: "Confirm expected-output blocks outside verification steps are appropriate"
    expected: "Steps 1, 2, 3, and 3.5 include expected output blocks — verify this is acceptable given these are environment-setup confirmation steps"
    why_human: "Must_have truth states expected outputs only at 4.10a/b/c/d and 6.5, but PLAN task body explicitly instructed outputs at Steps 1/2/3/3.5 too. Human must decide if the must_have should be read as written or as implemented"
---

# Phase 4: Instructor Reference Sheet Verification Report

**Phase Goal:** Produce INSTRUCTOR_GUIDE.md at the repo root — a standalone instructor-facing live reference sheet listing every participant-typed input in sequence across the full lab, organized to match LAB_INSTRUCTIONS.md section/step structure, with timing cues, Watch for: callouts at sticking points, and Call out to group: notes at key transitions.

**Verified:** 2026-03-07
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Every participant-typed input from LAB_INSTRUCTIONS.md appears in sequence | ? UNCERTAIN | All step labels and code blocks present (Steps 1-3, 3.3-3.5, 4.1-4.12 with sub-steps, 5, 6.1-6.7); verbatim accuracy requires human cross-check |
| 2 | Step numbers match LAB_INSTRUCTIONS.md exactly | VERIFIED | Confirmed: Steps 1/2/3 match source; 3.3, 3.4, 3.5, 4.1-4.12 including 4.10a/b/c/d, 6.1-6.7 all present and labeled correctly |
| 3 | Timing cues at each section header match LAB_INSTRUCTIONS.md estimates | VERIFIED | All 6 section headers include timing: Section 1 (~10 min), Section 2 (~5 min), Section 3 (~10 min), Section 4 (~30 min), Section 5 (~2 min), Section 6 (~20 min) |
| 4 | Watch for: callouts appear at all 12 identified sticking-point steps | VERIFIED | 13 Watch for: callouts found (exceeds required 12): Steps 1, 2, 3, 3.5, 4.3, 4.6, 4.10a, 4.10b, 4.10c, Section 5 (/new), 6.3 (×2), 6.5 |
| 5 | Call out to group: notes appear at all 6 identified key transitions | VERIFIED | Exactly 6 Call out to group: notes: Steps 4.3, 4.10b, 4.10d, Section 5, 6.5, 6.7 |
| 6 | Conditional/fallback prompts included for steps 4.3, 4.5, 4.6 (materialization), 6.5 (debug) | VERIFIED | 4.3: [If plan misses intermediate model or agent file] present; 4.5: [If Cortex Code's plan doesn't include retry detection SQL] present; 4.6: expressed as Watch for: callout (per task body — no participant input exists at this step); 6.5: [If KPI card shows 0] present |
| 7 | Expected outputs present only for verification steps: 4.10a, 4.10b, 4.10c, 4.10d, 6.5 | ? UNCERTAIN | Expected output blocks appear at Steps 1, 2, 3, and 3.5 in addition to 4.10a/b/c/d and 6.5. Task body explicitly instructed these for setup confirmation steps. Human must confirm whether this is acceptable. |
| 8 | EPA-2 and EPA-3 used as ticket IDs (not placeholders) | VERIFIED | EPA-2 at Step 4.1 (1 occurrence); EPA-3 at Steps 6.1 and 6.3 (2 occurrences). Both are live IDs, not placeholder text. |
| 9 | No participant-facing explanatory prose — every non-code line is a step label or callout | VERIFIED | grep for bare prose paragraphs returned zero results. All non-code content is step labels (**Step X.Y — label**), callouts (> Watch for: / > Call out to group:), or bracketed fallback labels |
| 10 | Quick-reference troubleshooting table present at end | VERIFIED | Table present at end of document; 7 data rows matching issues: `cortex: command not found`, dynamic table stale data, semantic view metric missing, KPI card shows 0, Cortex Agent generic answer, /plan after /new, verification query empty |

**Score:** 9/10 truths verified (8 confirmed, 2 require human judgment)

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `INSTRUCTOR_GUIDE.md` | Instructor-facing live-use reference sheet containing Sections 1-6 | VERIFIED | File exists at repo root; 368 lines; all 6 sections present with step-entry format throughout |

**Artifact checks:**

- Exists: Yes (`INSTRUCTOR_GUIDE.md` at repo root)
- Substantive: Yes (368 lines; full content from Section 1 through troubleshooting table)
- Wired: N/A — this is a documentation artifact, not code; no import/usage wiring applies

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| INSTRUCTOR_GUIDE.md step numbers | LAB_INSTRUCTIONS.md step numbers | exact match — no renumbering or collapsing | VERIFIED | `grep -n "Step 4\.10"` returns 6 matches (4.10a/b/c/d sub-steps + 2 troubleshooting table references); sub-steps are not collapsed. Section 2 uses Step 1/2/3 which matches LAB_INSTRUCTIONS.md exactly (not 2.1/2.2/2.3 as the PLAN frontmatter stated — source uses Step 1/2/3 without section prefix). |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| CONTEXT-04 | 04-01-PLAN.md | Produce instructor-facing reference sheet with all participant inputs, timing cues, Watch for:/Call out to group: callouts — defined in 04-CONTEXT.md phase boundary | SATISFIED | INSTRUCTOR_GUIDE.md exists with complete content. All must_have truths except two with human-judgment items are verified. CONTEXT-04 is referenced in ROADMAP.md Phase 4 and in 04-01-PLAN.md `requirements` field. SUMMARY.md records `requirements-completed: [CONTEXT-04]`. |

**Notes on CONTEXT-04:** No separate REQUIREMENTS.md file exists in this project. CONTEXT-04 is defined by the phase boundary in 04-CONTEXT.md and referenced in ROADMAP.md. The requirement is fully satisfied by INSTRUCTOR_GUIDE.md's existence and content.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | No TODOs, FIXMEs, placeholders, empty return statements, or stub patterns found | — | — |

**Scan results:**
- `grep -in "TODO|FIXME|PLACEHOLDER|coming soon"` — zero matches
- No empty implementations (not applicable — document artifact)
- No console.log-only stubs (not applicable)
- Commits verified: `1781c56`, `5feadcb`, `5998f79` all exist in git log

---

### Human Verification Required

#### 1. Verbatim Prompt Accuracy

**Test:** Open INSTRUCTOR_GUIDE.md and LAB_INSTRUCTIONS.md side-by-side. For each step in the guide, confirm the code block content matches the participant input in LAB_INSTRUCTIONS.md verbatim.

**Expected:** Every prompt a participant types in LAB_INSTRUCTIONS.md appears unchanged in INSTRUCTOR_GUIDE.md at the matching step number. Pay particular attention to long prompts at Steps 4.3, 4.10a, 4.10b, 4.10c, 4.10d, 6.3.

**Why human:** Automated checks confirm code blocks exist at every step but cannot compare their text contents against the source document.

#### 2. Expected Outputs at Setup Steps

**Test:** Review the expected output blocks at Steps 1, 2, 3, and 3.5 (environment setup and CLI verification steps in Sections 2 and 3).

**Expected:** Confirm that including expected outputs at these setup confirmation steps is appropriate for instructor use (instructors need to know what a successful run looks like at setup verification points).

**Why human:** The must_have truth states "Expected outputs present only for verification steps: 4.10a, 4.10b, 4.10c, 4.10d, 6.5" but the PLAN's task body explicitly instructed outputs at these setup steps too. The task body takes precedence over the must_have in this case, but a human should confirm the output is appropriate.

---

### Gaps Summary

No blocking gaps found. The document is complete, substantive, and correctly structured.

Two items require human judgment before final approval:

1. **Verbatim accuracy** — The guide contains ~30 participant-typed prompts. Automated verification confirms structure (step labels, code blocks, callout placement) but not content fidelity against LAB_INSTRUCTIONS.md. This is the critical check for live-use accuracy.

2. **Expected outputs at setup steps** — Steps 1, 2, 3, and 3.5 include expected output blocks. The PLAN task body explicitly called for these; the must_have truth written in PLAN frontmatter did not. This is a minor internal inconsistency that a human should confirm is acceptable.

All 10 automated verifications from the PLAN's `<verification>` section pass:
- `test -f INSTRUCTOR_GUIDE.md` — PASS
- `grep -c "EPA-2" INSTRUCTOR_GUIDE.md` returns 1 — PASS (threshold: 1+)
- `grep -c "EPA-3" INSTRUCTOR_GUIDE.md` returns 2 — PASS (threshold: 1+)
- `grep -c "Watch for:" INSTRUCTOR_GUIDE.md` returns 13 — PASS (threshold: 10+)
- `grep -c "Call out to group:" INSTRUCTOR_GUIDE.md` returns 6 — PASS (threshold: 5+)
- `grep -c "Step 4.10" INSTRUCTOR_GUIDE.md` returns 6 — PASS (threshold: 4+)

---

_Verified: 2026-03-07_
_Verifier: Claude (gsd-verifier)_
