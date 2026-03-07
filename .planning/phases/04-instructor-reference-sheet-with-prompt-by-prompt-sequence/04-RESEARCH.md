# Phase 4: Instructor Reference Sheet with Prompt by Prompt Sequence - Research

**Researched:** 2026-03-06
**Domain:** Technical documentation authoring — instructor-facing live-use reference
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Audience and placement**
- Instructor-only — participants never see this document
- Standalone file: `INSTRUCTOR_GUIDE.md` at repo root (not appended to INFRASTRUCTURE.md)
- No cross-linking from INFRASTRUCTURE.md
- Format optimized for live use during the session — scannable at a glance under time pressure
- Single instructor use (no hand-off notes needed between sections)

**Prompt scope**
- Complete sequence — every prompt a participant types, not just key moments
- Full lab coverage: Section 2 (env verification), Section 3 (Cortex Code primer), Ticket 1 end-to-end, context switch, Ticket 2 end-to-end
- Source of prompts: same prompts already in LAB_INSTRUCTIONS.md, extracted and reformatted — no new prompts invented
- Includes all participant-typed inputs: Cortex Code prompts, git commands, SQL verification queries, npm/node commands

**Entry format**
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

**Facilitation notes**
- Timing cues at each section header matching LAB_INSTRUCTIONS.md estimates (e.g., "~30 min")
- Inline "Watch for:" callouts at steps where participants commonly get stuck
- Brief "Call out to group:" notes at key transitions (e.g., when plan mode shows the Cortex Code diff, when semantic view update is visible in Snowsight)
- No pre-lab checklist — already in INFRASTRUCTURE.md

### Claude's Discretion
- Which specific steps get "Watch for:" callouts (infer from content — wrong role, missing env vars, AGENTS.md not found, etc.)
- Which transitions get "Call out to group:" notes (high-impact demo moments)
- Exact wording of facilitation callouts

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

## Summary

This phase produces a single Markdown file (`INSTRUCTOR_GUIDE.md`) at the repo root. It is a documentation authoring task, not a software development task. There are no libraries to install, no APIs to call, and no tests to write beyond manual review. All research value comes from understanding the source material (LAB_INSTRUCTIONS.md) deeply enough to make accurate extraction and curation decisions.

The document's primary purpose is enabling a facilitator to track exactly where participants are in the lab — step by step — while keeping their eyes mostly on the room, not on the instructions. This means density and scannability are more important than completeness of explanation: every word in a callout must earn its place.

The only technical dependency is Jira ticket ID accuracy. Phase 3 confirmed that EPA-2 is the retry success rate story (Ticket 1) and EPA-3 is the KPI card story (Ticket 2). These real IDs are already substituted into LAB_INSTRUCTIONS.md and must be used as-is in INSTRUCTOR_GUIDE.md.

**Primary recommendation:** Extract every participant-typed input verbatim from LAB_INSTRUCTIONS.md in section/step order, layer in timing from section headers, then add "Watch for:" and "Call out to group:" annotations at the specific steps identified below.

---

## Source Material Inventory

This section catalogs all participant-typed inputs found in LAB_INSTRUCTIONS.md, organized by section, with their exact text. This is the raw extraction the planner will work from.

### Section 2: Environment Setup Verification (~5 min)

| Step | Input Type | Exact Input |
|------|-----------|-------------|
| Step 1 | bash command | `snow sql -c ennovate -q "SELECT CURRENT_ROLE(), CURRENT_DATABASE(), CURRENT_SCHEMA();"` |
| Step 2 | bash command | `cd apps/frontend && npm install && npm run dev` |
| Step 3 | bash command | `cortex --version` |
| Step 3 (fallback) | bash command | `curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh \| sh` |

**Verification outputs exist for:** Steps 1, 2, and 3 (all three have expected output blocks in LAB_INSTRUCTIONS.md).

### Section 3: Cortex Code Primer (~10 min)

