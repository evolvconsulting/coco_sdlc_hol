# Hands-On Lab: AI-Assisted SDLC with Cortex Code (Snowsight Path)

**Duration:** ~90 minutes
**Format:** Guided, hands-on development using Cortex Code in Snowsight (no CLI required)

> **CLI path:** If you have Snow CLI and Cortex Code CLI installed locally, use `LAB_INSTRUCTIONS_CLI.md` instead.

> **Visual overview:** Open `lab_flow.html` in your browser for an interactive step-by-step diagram and path comparison before starting.

## What You Will Build

The solution you are working on is a **payments analytics platform** built on Snowflake. It processes transaction data — including payment attempts, retries, and outcomes — and exposes key metrics through a natural language Cortex Agent and a Streamlit dashboard, enabling business users to query payment performance without writing SQL.

In this lab, you will add a **retry success rate** metric end-to-end across the full data stack, working through two Jira tickets using Snowflake's AI coding assistant, Cortex Code:

- **Ticket 1 (~30 min):** Add the retry success rate metric to the dbt mart, semantic view, and Cortex Agent — making it queryable via natural language.
- **Ticket 2 (~20 min):** Add a KPI card to the Streamlit dashboard that displays the new metric.

By the end, you will have experienced AI-assisted development across every layer of the stack: dbt model, dynamic table, semantic view, Cortex Agent, and Streamlit dashboard — entirely inside Snowsight.

## Prerequisites

**You only need a Snowflake account.** No local tools required.

Your instructor will provide:
- Snowflake account URL
- Username (e.g. `HOL_USER_03`)
- Password

---

## Section 1: Environment Setup (~5 min)

### Step 1.1: Log Into Snowsight

Open Snowsight using the account URL provided by your instructor. Log in with your HOL credentials:

- **Username:** Your assigned user — e.g. `HOL_USER_03`
- **Password:** Provided by your instructor

### Step 1.2: Confirm the App Runs

Before making any changes, verify the baseline dashboard is working. In the left navigation go to **Projects → Streamlit** and open `PAYMENT_ANALYTICS_DASHBOARD` (listed under your assigned database).

You should see the Payment Analytics dashboard with real transaction data — 4 KPI cards, charts, and the date/brand filters in the sidebar. You will return here after Task 2 to verify your new KPI card.

### Step 1.3: Open Cortex Code and Set Session Context

In Snowsight, open **AI & ML → Cortex Code** (or click the Cortex Code icon in the left navigation). Replace `NN` with your assigned number (e.g. `03` for `HOL_USER_03`) and paste:

```
Set my role to HOL_ROLE_NN, warehouse to HOL_WH_NN, and use database COCO_SDLC_HOL_NN with schema MARTS.
```

Run `/status` to confirm. You should see `HOL_ROLE_NN` as the role and `COCO_SDLC_HOL_NN` as the database.

### Step 1.4: Open Your Workspace

In Cortex Code, paste:

```
open HOL_WORKSPACE
```

The file tree on the left shows the full project — dbt models, SQL utilities, and context files. This is your editing environment for the lab.

> **Note:** Cortex Code reads `AGENTS.md` from your workspace automatically. This file contains the full architecture context — Snowflake connection details, table schema, business rules, and key file paths.

---

## Section 2: Cortex Code UI Primer (~5 min)

### 2.1 What is Cortex Code

Cortex Code is Snowflake's AI coding assistant. In the Snowsight UI, it:

- **Reads your workspace files** to understand your project's data architecture and business rules
- **Executes SQL** against your Snowflake environment directly
- **Edits files** in your workspace and proposes changes for your review
- **Answers questions** about your data stack, schema, and code

### 2.2 Key Features in the UI

| Feature | How to use |
|---------|-----------|
| Plan mode | Ask Cortex Code to "use plan mode" or "show me a plan before making changes" |
| File context | Cortex Code reads workspace files automatically — no setup needed |
| SQL execution | Ask Cortex Code to run SQL — it executes in your session context |
| Code edits | Cortex Code proposes edits; click **Apply** to accept or **Dismiss** to reject |

### 2.3 Jira Access

Since MCP is not available in the Snowsight UI, you will use a Jira lookup function instead. In Section 4, you will ask Cortex Code to create a `GET_JIRA_TICKET` function that connects to the Atlassian REST API. Once created, you can retrieve any ticket by asking Cortex Code or by calling the function directly.

---

## Section 3: Architecture Overview (~5 min)

