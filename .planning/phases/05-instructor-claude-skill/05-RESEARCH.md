# Phase 5: Instructor Claude Skill - Research

**Researched:** 2026-03-08
**Domain:** Claude Code skill authoring — interactive facilitation assistant
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Skill purpose and mode**
- The skill is a **sequential guide** — it leads the instructor through the lab flow step by step, not a lookup or Q&A tool
- Primary use: live facilitation during the ~90-minute session
- Instructor starts the skill and it walks them forward through each section in order

**Invocation**
- Single skill: `/facilitate`
- One all-purpose command — no separate skills for navigation, troubleshooting, or callouts
- Skill file lives in `.claude/skills/facilitate.md`

**Return format at each step**
- **Full coaching script** per step: what to say/present, expected participant outputs, watch-fors, group callout cues, and fallback prompts if a participant is stuck
- Hints for self-verification (brief cues the instructor can relay to participants) — not SQL the instructor executes

**Content strategy**
- Skill reads `INSTRUCTOR_GUIDE.md` at runtime (not inlined) — stays in sync as guide evolves
- Also loads `AGENTS.md` (Snowflake schema/business rules context) and `LAB_INSTRUCTIONS.md` (participant-facing steps)
- When questions fall outside INSTRUCTOR_GUIDE content, Claude reasons from the loaded context (AGENTS.md + codebase) rather than deferring

**Live data / SQL**
- Guidance-only — no SQL execution against Snowflake
- Each participant has their own isolated Snowflake environment not accessible to the instructor
- Verification prompts in the skill are brief cues the instructor passes to participants so they self-verify (e.g., "Ask participants to run DESCRIBE SEMANTIC VIEW and confirm RETRY_SUCCESS_RATE appears")

**Participant tracking**
- No roster, no per-participant state
- Skill tracks the instructor's position in the lab flow (which section/step they're on), not individual participant progress
- Instructor triage (multiple stuck participants) is handled by instructor judgment, not the skill

### Claude's Discretion
- Exact skill prompt structure and section chunking
- How the skill signals "move to next step" vs waits for instructor input
- Tone of coaching script content (mirroring INSTRUCTOR_GUIDE style)

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within phase scope

</user_constraints>

---

## Summary

This phase produces a single markdown file: `.claude/skills/facilitate.md`. It is a Claude Code skill authoring task — the output is a skill prompt document that tells Claude how to behave when the instructor invokes `/facilitate` during live lab delivery.

The skill is unusual among skill files: it is not a workflow executor (no bash commands, no API calls, no file writes). Its entire output is conversational — coaching script presented step by step to an instructor in real time. The implementation challenge is prompt engineering, not software engineering: the skill must define a clear sequential state machine (which section/step we are on), establish how Claude responds at each step (full script with watch-fors and callout cues), and handle the instructor advancing through the session naturally.

The content source is already complete: `INSTRUCTOR_GUIDE.md` (350+ lines, 7 sections, all step-by-step prompts, watch-fors, callouts, and troubleshooting) was authored in Phase 4 and is the authoritative coaching script. The skill's job is to deliver that content interactively — surfacing one section at a time as the instructor advances — rather than replacing or duplicating it.

**Primary recommendation:** Write a skill that (1) reads `INSTRUCTOR_GUIDE.md`, `AGENTS.md`, and `LAB_INSTRUCTIONS.md` on invocation, (2) opens with Section 1 and waits, (3) advances to the next section when the instructor says "next" or equivalent, (4) delivers the full coaching script for each section including all watch-fors and fallback prompts, and (5) answers ad hoc questions from context rather than deferring.

---

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Claude Code skill file | Markdown | Defines `/facilitate` slash command behavior | Native Claude Code mechanism; no tooling needed |
| INSTRUCTOR_GUIDE.md | Current (Phase 4 output) | Primary coaching content source | Single source of truth; already authored and approved |
| AGENTS.md | Current | Snowflake schema, business rules, key paths | Needed for ad hoc data questions during facilitation |
| LAB_INSTRUCTIONS.md | Current (625 lines) | Participant-facing steps | Needed so skill knows what participants are seeing |

### Supporting

| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| `.claude/` directory | Created by this phase | Skill storage location | Required parent directory for skill file |
| `.claude/skills/` directory | Created by this phase | Skill file subdirectory | Required by Claude Code skill loading convention |

### Installation

```bash
mkdir -p .claude/skills
# Then write .claude/skills/facilitate.md
```

No npm packages. No dependencies. Pure markdown.

---

## Architecture Patterns

