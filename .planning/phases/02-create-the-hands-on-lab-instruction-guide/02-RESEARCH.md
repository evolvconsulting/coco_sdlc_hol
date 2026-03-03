# Phase 2: Create the Hands-On Lab Instruction Guide - Research

**Researched:** 2026-03-02
**Domain:** Technical instruction writing for AI-assisted SDLC demonstrations (Cortex Code CLI + Snowflake data stack)
**Confidence:** HIGH (codebase fully examined, official Cortex Code docs fetched, Snowflake release notes reviewed)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Guide structure:**
- Linear sequence: Overview → Setup verification → Task 1 → Task 2 → Wrap-up
- Skip setup execution: Guide provides overview of what's pre-configured but doesn't walk through `hol_setup.sql`
- All optional sections included: Cortex Code primer, architecture overview, appendix/resources, wrap-up
- Time estimates: Each section shows expected duration (e.g., "~10 min")
- Verification steps: After each task, show expected output/query results participants should see
- Single feature branch: All changes on one branch, commit as you go

**Task flow (two tickets):**

Ticket 1: Add Retry Success Rate metric to NLQ agent
1. Read Jira ticket (pre-created in demo project)
2. Create local git branch
3. Use Cortex Code plan mode to plan the work
4. Confirm and execute plan
5. dbt model update — add `retry_success_rate` measure to authorizations
6. dbt materialization update — view → dynamic table
7. Update and run unit tests
8. Review and confirm semantic view update (add new metric)
9. Review and confirm Cortex Agent instruction change
10. Launch local app for human-in-the-loop verification
11. Commit and push change
12. Update Confluence data dictionary (existing page)

Context switch — clear context window

Ticket 2: Add KPI card to dashboard using new metric
1. Pull next Jira ticket
2. Create branch
3. Use Cortex Code plan mode to plan the update
4. Apply the update (new KPI card in frontend)
5. Launch local app for verification
6. Commit and push change
7. Submit PR

**Task specifics:**
- Domain focus: Authorizations (highest volume, most visible impact)
- New metric: Retry success rate — count of retry attempts that succeeded after initial decline
- New visualization: KPI card showing the retry success rate metric
- Jira tickets: Pre-created by instructor in a demo Jira project; guide references ticket IDs
- Confluence: Existing data dictionary page that participants update
- Skills: Jira and Confluence skills installed during lab as part of primer section

**Delivery format:**
- Primary format: Markdown file in repo root
- Single file: One comprehensive document with all sections
- Location: `HANDS_ON_LAB.md` at repo root
- Visuals: Mixed — diagrams for architecture, screenshots for verification points

**Tone and depth:**
- Voice: Third person instructional ("In this section, you will...")
- Detail level: Step-by-step with every command spelled out, copy-paste ready
- Explanations: Include context explaining why each step matters
- Prompts: Suggested prompts shown with note that variations work

### Claude's Discretion

No explicit discretion areas declared in CONTEXT.md — all decisions are locked.

### Deferred Ideas (OUT OF SCOPE)

- Video walkthrough companion to written guide — separate deliverable
- Multi-domain lab variant (chargebacks, settlements) — future enhancement
- Automated lab environment reset script — instructor tooling
- Participant progress tracking dashboard — future milestone
</user_constraints>

---

## Summary