### 3.1 Explore the Architecture with Cortex Code

In the Cortex Code UI, ask:

```
Describe this project's data architecture and the Cortex Agent setup. What database, schemas, layers, domain tables, semantic view, and metrics are configured?
```

**Expected behavior:** Cortex Code should describe the medallion architecture (RAW → STAGING → INTERMEDIATE → MARTS), the domain tables, the materialization strategy, and the `PAYMENT_ANALYTICS` semantic view with its 10 metrics — all sourced from the workspace files.

### 3.2 Architecture Reference

**Medallion Pattern:**

```
RAW → STAGING (views) → INTERMEDIATE (dynamic tables) → MARTS (dynamic tables)
```

| Layer | Schema | Materialization | Purpose |
|-------|--------|-----------------|---------|
| **RAW** | `RAW` | Tables | Source data as-is from upstream systems |
| **STAGING** | `STAGING` | Views | Light transformations: renaming, casting, basic filters |
| **INTERMEDIATE** | `INTERMEDIATE` | Dynamic Tables | Business logic: joins, enrichment, derived columns |
| **MARTS** | `MARTS` | Dynamic Tables | Final business-ready tables exposed to BI and AI |

**Domain Tables:**

| Domain | RAW Table | MARTS Table | Key Measures |
|--------|-----------|-------------|--------------|
| Authorization | `CLX_AUTH` | `AUTHORIZATIONS` | transaction_amount, approval_status, transactions_count |
| Settlement | `CLX_SETTLE` | `SETTLEMENTS` | net_amount, sales_count, refund_count |
| Funding | `CLX_FUND` | `DEPOSITS` | deposit_amount, net_sales_amount, total_fees_amount |
| Chargeback | `CLX_CBK` | `CHARGEBACKS` | dispute_amount, disputes_count, outcome |
| Retrieval | `CLX_RTRVL` | `RETRIEVALS` | retrieval_amount, retrievals_count, retrieval_status |
| Adjustment | `CLX_ADJ` | `ADJUSTMENTS` | adjustment_amount, adjustment_type |
| Merchants | `CLX_MRCH_MSTR` | `DIM_MERCHANTS` | merchant_name, city, state, mcc_code |

**Cortex Agent and Semantic View:**

- **Semantic View:** `COCO_SDLC_HOL_NN.MARTS.PAYMENT_ANALYTICS`
- **Cortex Agent:** `COCO_SDLC_HOL_NN.MARTS.PAYMENT_ANALYTICS_AGENT`
- **Metrics:** 10 pre-defined calculations (approval_rate, chargeback_win_rate, effective_fee_rate, etc.)

During the lab, you will add `RETRY_SUCCESS_RATE` to this semantic view and verify the Cortex Agent can answer questions about it.

---

## Section 4: Task 1 — Add Retry Success Rate Metric (~30 min)

In this task, you will add a new business metric — retry success rate — that measures what percentage of initially declined transactions succeeded when the customer retried. You will modify the dbt data model, the semantic view, the Cortex Agent instructions, and verify the change in Snowflake.

### Step 4.1: Set Up Jira Access

Because MCP is not available in the Snowsight UI, you will create a `GET_JIRA_TICKET` function that calls the Atlassian REST API. This only needs to be done once.

In the Cortex Code UI, run the following three prompts in order:

---

**Prompt 1 — Create the UDF:**

> Create a Python UDF called `GET_JIRA_TICKET(issue_key VARCHAR)` in `COCO_SDLC_HOL_NN.PUBLIC` (substitute `NN` with your user number). It should call the Jira REST API and return the ticket type, summary, status, and description as plain text.
>
> Use these details:
> - REST API: `https://api.atlassian.com/ex/jira/310bd229-0685-4130-a7cc-f994764ba475/rest/api/3/issue/{issue_key}`
> - Auth: Basic auth — the token is stored in `HOL_SHARED.PUBLIC.ATLASSIAN_TOKEN_SECRET` (TYPE = GENERIC_STRING, already Base64-encoded)
> - External access integration: `ATLASSIAN_EAI`
> - Runtime: Python 3.11

> **Note:** If Cortex Code asks which database to use, select `COCO_SDLC_HOL_NN` (your own HOL database, not `HOL_SHARED`).

---

**Prompt 2 — Update the agent:**