### Skill File Structure

Claude Code skill files are markdown documents with a YAML frontmatter block, followed by the operational instructions. The frontmatter `name` and `description` fields control how the skill appears and when it auto-triggers.

```
.claude/
└── skills/
    └── facilitate.md       # The /facilitate skill
```

### Pattern 1: YAML Frontmatter for Skill Registration

**What:** A YAML block at the top of the skill file names the skill and provides the description that Claude uses to decide when to invoke it.

**When to use:** Every skill file requires this block.

**Example (from existing skills in ~/.claude/skills/):**
```yaml
---
name: facilitate
description: |
  Live facilitation assistant for the COCO SDLC HOL. Use this skill whenever
  the instructor invokes /facilitate or asks to start, continue, or advance
  the lab session. Guides the instructor step-by-step through each section
  of the ~90-minute hands-on lab with full coaching scripts, watch-fors,
  callout cues, and fallback prompts.
---
```

### Pattern 2: Explicit File Loading Instructions

**What:** The skill instructs Claude to read specific files at invocation time, rather than inlining content.

**When to use:** When content is maintained externally (as INSTRUCTOR_GUIDE.md is) or is large enough that inlining would be impractical.

**Example pattern:**
```markdown
## On Invocation

Read the following files before responding:
- `INSTRUCTOR_GUIDE.md` — primary coaching script (sections 1–7, all watch-fors)
- `AGENTS.md` — Snowflake schema, business rules, and key paths
- `LAB_INSTRUCTIONS.md` — participant-facing guide (so you know what participants are seeing)
```

**Why this matters:** The "reads at runtime" approach means the skill stays in sync automatically if INSTRUCTOR_GUIDE.md is ever updated. Inlining content into the skill file would create drift.

### Pattern 3: Sequential State Machine with Explicit Advancement

**What:** The skill establishes a starting position (Section 1) and defines how Claude advances through sections — only when the instructor explicitly requests the next step.

**When to use:** Interactive sequential guides where the user controls the pace.

**The key design decision:** Claude should NOT automatically chain through all sections. Each section is a discrete delivery unit. The instructor advances by saying "next", "continue", "go to Section 4", or equivalent natural language.

**Example pattern:**
```markdown
## Session Flow

When invoked, present Section 1 content and wait. Do not advance automatically.

The instructor advances by saying:
- "next" / "continue" / "next section"
- "move on" / "let's go" / "ready"
- A section name or number: "Section 4", "Task 1"
- Any natural language indicating readiness to proceed

When advancing, present the FULL coaching content for that section from
INSTRUCTOR_GUIDE.md — do not summarize or abbreviate.
```

### Pattern 4: Full-Script Delivery Per Section

**What:** When presenting a section, deliver everything the instructor needs — not a summary, not a pointer to the file. The full coaching script including watch-fors and callout cues.

**When to use:** Every section presentation.

**Rationale:** The instructor is in front of a room. They cannot read the source file while facilitating. The skill must surface the complete coaching content so the instructor can act without switching contexts.

**What "full script" means per section:**
- What to say/present to the room
- The exact participant prompts (for instructor to relay or project)
- Expected participant outputs for each step
- Watch-for callouts at steps where participants commonly get stuck
- Group callout cues at key demo transitions
- Fallback prompts if participants are stuck (conditional prompts)
- Verification hints phrased as instructor relay prompts ("Ask participants to confirm...")

### Pattern 5: Ad Hoc Question Handling

**What:** When the instructor asks a question not covered by the current section, Claude answers from the loaded context (AGENTS.md + INSTRUCTOR_GUIDE.md + LAB_INSTRUCTIONS.md) rather than deferring.

**When to use:** Any time instructor asks a data question, schema question, or "what if" scenario during facilitation.

**Locked decision from CONTEXT.md:** "When questions fall outside INSTRUCTOR_GUIDE content, Claude reasons from the loaded context (AGENTS.md + codebase) rather than deferring."

**Example skill instruction:**
```markdown
## Ad Hoc Questions

During facilitation, instructors may ask questions not covered in the current
section. Answer from the loaded context:

- Data/schema questions → reason from AGENTS.md
- Participant-step questions → reason from LAB_INSTRUCTIONS.md
- Troubleshooting questions → check INSTRUCTOR_GUIDE.md troubleshooting table first

Never say "I don't know" when the answer can be derived from loaded files.
```

### Pattern 6: Verification Hints as Relay Prompts

**What:** Verification steps are phrased as instructor relay prompts, not as SQL or commands the instructor executes.