| Step | Input Type | Exact Input |
|------|-----------|-------------|
| 3.3 | bash command | `cortex mcp add jira --url https://evolv-coco-sdlc-hol.atlassian.net --auth-token ATATT3xFfGF0D7Aiugi8RrvbyL4UHnMz-wrOpVZkykXnM7OQcUWgruzWN1HreG_iWhaVD9vfsuE_ZAtDIgTHG3xjRmue861sVE3v2nVs1_uqhjQ_XRsx4eSKVV1Zr8FFLZ1BMOdtusft0jPXZcrZkzmbA_KfOLjXOGDWqoNiKFkw-bRxuM5-iCU=64649D40` |
| 3.3 (alternative) | Cortex Code slash command | `/mcp` (then follow prompts) |
| 3.4 | bash command | `cortex mcp add confluence --url https://evolv-coco-sdlc-hol.atlassian.net --auth-token ATATT3xFfGF0JmTTc6yxUOmZbKA0ZlbDtsH8KZv3pijAYQ3Su0tUGnz7xODTQiYe16J1Xvz7nl6o-GtkOgkX0LWGcl-VcjygrFz9KNcAqDJqvOZlNyvmGn_ozYe5Bedn8QRqi2_nAMOaUNniftWkIYqNrHke4d09m0BnOJGfpUdLDOjwO-TWDq0=363884CD` |
| 3.5 | bash command | `cortex` |
| 3.5 | Cortex Code natural language | `What database and schema does this project use?` |

**Verification output exists for:** Step 3.5 (expected behavior: mentions COCO_SDLC_HOL and medallion layers).

### Section 4: Task 1 — Add Retry Success Rate Metric (~30 min)

| Step | Input Type | Exact Input |
|------|-----------|-------------|
| 4.1 | bash command | `cortex` |
| 4.1 | Cortex Code natural language | `Show me Jira ticket EPA-2. What does it ask me to implement?` |
| 4.2 | Cortex Code natural language | `Create a new git branch called feature/retry-success-rate and switch to it.` |
| 4.3 | Cortex Code slash command | `/plan` |
| 4.3 | Cortex Code natural language | `I need to add a retry success rate metric to the authorizations domain. Retry success rate = count of transactions where a customer was initially declined then approved on a subsequent attempt. Add this to the dbt mart, the semantic view, and update the Cortex Agent instructions. Start by reading the relevant files.` |
| 4.3 (scope expansion) | Cortex Code natural language | `Please also include changes to the intermediate model (int_authorizations__enriched.sql) for the retry detection logic and the Cortex Agent instructions (03_create_agent.sql).` |
| 4.4 | Cortex Code natural language | `The plan looks good. Execute it.` |
| 4.5 (if needed) | Cortex Code natural language | `Add the retry detection logic as a window function in int_authorizations__enriched.sql. A retry is when the same card_bin, card_last_four, and transaction_amount appear from the same merchant within 5 minutes of a declined transaction. Add retry_attempt_flag and retry_success_flag columns.` |
| 4.10a | Cortex Code natural language | `Run the compiled CREATE OR REPLACE DYNAMIC TABLE statements from the modified dbt models against Snowflake to apply the new columns. Then refresh both dynamic tables so the data is immediately available: ALTER DYNAMIC TABLE COCO_SDLC_HOL.INTERMEDIATE.INT_AUTHORIZATIONS__ENRICHED REFRESH; and ALTER DYNAMIC TABLE COCO_SDLC_HOL.MARTS.AUTHORIZATIONS REFRESH;` |
| 4.10b | Cortex Code natural language | `Run the updated semantic view DDL from packages/dbt/analyses/payment_analytics_semantic_view.sql against Snowflake. Then run DESCRIBE SEMANTIC VIEW COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS and confirm RETRY_SUCCESS_RATE appears in the metrics list.` |
| 4.10c | Cortex Code natural language | `Query the AUTHORIZATIONS mart to verify the retry columns contain data. Calculate successful_retries, total_retries, and retry_success_rate_pct for clnt_id = 'dmcl' over the last 30 days.` |
| 4.10d | Cortex Code natural language | `What is the retry success rate for the last 30 days?` |
| 4.11 | Cortex Code natural language | `Commit all changes in packages/dbt/ and packages/database/ with the message "feat(dbt): add retry_success_rate to authorizations mart and semantic view". Then push to origin.` |
| 4.12 | Cortex Code natural language | `Read the Confluence data dictionary page at https://evolv-coco-sdlc-hol.atlassian.net/wiki/spaces/EPA/pages/851970/Data+Dictionary+-+Authorizations. What metrics are currently documented? How should I document the new retry_success_rate metric to match the existing format?` |

**Verification outputs exist for:** Steps 4.10a (DDL confirmation), 4.10b (RETRY_SUCCESS_RATE in DESCRIBE output), 4.10c (non-null retry_success_rate_pct), 4.10d (Cortex Agent returns meaningful answer).