> Add a `JiraLookup` tool to `COCO_SDLC_HOL_NN.MARTS.PAYMENT_ANALYTICS_AGENT` that calls `COCO_SDLC_HOL_NN.PUBLIC.GET_JIRA_TICKET`. Update the agent instructions to tell it to use JiraLookup when the user asks about a Jira ticket or implementation requirements.

---

**Prompt 3 — Read the Ticket:**

> Show me Jira ticket EPA-2. What does it ask me to implement?

---

The agent will use the `JiraLookup` tool to retrieve the ticket. Review the acceptance criteria before proceeding.

**Prompt 4 — Implement the Metric:**

```
Based on the EPA-2 Jira ticket requirements, implement the retry success rate metric: add retry_attempt_flag and retry_success_flag columns to int_authorizations__enriched.sql using a window function (same card/amount/merchant within 5 minutes of a prior decline), pass both flags through in authorizations.sql, add the RETRY_SUCCESS_RATE metric to payment_analytics_semantic_view.sql, and update the Cortex Agent instructions in 03_create_agent.sql. Do not run dbt compile, dbt deps, or any dbt CLI commands after making the changes.
```

Cortex Code will edit 4 files:

- `int_authorizations__enriched.sql` — adds `retry_attempt_flag` and `retry_success_flag` via window function
- `authorizations.sql` — passes the two flags through to the marts layer
- `payment_analytics_semantic_view.sql` — adds `RETRY_SUCCESS_RATE` metric
- `03_create_agent.sql` — updates agent instructions to include retry success rate

A **Changed N files** banner appears at the bottom — click **Keep all** to accept all edits at once.

### Step 4.2: Deploy from Workspace

Ask Cortex Code to deploy your workspace edits and run the dbt project:

```
Deploy my workspace edits: add a new version (no alias) from HOL_WORKSPACE using versions/live, then execute the dbt project with ARGS = 'run --select int_authorizations__enriched+ --full-refresh'. Do not add a VERSION clause to EXECUTE DBT PROJECT.
```

Cortex Code will run two statements in order:

1. `ALTER DBT PROJECT ... ADD VERSION FROM 'snow://workspace/.../versions/live'` — packages the current live workspace state (your Cortex Code edits) into a new project version
2. `EXECUTE DBT PROJECT ... ARGS = 'run --select int_authorizations__enriched+ --full-refresh'` — rebuilds only the intermediate and marts dynamic tables with the new columns

> **Important:** The prompt explicitly requests `versions/live`. This ensures your workspace edits are packaged — `versions/last` only snapshots explicitly committed workspace versions and will miss Cortex Code file changes.

> **Note:** The `--select int_authorizations__enriched+` scope skips staging views. `HOL_ROLE_NN` does not have `CREATE VIEW` on the STAGING schema — running without `--select` would fail.

> **Note:** Dynamic tables begin refreshing automatically after the dbt project runs. This may take 2–3 minutes.

### Step 4.3: Rebuild Semantic View and Cortex Agent

```
Execute the semantic view DDL from packages/dbt/analyses/payment_analytics_semantic_view.sql and the Cortex Agent DDL from packages/database/utilities/03_create_agent.sql against my database.
```

> **Note:** These files are not executed by `EXECUTE DBT PROJECT` — they must be applied separately as DDL statements.

### Steps 4.4–4.5: Verify

```
Verify the retry success rate metric end-to-end: query MARTS.AUTHORIZATIONS directly for the retry success rate over the last 30 days using retry_attempt_flag and retry_success_flag, then ask the PAYMENT_ANALYTICS_AGENT the same question and confirm both return a consistent non-null percentage.
```

**Expected:** A percentage value between 20% and 80%. If the direct query returns null, the dynamic table is still refreshing — wait 2–3 minutes and retry.

> **Note:** Cortex Code validates the agent by querying the `PAYMENT_ANALYTICS` semantic view via Cortex Analyst — the same underlying engine the agent uses. You will see "Cortex Analyst" in the output rather than a literal agent call; both paths exercise the same metric.

---

## Section 5: Context Switch (~2 min)

Before starting Task 2, start a fresh Cortex Code conversation. This simulates a real-world context switch — moving from one ticket to the next without carrying stale context from the previous task.

In the Cortex Code UI, click **New Conversation** (or the `+` icon).

### Review What You Accomplished in Task 1

- Added retry detection logic (window function) to the intermediate dbt model
- Passed `retry_attempt_flag` and `retry_success_flag` through to the authorizations mart
- Added the `RETRY_SUCCESS_RATE` metric to the semantic view
- Updated the Cortex Agent instructions to recognize the new metric
- Deployed directly from the Snowsight workspace
- Verified the metric end-to-end via SQL query and natural language through the Cortex Agent