**When to use:** All verification-heavy steps (Section 4: 4.10a/b/c/d).

**Example format:**
```
Verification hint: "Ask participants to run DESCRIBE SEMANTIC VIEW
COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS and confirm RETRY_SUCCESS_RATE
appears in the metrics list."
```

**NOT:**
```sql
DESCRIBE SEMANTIC VIEW COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS;
```

### Anti-Patterns to Avoid

- **Auto-advancing:** Do not chain sections without waiting for instructor input. The instructor controls the pace.
- **Summarizing INSTRUCTOR_GUIDE.md:** The skill should surface the full coaching script per section, not a compressed summary.
- **SQL execution:** The skill never issues SQL against Snowflake. No Snowflake tools are used.
- **Participant tracking:** The skill does not maintain per-participant state. It tracks the instructor's position only.
- **Deferring on ad hoc questions:** "I don't have information about that" is not acceptable when the answer is in AGENTS.md or LAB_INSTRUCTIONS.md.

---

## Skill Content Map

The skill must cover all 7 sections from INSTRUCTOR_GUIDE.md:

| Section | Duration | Type | Participant Inputs |
|---------|----------|------|-------------------|
| Section 1: Architecture Overview | ~10 min | Instructor-led | None |
| Section 2: Environment Setup Verification | ~5 min | Guided | 3 bash commands + verification outputs |
| Section 3: Cortex Code Primer | ~10 min | Guided | MCP setup + quick test |
| Section 4: Task 1 — Add Retry Success Rate | ~30 min | Hands-on | 15+ prompts, 4 verification steps |
| Section 5: Context Switch | ~2 min | Procedural | /new command |
| Section 6: Task 2 — Add KPI Card | ~20 min | Hands-on | 8+ prompts, 1 verification step |
| Section 7: Wrap-up (INSTRUCTOR_GUIDE omits this) | ~5 min | Discussion | None |

**Note:** INSTRUCTOR_GUIDE.md already omits Section 7 (no participant inputs). The skill mirrors this — Section 7 is discussion-only and not tracked.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Coaching script content | Write new facilitation scripts | Read INSTRUCTOR_GUIDE.md at runtime | INSTRUCTOR_GUIDE.md is human-approved and validated against the actual lab |
| Section content | Inline step text into skill file | Reference INSTRUCTOR_GUIDE.md sections by name | Prevents drift when guide is updated |
| Verification SQL | Write SQL for the instructor to run | Relay hints phrased as participant self-checks | Instructor cannot access participant Snowflake environments |
| Session state | Build complex state tracking | Track current section in conversational context | Claude's conversation context is sufficient for position tracking |
| Troubleshooting lookup | Build a search index | Read INSTRUCTOR_GUIDE.md troubleshooting table | The 7-row table in INSTRUCTOR_GUIDE.md covers all known failure modes |

---

## Common Pitfalls

### Pitfall 1: Skill File Inlines Content Instead of Reading Files

**What goes wrong:** The skill file contains a copy of all INSTRUCTOR_GUIDE.md content directly in its body, rather than instructing Claude to read the file.

**Why it happens:** Feels more reliable to have content in one place.

**How to avoid:** The `## On Invocation` section must explicitly instruct Claude to read the three source files. Content stays in INSTRUCTOR_GUIDE.md.

**Warning signs:** Skill file exceeds ~100 lines with actual coaching content inside it.

### Pitfall 2: Skill Advances Sections Automatically

**What goes wrong:** Claude presents Section 1 content and then immediately continues to Section 2 without waiting.

**Why it happens:** Claude's default behavior is to be helpful and thorough — it may treat sequential sections as a list to complete.

**How to avoid:** The skill must explicitly state "wait for the instructor to indicate readiness before presenting the next section." Provide clear advancement trigger examples.

**Warning signs:** A test invocation dumps all 7 sections at once.

### Pitfall 3: Watch-Fors and Fallback Prompts Omitted

**What goes wrong:** Each section delivery only shows participant prompts, omitting watch-fors and fallback prompts from INSTRUCTOR_GUIDE.md.

**Why it happens:** Watch-fors and fallbacks read as "edge case" content that can be skipped for brevity.

**How to avoid:** Explicitly instruct the skill to include ALL coaching annotations — not just the participant prompt sequence. The watch-fors are the most instructor-critical content.

**Warning signs:** Section output shows only code blocks with no "> Watch for:" or "> Call out to group:" annotations.

### Pitfall 4: Skill Tries to Execute SQL

