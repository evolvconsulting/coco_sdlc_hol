# Hands-On Lab: AI-Assisted SDLC with Cortex Code

**Duration:** ~90 minutes
**Format:** Guided, hands-on development using Cortex Code CLI

## What You Will Build

In this lab, you will add a **retry success rate** metric end-to-end across the full data stack, working through two Jira tickets using Snowflake's AI coding assistant, Cortex Code:

- **Ticket 1 (~30 min):** Add the retry success rate metric to the dbt mart, semantic view, and Cortex Agent -- making it queryable via natural language.
- **Ticket 2 (~20 min):** Add a KPI card to the frontend dashboard that displays the new metric.

By the end, you will have experienced AI-assisted development across every layer of the stack: dbt model, dynamic table, semantic view, Cortex Agent, and React frontend.

## Prerequisites

- Snowflake account (pre-configured by your instructor)
- Git installed locally
- Node.js (v18+) installed locally
- WSL (Windows only -- required for Cortex Code CLI)

> **Note:** The lab environment has been pre-configured using `hol_setup.sql`. You do not need to run this script. Your instructor has already provisioned the Snowflake database, schemas, roles, sample data, and all supporting objects.

---

## Section 1: Architecture Overview (~10 min)

In this section, you will review the data architecture that has been pre-configured for the lab. Understanding these layers is essential because the development tasks require changes at multiple levels of the stack.

### Medallion Data Architecture

The project follows a medallion architecture with four layers. Data flows from raw source tables through progressively refined transformations:

```
+----------+     +----------------+     +------------------+     +-----------------+
|   RAW    | --> |    STAGING     | --> |  INTERMEDIATE    | --> |     MARTS       |
|          |     |   (views)      |     | (dynamic tables) |     | (dynamic tables)|
+----------+     +----------------+     +------------------+     +-----------------+
| Source   |     | Clean column   |     | Business logic,  |     | Final metrics   |
| tables   |     | names, types   |     | enrichment,      |     | ready for       |
| from     |     | cast, rename   |     | joins, lookups   |     | analytics       |
| CLX_*    |     | stg_clx_*      |     | int_*__enriched  |     | AUTHORIZATIONS  |
+----------+     +----------------+     +------------------+     +-----------------+
```

- **RAW:** Source data tables (`CLX_AUTH`, `CLX_SETTLE`, `CLX_FUND`, etc.) loaded by the setup script.
- **STAGING:** Views over RAW that apply clean column names, type casting, and renaming. These are lightweight SQL views (`stg_clx_*`).
- **INTERMEDIATE:** Dynamic tables that apply business logic, enrichment, and joins. These refresh automatically on a schedule (`int_*__enriched`).
- **MARTS:** Final business-ready dynamic tables consumed by the semantic view and frontend. These are the tables you will query and extend in this lab.

### MARTS Tables

The MARTS schema contains seven tables covering all payment domains:

| MARTS Table | RAW Source | Key Measures |
|-------------|-----------|--------------|
| `AUTHORIZATIONS` | `CLX_AUTH` | transaction_amount, approval_status, transactions_count |
| `SETTLEMENTS` | `CLX_SETTLE` | net_amount, sales_count, refund_count, sales_amount |
| `DEPOSITS` | `CLX_FUND` | deposit_amount, net_sales_amount, total_fees_amount |
| `CHARGEBACKS` | `CLX_CBK` | dispute_amount, disputes_count, outcome |
| `RETRIEVALS` | `CLX_RTRVL` | retrieval_amount, retrievals_count, retrieval_status |
| `ADJUSTMENTS` | `CLX_ADJ` | adjustment_amount, adjustment_type |
| `DIM_MERCHANTS` | `CLX_MRCH_MSTR` | merchant_name, city, state, mcc_code |

All transaction queries in this lab filter by `clnt_id = 'dmcl'` for row-level security.

### Cortex Agent and Semantic View Architecture

The natural language query (NLQ) capability is powered by two Snowflake objects working together:

