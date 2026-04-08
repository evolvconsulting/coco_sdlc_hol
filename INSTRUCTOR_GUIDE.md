# Instructor Reference Guide — AI-Assisted SDLC HOL

**Instructor-only.** Live-use reference during the session. Companion to LAB_INSTRUCTIONS.md (participant guide) and INFRASTRUCTURE.md (pre-lab setup).

**How to use:** Step numbers here mirror LAB_INSTRUCTIONS.md exactly — when a participant says "I'm on step 4.3," look it up here instantly.

**Total duration:** ~90 min

---

## Section 1: Environment Setup Verification (~5 min)

**Step 0 — Fork and Clone the Lab Repository**

Participant action: Fork `evolvconsulting/coco_sdlc_hol` on GitHub, then clone their own fork:

```bash
git clone https://github.com/<their-username>/coco_sdlc_hol.git
cd coco_sdlc_hol
```

> Watch for: Participants who skip this step will hit errors in Step 3 (missing `apps/frontend`) and Section 3 (Cortex Code won't find `AGENTS.md`).
> Watch for: Participant cloned the upstream URL (`evolvconsulting/coco_sdlc_hol`) instead of their fork — push in Step 4.11 will fail with "permission denied" or "protected branch." Diagnose with `git remote -v`; origin must show their username. Fix: `git remote set-url origin https://github.com/<their-username>/coco_sdlc_hol.git`.
> Watch for: Participant skipped forking entirely — same push-failure symptom. Have them fork first on GitHub, then re-clone or update their remote with the fix command above.

---

**Step 1 — Temporarily Bypass MFA**

Each participant logs in to Snowsight and runs:

```sql
ALTER USER USER SET MINS_TO_BYPASS_MFA = 720;
```

(Replace `USER` with their actual username if it differs.) This grants a 12-hour MFA bypass window so Cortex Code CLI connections don't trigger MFA prompts.

> Watch for: Participant skips this step — the Cortex Code setup wizard may trigger an MFA prompt that blocks the connection flow. Have them go back and run the ALTER USER command in Snowsight.

---

**Step 2 — Configure and Confirm Snowflake Connection**

Each attendee launches Cortex Code CLI, which triggers the first-run setup wizard to create a Snowflake connection.

From the cloned repository root:
```bash
cortex
```

The setup wizard presents connection options. Attendees select **"More options"** to create a new connection:

| Prompt | Value |
|--------|-------|
| Connection name | `coco-hol` (attendee's choice) |
| Account identifier | Provide per-attendee (format: `orgname-accountname`) |
| Username | `USER` (unless you specify otherwise) |
| Authentication method | Password (`snowflake`) |

Once connected, attendees set session context and verify:
```
Set my role to ATTENDEE_ROLE, warehouse to COMPUTE_WH, and use database COCO_SDLC_HOL with schema MARTS.
```

Then:
```
/status
```

Expected output: `ATTENDEE_ROLE` as role, `COCO_SDLC_HOL` as database, `MARTS` as schema.

> Watch for: Role shows as SYSADMIN or empty — attendee needs to run `USE ROLE ATTENDEE_ROLE;` via `/sql`.
> Watch for: "Account not found" or "invalid account" in the wizard — check the account identifier format with the attendee (must be `orgname-accountname`, not a URL).
> Watch for: If password auth fails, confirm the username and password with the attendee.
> Watch for: Connection saved to `~/.snowflake/connections.toml` — if attendee needs to redo, they can edit or delete that file and re-run `cortex`.

**Step 2c — Configure Local Project Files**

Participant asks Cortex Code:
```
Update SNOWFLAKE_ACCOUNT in apps/frontend/.env.local and the account field in packages/dbt/profiles.yml with my account identifier <orgname-accountname>.
```

Expected behavior: Cortex Code reads both files and replaces the placeholder values with the participant's account identifier.

> Watch for: Participant uses a URL instead of `orgname-accountname` format — same format as the wizard in Step 2a.

---

**Step 3 — Confirm Local App Runs**

Participant asks Cortex Code:
```
Install the frontend dependencies and start the dev server from apps/frontend.
```

Expected output: Dashboard loads at http://localhost:3000 with real transaction data.

> Watch for: Dashboard loads but shows no data — check `.env.local` SNOWFLAKE_ACCOUNT value.

---

## Section 2: Cortex Code Primer (~10 min)

Sections 2.1 and 2.2 are instructor-led explanations — no participant inputs.

**Step 2.3 — Install Atlassian MCP**

Participants must exit Cortex Code first (`/exit`), then run the MCP registration command in the terminal:

```bash
cortex mcp add atlassian https://mcp.atlassian.com/v1/mcp -t http -H "Authorization: Basic dHJlbnQuZm9sZXlAZXZvbHZjb25zdWx0aW5nLmNvbTpBVEFUVDN4RmZHRjBzRlNUanJfUFhtcTNmXzZpUjNOZDdnSWtsMDUweG92Vk5Nc2xMTTZ1bTlyb1lLelBpU2NsbUFoQjEzdjUzVzdiQ2xvamk3MHQwcEFITUdkZE9VZEcwY3E0RnhqM1BCNmo5R0NKbjl2bTVUMENzMVpnOEdJQk5veXVrUDVoQXF0SFZSMWY0Qmo0X2pYOUw0YmNRd2x6cWZ1RWhHVVV6VndJS2FTYVgtRy1RZG89NzU1RUY3RDU="
```

> Watch for: Participant runs `cortex mcp add` inside Cortex Code — it must be run in the terminal. Have them `/exit` first.
> Watch for: "command not found" for `cortex mcp add` — Cortex Code CLI not installed. Have attendee install it (see Prerequisites in LAB_INSTRUCTIONS.md) and restart terminal.

---

## Section 3: Architecture Overview (~10 min)

Participants use Cortex Code interactively to explore the architecture — this replaces a static instructor-led walkthrough.

**Step 3.1 — Explore the Architecture with Cortex Code**

Participants relaunch Cortex Code from the repository root (`cortex`), then ask:

```
Describe this project's data architecture and the Cortex Agent setup. What database, schemas, layers, domain tables, semantic view, and metrics are configured?
```

Expected behavior: Response mentions `COCO_SDLC_HOL` and the medallion architecture (RAW, STAGING, INTERMEDIATE, MARTS) with domain tables, plus the `PAYMENT_ANALYTICS` semantic view and `PAYMENT_ANALYTICS_AGENT` with 10 metrics — all sourced from `AGENTS.md`.

> Watch for: Response is generic and doesn't mention COCO_SDLC_HOL — Cortex Code must be launched from repo root, not a subdirectory. If participants haven't cloned yet (missed Step 0), stop and have them do that first.
> Call out to group: Cortex Code reads `AGENTS.md` automatically — this is how it knows the project architecture without being told.

---

## Section 4: Task 1 — Add Retry Success Rate Metric (~30 min)

**Step 4.1 — Read the Jira Ticket**

In Cortex Code (still running from Section 3):
```
Show me Jira ticket EPA-2. What does it ask me to implement?
```

---

**Step 4.2 — Create Feature Branch**

```
Create a new git branch called feature/retry-success-rate and switch to it.
```

---

**Step 4.3 — Enable Plan Mode and Describe Task**

```cortex
/plan
```

Then:
```
Add a retry success rate metric to the authorizations domain. A retry is when a declined transaction is re-attempted and approved. Update the dbt models, semantic view, and Cortex Agent instructions. Read the relevant files first.
```

> Watch for: Plan shows only 2-3 files — prompt to expand scope.

[If plan misses intermediate model or agent file]:
```
Please also include changes to the intermediate model (int_authorizations__enriched.sql) for the retry detection logic and the Cortex Agent instructions (03_create_agent.sql).
```

> Call out to group: Plan mode — Cortex Code shows what it will do before doing it. This is your review gate.

---

**Step 4.4 — Confirm and Execute Plan**

```
The plan looks good. Execute it.
```

---

**Step 4.5 — dbt Model Update (if retry logic missing)**

[If Cortex Code's plan doesn't include retry detection SQL]:
```
Add retry detection logic in int_authorizations__enriched.sql using a window function. Flag transactions where the same card and amount retry within 5 minutes of a decline. Add retry_attempt_flag and retry_success_flag columns.
```

---

**Step 4.6 — dbt Materialization Check** _(no participant input)_

> Watch for: Any suggestion to change materialization type — existing types (staging=view, intermediate=dynamic table, marts=dynamic table) must be preserved.

---

**Step 4.7 — dbt Unit Tests** _(no participant input)_

_(Cortex Code may update tests automatically — review for correctness. No manual prompt needed in lab environment.)_

---

**Step 4.8 — Review Semantic View Update** _(no participant input)_

_(Cortex Code applies RETRY_SUCCESS_RATE metric automatically as part of plan execution. Review output for correct metric structure.)_

---

**Step 4.9 — Review Cortex Agent Instruction Change** _(no participant input)_

_(Cortex Code updates 03_create_agent.sql automatically. Verify instruction text mentions "retry success rate".)_

---

**Step 4.10a — Apply DDL and Refresh Dynamic Tables**

Participant prompt to Cortex Code:
```
Deploy my dbt changes to Snowflake and refresh the intermediate and marts dynamic tables.
```

Expected behavior: Cortex Code runs the compiled DDL and executes `ALTER DYNAMIC TABLE ... REFRESH` on both `INT_AUTHORIZATIONS__ENRICHED` and `AUTHORIZATIONS`. Participant sees confirmation that both tables were updated.

> Watch for: Cortex Code skips the refresh — remind participant to re-prompt asking it to also refresh the dynamic tables.
> Watch for: DDL fails with "insufficient privileges" — attendee's connection is not using ATTENDEE_ROLE (re-check Step 1).

---

**Step 4.10b — Rebuild Semantic View and Verify**

Participant prompt to Cortex Code:
```
Rebuild the semantic view from the updated DDL file and verify that RETRY_SUCCESS_RATE now appears as a metric.
```

Expected behavior: Cortex Code runs the semantic view DDL from `payment_analytics_semantic_view.sql` and shows DESCRIBE output with `RETRY_SUCCESS_RATE` in the metrics list.

> Watch for: Metric missing from DESCRIBE — Cortex Code may have run an older cached version. Ask participant to re-prompt specifying the file path explicitly.

> Call out to group: Metric is now live in the semantic view — Cortex Agent can answer questions about it.

---

**Step 4.10c — Verify Metric Data**

Participant prompt to Cortex Code:
```
Query the authorizations mart and show me the retry success rate for the last 30 days.
```

Expected behavior: Non-null retry_success_rate_pct value (typically 20-80%).

> Watch for: Zero rows or null values — Cortex Code may have omitted the `clnt_id = 'dmcl'` filter. Ask participant to re-prompt with "for clnt_id dmcl".

---

**Step 4.10d — Test Cortex Agent**

```
What is the retry success rate for the last 30 days?
```

Expected behavior: Cortex Agent generates SQL using RETRY_SUCCESS_RATE metric and returns a meaningful answer.

> Call out to group: Full stack connected — one natural language question, Cortex generates the SQL automatically.

---

**Step 4.11 — Commit and Push**

```
Commit all changes in packages/dbt/ and packages/database/ with message "feat(dbt): add retry_success_rate metric" and push to origin.
```

---

**Step 4.12 — Reference Confluence Data Dictionary**

```
Read the Confluence data dictionary at https://evolv-coco-sdlc-hol.atlassian.net/wiki/spaces/EPA/pages/851970/Data+Dictionary+-+Authorizations. How should I document retry_success_rate to match the existing format?
```

---

## Section 5: Context Switch (~2 min)

**Clear Context**

```cortex
/new
```

> Call out to group: Context hygiene — clear stale context before switching tasks. Clean context = better AI suggestions.

> Watch for: After /new, plan mode is off. Participants must re-enable /plan at the start of Task 2.

---

## Section 6: Task 2 — Add KPI Card to Dashboard (~20 min)

**Step 6.1 — Read the Jira Ticket**

```
Show me Jira ticket EPA-3. What does it ask me to implement?
```

---

**Step 6.2 — Create Feature Branch**

```
Create a new git branch called feature/retry-success-kpi-card and switch to it.
```

---

**Step 6.3 — Enable Plan Mode and Describe Task**

```cortex
/plan
```

Then:
```
Read Jira ticket EPA-3 and add a retry success rate KPI card to the authorization dashboard. Follow the same pattern as the existing KPI cards.
```

> Watch for: Plan order wrong — TypeScript interface (domain.ts) must be updated BEFORE API route and page component. If page.tsx appears first, ask Cortex Code to reorder.

> Watch for: Plan mode is session-scoped — after /new, participants must re-enable /plan. If Cortex Code starts executing immediately, remind them.

---

**Step 6.4 — Execute the Plan**

```
The plan looks good. Execute it.
```

---

**Step 6.5 — Verify Locally**

```
Start the frontend dev server from apps/frontend.
```

Open http://localhost:3000/analytics/authorization. Expected behavior: "Retry Success Rate" KPI card visible, showing a percentage value with green color indicator.

> Watch for: Card shows 0 or undefined — use debug prompt below.

> Call out to group: Ticket 1 became Ticket 2's data source — same metric, different surface, full SDLC cycle complete.

[If KPI card shows 0]:
```
The retry success rate KPI card is showing 0. Check that the AuthorizationKPIs interface in domain.ts includes retrySuccessRate and that the API route in kpis/route.ts returns the field.
```

---

**Step 6.6 — Commit and Push**

```
Commit all frontend changes with message "feat(frontend): add retry success rate KPI card" and push to origin.
```

---

**Step 6.7 — Create a Pull Request**

```
Create a GitHub pull request for this branch. Title: "Add retry success rate KPI card". Describe what was changed and why.
```

> Call out to group: Jira ticket read at the start, PR created at the end — full development loop without leaving the terminal.

_Lab complete._

---

## Quick-Reference Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| `cortex: command not found` | CLI not in PATH | `curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh \| sh` then restart terminal |
| Dynamic table shows old data | Refreshes on schedule, not on DDL | Ask Cortex Code: `ALTER DYNAMIC TABLE ... REFRESH;` (Step 4.10a) |
| Semantic view metric not found | YAML updated but view not rebuilt | Ask Cortex Code to rerun semantic view DDL (Step 4.10b) |
| KPI card shows 0 or undefined | TypeScript interface not updated | Add `retrySuccessRate: number` to `AuthorizationKPIs` in `domain.ts` |
| Cortex Agent gives generic answer | Agent instructions not updated | Rerun `03_create_agent.sql` with updated `instructions.response` |
| `/plan` mode off after `/new` | Plan mode is session-scoped | Re-enable with `/plan` in each new session |
| Verification query returns empty | Missing `clnt_id` filter | Add `WHERE clnt_id = 'dmcl'` to all verification queries |
