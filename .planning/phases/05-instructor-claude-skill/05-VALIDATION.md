---
phase: 5
slug: instructor-claude-skill
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-08
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual review — no automated test framework |
| **Config file** | none |
| **Quick run command** | Invoke `/facilitate` in Claude Code and verify behavior |
| **Full suite command** | n/a — all verifications are manual |
| **Estimated runtime** | ~5 minutes manual review |

---

## Sampling Rate

- **After every task commit:** Verify file was written correctly (syntax check via Read tool)
- **After every plan wave:** Manual smoke test: invoke `/facilitate` and confirm no parse errors
- **Before `/gsd:verify-work`:** Full manual checklist must be complete
- **Max feedback latency:** ~5 minutes (manual review)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 5-01-01 | 01 | 0 | DIR-SETUP | manual | n/a — check `.claude/skills/` exists | ❌ W0 | ⬜ pending |
| 5-01-02 | 01 | 1 | SKILL-FILE | manual | n/a — invoke `/facilitate` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.claude/` directory — must be created before skill file can be written
- [ ] `.claude/skills/` directory — must be created before skill file can be written

*No test framework installation needed — pure markdown deliverable.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Skill file parseable by Claude Code | SKILL-PARSE | No automated parser for Claude Code skill files | Invoke `/facilitate` — confirm no parse errors |
| Files loaded on invocation | SKILL-LOAD | Runtime behavior, not static analysis | Check first response references INSTRUCTOR_GUIDE.md content |
| Opens with Section 1, waits | SKILL-SEQ | Conversational behavior | Verify skill does not dump all sections on first response |
| Advances only on instructor input | SKILL-ADVANCE | Conversational behavior | Say "next" and verify Section 2 appears |
| Full coaching script per section | SKILL-FULLSCRIPT | Content completeness | Verify watch-fors and callout cues appear in section output |
| Verification steps phrased as relay prompts | SKILL-RELAY | No SQL execution | Confirm no SQL in Section 4.10a/b/c/d output |
| Ad hoc questions answered from context | SKILL-ADHOC | Contextual reasoning | Ask "what is the clnt_id filter?" and confirm AGENTS.md value returned |
| Jump navigation works | SKILL-JUMP | Conversational behavior | Say "go to Section 6" and verify direct jump |
| No SQL execution attempted | SKILL-NOSQL | Safety constraint | Confirm no Snowflake tool calls during any section |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5 minutes
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