- **Semantic View** (`COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS`): A YAML-defined layer over the MARTS tables that declares dimensions, facts, metrics, and relationships. It tells the Cortex Agent what data is available and how to query it. Currently defines 10 metrics (approval_rate, chargeback_win_rate, effective_fee_rate, etc.) across all 7 MARTS tables with 6 merchant relationships.
- **Cortex Agent** (`COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS_AGENT`): Uses the semantic view to translate natural language questions into SQL. Defined in `packages/database/utilities/03_create_agent.sql`.

### End-to-End Data Flow

The complete data flow from source to user looks like this:

```
dbt models          Dynamic Tables       Semantic View         Cortex Agent        Frontend
+-----------+     +----------------+     +--------------+     +--------------+     +----------+
| .sql      | --> | INTERMEDIATE   | --> | PAYMENT_     | --> | PAYMENT_     | --> | Next.js  |
| files in  |     | & MARTS        |     | ANALYTICS    |     | ANALYTICS_   |     | app at   |
| packages/ |     | schemas        |     | (YAML)       |     | AGENT        |     | :3000    |
| dbt/      |     |                |     |              |     |              |     |          |
+-----------+     +----------------+     +--------------+     +--------------+     +----------+
```

When you add a new metric in Ticket 1, the change flows through each of these layers. When you add a KPI card in Ticket 2, the frontend reads from the MARTS tables via its own API route.

### AGENTS.md Context File

The repository includes an `AGENTS.md` file at the root. Cortex Code reads this file automatically when launched from the repo directory. It contains the Snowflake connection details, data architecture reference, business rules (approval codes, chargeback cycles, etc.), and key file paths. You do not need to configure this -- it is already set up for the lab.

---

## Section 2: Environment Setup Verification (~5 min)

In this section, you will verify that your pre-configured environment is working correctly. Each step includes the expected output so you can confirm everything is ready before starting the development tasks.

> **Windows note:** If you are on Windows, you must use WSL (Windows Subsystem for Linux). Open a WSL terminal before running any commands in this lab.

### Step 1: Confirm Snowflake Connection

Run the following command to verify your Snowflake CLI connection:

```bash
snow sql -c ennovate -q "SELECT CURRENT_ROLE(), CURRENT_DATABASE(), CURRENT_SCHEMA();"
```

**Expected output:**

```
+----------------+--------------------+------------------+
| CURRENT_ROLE() | CURRENT_DATABASE() | CURRENT_SCHEMA() |
+----------------+--------------------+------------------+
| ATTENDEE_ROLE  | COCO_SDLC_HOL      | MARTS            |
+----------------+--------------------+------------------+
```

This confirms your Snowflake CLI is configured with the correct connection profile, role, database, and schema. The `ATTENDEE_ROLE` has been granted the permissions needed for all lab tasks.

### Step 2: Confirm Local App Runs

Start the frontend application to verify it can connect to Snowflake and display real data:

```bash
cd apps/frontend && npm install && npm run dev
```

**Expected output:**

```
  > Ready on http://localhost:3000
```

