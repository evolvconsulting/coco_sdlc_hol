# Instructor Reference Guide — AI-Assisted SDLC HOL

**Instructor-only.** Live-use reference during the session. Companion to LAB_INSTRUCTIONS.md (participant guide) and INFRASTRUCTURE.md (pre-lab setup).

**How to use:** Step numbers here mirror LAB_INSTRUCTIONS.md exactly — when a participant says "I'm on step 4.3," look it up here instantly.

**Total duration:** ~90 min

---

## Section 1: Architecture Overview (~10 min)

Instructor-led architecture walkthrough — no participant inputs.

---

## Section 2: Environment Setup Verification (~5 min)

**Step 0 — Clone the Lab Repository**

```bash
git clone https://github.com/evolvconsulting/coco_sdlc_hol.git
cd coco_sdlc_hol
```

> Watch for: Participants who skip this step will hit errors in Step 2 (missing `apps/frontend`) and Step 3.5 (Cortex Code won't find `AGENTS.md`).

---

**Step 1 — Configure and Confirm Snowflake Connection**

Each attendee creates their own named connection with `snow connection add`, then verifies it.

Prompts and recommended values:

| Prompt | Value |
|--------|-------|
| Connection name | `coco-hol` (attendee's choice) |
| Account name | Provide per-attendee (format: `orgname-accountname`) |
| Username | Provide per-attendee |
| Authenticator | `externalbrowser` (SSO) or `snowflake` |
| Role | `ATTENDEE_ROLE` |
| Warehouse | `COMPUTE_WH` |
| Database | `COCO_SDLC_HOL` |
| Schema | `MARTS` |

Verification command (attendee substitutes their chosen connection name):
```bash
snow sql -c <their-connection> -q "SELECT CURRENT_ROLE(), CURRENT_DATABASE(), CURRENT_SCHEMA();"
```

Expected output:
```
+----------------+--------------------+------------------+
| CURRENT_ROLE() | CURRENT_DATABASE() | CURRENT_SCHEMA() |
+----------------+--------------------+------------------+
| ATTENDEE_ROLE  | COCO_SDLC_HOL      | MARTS            |
+----------------+--------------------+------------------+
```

> Watch for: Role must be ATTENDEE_ROLE — if SYSADMIN or empty, `snow connection add` skipped the Role field.
> Watch for: Browser auth window does not open — attendee may need to run `snow connection add` again and choose `snowflake` authenticator instead.
> Watch for: "Account not found" or "invalid account" — check the account identifier format with the attendee (must be `orgname-accountname`, not a URL).

---

**Step 2 — Confirm Local App Runs**

```bash
cd apps/frontend && npm install && npm run dev
```

Expected output: `> Ready on http://localhost:3000`

> Watch for: Dashboard loads but shows no data — check `.env.local` SNOWFLAKE_ACCOUNT value.

---

**Step 3 — Confirm Cortex Code CLI Installed**

```bash
cortex --version
```

Expected output: version string (e.g., `cortex 1.x.x`)

> Watch for: "command not found" after install — instruct to restart terminal.

[If not installed — fallback]:
```bash
curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh
```

---

## Section 3: Cortex Code Primer (~10 min)

Sections 3.1 and 3.2 are instructor-led explanations — no participant inputs.

**Step 3.3 — Install Jira MCP Skill**

```bash
cortex mcp add jira --url https://evolv-coco-sdlc-hol.atlassian.net --auth-token ATATT3xFfGF0D7Aiugi8RrvbyL4UHnMz-wrOpVZkykXnM7OQcUWgruzWN1HreG_iWhaVD9vfsuE_ZAtDIgTHG3xjRmue861sVE3v2nVs1_uqhjQ_XRsx4eSKVV1Zr8FFLZ1BMOdtusft0jPXZcrZkzmbA_KfOLjXOGDWqoNiKFkw-bRxuM5-iCU=64649D40
```

[Alternative — interactive]:
```
/mcp
```
(then follow prompts to add Jira server)

---

**Step 3.4 — Install Confluence MCP Skill**

```bash
cortex mcp add confluence --url https://evolv-coco-sdlc-hol.atlassian.net --auth-token ATATT3xFfGF0JmTTc6yxUOmZbKA0ZlbDtsH8KZv3pijAYQ3Su0tUGnz7xODTQiYe16J1Xvz7nl6o-GtkOgkX0LWGcl-VcjygrFz9KNcAqDJqvOZlNyvmGn_ozYe5Bedn8QRqi2_nAMOaUNniftWkIYqNrHke4d09m0BnOJGfpUdLDOjwO-TWDq0=363884CD
```

---

**Step 3.5 — Quick Test — Verify Cortex Code Reads Repo Context**

Participants should already be in the cloned repo root (from Step 0).

```bash
cortex
```

Then in Cortex Code:
```
What database and schema does this project use?
```

Expected behavior: Response mentions `COCO_SDLC_HOL` and the medallion architecture (RAW, STAGING, INTERMEDIATE, MARTS).

> Watch for: Response is generic and doesn't mention COCO_SDLC_HOL — Cortex Code must be launched from repo root, not a subdirectory. If participants haven't cloned yet (missed Step 0), stop and have them do that first.

---

## Section 4: Task 1 — Add Retry Success Rate Metric (~30 min)

**Step 4.1 — Launch Cortex Code and Read Ticket**

```bash
cortex
```

Then in Cortex Code:
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
I need to add a retry success rate metric to the authorizations domain. Retry success rate = count of transactions where a customer was initially declined then approved on a subsequent attempt. Add this to the dbt mart, the semantic view, and update the Cortex Agent instructions. Start by reading the relevant files.
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
Add the retry detection logic as a window function in int_authorizations__enriched.sql. A retry is when the same card_bin, card_last_four, and transaction_amount appear from the same merchant within 5 minutes of a declined transaction. Add retry_attempt_flag and retry_success_flag columns.
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
Deploy my dbt model changes to Snowflake and manually refresh the intermediate and marts dynamic tables so the new retry columns have data right away.
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
Commit all changes in packages/dbt/ and packages/database/ with the message "feat(dbt): add retry_success_rate to authorizations mart and semantic view". Then push to origin.
```

---

**Step 4.12 — Reference Confluence Data Dictionary**

```
Read the Confluence data dictionary page at https://evolv-coco-sdlc-hol.atlassian.net/wiki/spaces/EPA/pages/851970/Data+Dictionary+-+Authorizations. What metrics are currently documented? How should I document the new retry_success_rate metric to match the existing format?
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
Read Jira ticket EPA-3. Look at apps/frontend/src/app/analytics/authorization/page.tsx, apps/frontend/src/components/ui/KPICard.tsx, and apps/frontend/src/types/domain.ts. Add a KPI card that shows the retry_success_rate from the authorization KPIs API. Follow the exact same pattern as the existing KPI cards.
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
Commit all changes in apps/frontend/ with the message "feat(frontend): add retry success rate KPI card to authorization dashboard". Then push to origin.
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