### Section 5: Context Switch (~2 min)

| Step | Input Type | Exact Input |
|------|-----------|-------------|
| Clear context | Cortex Code slash command | `/new` |

No verification output — this is a procedural step.

### Section 6: Task 2 — Add KPI Card to Dashboard (~20 min)

| Step | Input Type | Exact Input |
|------|-----------|-------------|
| 6.1 | Cortex Code natural language | `Show me Jira ticket EPA-3. What does it ask me to implement?` |
| 6.2 | Cortex Code natural language | `Create a new git branch called feature/retry-success-kpi-card and switch to it.` |
| 6.3 | Cortex Code slash command | `/plan` |
| 6.3 | Cortex Code natural language | `Read Jira ticket EPA-3. Look at apps/frontend/src/app/analytics/authorization/page.tsx, apps/frontend/src/components/ui/KPICard.tsx, and apps/frontend/src/types/domain.ts. Add a KPI card that shows the retry_success_rate from the authorization KPIs API. Follow the exact same pattern as the existing KPI cards.` |
| 6.4 | Cortex Code natural language | `The plan looks good. Execute it.` |
| 6.5 | Cortex Code natural language | `Start the frontend dev server from apps/frontend.` |
| 6.5 (debug, if needed) | Cortex Code natural language | `The retry success rate KPI card is showing 0. Check that the AuthorizationKPIs interface in domain.ts includes retrySuccessRate and that the API route in kpis/route.ts returns the field.` |
| 6.6 | Cortex Code natural language | `Commit all changes in apps/frontend/ with the message "feat(frontend): add retry success rate KPI card to authorization dashboard". Then push to origin.` |
| 6.7 | Cortex Code natural language | `Create a GitHub pull request for this branch. Title: "Add retry success rate KPI card". Describe what was changed and why.` |

**Verification outputs exist for:** Step 6.5 (KPI card visible at localhost:3000/analytics/authorization with a percentage value and green color).

---

## Timing Cues (from LAB_INSTRUCTIONS.md)

Match these exactly — they come from the section headers in LAB_INSTRUCTIONS.md:

| Section | Duration | Notes |
|---------|----------|-------|
| Section 1: Architecture Overview | ~10 min | Instructor-led walkthrough, no participant inputs |
| Section 2: Environment Setup Verification | ~5 min | 3 verification steps |
| Section 3: Cortex Code Primer | ~10 min | MCP setup + quick test |
| Section 4: Task 1 — Retry Success Rate | ~30 min | Heaviest step count; plan/execute/verify cycle |
| Section 5: Context Switch | ~2 min | One command + reflection pause |
| Section 6: Task 2 — KPI Card | ~20 min | Shorter; pattern follows Task 1 |
| Section 7: Wrap-up | ~5 min | Discussion only, no participant inputs |
| **Total** | **~92 min** | Rounds to "~90 min" in LAB_INSTRUCTIONS.md |

---

## Facilitation Callout Analysis

### "Watch for:" Callout Candidates

These are the specific steps where participants are most likely to get stuck based on content analysis:

| Step | Risk | Recommended Callout |
|------|------|---------------------|
| Step 1 (snow sql) | Wrong role returned (`SYSADMIN` instead of `ATTENDEE_ROLE`) | Watch for: Role must be ATTENDEE_ROLE — if SYSADMIN, connection profile is wrong |
| Step 2 (npm run dev) | Missing `.env.local` / wrong `SNOWFLAKE_ACCOUNT` value | Watch for: Dashboard loads but shows no data — check `.env.local` SNOWFLAKE_ACCOUNT |
| Step 3 (cortex --version) | Cortex Code not in PATH after installation | Watch for: "command not found" after install — instruct to restart terminal |
| Step 3.5 (quick test) | AGENTS.md not loaded — Cortex gives generic answer | Watch for: Response doesn't mention COCO_SDLC_HOL — must launch `cortex` from repo root, not a subdirectory |
| Step 4.3 (plan mode) | Plan misses intermediate model or agent file | Watch for: Plan shows only 2-3 files — prompt to expand scope (expansion prompt provided) |
| Step 4.6 (materialization) | Cortex Code suggests changing dynamic table to table or view | Watch for: Any suggestion to change materialization type — existing types must be preserved |
| Step 4.10a (DDL deploy) | Dynamic table refresh skipped or fails silently | Watch for: Confirmation message missing — without refresh, new columns have no data |
| Step 4.10b (semantic view) | RETRY_SUCCESS_RATE absent from DESCRIBE output | Watch for: Metric missing — re-run the semantic view DDL manually |
| Step 4.10c (verification query) | Empty results due to missing `clnt_id` filter | Watch for: Zero rows — all queries must filter `clnt_id = 'dmcl'` |
| Step 6.3 plan order | Cortex Code puts page.tsx change before domain.ts | Watch for: TypeScript interface must be updated BEFORE API route and page component |
| Step 6.5 (KPI card = 0) | Interface not updated before testing | Watch for: Card shows 0 — use debug prompt to check domain.ts and route.ts |
| Step 6.3 (/plan after /new) | Participant forgot to re-enable plan mode | Watch for: Cortex Code starts executing immediately — remind `/plan` is session-scoped |