Open [http://localhost:3000](http://localhost:3000) in your browser. You should see the Performance Intelligence dashboard populated with real transaction data -- charts, KPI cards, and a natural language query interface.

If the dashboard loads with data, your local environment is correctly connected to the Snowflake backend. Leave this terminal running or stop the server with `Ctrl+C` (you will restart it during verification steps later).

### Step 3: Confirm Cortex Code CLI Installed

Verify that the Cortex Code CLI is available:

```bash
cortex --version
```

**Expected output:** A version string (e.g., `cortex 1.x.x`).

If the command is not found, install Cortex Code CLI:

```bash
curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh
```

After installation, restart your terminal and run `cortex --version` again to confirm. Cortex Code CLI is Snowflake's AI coding assistant -- you will use it extensively throughout both tickets in this lab.

---

## Section 3: Cortex Code Primer (~10 min)

In this section, you will learn the essential Cortex Code commands and set up the integrations needed for the lab tasks. By the end, you will be ready to use Cortex Code as your AI coding assistant throughout the development workflow.

### 3.1 What is Cortex Code

Cortex Code is Snowflake's AI coding assistant, generally available since February 2, 2026. Built on the Claude Code foundation, it runs directly in your terminal and provides AI-assisted development with Snowflake-native capabilities:

- **Automatic repo context:** Reads the `AGENTS.md` file at the repo root to understand your project's data architecture, business rules, and key file paths.
- **Snowflake-native features:** SQL execution, dbt skills, Snowflake object search, and RBAC awareness.
- **MCP integrations:** Connect to Jira, Confluence, and other tools directly from the coding assistant.

### 3.2 Key Slash Commands

The following slash commands are used throughout this lab:

| Command | Purpose |
|---------|---------|
| `/plan` | Enable plan mode -- Cortex Code shows an action plan before executing |
| `/plan-off` | Disable plan mode -- return to direct execution |
| `/new` | Start a fresh conversation (clears context) |
| `/model` | Select AI model (auto, Opus 4.6, Sonnet 4.6, etc.) |
| `/mcp` | Manage MCP integrations |
| `/status` | Show current session status |

> **Note:** Plan mode is session-scoped. After `/new`, you must re-enable `/plan` if you want plan mode in the new session.

### 3.3 Install Jira MCP Skill

Cortex Code connects to Jira via MCP (Model Context Protocol), allowing you to read and interact with Jira tickets directly from the coding assistant. In this lab, you will use this to pull ticket details for both development tasks.

In Cortex Code, run:

```
/mcp
```

Then follow the prompts to add the Jira server. Alternatively, use the CLI:

```bash
cortex mcp add jira --url https://your-org.atlassian.net --auth-token <token>
```

> **Note:** Your instructor will provide the Jira instance URL and API token.

### 3.4 Install Confluence MCP Skill

The Confluence skill allows you to update documentation pages directly from Cortex Code. You will use this in Ticket 1 to update the data dictionary.

Install using the same pattern as Jira:

```bash
cortex mcp add confluence --url https://your-org.atlassian.net --auth-token <token>
```

> **Note:** Your instructor will provide the Confluence instance URL and API token. This typically uses the same Atlassian instance as Jira.

### 3.5 Quick Test -- Verify Cortex Code Reads Repo Context

Launch Cortex Code from the repository root to verify it picks up the project context:

```bash
cortex
```

Once Cortex Code starts, ask it a question about the project:

```
What database and schema does this project use?
```

**Expected behavior:** Cortex Code should reference `COCO_SDLC_HOL` as the database and describe the medallion architecture (RAW, STAGING, INTERMEDIATE, MARTS) based on the information in `AGENTS.md`. If it does, the repo context is loaded correctly.

> **Note:** Suggested prompts throughout this lab are starting points -- feel free to rephrase in your own words. Cortex Code understands natural language variations.

---

## Section 4: Task 1 -- Add Retry Success Rate Metric (~30 min)

In this task, you will add a new business metric -- retry success rate -- that measures what percentage of initially declined transactions succeeded when the customer retried. You will modify the dbt data model, the semantic view, the Cortex Agent instructions, and verify the change locally. This is a complete SDLC cycle: from reading a Jira ticket to committing code and updating documentation.

### Step 4.1: Read the Jira Ticket

Launch Cortex Code from the repository root:

```bash
cortex
```

Once Cortex Code starts, ask it to pull the ticket details:

> Show me Jira ticket [TICKET-1]. What does it ask me to implement?

> **Note:** [TICKET-1] is a placeholder -- your instructor will provide the actual Jira ticket ID (e.g., COCO-42).

Cortex Code will use the Jira MCP skill you configured in Section 3 to retrieve the ticket. You should see a description asking you to add a retry success rate metric to the authorizations domain. Review the acceptance criteria before proceeding.

### Step 4.2: Create a Git Branch

Create a feature branch for this work:

```bash
git checkout -b feature/retry-success-rate
```

This keeps your changes isolated from the main branch. You will push this branch after verifying the metric works.

### Step 4.3: Enable Plan Mode

In the Cortex Code terminal, enable plan mode so you can review the proposed changes before execution:

```
/plan
```

Then describe the task to Cortex Code. Suggested prompt:

> I need to add a retry success rate metric to the authorizations domain. Retry success rate = count of transactions where a customer was initially declined then approved on a subsequent attempt. Add this to the dbt mart, the semantic view, and update the Cortex Agent instructions. Start by reading the relevant files.

Cortex Code will generate a numbered plan showing each file it intends to modify. Review the plan and confirm it includes changes to:

- `packages/dbt/models/intermediate/payments/int_authorizations__enriched.sql`
- `packages/dbt/models/marts/payments/authorizations.sql`
- `packages/dbt/analyses/payment_analytics_semantic_view.sql`
- `packages/database/utilities/03_create_agent.sql`

If the plan does not include all four files, ask Cortex Code to expand the scope:

> Please also include changes to the intermediate model (int_authorizations__enriched.sql) for the retry detection logic and the Cortex Agent instructions (03_create_agent.sql).

### Step 4.4: Confirm and Execute the Plan

Once the plan looks complete, confirm execution:

> The plan looks good. Execute it.

Cortex Code will proceed through each file modification, asking for your approval at each step (since plan mode is active). Review each change carefully as it is applied.

### Step 4.5: dbt Model Update -- Add Retry Detection Logic

This is the core data modeling change. Cortex Code should make the following updates:

**In `packages/dbt/models/intermediate/payments/int_authorizations__enriched.sql`:**

Add window function logic to detect retries. A retry is when the same card (`card_bin` + `card_last_four`) and the same `transaction_amount` appear from the same merchant within 5 minutes of a declined transaction. The intermediate model should add two new columns:

- `retry_attempt_flag` -- 1 if this transaction is a retry attempt (same card/amount/merchant within 5 minutes of a prior decline), 0 otherwise
- `retry_success_flag` -- 1 if this retry attempt was approved, 0 otherwise

If Cortex Code's plan does not include the SQL logic for computing retries, prompt it:

> Add the retry detection logic as a window function in int_authorizations__enriched.sql. A retry is when the same card_bin, card_last_four, and transaction_amount appear from the same merchant within 5 minutes of a declined transaction. Add retry_attempt_flag and retry_success_flag columns.

**In `packages/dbt/models/marts/payments/authorizations.sql`:**

Pass through the two new columns from the enriched intermediate model:

```sql
-- Retry metrics
retry_attempt_flag,
retry_success_flag
```

These columns are added to the `select` list so they flow through to the MARTS table where they can be queried directly and referenced by the semantic view.

### Step 4.6: dbt Materialization Check

The intermediate model (`int_authorizations__enriched`) is already configured as a dynamic table, and the mart (`authorizations`) is also a dynamic table. If Cortex Code suggests changing any materialization, review carefully -- the existing materializations (staging = view, intermediate = dynamic table, marts = dynamic table) should be preserved.

### Step 4.7: Update and Run Unit Tests

If the project has dbt tests, Cortex Code may update them to cover the new columns. Review any test changes for correctness.

> **Note:** In this lab environment, dbt tests are not run directly -- the compiled DDL is what matters. You will apply the DDL changes to Snowflake in the verification step.

### Step 4.8: Review Semantic View Update

Cortex Code should add a `RETRY_SUCCESS_RATE` metric to the semantic view YAML in `packages/dbt/analyses/payment_analytics_semantic_view.sql`. The metric follows the same pattern as existing metrics like `APPROVAL_RATE` and `CHARGEBACK_WIN_RATE`.

Verify the metric structure looks like this:

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

This metric divides successful retries by total retry attempts, producing a percentage. The `NULLIF` prevents division by zero when there are no retry attempts.

### Step 4.9: Review Cortex Agent Instruction Change

Cortex Code should update `packages/database/utilities/03_create_agent.sql` to mention retry success rate in the `instructions.response` text. This tells the agent that retry success rate is a queryable metric so it can provide relevant answers.

Verify the instruction text mentions retry success rate. For example, the `response` instruction might now read:

> "You are a helpful payment analytics assistant. Provide clear, concise answers about payment transactions, settlements, funding, chargebacks, retry success rates, and merchant performance. Format numerical data appropriately with dollar signs and percentages where relevant."

### Step 4.10: Verify Locally

Now verify that the changes work end-to-end in Snowflake. This has four sub-steps.

**a) Apply DDL changes in a Snowflake Worksheet**

