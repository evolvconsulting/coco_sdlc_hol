---
status: complete
phase: 05-instructor-claude-skill
source: 05-01-PLAN.md (VALIDATION.md checklist — no SUMMARY.md; skill built interactively)
started: 2026-03-10T00:00:00Z
updated: 2026-03-10T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. SKILL-PARSE — /facilitate invokes without parse errors
expected: Open a Cortex Code session in the project root. Run /facilitate. The skill loads with no error messages or YAML parse failures.
result: pass

### 2. SKILL-LOAD — First response references INSTRUCTOR_GUIDE.md content
expected: The opening response contains actual content drawn from INSTRUCTOR_GUIDE.md (e.g., Section 1 architecture overview material), not a generic greeting.
result: pass

### 3. SKILL-SEQ — Opens with Section 1 only
expected: The first response presents Section 1 content and ends with a readiness prompt. It does NOT dump all 7 sections at once.
result: pass

### 4. SKILL-ADVANCE — "next" produces Section 2
expected: After /facilitate opens on Section 1, typing "next" produces Section 2 content (environment setup verification, ~5 min) — including the snow sql command in a code block and the "Role must be ATTENDEE_ROLE" watch-for.
result: pass

### 5. SKILL-FULLSCRIPT — Watch-fors and callout cues appear
expected: Section output includes watch-for annotations and group callout cues as written in INSTRUCTOR_GUIDE.md — not summarized or omitted.
result: pass

### 6. SKILL-RELAY — Section 4.10 verification steps have no raw SQL
expected: When Section 4 is presented, the 4.10a/b/c steps are phrased as instructor relay prompts ("Ask participants to..." or "Tell participants to confirm..."). No raw SQL that the instructor would execute appears.
result: pass

### 7. SKILL-ADHOC — Ad hoc question answered from AGENTS.md
expected: Asking "What is the clnt_id filter value?" during facilitation returns the answer from AGENTS.md (clnt_id = 'dmcl'). The skill does not say "I don't know". After answering, it notes current section position.
result: pass

### 8. SKILL-JUMP — Jump navigation skips intermediate sections
expected: Saying "go to Section 4" (from Section 1 or 2) jumps directly to Section 4 without reciting Sections 2 or 3.
result: pass

### 9. SKILL-NOSQL — No Snowflake tool calls attempted
expected: Throughout any section, the skill does not attempt to execute SQL or invoke Snowflake tools. All verification is presented as relay prompts only.
result: pass

## Summary

total: 9
passed: 9
issues: 0
pending: 0
skipped: 0

## Gaps

[none yet]