You are now ready for Task 2.

---

## Section 6: Task 2 — Add KPI Card to Streamlit Dashboard (~20 min)

In this task, you will add a KPI card to the payment analytics Streamlit dashboard that displays the retry success rate metric you created in Task 1.

### Step 6.1: Read the Jira Ticket

Ask the Cortex Agent (under **AI & ML → Cortex Agents**):

```
Show me Jira ticket EPA-3. What does it ask me to implement?
```

The agent will use the `JiraLookup` tool to retrieve the ticket. Review the acceptance criteria — it should describe adding a Retry Success Rate KPI card to the dashboard.

### Step 6.2: Implement the KPI Card

```
Based on the EPA-3 Jira ticket, implement the Retry Success Rate KPI card in apps/streamlit/app.py.
```

Cortex Code will edit `apps/streamlit/app.py` and deploy the updated file to the Streamlit stage. The two changes are:

**In the KPI SQL query**, add the retry success rate column:

```sql
ROUND(SUM(CASE WHEN retry_success_flag THEN 1 ELSE 0 END) * 100.0
      / NULLIF(SUM(CASE WHEN retry_attempt_flag THEN 1 ELSE 0 END), 0), 2)
AS retry_success_rate
```

**In the KPI cards row**, uncomment the fifth metric card:

```python
st.metric("Retry success rate", fmt_pct(row["RETRY_SUCCESS_RATE"]), border=True)
```

### Step 6.3: Verify the Dashboard

Navigate to **Projects → Streamlit** in the left navigation. Open `PAYMENT_ANALYTICS_DASHBOARD` (under your assigned database).

The dashboard should display five KPI cards: Total Transactions, Approval Rate, Approved Amount, Avg Ticket Size, and **Retry Success Rate**.

---

## Section 7: Wrap-up (~5 min)

Congratulations! In this lab, you completed two full development cycles using Cortex Code in Snowsight:

### What You Accomplished

- **Task 1:** Added a new business metric (retry success rate) end-to-end through the data stack — dbt intermediate model, marts dynamic table, semantic view, and Cortex Agent instructions. Verified the metric via SQL query and natural language.
- **Task 2:** Added a frontend KPI card to the Streamlit dashboard to visualize the new metric.
- **Along the way:** Read Jira tickets via the Cortex Agent, planned work with AI before executing, reviewed changes step-by-step, and verified results — all inside Snowsight without any local tools.

### Key Takeaways

1. **Automatic file context:** Cortex Code reads workspace files automatically — no manual setup needed. This gives the AI full awareness of your data architecture, business rules, and file paths.
2. **Workspace as deployment pipeline:** Workspace edits flow directly to production — dbt changes via `ADD VERSION`, Streamlit changes via `COPY FILES`. No external CI/CD or git push required.
3. **No local tooling required:** The entire SDLC cycle — from reading requirements to deploying and verifying — can happen inside Snowsight using Cortex Code and Snowflake-native objects.
4. **Extend existing patterns:** AI-assisted development works best when you follow established patterns. Both tasks extended existing components and conventions rather than starting from scratch.
5. **Context hygiene matters:** Starting a new conversation between tasks keeps context focused and produces better AI suggestions.

---

## Section 8: Bonus — Semantic View as a dbt Model

> **Optional.** Complete Sections 1–7 first. This step works best if you have extra time.