**What goes wrong:** Claude attempts to execute verification SQL against Snowflake when presenting a verification step.

**Why it happens:** The AGENTS.md Snowflake connection config is loaded — Claude may attempt to use it.

**How to avoid:** Skill must explicitly state: "Do not execute any SQL or Snowflake commands. All verification is done by participants in their own environments. Present verification steps as relay prompts only."

**Warning signs:** Skill response includes a SQL result set instead of a coaching script.

### Pitfall 5: .claude/ Directory Not Created

**What goes wrong:** The skill file is written to `.claude/skills/facilitate.md` but the `.claude/` and `.claude/skills/` directories do not yet exist.

**Why it happens:** Neither directory exists in the repo before this phase (confirmed in CONTEXT.md: "No existing `.claude/` or `.agents/` directories — this phase creates both").

**How to avoid:** The plan must include an explicit step to create both directories before writing the skill file.

**Warning signs:** `Write` tool fails with "directory not found."

---

## Code Examples

### Minimal Skill File Structure

The skill file's required skeleton based on observed patterns from `~/.claude/skills/`:

```markdown
---
name: facilitate
description: |
  Live facilitation assistant for the COCO SDLC HOL. Guides the instructor
  step-by-step through each section of the ~90-minute lab with full coaching
  scripts, watch-fors, and fallback prompts.

  Use when: instructor invokes /facilitate, says "start the lab", "next section",
  "continue", or asks facilitation questions during a live session.
---

# Facilitate: COCO SDLC HOL Instructor Assistant

[objective section]

[on_invocation section — file loading instructions]

[session_flow section — state machine rules]

[per_section behavior rules]

[ad_hoc_questions section]

[constraints section — no SQL, no participant tracking]
```

### On-Invocation File Loading

```markdown
## On Invocation

Before responding, read these files in full:

1. `INSTRUCTOR_GUIDE.md` — The primary coaching script. All section content,
   watch-fors, callout cues, fallback prompts, and the troubleshooting table
   come from here.
2. `AGENTS.md` — Snowflake schema, business rules, and key file paths. Use for
   ad hoc data and architecture questions during the session.
3. `LAB_INSTRUCTIONS.md` — Participant-facing lab guide. Use to understand what
   participants are seeing at each step.

After reading, open with a brief orientation message and present Section 1.
```

### Advancement Trigger Pattern

```markdown
## Advancing Through the Session

Present one section at a time. After presenting a section, wait.

**Advance when the instructor says:**
- "next" / "continue" / "move on" / "ready"
- A section name: "Section 4", "Task 1", "context switch"
- "let's go" / "proceed" / "keep going"
- Any indication they are ready to move forward

**Do not advance automatically.** The instructor controls timing.

**Jump navigation:** If the instructor says "go to Section 6" or "skip to Task 2",
jump directly to that section — do not recite intermediate sections.
```

### Section Delivery Pattern

```markdown
## Presenting a Section

When presenting a section, always include:

1. **Section header** with timing cue (e.g., "## Section 4: Task 1 — Add Retry
   Success Rate Metric (~30 min)")
2. **All steps** in order, each with:
   - Step label matching INSTRUCTOR_GUIDE.md (e.g., "Step 4.3")
   - Participant prompt(s) in code blocks (verbatim from INSTRUCTOR_GUIDE.md)
   - Expected output (for verification steps only)
   - Watch-for callout if present in INSTRUCTOR_GUIDE.md
   - Group callout cue if present in INSTRUCTOR_GUIDE.md
   - Fallback/conditional prompts in brackets (e.g., "[If plan misses intermediate
     model]:")
3. **Closing prompt:** "Ready for the next section?"

Do not summarize or abbreviate any step. Present the full coaching script.
```

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|-----------------|-------|
| Static reference doc (INSTRUCTOR_GUIDE.md) | Interactive facilitation assistant | Phase 5 adds conversational delivery layer over the same content |
| Instructor scans a long document during live delivery | Skill surfaces one section at a time on demand | Reduces cognitive load during facilitation |
| Skill files have self-contained content | Skill files reference external source files | Correct pattern for live-sync content |

---

## Open Questions

1. **Section 1 has no participant inputs — present it or skip?**
   - What we know: Section 1 is instructor-led architecture walkthrough. INSTRUCTOR_GUIDE.md includes a Section 1 header with "~10 min" and notes it has no participant inputs.
   - What's unclear: Whether the skill should present a Section 1 entry or just start at Section 2.
   - Recommendation: Present Section 1 as a brief entry noting timing and intent ("Instructor-led architecture walkthrough — no participant inputs. ~10 min"). Maintains timing continuity and matches INSTRUCTOR_GUIDE.md structure.

