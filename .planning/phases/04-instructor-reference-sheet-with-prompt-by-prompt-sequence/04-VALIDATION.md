---
phase: 4
slug: instructor-reference-sheet-with-prompt-by-prompt-sequence
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-06
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual review — no automated test framework applies |
| **Config file** | none |
| **Quick run command** | n/a — manual review of affected section vs LAB_INSTRUCTIONS.md |
| **Full suite command** | n/a — full side-by-side review of INSTRUCTOR_GUIDE.md vs LAB_INSTRUCTIONS.md |
| **Estimated runtime** | ~5 minutes |

---

## Sampling Rate

- **After every task commit:** Manual review of the affected section against LAB_INSTRUCTIONS.md
- **After every plan wave:** Full side-by-side comparison of INSTRUCTOR_GUIDE.md vs LAB_INSTRUCTIONS.md
- **Before `/gsd:verify-work`:** Full review must confirm all behaviors in the Per-Task Verification Map
- **Max feedback latency:** ~5 minutes

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 1 | All participant inputs extracted | manual | n/a | ❌ W0 | ⬜ pending |
| 4-01-02 | 01 | 1 | Step numbers match LAB_INSTRUCTIONS.md | manual | n/a | ❌ W0 | ⬜ pending |
| 4-01-03 | 01 | 1 | Timing cues match LAB_INSTRUCTIONS.md | manual | n/a | ❌ W0 | ⬜ pending |
| 4-01-04 | 01 | 1 | EPA-2 / EPA-3 ticket IDs present | manual | `grep -c "EPA-[23]" INSTRUCTOR_GUIDE.md` | ❌ W0 | ⬜ pending |
| 4-01-05 | 01 | 1 | Verification outputs at correct steps | manual | n/a | ❌ W0 | ⬜ pending |
| 4-01-06 | 01 | 1 | No participant-facing explanation prose | manual | n/a | ❌ W0 | ⬜ pending |
| 4-01-07 | 01 | 1 | Conditional/fallback prompts included | manual | n/a | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

None — this phase produces a single document. No test infrastructure is needed.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| All participant inputs extracted | Phase 4 scope | Document authoring — no automated extraction | Side-by-side with LAB_INSTRUCTIONS.md |
| Step numbers match LAB_INSTRUCTIONS.md | Phase 4 scope | Structural check requires human judgment | Verify each section/step header against source |
| Timing cues match LAB_INSTRUCTIONS.md | Phase 4 scope | String match in context of section headers | Check each section timing string |
| EPA-2 / EPA-3 ticket IDs present | Phase 4 scope | Partially automatable via grep | Search INSTRUCTOR_GUIDE.md for "EPA-2" and "EPA-3" |
| Verification outputs at correct steps | Phase 4 scope | Requires judgment on "correct" steps | Check steps 4.10a/b/c/d and 6.5 have expected-output blocks |
| No participant-facing prose | Phase 4 scope | Readability / audience check | Scan for paragraphs not structured as step/callout/code |
| Conditional prompts (fallback) included | Phase 4 scope | Content completeness check | Confirm 4.3 scope expansion, 4.5 retry logic, 4.6 materialization, 6.5 debug are present |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5 minutes
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