### "Call out to group:" Transition Candidates

These are the high-impact moments where a brief group callout reinforces the teaching objective:

| Moment | Why It Matters | Recommended Callout |
|--------|---------------|---------------------|
| Step 4.3: Plan mode output appears | First time participants see Cortex Code enumerate a multi-file plan | Call out: This is plan mode — Cortex Code is showing what it will do before doing it. This is your review gate. |
| Step 4.10b: RETRY_SUCCESS_RATE in DESCRIBE output | First proof that the semantic layer picked up the new metric | Call out: The metric is now live in the semantic view — the Cortex Agent can answer questions about it. |
| Step 4.10d: Agent answers the retry question | Full chain working: dbt → mart → semantic view → agent | Call out: Full stack is connected — one natural language question, Cortex generates the SQL automatically. |
| Step 5: Context switch with /new | Demonstrates AI workflow hygiene | Call out: This is context hygiene — we clear stale context before switching tasks. Clean context = better AI suggestions. |
| Step 6.5: KPI card visible in browser | Visual confirmation that backend metric became a frontend UI element | Call out: Ticket 1 became Ticket 2's data source — same metric, different surface, full SDLC cycle complete. |
| Step 6.7: PR created | Closes the loop from Jira ticket to merged PR | Call out: Jira ticket read at the start, PR created at the end — the full development loop without leaving the terminal. |

---

## Architecture Patterns

### Document Structure (Recommended)

The INSTRUCTOR_GUIDE.md should follow this structure for scannability:

```
INSTRUCTOR_GUIDE.md
├── Header — file purpose, companion docs, how to use
├── Section 2: Environment Verification  (~5 min)
│   ├── [section timing cue]
│   └── Steps 1–3 with inputs, expected outputs, Watch for: callouts
├── Section 3: Cortex Code Primer  (~10 min)
│   ├── [section timing cue]
│   └── Steps 3.1–3.5 with inputs, Watch for: callouts
├── Section 4: Task 1 — Add Retry Success Rate Metric  (~30 min)
│   ├── [section timing cue]
│   └── Steps 4.1–4.12 with inputs, Watch for: callouts, Call out: notes
├── Section 5: Context Switch  (~2 min)
│   ├── [section timing cue]
│   └── /new command + Call out: note
├── Section 6: Task 2 — Add KPI Card  (~20 min)
│   ├── [section timing cue]
│   └── Steps 6.1–6.7 with inputs, Watch for: callouts, Call out: notes
└── Quick-Reference Troubleshooting Table
    └── Condensed version of LAB_INSTRUCTIONS.md Appendix A
```

### Entry Format Pattern

The entry format is locked by CONTEXT.md. The canonical pattern is:

```
**Step X.Y — [1-line action label]**
```[input-type]
[exact input verbatim]
```
> Watch for: [callout text — only at known sticking points]
> Call out to group: [callout text — only at key transitions]
```

Where `[input-type]` is one of:
- *(no label needed for Cortex Code natural language — it is the default)*
- `bash` for terminal commands
- `cortex` for slash commands

Expected outputs appear as their own fenced block immediately after the input block, only for verification steps (4.10a, 4.10b, 4.10c, 4.10d, 6.5).

### Voice and Tone

Match INFRASTRUCTURE.md: direct instructional tone, no hand-holding. Callouts are prompts to act, not explanations of why.