The semantic view in `packages/dbt/analyses/payment_analytics_semantic_view.sql` is currently a standalone DDL file executed manually as a one-off SQL statement. The [`dbt_semantic_view`](https://www.snowflake.com/en/engineering-blog/dbt-semantic-view-package/) package from Snowflake Labs promotes it to a first-class dbt model — managed as code, tracked in the dbt DAG with full upstream lineage, and deployed via `EXECUTE DBT PROJECT` alongside your other models.

### Step 8.1: Implement

Use this prompt — include the blog link so Cortex Code can research the package:

```
Can you implement the semantic view using dbt_semantic_view? https://www.snowflake.com/en/engineering-blog/dbt-semantic-view-package/
```

Cortex Code will:

1. Add `Snowflake-Labs/dbt_semantic_view` to `packages/dbt/packages.yml`
2. Install the package with `dbt deps`
3. Create `packages/dbt/models/marts/payments/payment_analytics.sql` — a dbt model using `materialized='semantic_view'` with `{{ ref() }}` references to all 7 mart tables

The new model generates native `CREATE OR REPLACE SEMANTIC VIEW` DDL and replaces the manual `analyses/` file as the source of truth for the semantic layer.

### Step 8.2: Deploy and Verify

```
Deploy my workspace edits: add a new version (no alias) from HOL_WORKSPACE using versions/live, execute the dbt project with --select payment_analytics, and ask the PAYMENT_ANALYTICS_AGENT for the retry success rate to confirm the semantic view still works correctly.
```

> The semantic view now has full dbt lineage — all 7 mart tables appear as upstream dependencies in the dbt DAG alongside the models that build them.

---

## Appendix

### A. Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Cortex Code asks which database to use | Multiple databases visible | Select `COCO_SDLC_HOL_NN` (your own HOL database) |
| `GET_JIRA_TICKET` returns an error | EAI or secret not accessible | Confirm your role is `HOL_ROLE_NN` and rerun Prompt 1 from Step 4.1 |
| Dynamic table shows old data | Dynamic tables refresh on schedule | Run `ALTER DYNAMIC TABLE COCO_SDLC_HOL_NN.MARTS.AUTHORIZATIONS REFRESH;` in a SQL Worksheet |
| New columns missing after dbt run | `ADD VERSION` used `versions/last` (last committed snapshot) instead of `versions/live` — workspace edits were not packaged | Re-run the Step 4.2 prompt verbatim — it explicitly requests `versions/live`. Then re-run EXECUTE with `ARGS = 'run --select int_authorizations__enriched+ --full-refresh'` |
| dbt run fails — permission denied on STAGING | Cortex Code omitted `--select` from the EXECUTE command, causing `--full-refresh` to try recreating staging views | Ask Cortex Code: `Re-run EXECUTE DBT PROJECT with ARGS = 'run --select int_authorizations__enriched+ --full-refresh'` |
| Semantic view metric not found | View not rebuilt after workspace edit | Ask Cortex Code to rerun: `Execute the semantic view DDL from packages/dbt/analyses/payment_analytics_semantic_view.sql against my database` |
| Cortex Agent gives generic answer | Agent not rebuilt after spec change | Ask Cortex Code to rerun: `Execute the Cortex Agent DDL from packages/database/utilities/03_create_agent.sql against my database` |
| Streamlit shows old version | App not refreshed | Click the refresh button in the top-right of the Streamlit app view |
| `EXECUTE DBT PROJECT` permission denied | Missing grants | Ask your instructor to verify `HOL_ROLE_NN` has USAGE on the dbt project |

### B. Resources

- **Cortex Code documentation:** [docs.snowflake.com/en/user-guide/cortex-code/cortex-code](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code)
- **Streamlit in Snowflake:** [docs.snowflake.com/en/developer-guide/streamlit/about-streamlit](https://docs.snowflake.com/en/developer-guide/streamlit/about-streamlit)
- **Snowflake Dynamic Tables:** [docs.snowflake.com/en/user-guide/dynamic-tables](https://docs.snowflake.com/en/user-guide/dynamic-tables)
- **dbt documentation:** [docs.getdbt.com](https://docs.getdbt.com)

### C. Glossary

- **Medallion architecture:** Data pipeline pattern with RAW (bronze), STAGING (silver), INTERMEDIATE/MARTS (gold) layers. Each layer progressively refines and enriches the data.
- **Dynamic table:** A Snowflake table that auto-refreshes based on upstream changes, configured with a target lag (e.g., every hour). Dynamic tables do not refresh on DDL changes — a manual refresh is required after schema modifications.
- **Snowflake-native dbt:** A deployment model where the dbt project is created as a Snowflake object (`CREATE DBT PROJECT`) and executed server-side (`EXECUTE DBT PROJECT`). No local dbt CLI required.
- **Semantic view:** A YAML-defined metadata layer over tables that declares dimensions, facts, metrics, and relationships. Enables natural language queries via the Cortex Agent.
- **Cortex Agent:** A Snowflake AI agent that answers natural language questions by generating SQL queries against semantic view metadata.
- **Streamlit in Snowflake:** A Streamlit app deployed as a native Snowflake object. Runs in Snowsight, connects to Snowflake using the active session — no credentials or local server required.
- **Plan mode:** A Cortex Code mode where changes are proposed and reviewed before execution. Ask Cortex Code to "use plan mode" to enable it.