This phase produces a single `HANDS_ON_LAB.md` document. The technical domain is instruction writing, not code implementation — the "stack" is Cortex Code CLI (Snowflake's AI coding assistant) demonstrated against this specific codebase. The primary research challenge is mapping accurate Cortex Code CLI commands, behaviors, and quirks onto the exact files and workflows in this repo.

Cortex Code CLI reached general availability on February 2, 2026. It is built on Claude Code's foundation (same core architecture) with Snowflake-native additions: SQL execution, Snowflake object search, RBAC awareness, dbt support, and semantic view/agent integration. As of February 23, 2026, it also natively supports dbt and Apache Airflow workflows via built-in skills. The official slash command set, plan mode behavior, MCP integration for Jira/Confluence, and AGENTS.md context file support are all verified from official Snowflake documentation.

The codebase has been fully examined. All target files exist, all patterns are understood, and the data flow from the new metric through every layer is clear: `CLX_AUTH` RAW → `stg_clx_auth` staging view → `int_authorizations__enriched` intermediate → `authorizations` mart → `PAYMENT_ANALYTICS` semantic view → Cortex Agent instructions → frontend `AuthorizationKPIs` type + API route + `KPICard` component.

**Primary recommendation:** Write the guide using accurate Cortex Code CLI commands from official docs. Where Cortex Code behavior exactly mirrors Claude Code (same foundation), explicitly note this for participants who may know Claude Code. Treat every suggested prompt as "illustrative — variations work" per the locked decision.

---

## Standard Stack

### Core (for writing the guide)
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Cortex Code CLI | GA (Feb 2, 2026) | AI coding assistant throughout SDLC | Snowflake-native, subject of the HOL |
| dbt-snowflake | 1.x (installed) | Transform RAW → marts dynamic tables | Already in `packages/dbt` |
| Next.js | 14 (installed) | Frontend app participants verify against | Already in `apps/frontend` |
| Git | Any | Branch, commit, push, PR | Standard VCS |

### Supporting (for HOL workflows shown in guide)
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| Jira MCP | Via `cortex mcp add` | Read tickets from Cortex Code | Ticket 1 + Ticket 2 openers |
| Confluence MCP | Via `cortex mcp add` | Update data dictionary page | Ticket 1 step 12 |
| Snow CLI | Installed | Run SQL scripts | Optional — Snowflake Worksheet is primary |

### Installation Commands
```bash
# Install Cortex Code CLI
curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh

# First run — setup wizard
cortex

# dbt (already installed per README)
pip install dbt-snowflake

# Node.js deps for local app verification
cd apps/frontend && npm install
```

---

## Architecture Patterns

### Recommended Document Structure
```
HANDS_ON_LAB.md
├── Header: Lab title, duration estimate, what you'll build
├── Section 1: Architecture Overview (~10 min)
│   ├── Medallion layer diagram (ASCII or Mermaid)
│   ├── MARTS tables reference table
│   └── Cortex Agent / Semantic View overview
├── Section 2: Environment Setup Verification (~5 min)
│   ├── Confirm Snowflake connection
│   ├── Confirm app runs locally
│   └── Confirm Cortex Code CLI installed
├── Section 3: Cortex Code Primer (~10 min)
│   ├── Installation (if not done)
│   ├── /plan mode explanation
│   ├── Key slash commands reference
│   └── MCP skills setup (Jira + Confluence)
├── Section 4: Task 1 — Retry Success Rate Metric (~30 min)
│   ├── Step 4.1: Read Jira ticket
│   ├── Step 4.2: Create git branch
│   ├── Step 4.3: Plan mode
│   ├── Steps 4.4–4.9: Execute changes (dbt → semantic view → agent)
│   ├── Step 4.10: Verify locally
│   ├── Step 4.11: Commit and push
│   └── Step 4.12: Update Confluence
├── Section 5: Context Switch (~2 min)
├── Section 6: Task 2 — KPI Card (~20 min)
│   ├── Steps 6.1–6.7: Read ticket → branch → plan → apply → verify → commit → PR
├── Section 7: Wrap-up (~5 min)
└── Appendix: Troubleshooting, resources, glossary
```

### Pattern 1: Cortex Code Plan Mode Workflow

**What:** The participant types `/plan` to enable plan mode, then describes the task. Cortex Code presents a step-by-step action plan for review before executing anything. After reviewing, the participant confirms or modifies, then Cortex Code executes with explicit approval at each action.

**When to use:** At the start of each ticket — shows AI-assisted planning before touching code.

**Example (guide prose pattern):**
```
In the Cortex Code terminal, enable plan mode:

/plan

Then describe the task:

> I need to add a retry success rate metric to the authorizations domain.
> Retry success rate = count of transactions where a customer was initially
> declined then approved on a subsequent attempt. Add this to the dbt mart,
> the semantic view, and update the Cortex Agent instructions.
> Start by reading the relevant files.

Cortex Code will generate a numbered plan showing each file it intends to
modify. Review the plan — confirm it includes authorizations.sql, the semantic
view DDL, and 03_create_agent.sql. Then confirm execution.
```

**Source:** Snowflake official docs `docs.snowflake.com/en/user-guide/cortex-code/cli-reference` — `/plan` enables plan mode requiring approval before each action. Confirmed GA (Feb 2, 2026).

### Pattern 2: Context Switch Between Tasks

**What:** After Task 1 is committed, the participant starts a fresh Cortex Code session to avoid carrying context from Task 1 into Task 2. This simulates real-world context switching.

**How:** Use `/new` to start a new conversation, or exit and restart with `cortex`. Documented in official CLI reference as session management.

**Example (guide prose pattern):**
```
Before starting Task 2, clear your Cortex Code context window:

/new

This starts a fresh conversation. Cortex Code no longer has Task 1's
context loaded. This is intentional — it demonstrates good AI workflow
hygiene: bring only the context needed for the task at hand.
```

### Pattern 3: MCP Skills for Jira and Confluence

**What:** Cortex Code connects to Jira and Confluence via MCP (Model Context Protocol). Configured in `~/.snowflake/cortex/mcp.json`. Once configured, participants can invoke via natural language.

**Installation pattern (in Cortex Code primer section):**
```bash
# In Cortex Code terminal:
/mcp

# Follow prompts to add Jira server
# Or via CLI:
cortex mcp add jira --url https://your-org.atlassian.net \
  --auth-token <token>
```

**Usage pattern:**
```
> Show me Jira ticket COCO-42
> What does this ticket ask me to implement?
```

**Source:** Snowflake official docs `docs.snowflake.com/en/user-guide/cortex-code/extensibility` — MCP supports stdio, HTTP, SSE transport. Jira and Confluence via HTTP MCP. Confirmed.

### Pattern 4: AGENTS.md Context File

**What:** The repo already has `AGENTS.md` at root with Snowflake connection details, data architecture, business rules, and key paths. Cortex Code reads this automatically when launched from the repo directory. Participants should be told this is pre-configured.

**Guide prose pattern:**
```
The repository includes an AGENTS.md file at the root — Cortex Code reads
this automatically when you launch it from the repo directory. It tells
Cortex Code about your Snowflake connection, the medallion architecture,
business rules (approval codes, etc.), and where key files live.
You do not need to configure this — it is already set up for the lab.
```

### Pattern 5: dbt Model Update via Cortex Code

**What:** Cortex Code has built-in dbt skills (GA Feb 23, 2026). Participants use natural language to add a measure to `authorizations.sql`. The key behavior: Cortex Code edits the dbt SQL file directly — it does NOT try to run `dbt build` in the HOL environment (the compiled DDL is what matters for the HOL scenario).

**Exact files to modify:**
- `packages/dbt/models/marts/payments/authorizations.sql` — add `retry_success_rate` measure (computed from RAW via intermediate)
- `packages/dbt/models/marts/payments/_payments__models.yml` — add column documentation
- `packages/dbt/analyses/payment_analytics_semantic_view.sql` — add metric to `## METRICS` section
- `packages/database/utilities/03_create_agent.sql` — update `orchestration.instructions.response` to mention retry success rate

### Pattern 6: Frontend KPI Card Addition

**What:** Ticket 2 adds a KPI card to the authorization page. The pattern is already established in the codebase — four existing KPI cards in a `Row gutter` grid. Adding a fifth follows the exact same structure.

**Files to modify:**
- `apps/frontend/src/types/domain.ts` — add `retrySuccessRate` to `AuthorizationKPIs` interface
- `apps/frontend/src/app/api/analytics/authorization/kpis/route.ts` — add SQL column + return field
- `apps/frontend/src/app/analytics/authorization/page.tsx` — add `<Col>` + `<KPICard>` in the KPI row

**KPI card component API (from `KPICard.tsx`):**
```tsx
<KPICard
  title="Retry Success Rate"
  value={kpiData?.retrySuccessRate ?? 0}
  format="percent"
  description="Percentage of initially declined transactions that succeeded on retry"
  loading={kpis.isLoading}
  color="#52c41a"
/>
```

### Anti-Patterns to Avoid

- **Telling participants to run `dbt build`:** The HOL environment has pre-compiled DDL in hol_setup.sql. dbt is present for exploration, not execution. The guide must NOT instruct participants to run `dbt build` to apply their mart changes — they should apply DDL directly in Snowflake.
- **Overly-specific AI prompts presented as required:** The locked decision says "variations work." Do not present Cortex Code prompts as exact commands — frame them as starting points.
- **Implying Cortex Code CLI runs on Windows natively:** Official docs state it supports macOS (arm64/x64), Linux (x64/arm64), and Windows via WSL only. Participants on Windows need WSL. The README already notes this.
- **Skipping the CLNT_ID filter in verification queries:** All production queries use `WHERE clnt_id = 'dmcl'`. Verification SQL in the guide must include this filter or results will be wrong/empty.
- **Treating semantic view update as live-refresh:** The semantic view is rebuilt with `CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(...)`. The guide must include this call — it is not automatic.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| KPI card display | Custom React component | `KPICard` component already in `/components/ui/` | Already handles loading, trend, format, color |
| Data fetching | Raw `fetch()` call | `useAnalyticsData` hook | Already handles React Query, cache, error codes |
| SQL parameterization | String interpolation | `binds` array pattern (already in kpis route) | SQL injection protection — established pattern |
| Semantic view metric | Custom SQL view | Add metric to existing `payment_analytics_semantic_view.sql` | Single source of truth for all NLQ metrics |
| Confluence update instruction | Manual wiki UI steps | Cortex Code MCP + natural language | Demonstrates the full AI-assisted SDLC |

**Key insight:** Every pattern in the codebase is already established. The guide should consistently direct participants to extend existing patterns, never start from scratch.

---

## Common Pitfalls

### Pitfall 1: retry_success_rate Requires a Data Model Decision
**What goes wrong:** The CONTEXT says "retry success rate = count of retry attempts that succeeded after initial decline." However, the RAW `CLX_AUTH` table does not have a `retry_attempt_number` column or explicit retry linkage. The intermediate model (`int_authorizations__enriched.sql`) also has no retry logic. This metric requires either (a) a same-card, same-amount, same-merchant, short-time-window self-join, or (b) a dedicated flag in the RAW table.
**Why it happens:** The metric concept is clear business-wise but the raw data structure may not have explicit retry linkage.
**How to avoid:** The guide must define a concrete SQL implementation for `retry_success_rate` that works with the actual data shape. The recommended approach: define it as a SQL expression in the semantic view's `metrics` block using a proxy definition (e.g., count of `risk_score`-correlated retries, or simply a placeholder that Cortex Code can enhance). Alternatively, define it as a computed column added to the `authorizations` mart via a window function on `card_bin + transaction_amount + merchant_name` within a 60-second window. The guide should show a specific, working SQL implementation — not leave it ambiguous.
**Warning signs:** If Cortex Code's plan shows no SQL for computing the metric, prompt it to add the calculation.

**Recommended concrete implementation for the guide:**
```sql
-- In authorizations mart, retry_success_rate expressed as a fact/measure:
-- A retry is when the same card (card_bin + card_last_four) and same amount
-- appear within 5 minutes of a decline from the same merchant.
-- retry_success_flag = 1 when this transaction is Approved AND a prior
-- Declined transaction exists within the window.
retry_attempt_flag,      -- pre-computed in intermediate
retry_success_flag       -- pre-computed in intermediate
```
Add these columns to `int_authorizations__enriched.sql` using window functions, then pass through to `authorizations.sql`. Add a `RETRY_SUCCESS_RATE` metric to the semantic view.

### Pitfall 2: Semantic View Rebuild is Not Automatic
**What goes wrong:** Participant adds the metric to the YAML in `payment_analytics_semantic_view.sql` but doesn't call `SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML`. The old semantic view stays in place. Cortex Agent queries don't use the new metric.
**Why it happens:** Editing a file doesn't deploy it — there's a DDL call required.
**How to avoid:** Verification step must include: run the `CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(...)` statement in a Snowflake Worksheet, then verify the metric appears with `DESCRIBE SEMANTIC VIEW COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS`.

### Pitfall 3: Agent Recreate vs Instruction Update
**What goes wrong:** Participant recreates the agent (`CREATE OR REPLACE AGENT`) with the new instruction but forgets to update the `orchestration.instructions.response` text to mention retry success rate. The agent can answer queries but gives generic responses.
**Why it happens:** The agent DDL (`03_create_agent.sql`) has both the tool spec AND the instructions. Easy to update the tool spec but miss the `instructions.response` field.
**How to avoid:** Guide must explicitly call out: "Update the `response` instruction in `03_create_agent.sql` to mention retry success rate as a queryable metric."

### Pitfall 4: TypeScript Type Not Extended Before Route
**What goes wrong:** The API route (`kpis/route.ts`) returns `retrySuccessRate` in the JSON but the TypeScript interface `AuthorizationKPIs` doesn't include it. TypeScript will compile but the frontend will silently get `undefined` for `kpiData?.retrySuccessRate`.
**Why it happens:** The TypeScript interface and the API route SQL must be updated together.
**How to avoid:** The guide must show both changes together and note that the type in `domain.ts` must be updated first.

### Pitfall 5: Dynamic Table Does Not Auto-Refresh in HOL Timeframe
**What goes wrong:** Participant adds `retry_success_flag` to the intermediate dynamic table. The dynamic table has `+target_lag: '1 hour'`. The participant expects to query the new metric immediately but the table hasn't refreshed yet.
**Why it happens:** Snowflake Dynamic Tables refresh on their configured lag schedule, not on DDL changes.
**How to avoid:** Guide must include a manual refresh step: `ALTER DYNAMIC TABLE COCO_SDLC_HOL.INTERMEDIATE.INT_AUTHORIZATIONS__ENRICHED REFRESH;` and `ALTER DYNAMIC TABLE COCO_SDLC_HOL.MARTS.AUTHORIZATIONS REFRESH;` after applying DDL changes.

### Pitfall 6: Cortex Code CLI Not Available on Windows Without WSL
**What goes wrong:** A Windows participant tries to install Cortex Code CLI natively (without WSL) and the install script fails.
**Why it happens:** Official docs confirm: platforms supported are macOS (arm64/x64), Linux (x64/arm64), Windows (WSL only).
**How to avoid:** Primer section must include a Windows note: "If you are on Windows, you must use WSL (Windows Subsystem for Linux). Open a WSL terminal before running the install script."

### Pitfall 7: /plan Mode and /plan-off Confusion
**What goes wrong:** A participant enables `/plan` at the start of Ticket 1 and doesn't realize it persists throughout the session. In Ticket 2 (new session via `/new`), plan mode is off by default and they expect it to still be on.
**Why it happens:** `/plan` is a session-scoped toggle. `/new` resets the session including mode state.
**How to avoid:** Guide should explicitly state: "Plan mode is session-scoped. After the context switch (/new), enable it again at the start of Ticket 2."

---

## Code Examples

Verified patterns from official sources and codebase examination:

### Cortex Code CLI Plan Mode Enable
```
/plan
```
Source: `docs.snowflake.com/en/user-guide/cortex-code/cli-reference`

### Cortex Code CLI Context Switch (New Session)
```
/new
```
Source: `docs.snowflake.com/en/user-guide/cortex-code/cli-reference` — session management commands

### Cortex Code CLI Model Selection
```
/model
```
Source: `docs.snowflake.com/en/user-guide/cortex-code/cli-reference` — select from Opus 4.6, Sonnet 4.6, etc.

### Semantic View Metric Addition Pattern
```yaml
metrics:
  - name: RETRY_SUCCESS_RATE
    description: Percentage of initially declined transactions successfully retried
    expr: SUM(CASE WHEN AUTHORIZATIONS.RETRY_SUCCESS_FLAG = 1 THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(CASE WHEN AUTHORIZATIONS.RETRY_ATTEMPT_FLAG = 1 THEN 1 ELSE 0 END), 0)
    data_type: NUMBER
    synonyms:
      - retry success rate
      - retry rate
      - declined retry success
```
Source: Existing pattern in `packages/dbt/analyses/payment_analytics_semantic_view.sql` — all existing metrics follow this `expr` + `data_type` + `synonyms` structure.

### Semantic View Rebuild DDL
```sql
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'COCO_SDLC_HOL.MARTS',
  $$ ... updated YAML ... $$,
  FALSE  -- Set TRUE to validate only
);
```
Source: `packages/dbt/analyses/payment_analytics_semantic_view.sql` — existing pattern

### Dynamic Table Manual Refresh
```sql
ALTER DYNAMIC TABLE COCO_SDLC_HOL.INTERMEDIATE.INT_AUTHORIZATIONS__ENRICHED REFRESH;
ALTER DYNAMIC TABLE COCO_SDLC_HOL.MARTS.AUTHORIZATIONS REFRESH;
```
Source: Snowflake docs — dynamic table management

### KPI Card Component Usage (Ticket 2)
```tsx
// In apps/frontend/src/app/analytics/authorization/page.tsx
// Add after existing KPI cards in the <Row gutter={[16, 16]}> block:
<Col xs={24} sm={12} lg={6}>
  <KPICard
    title="Retry Success Rate"
    value={kpiData?.retrySuccessRate ?? 0}
    format="percent"
    description="Percentage of declined transactions that succeeded on retry"
    loading={kpis.isLoading}
    color="#52c41a"
  />
</Col>
```
Source: `apps/frontend/src/components/ui/KPICard.tsx` + `apps/frontend/src/app/analytics/authorization/page.tsx` — existing usage pattern

### TypeScript Interface Extension
```typescript
// In apps/frontend/src/types/domain.ts
export interface AuthorizationKPIs {
  totalTransactions: number;
  approvedCount: number;
  declinedCount: number;
  approvalRate: number;
  totalAmount: number;
  approvedAmount: number;
  avgTicketSize: number;
  retrySuccessRate: number;  // NEW
  trends: {
    transactions: number;
    approvalRate: number;
    amount: number;
  };
}
```
Source: `apps/frontend/src/types/domain.ts` — existing interface

### API Route SQL Extension Pattern
```typescript
// In apps/frontend/src/app/api/analytics/authorization/kpis/route.ts
// Add to the SELECT:
ROUND(
  SUM(CASE WHEN retry_success_flag = 1 THEN 1.0 ELSE 0 END) * 100.0 /
  NULLIF(SUM(CASE WHEN retry_attempt_flag = 1 THEN 1 ELSE 0 END), 0),
2) as retry_success_rate

// Add to the return object:
const kpis = {
  ...
  retrySuccessRate: Number(row.RETRY_SUCCESS_RATE) || 0,
  ...
};
```
Source: `apps/frontend/src/app/api/analytics/authorization/kpis/route.ts` — existing pattern

### Verification Query (Snowflake Worksheet)
```sql
-- Verify retry success rate metric exists in mart
SELECT
  SUM(CASE WHEN retry_success_flag = 1 THEN 1 ELSE 0 END) AS successful_retries,
  SUM(CASE WHEN retry_attempt_flag = 1 THEN 1 ELSE 0 END) AS total_retries,
  ROUND(
    SUM(CASE WHEN retry_success_flag = 1 THEN 1.0 ELSE 0 END) * 100.0 /
    NULLIF(SUM(CASE WHEN retry_attempt_flag = 1 THEN 1 ELSE 0 END), 0),
  2) AS retry_success_rate_pct
FROM COCO_SDLC_HOL.MARTS.AUTHORIZATIONS
WHERE clnt_id = 'dmcl'  -- row-level security filter
  AND transaction_date >= CURRENT_DATE - 30;
```
Source: Codebase patterns — all queries filter by `clnt_id`

### Git Workflow for HOL
```bash
# Ticket 1 branch
git checkout -b feature/retry-success-rate

# After each file change, commit incrementally
git add packages/dbt/models/marts/payments/authorizations.sql
git commit -m "feat(dbt): add retry_success_rate to authorizations mart"

# Push branch
git push -u origin feature/retry-success-rate

# Ticket 2 branch (after /new in Cortex Code)
git checkout -b feature/retry-success-kpi-card

# PR creation (Ticket 2 wrap-up)
gh pr create --title "Add retry success rate KPI card" \
  --body "Adds Retry Success Rate metric end-to-end: dbt mart → semantic view → Cortex Agent → frontend KPI card"
```
Source: Standard git + GitHub CLI workflow

### Cortex Code Suggested Prompts for Ticket 1
```
# After enabling /plan, describe the full ticket scope:
> Read Jira ticket COCO-42. Then look at packages/dbt/models/marts/payments/authorizations.sql,
> packages/dbt/analyses/payment_analytics_semantic_view.sql, and
> packages/database/utilities/03_create_agent.sql.
> I need to add a "retry success rate" metric that measures what percentage
> of transactions that were initially declined succeeded when the customer
> retried. Plan all the changes needed end to end.

# After reviewing the plan, confirm:
> The plan looks good. Execute it.
```

### Cortex Code Suggested Prompts for Ticket 2
```
# After /new and /plan:
> Read Jira ticket COCO-43. Look at
> apps/frontend/src/app/analytics/authorization/page.tsx,
> apps/frontend/src/components/ui/KPICard.tsx, and
> apps/frontend/src/types/domain.ts.
> Add a KPI card that shows the retry_success_rate from the authorization
> KPIs API. Follow the exact same pattern as the existing KPI cards.

> The plan looks good. Execute it.
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Cortex Code CLI in preview | GA with full feature set | Feb 2, 2026 | Safe to use in HOL — stable API |
| Snowflake-only workflows | dbt + Airflow support added | Feb 23, 2026 | Cortex Code understands dbt natively, `/dbt` command available |
| Generic AI coding assistant | AGENTS.md context file support | Feb 2026 | Repo's existing AGENTS.md is automatically loaded — no extra setup |
| Manual semantic view YAML | `SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML` stored procedure | Pre-existing | Already established in codebase |

**Current as of research date (2026-03-02):**
- Cortex Code CLI model options: auto (default), Claude Opus 4.6, Claude Sonnet 4.6, Claude Opus 4.5, Claude Sonnet 4.5
- Recommended model for the HOL: `auto` (Cortex selects highest quality — will use Opus 4.6 for complex tasks)
- Cortex Code Snowsight (in-browser): still in Preview as of research date — guide should use CLI

---

## Open Questions

1. **Retry attempt data in CLX_AUTH**
   - What we know: `CLX_AUTH` has `risk_score`, `approval_status_code`, `card_bin`, `card_last_four`, `transaction_amount`, `merchant_dba_name`, `transaction_timestamp` — enough for a proxy retry detection via self-join
   - What's unclear: Whether there is a dedicated `retry_attempt_id` or `original_auth_id` field in the raw data that was not included in the staging views
   - Recommendation: Guide should define retry detection as a window function (same card_bin + card_last_four + transaction_amount within 5 minutes of a decline). This is deterministic and works with existing data. If a cleaner field exists in CLX_AUTH, Cortex Code will find it when it reads the file.

2. **Jira ticket IDs**
   - What we know: Tickets are pre-created by the instructor; guide references them by ID
   - What's unclear: The actual ticket IDs (e.g., COCO-42, COCO-43) — these must be filled in by the guide author or parameterized as `[TICKET-ID]` placeholders
   - Recommendation: Use `[TICKET-1]` and `[TICKET-2]` as placeholders with an instructor note explaining to replace with actual IDs.

3. **Confluence page URL**
   - What we know: An existing data dictionary page is updated in Ticket 1 step 12
   - What's unclear: The actual Confluence URL and page name
   - Recommendation: Use `[CONFLUENCE-DATA-DICTIONARY-URL]` as a placeholder.

4. **Cortex Code CLI on Windows (non-WSL)**
   - What we know: Official docs say Windows via WSL only
   - What's unclear: Whether Cortex Code has added native Windows support since the GA announcement
   - Recommendation: Guide should note WSL requirement with a fallback: facilitator provides shared terminal or demo machine.

---

## Validation Architecture

`workflow.nyquist_validation` is not set in `.planning/config.json` (the `workflow` object has `research`, `plan_check`, `verifier` keys but no `nyquist_validation` key). Interpreting as false/not applicable — skipping this section.

---

## Sources

### Primary (HIGH confidence)
- `docs.snowflake.com/en/user-guide/cortex-code/cortex-code-cli` — Installation, model list, connection setup, Windows/WSL requirement
- `docs.snowflake.com/en/user-guide/cortex-code/cli-reference` — Slash commands: `/plan`, `/plan-off`, `/new`, `/fork`, `/rewind`, `/model`, `/mcp`, `/skill`, `/bypass`, `/status`
- `docs.snowflake.com/en/user-guide/cortex-code/extensibility` — Skills system, MCP configuration, Jira/GitHub integration pattern
- `docs.snowflake.com/en/user-guide/cortex-code/settings` — settings.json, permissions.json, mcp.json config files, CORTEX_AGENT_MODEL env var
- `docs.snowflake.com/en/release-notes/2026/other/2026-02-02-cortex-code-cli` — GA release, feature list
- Codebase examination: all target files read directly — HIGH confidence on exact APIs, patterns, data shapes

### Secondary (MEDIUM confidence)
- `businesswire.com/news/home/20260223976731/en/Snowflake-Cortex-Code-Expands-Towards-Supporting-Any-Data-Anywhere` — dbt + Airflow native support added Feb 23, 2026. Verified by multiple sources.
- `mechanicalrock.io/blog/taking-snowflake-cortex-code-cli-for-a-spin` — Practical plan mode workflow walkthrough, gotchas (permission errors, warehouse setup). MEDIUM — single third-party source but consistent with official docs.

### Tertiary (LOW confidence)
- WebSearch synthesis on Jira/Confluence MCP configuration specifics. The `cortex mcp add` command form and `mcp.json` location are from official docs (HIGH) but exact Jira/Confluence MCP server configuration syntax was not confirmed from official docs — participants may need to consult `docs.snowflake.com/en/user-guide/cortex-code/extensibility` during the lab.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tools are installed/verified in codebase, Cortex Code CLI docs confirmed
- Architecture: HIGH — all target files examined, data flow fully traced end-to-end
- Pitfalls: HIGH (pitfalls 2-7) / MEDIUM (pitfall 1, retry data model) — most confirmed from code; retry data shape requires assumption
- Code examples: HIGH — all examples derived from existing codebase patterns or official docs

**Research date:** 2026-03-02
**Valid until:** 2026-04-02 (Cortex Code CLI is actively evolving — re-verify slash commands if more than 30 days elapse)