- **Good:** `Watch for: Role must be ATTENDEE_ROLE — if not, connection profile is wrong`
- **Bad:** `Watch for: If participants see the wrong role, it means their Snow CLI configuration file points to a different connection profile than the one configured during pre-lab setup, which will cause subsequent commands to fail`

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Step numbering | Re-derive step numbers from content | Copy numbering exactly from LAB_INSTRUCTIONS.md | Step numbers are the cross-reference mechanism; any deviation breaks the "everyone on step X" affordance |
| Timing estimates | Calculate from task counts | Copy timing strings exactly from LAB_INSTRUCTIONS.md section headers | These are user-validated estimates, not guesses |
| Ticket IDs | Invent placeholder IDs | Use EPA-2 and EPA-3 (confirmed live from Phase 3) | Placeholders in a live-use doc create instructor confusion |
| Prompt text | Paraphrase or improve | Extract verbatim from LAB_INSTRUCTIONS.md | Instructors will direct confused participants to copy the exact text |
| Verification outputs | Reconstruct from schema knowledge | Copy expected output blocks verbatim from LAB_INSTRUCTIONS.md | These blocks were validated against real data |

---

## Common Pitfalls

### Pitfall 1: Including participant-facing explanation
**What goes wrong:** Copying explanatory text from LAB_INSTRUCTIONS.md alongside the commands (e.g., the "Why the refresh?" callout).
**Why it happens:** It feels helpful to preserve context.
**How to avoid:** The reference sheet is a sequence list, not a tutorial. If an explanation is needed for the instructor, it belongs in a "Call out to group:" note, not inline prose.
**Warning signs:** Any sentence that starts with "This" or "The" rather than being a direct prompt or callout.

### Pitfall 2: Missing conditional prompts
**What goes wrong:** Omitting the "if this doesn't work" fallback prompts (scope expansion in 4.3, debug in 6.5, materialization warning in 4.6).
**Why it happens:** They feel like edge cases.
**How to avoid:** These are the most instructor-critical entries — they are what the instructor needs when a participant is stuck. Include all conditional prompts from LAB_INSTRUCTIONS.md as bracketed entries (e.g., `[If plan misses intermediate model]`).
**Warning signs:** Any step in LAB_INSTRUCTIONS.md that contains "If Cortex Code's plan does not include..." or "If the card shows 0..."

### Pitfall 3: Step number drift
**What goes wrong:** Renumbering steps or omitting sub-steps (e.g., collapsing 4.10a/b/c/d into "Step 4.10").
**Why it happens:** Sub-steps feel like implementation detail.
**How to avoid:** The sub-steps in 4.10 are distinct prompts with distinct expected outputs. Keep them as separate labeled entries: `Step 4.10a`, `Step 4.10b`, etc.
**Warning signs:** Any step with multiple distinct participant inputs collapsed into one entry.

### Pitfall 4: Omitting Section 1 header with note
**What goes wrong:** Jumping straight from the doc header into Section 2.
**Why it happens:** Section 1 has no participant inputs so it seems out of scope.
**How to avoid:** Include a Section 1 header with timing cue and a one-line note ("No participant inputs — instructor-led architecture walkthrough"). The instructor needs to track session time continuously.
**Warning signs:** Document starts at Section 2.

### Pitfall 5: Omitting the quick-reference troubleshooting table
**What goes wrong:** Leaving the troubleshooting content solely in LAB_INSTRUCTIONS.md Appendix A.
**Why it happens:** The CONTEXT.md doesn't explicitly call for a troubleshooting table.
**How to avoid:** The CONTEXT.md calls for "Watch for:" callouts at sticking points. A condensed troubleshooting table at the end of INSTRUCTOR_GUIDE.md serves the same function in aggregate. INFRASTRUCTURE.md's tone establishes this pattern. Include it as a condensed version of the 7-row table from LAB_INSTRUCTIONS.md Appendix A.
**Warning signs:** No troubleshooting section at all.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual review — no automated test framework applies |
| Config file | none |
| Quick run command | n/a |
| Full suite command | n/a |

### Phase Requirements → Test Map

| Behavior | Test Type | Verification Method |
|----------|-----------|---------------------|
| All participant inputs extracted | manual | Side-by-side comparison with LAB_INSTRUCTIONS.md |
| Step numbers match LAB_INSTRUCTIONS.md | manual | Check each section/step header against source |
| Timing cues match LAB_INSTRUCTIONS.md section headers | manual | Verify each section timing string |
| EPA-2 / EPA-3 ticket IDs present (not placeholders) | manual | Search INSTRUCTOR_GUIDE.md for "EPA-2" and "EPA-3" |
| Verification outputs included at correct steps | manual | Check steps 4.10a/b/c/d and 6.5 have expected-output blocks |
| No participant-facing explanation prose | manual | Scan for paragraphs not structured as step/callout/code |
| Conditional prompts (fallback) included | manual | Confirm 4.3 scope expansion, 4.5 retry logic, 4.6 materialization, 6.5 debug are present |

