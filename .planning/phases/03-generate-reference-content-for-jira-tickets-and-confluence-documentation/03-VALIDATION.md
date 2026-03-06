---
phase: 3
slug: generate-reference-content-for-jira-tickets-and-confluence-documentation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-06
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual validation (content files + API response codes) |
| **Config file** | none |
| **Quick run command** | `cat docs/jira/*.wiki docs/confluence/*.wiki` |
| **Full suite command** | API creation script with HTTP response code verification |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Visual review of .wiki file content
- **After every plan wave:** Run API creation, verify HTTP 2xx responses
- **Before `/gsd:verify-work`:** All Jira issues and Confluence page exist with correct content
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | CONTENT-01 | manual | Visual inspection of docs/jira/*.wiki | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | CONTENT-02 | manual | Visual inspection of docs/confluence/*.wiki | ❌ W0 | ⬜ pending |
| 03-02-01 | 02 | 2 | API-01 | smoke | curl GET /rest/api/3/issue/EPA-XX | ❌ W0 | ⬜ pending |
| 03-02-02 | 02 | 2 | API-02 | smoke | curl GET /rest/api/3/issue/EPA-XX?fields=parent | ❌ W0 | ⬜ pending |
| 03-02-03 | 02 | 2 | API-03 | smoke | curl GET Confluence page by title | ❌ W0 | ⬜ pending |
| 03-02-04 | 02 | 2 | API-04 | manual | Search page content for "retry" | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `docs/jira/` directory — does not exist yet
- [ ] `docs/confluence/` directory — does not exist yet
- [ ] API creation script (bash) — does not exist yet

*Wave 0 creates the directory structure and script scaffolding.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Wiki markup is valid Jira syntax | CONTENT-01 | No local parser available | Review .wiki files for correct h2., *bold*, table syntax |
| Wiki markup is valid Confluence syntax | CONTENT-02 | No local parser available | Review .wiki file for correct headings, tables, panels |
| Data dictionary omits retry_success_rate | API-04 | Content correctness check | Search Confluence page for "retry" — should not appear |
| Ticket content aligns with HANDS_ON_LAB.md | CONTENT-01 | Semantic alignment | Compare ticket AC with lab guide task descriptions |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
