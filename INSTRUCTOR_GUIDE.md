# Instructor Reference Guide — AI-Assisted SDLC HOL

**Instructor-only.** Live-use reference during the session. Companion to LAB_INSTRUCTIONS.md (participant guide) and INFRASTRUCTURE.md (pre-lab setup).

**How to use:** Step numbers here mirror LAB_INSTRUCTIONS.md exactly — when a participant says "I'm on step 4.3," look it up here instantly.

**Total duration:** ~90 min

---

## Section 1: Architecture Overview (~10 min)

Instructor-led architecture walkthrough — no participant inputs.

---

## Section 2: Environment Setup Verification (~5 min)

**Step 1 — Confirm Snowflake Connection**

```bash
snow sql -c ennovate -q "SELECT CURRENT_ROLE(), CURRENT_DATABASE(), CURRENT_SCHEMA();"
```

Expected output:
```
+----------------+--------------------+------------------+
| CURRENT_ROLE() | CURRENT_DATABASE() | CURRENT_SCHEMA() |
+----------------+--------------------+------------------+
| ATTENDEE_ROLE  | COCO_SDLC_HOL      | MARTS            |
+----------------+--------------------+------------------+
```

> Watch for: Role must be ATTENDEE_ROLE — if SYSADMIN, connection profile is wrong.

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

```bash
cortex
```

Then in Cortex Code:
```
What database and schema does this project use?
```

Expected behavior: Response mentions `COCO_SDLC_HOL` and the medallion architecture (RAW, STAGING, INTERMEDIATE, MARTS).

> Watch for: Response is generic and doesn't mention COCO_SDLC_HOL — Cortex Code must be launched from repo root, not a subdirectory.

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

```
Run the compiled CREATE OR REPLACE DYNAMIC TABLE statements from the modified dbt models against Snowflake to apply the new columns. Then refresh both dynamic tables so the data is immediately available: ALTER DYNAMIC TABLE COCO_SDLC_HOL.INTERMEDIATE.INT_AUTHORIZATIONS__ENRICHED REFRESH; and ALTER DYNAMIC TABLE COCO_SDLC_HOL.MARTS.AUTHORIZATIONS REFRESH;
```

Expected behavior: Confirmation that both tables were updated.

> Watch for: Confirmation message missing — without refresh, new columns have no data.

---

**Step 4.10b — Rebuild Semantic View and Verify**

```
Run the updated semantic view DDL from packages/dbt/analyses/payment_analytics_semantic_view.sql against Snowflake. Then run DESCRIBE SEMANTIC VIEW COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS and confirm RETRY_SUCCESS_RATE appears in the metrics list.
```

Expected behavior: RETRY_SUCCESS_RATE appears in DESCRIBE output.

> Watch for: Metric missing — ask Cortex Code to re-run the semantic view DDL manually.

> Call out to group: Metric is now live in the semantic view — Cortex Agent can answer questions about it.

---

**Step 4.10c — Verify Metric Data**

```
Query the AUTHORIZATIONS mart to verify the retry columns contain data. Calculate successful_retries, total_retries, and retry_success_rate_pct for clnt_id = 'dmcl' over the last 30 days.
```

Expected behavior: Non-null retry_success_rate_pct value (typically 20-80%).

> Watch for: Zero rows — all queries must filter `clnt_id = 'dmcl'`.

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