### Sampling Rate

- **Per task commit:** Manual review of the affected section against LAB_INSTRUCTIONS.md
- **Phase gate:** Full side-by-side review before `/gsd:verify-work`

### Wave 0 Gaps

None — this phase produces a single document. No test infrastructure is needed.

---

## State of the Art

| Item | Current State | Source |
|------|---------------|--------|
| Ticket IDs | EPA-2 (retry success rate), EPA-3 (KPI card) | Phase 3 confirmed live (03-02-SUMMARY.md) |
| Section numbering | Sections 1–7 in LAB_INSTRUCTIONS.md | Read directly |
| Step numbering | 1–3 (Section 2), 3.1–3.5 (Section 3), 4.1–4.12 (Section 4), 5 (context switch), 6.1–6.7 (Section 6) | Read directly |
| Lab total duration | ~90 min (actual ~92 min) | LAB_INSTRUCTIONS.md header |
| INFRASTRUCTURE.md tone | Direct, no hand-holding, imperative | INFRASTRUCTURE.md read directly |

---

## Open Questions

1. **Section 1 has no participant inputs — include header or skip?**
   - What we know: CONTEXT.md says "Full lab coverage: Section 2 (env verification), Section 3 (Cortex Code primer)..." — Section 1 not listed.
   - What's unclear: Whether the instructor guide should still have a Section 1 header with timing so the facilitator can track against total session time.
   - Recommendation: Include Section 1 as a one-line header-only entry ("Instructor-led architecture walkthrough — no participant inputs") to maintain timing continuity. The planner should make the final call.

2. **Cortex Code natural language prompts: code block or blockquote?**
   - What we know: CONTEXT.md shows an example using a fenced code block for the prompt text. LAB_INSTRUCTIONS.md uses both blockquotes (Step 4.1: `> Show me Jira ticket...`) and inline prose for natural language prompts.
   - What's unclear: The exact rendering preference for natural language prompts vs. slash commands in the reference sheet.
   - Recommendation: Use fenced code blocks (no language tag) for all participant-typed inputs uniformly — this makes copy-paste easier and visually distinct from callout text. Slash commands and natural language prompts treated identically.

3. **Section 7 (Wrap-up): include or omit?**
   - What we know: Section 7 has no participant inputs. CONTEXT.md specifies coverage through "Ticket 2 end-to-end" which ends at Step 6.7.
   - Recommendation: Omit Section 7 from INSTRUCTOR_GUIDE.md — it is facilitated discussion with no inputs to track. Include a brief closing note after Step 6.7 indicating the lab is complete.

---

## Sources

### Primary (HIGH confidence)
- `LAB_INSTRUCTIONS.md` — Direct read; all participant inputs, section structure, timing cues, expected outputs extracted from this file
- `INFRASTRUCTURE.md` — Direct read; voice/tone reference for instructor callout style
- `.planning/phases/04-instructor-reference-sheet-with-prompt-by-prompt-sequence/04-CONTEXT.md` — Direct read; all locked decisions and scope constraints
- `.planning/phases/03-generate-reference-content-for-jira-tickets-and-confluence-documentation/03-02-SUMMARY.md` — Direct read; confirmed EPA-2 and EPA-3 as live ticket IDs

### Secondary (MEDIUM confidence)
- `.planning/STATE.md` — Direct read; project history and accumulated decisions confirming v1.0 milestone completion
- `.planning/config.json` — Direct read; confirmed `nyquist_validation` not set (treat as enabled), `commit_docs: true`

### Tertiary (LOW confidence)
None.

---

## Metadata

**Confidence breakdown:**
- Source material inventory: HIGH — extracted directly from LAB_INSTRUCTIONS.md
- Facilitation callout candidates: MEDIUM — inferred from content analysis, not validated against real lab delivery
- Document structure recommendation: HIGH — derived from locked CONTEXT.md decisions and INFRASTRUCTURE.md patterns
- Ticket IDs: HIGH — confirmed live from Phase 3 summary

**Research date:** 2026-03-06
**Valid until:** 2026-04-06 (LAB_INSTRUCTIONS.md content is stable; only changes if the lab content is revised)