Copy the updated `CREATE OR REPLACE DYNAMIC TABLE` statements (the compiled SQL from the modified dbt models) and run them in a Snowflake Worksheet. This applies the new columns to the live dynamic tables.

Then manually refresh the dynamic tables so the new columns are populated immediately (dynamic tables do not auto-refresh on DDL changes within the lab timeframe):

```sql
ALTER DYNAMIC TABLE COCO_SDLC_HOL.INTERMEDIATE.INT_AUTHORIZATIONS__ENRICHED REFRESH;
ALTER DYNAMIC TABLE COCO_SDLC_HOL.MARTS.AUTHORIZATIONS REFRESH;
```

> **Important:** Dynamic tables refresh on a schedule (e.g., every hour). Without the manual refresh above, you would have to wait for the next scheduled refresh before the new columns contain data.

**b) Rebuild the semantic view**

Run the updated semantic view DDL from `payment_analytics_semantic_view.sql` in a Snowflake Worksheet. This registers the new `RETRY_SUCCESS_RATE` metric with the semantic view.

Then verify the metric appears:

```sql
DESCRIBE SEMANTIC VIEW COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS;
```

You should see `RETRY_SUCCESS_RATE` listed among the metrics.

**c) Verify the metric data**

Run this query in a Snowflake Worksheet to confirm the retry columns contain data:

