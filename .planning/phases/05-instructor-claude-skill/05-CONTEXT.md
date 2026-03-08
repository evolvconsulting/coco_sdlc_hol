# Phase 5: Instructor Claude Skill - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Create a Claude Code skill (`/facilitate`) that guides an instructor step-by-step through delivering the COCO SDLC HOL. The skill is an interactive facilitation assistant — not a lookup tool. It leads the instructor sequentially through the lab sections, providing the full coaching script at each step (what to say, expected outputs, watch-fors, participant prompts, and fallback prompts). Verification queries, environment checks, and DDL steps are guided via brief hints for participants to self-verify — the instructor cannot access participant Snowflake environments.

</domain>

<decisions>
## Implementation Decisions

### Skill purpose and mode
- The skill is a **sequential guide** — it leads the instructor through the lab flow step by step, not a lookup or Q&A tool
- Primary use: live facilitation during the ~90-minute session
- Instructor starts the skill and it walks them forward through each section in order

### Invocation
- Single skill: `/facilitate`
- One all-purpose command — no separate skills for navigation, troubleshooting, or callouts
- Skill file lives in `.claude/skills/facilitate.md`

### Return format at each step
- **Full coaching script** per step: what to say/present, expected participant outputs, watch-fors, group callout cues, and fallback prompts if a participant is stuck
- Hints for self-verification (brief cues the instructor can relay to participants) — not SQL the instructor executes

### Content strategy
- Skill reads `INSTRUCTOR_GUIDE.md` at runtime (not inlined) — stays in sync as guide evolves
- Also loads `AGENTS.md` (Snowflake schema/business rules context) and `LAB_INSTRUCTIONS.md` (participant-facing steps)
- When questions fall outside INSTRUCTOR_GUIDE content, Claude reasons from the loaded context (AGENTS.md + codebase) rather than deferring

### Live data / SQL
- Guidance-only — no SQL execution against Snowflake
- Each participant has their own isolated Snowflake environment not accessible to the instructor
- Verification prompts in the skill are brief cues the instructor passes to participants so they self-verify (e.g., "Ask participants to run DESCRIBE SEMANTIC VIEW and confirm RETRY_SUCCESS_RATE appears")

### Participant tracking
- No roster, no per-participant state
- Skill tracks the instructor's position in the lab flow (which section/step they're on), not individual participant progress
- Instructor triage (multiple stuck participants) is handled by instructor judgment, not the skill

### Claude's Discretion
- Exact skill prompt structure and section chunking
- How the skill signals "move to next step" vs waits for instructor input
- Tone of coaching script content (mirroring INSTRUCTOR_GUIDE style)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `INSTRUCTOR_GUIDE.md`: Primary content source — 350+ lines, mirrors LAB_INSTRUCTIONS.md step numbering exactly, includes watch-fors and callout cues per step
- `AGENTS.md`: Snowflake connection config, 7 MARTS tables, business rules, key paths — loaded for data-related questions
- `LAB_INSTRUCTIONS.md`: Participant-facing guide (625 lines, 2 tasks) — loaded so skill understands what participants are seeing

### Established Patterns
- No existing `.claude/` or `.agents/` directories — this phase creates both
- Claude Code skill files follow the GSD pattern: markdown with `<objective>`, `<process>`, `<success_criteria>` sections
- Cortex Code (participant tool) uses `/plan`, `/new`, `/mcp` slash commands — skill should be aware of these so coaching script references them correctly

### Integration Points
- New files: `.claude/skills/facilitate.md` (the skill), `.claude/` directory (created by this phase)
- INSTRUCTOR_GUIDE.md, AGENTS.md, LAB_INSTRUCTIONS.md are read-only references — not modified by this phase

</code_context>

<specifics>
## Specific Ideas

- The skill should mirror the INSTRUCTOR_GUIDE's section structure (Section 1 through Section 7, including the troubleshooting table)
- "Step-by-step guide" mental model: when invoked, skill presents Section 1 content and waits — instructor advances through the session by asking for the next step
- Verification hints should be phrased as instructor relay prompts: "Tell participants to..." or "Ask participants to confirm..."

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-instructor-claude-skill*
*Context gathered: 2026-03-08*
