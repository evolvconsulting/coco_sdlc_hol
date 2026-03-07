# Phase 4: Instructor Reference Sheet with Prompt by Prompt Sequence - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce a standalone instructor-facing reference document (`INSTRUCTOR_GUIDE.md`) that lists every participant-typed input in sequence across the full lab — Cortex Code prompts, git commands, SQL, and npm commands — organized to match the LAB_INSTRUCTIONS.md section structure. Includes timing cues, inline trouble-spot callouts, and instructor talking-point notes at key transitions. Participant-facing content is out of scope.

**In scope:**
- All participant-typed inputs extracted from LAB_INSTRUCTIONS.md (both tickets, setup verification)
- Timing cues matching LAB_INSTRUCTIONS.md section estimates
- Inline "Watch for:" callouts at known participant sticking points
- Brief "Call out to group:" notes at high-impact transitions
- Scannable format for live use during the session

**Out of scope:**
- Pre-lab setup checklist (covered in INFRASTRUCTURE.md)
- New or enhanced prompts beyond what LAB_INSTRUCTIONS.md contains
- Participant-facing cheat sheet
- Cross-linking from INFRASTRUCTURE.md to this document

</domain>

<decisions>
## Implementation Decisions

### Audience and placement
- Instructor-only — participants never see this document
- Standalone file: `INSTRUCTOR_GUIDE.md` at repo root (not appended to INFRASTRUCTURE.md)
- No cross-linking from INFRASTRUCTURE.md
- Format optimized for live use during the session — scannable at a glance under time pressure
- Single instructor use (no hand-off notes needed between sections)

### Prompt scope
- Complete sequence — every prompt a participant types, not just key moments
- Full lab coverage: Section 2 (env verification), Section 3 (Cortex Code primer), Ticket 1 end-to-end, context switch, Ticket 2 end-to-end
- Source of prompts: same prompts already in LAB_INSTRUCTIONS.md, extracted and reformatted — no new prompts invented
- Includes all participant-typed inputs: Cortex Code prompts, git commands, SQL verification queries, npm/node commands

### Entry format
- Numbered steps with step context: step number matching LAB_INSTRUCTIONS.md numbering, 1-line action label, then exact input in a code block
- Example pattern:
  ```
  **Step 4.3 — Plan the work in Cortex Code**
  ```
  /plan Add retry_success_rate metric to the authorizations mart,
  update the semantic view, and update the Cortex Agent
  ```
  ```
- Mirrors LAB_INSTRUCTIONS.md section and step numbers exactly — instructor can cross-reference instantly
- Non-Cortex-Code commands (git, SQL, npm): command in code block + 1-line purpose label
- Expected outputs included only for verification steps (not every step)

### Facilitation notes
- Timing cues at each section header matching LAB_INSTRUCTIONS.md estimates (e.g., "~30 min")
- Inline "Watch for:" callouts at steps where participants commonly get stuck
- Brief "Call out to group:" notes at key transitions (e.g., when plan mode shows the Cortex Code diff, when semantic view update is visible in Snowsight)
- No pre-lab checklist — already in INFRASTRUCTURE.md

### Claude's Discretion
- Which specific steps get "Watch for:" callouts (infer from content — wrong role, missing env vars, AGENTS.md not found, etc.)
- Which transitions get "Call out to group:" notes (high-impact demo moments)
- Exact wording of facilitation callouts

</decisions>

<specifics>
## Specific Ideas

- The document is a live reference tool, not a script — callouts should be brief prompts, not full talking-point text
- Step numbers must stay in sync with LAB_INSTRUCTIONS.md so instructor can say "everyone should be on step 4.3" and look it up instantly
- The context switch between Ticket 1 and Ticket 2 is a key teaching moment — should have a "Call out to group:" note
- Verification steps in both tickets (local app launch, semantic view output) are the moments where the full stack comes together — highlight those

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `LAB_INSTRUCTIONS.md`: Primary source — all participant inputs are extracted from here; section/step numbering must match
- `INFRASTRUCTURE.md`: Pre-lab instructor reference; this document complements it (facilitation vs. setup)

### Established Patterns
- INFRASTRUCTURE.md uses direct instructional tone, no hand-holding — match that voice for instructor callouts
- LAB_INSTRUCTIONS.md uses time estimates per section (~10 min, ~30 min, etc.) — use same values as timing cues
- Suggested prompts in LAB_INSTRUCTIONS.md are framed as starting points — reference sheet should present them as the canonical form

### Integration Points
- Step numbers must mirror LAB_INSTRUCTIONS.md exactly
- Ticket IDs (EPA-X) in the reference sheet must match the actual Jira ticket IDs created in Phase 3

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-instructor-reference-sheet-with-prompt-by-prompt-sequence*
*Context gathered: 2026-03-06*