```sql
SELECT
  SUM(CASE WHEN retry_success_flag = 1 THEN 1 ELSE 0 END) AS successful_retries,
  SUM(CASE WHEN retry_attempt_flag = 1 THEN 1 ELSE 0 END) AS total_retries,
  ROUND(
    SUM(CASE WHEN retry_success_flag = 1 THEN 1.0 ELSE 0 END) * 100.0 /
    NULLIF(SUM(CASE WHEN retry_attempt_flag = 1 THEN 1 ELSE 0 END), 0),
  2) AS retry_success_rate_pct
FROM COCO_SDLC_HOL.MARTS.AUTHORIZATIONS
WHERE clnt_id = 'dmcl'
  AND transaction_date >= CURRENT_DATE - 30;
```

You should see a non-null `retry_success_rate_pct` value. The exact number depends on your sample data, but a typical value is between 20% and 80%.

**d) Test the Cortex Agent**

Ask the Cortex Agent about retry success rate -- either through the local app's natural language query interface or directly in Cortex Code:

> What is the retry success rate for the last 30 days?

The agent should generate a SQL query using the new `RETRY_SUCCESS_RATE` metric and return a meaningful answer.

### Step 4.11: Commit and Push

Once verification passes, commit your changes:

```bash
git add packages/dbt/ packages/database/
git commit -m "feat(dbt): add retry_success_rate to authorizations mart and semantic view"
git push -u origin feature/retry-success-rate
```

This commits all dbt model changes, the semantic view update, and the Cortex Agent instruction change together as a single logical unit.

### Step 4.12: Update Confluence Data Dictionary

The final step for this ticket is updating the data dictionary to document the new metric. In Cortex Code, use the Confluence MCP skill:

> Update the Confluence data dictionary page at [CONFLUENCE-DATA-DICTIONARY-URL] to add the retry_success_rate metric. It measures the percentage of initially declined transactions that succeeded on retry. It is computed from retry_attempt_flag and retry_success_flag in the AUTHORIZATIONS mart.

> **Note:** [CONFLUENCE-DATA-DICTIONARY-URL] is a placeholder -- your instructor will provide the actual Confluence page URL.

Cortex Code will use the Confluence MCP skill to read the existing page and add the new metric entry. Review the proposed changes before confirming.

This completes Ticket 1. You have added a new business metric end-to-end: from the intermediate dbt model through the mart, semantic view, Cortex Agent, and external documentation.