2. **How should the skill handle mid-section questions?**
   - What we know: The instructor may ask ad hoc questions ("what's the clnt_id filter value?") mid-section.
   - What's unclear: Should Claude answer immediately and then offer to return to the section, or answer inline?
   - Recommendation: Answer immediately from loaded context, then note current position ("You're on Step 4.3 — ready to continue?"). No need for explicit "return to section" mechanics — conversational context handles position.

3. **What is the opening message when /facilitate is invoked?**
   - What we know: Skill should open with Section 1. INSTRUCTOR_GUIDE.md total duration is ~90 min.
   - What's unclear: How much preamble to include (session overview, how to navigate, etc.).
   - Recommendation: Brief orientation (1-3 sentences: what the skill does, how to advance, total duration) then immediately present Section 1 content. Do not add lengthy usage instructions — the instructor is about to go live.

---

## Validation Architecture

No automated test framework applies to this phase. The deliverable is a markdown skill file evaluated by manual review.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual review — no automated test framework |
| Config file | none |
| Quick run command | n/a — invoke `/facilitate` in Claude Code and verify behavior |
| Full suite command | n/a |

### Behavior Verification Checklist

| Behavior | Test Type | Verification Method |
|----------|-----------|---------------------|
| Skill file parseable by Claude Code | smoke | Invoke `/facilitate` — no parse errors |
| Files loaded on invocation | manual | Check that first response references INSTRUCTOR_GUIDE.md content |
| Opens with Section 1, waits | manual | Verify skill does not dump all sections on first response |
| Advances only on instructor input | manual | Say "next" and verify Section 2 appears |
| Full coaching script per section (not summary) | manual | Verify watch-fors and callout cues appear in section output |
| Verification steps phrased as relay prompts | manual | Confirm no SQL in Section 4.10a/b/c/d output |
| Ad hoc questions answered from context | manual | Ask "what is the clnt_id filter?" and confirm AGENTS.md value returned |
| Jump navigation works | manual | Say "go to Section 6" and verify direct jump |
| No SQL execution attempted | manual | Confirm no Snowflake tool calls during any section |

### Wave 0 Gaps

- [ ] `.claude/` directory — must be created before skill file can be written
- [ ] `.claude/skills/` directory — must be created before skill file can be written

---

## Sources

### Primary (HIGH confidence)

- `INSTRUCTOR_GUIDE.md` — Direct read; all section structure, step content, watch-fors, callouts, timing cues, and troubleshooting table
- `AGENTS.md` — Direct read; Snowflake schema, business rules, key paths
- `LAB_INSTRUCTIONS.md` — Direct read (first 50 lines); section structure confirmation
- `.planning/phases/05-instructor-claude-skill/05-CONTEXT.md` — Direct read; all locked decisions and scope constraints
- `~/.claude/skills/evolv/new-project/SKILL.md` — Direct read; YAML frontmatter format, section structure pattern for Claude Code skills
- `~/.claude/skills/weekly-ai-digest/SKILL.md` — Direct read; runtime file-reading pattern, operational instruction format
- `~/.claude/skills/find-skills/SKILL.md` — Direct read; minimalist skill structure reference

### Secondary (MEDIUM confidence)

- `.planning/phases/04-instructor-reference-sheet-with-prompt-by-prompt-sequence/04-RESEARCH.md` — Direct read; full source material inventory from Phase 4, confirming INSTRUCTOR_GUIDE.md content completeness
- `.planning/STATE.md` — Direct read; project history, INSTRUCTOR_GUIDE.md human-approval confirmation
- `.planning/config.json` — Direct read; `commit_docs: true`, `nyquist_validation` absent (treat as enabled)

### Tertiary (LOW confidence)

None.

---

## Metadata

**Confidence breakdown:**
- Skill file format: HIGH — observed directly from multiple skill files in `~/.claude/skills/`
- Content source completeness: HIGH — INSTRUCTOR_GUIDE.md read directly, confirmed 350+ lines and all sections
- Section delivery pattern: HIGH — derived from locked CONTEXT.md decisions and skill format analysis
- Ad hoc question handling: MEDIUM — behavior prescribed by CONTEXT.md decision; Claude's actual runtime behavior is inferred, not tested

**Research date:** 2026-03-08
**Valid until:** 2026-04-08 (skill file format is stable; content sources are locked post-Phase 4)
