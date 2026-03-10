---
phase: 6
slug: update-instructions-to-include-step-to-fork-the-repository-per-option-a-standard-open-source-model
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-10
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — documentation-only phase |
| **Config file** | none |
| **Quick run command** | manual review |
| **Full suite command** | manual review |
| **Estimated runtime** | ~2 minutes |

---

## Sampling Rate

- **After every task commit:** Manually verify the edited section reads correctly
- **After every plan wave:** Full document review for correctness and consistency
- **Before `/gsd:verify-work`:** All three files reviewed end-to-end

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 6-01-01 | 01 | 1 | Fork step in LAB_INSTRUCTIONS.md | manual | n/a | ✅ | ⬜ pending |
| 6-01-02 | 01 | 1 | README.md updated | manual | n/a | ✅ | ⬜ pending |
| 6-01-03 | 01 | 1 | INSTRUCTOR_GUIDE.md pitfalls updated | manual | n/a | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*None — documentation phase requires no test infrastructure setup.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fork step inserted before clone in LAB_INSTRUCTIONS.md | Phase 6 goal | Documentation change, no automated check | Read Section 2, Step 0 — verify fork sub-step appears before git clone |
| README reflects fork-based workflow | Phase 6 goal | Documentation change | Read README setup section — verify fork mentioned |
| INSTRUCTOR_GUIDE pitfalls include fork-related errors | Phase 6 goal | Documentation change | Read instructor pitfalls — verify 4 fork pitfalls present |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
