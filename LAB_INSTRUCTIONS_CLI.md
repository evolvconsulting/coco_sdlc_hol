# Hands-On Lab: AI-Assisted SDLC with Cortex Code (CLI Path)

**Duration:** ~90 minutes
**Format:** Guided, hands-on development using Cortex Code CLI

> **Snowsight path:** If you cannot install Snow CLI or Cortex Code CLI (corporate machine restrictions, missing admin rights, etc.), use `LAB_INSTRUCTIONS_UI.md` instead — the full lab is available entirely in the browser.

> **Visual overview:** Open `lab_flow.html` in your browser for an interactive step-by-step diagram and path comparison before starting.

## What You Will Build

The solution you are working on is a **payments analytics platform** built on Snowflake. It processes transaction data — including payment attempts, retries, and outcomes — and exposes key metrics through a natural language Cortex Agent and a React dashboard, enabling business users to query payment performance without writing SQL.

In this lab, you will add a **retry success rate** metric end-to-end across the full data stack, working through two Jira tickets using Snowflake's AI coding assistant, Cortex Code:

- **Ticket 1 (~30 min):** Add the retry success rate metric to the dbt mart, semantic view, and Cortex Agent -- making it queryable via natural language.
- **Ticket 2 (~20 min):** Add a KPI card to the frontend dashboard that displays the new metric.

By the end, you will have experienced AI-assisted development across every layer of the stack: dbt model, dynamic table, semantic view, Cortex Agent, and React frontend.

## Prerequisites

**Complete these before the lab.** The Snowflake environment will be pre-provisioned by your instructor -- you only need the local development tools below.

> Several tools may require admin rights or be blocked on corporate-managed machines. Flag any blockers to your facilitator in advance.

### 1. Snowflake Account

Your instructor will provide a Snowflake account pre-configured for the lab. You need credentials to connect to it.

> **Note:** The lab environment has been pre-configured using `hol_setup.sql`. You do not need to run this script. Your instructor has already provisioned the Snowflake database, schemas, roles, sample data, and all supporting objects.

### 2. Snow CLI

The Snowflake CLI (`snow`) is a prerequisite for Cortex Code CLI.

**Install:** https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation

**Verify:**

```bash
snow --version
```

> **Corporate machine note:** Snow CLI installation may require elevated privileges. If your IT policy blocks the installer, request a pre-approved install or ask your facilitator for a pre-configured machine.

### 3. Cortex Code CLI

The primary tool for this lab -- Snowflake's AI coding assistant.

**Install:** https://docs.snowflake.com/en/user-guide/cortex-code-cli

**Verify:**

```bash
cortex --version
```

> **Corporate machine note:** The Cortex Code CLI may be flagged by endpoint security tools or require Python 3.9+. If you cannot install it, the lab facilitator can provide a shared environment.

### 4. Node.js 20.x

Required for running the React frontend application locally in Task 2.

**Install:** https://nodejs.org/en/download (use the LTS version, 20.x)

**Verify** (should print v20.x.x):

```bash
node --version
```

```bash
npm --version
```

> **Node.js not available?** Task 2 also has a Streamlit path that runs entirely in Snowsight — no Node.js needed. See Step 6 for details.

### 5. Git

```bash
git --version
```

Get the lab repository (fork + clone, or download ZIP) -- instructions are in Section 1, Step 0.

> **No CLI tools available?** Use `LAB_INSTRUCTIONS_UI.md` instead — the full lab is available entirely in Snowsight.

---

## Section 1: Environment Setup Verification (~5 min)

In this section you will fork the lab repository, connect to Snowflake using Cortex Code CLI, and confirm that the local development environment works.

### Step 0: Get the Lab Repository

Clone the repository directly -- no fork required:

```bash
git clone https://github.com/evolvconsulting/coco_sdlc_hol.git
cd coco_sdlc_hol
```

**Fallback -- if Git is not installed:** Download the repository as a ZIP archive:

1. Navigate to `https://github.com/evolvconsulting/coco_sdlc_hol`
2. Click the green **Code** button, then select **Download ZIP**
3. Extract the ZIP to a location of your choice
4. Open a terminal and navigate into the extracted folder:

```bash
cd coco_sdlc_hol-main
```

5. Initialize a local Git repository so you can still commit during the lab:

```bash
git init
git add .
git commit -m "Initial commit from ZIP download"
```

### Step 1: Configure and Confirm Snowflake Connection

Your instructor has pre-provisioned a dedicated Snowflake environment for you, including a personal database and MFA bypass for the duration of the lab. You only need to connect.

> **MFA note:** MFA is pre-bypassed for 20 hours. You will not be prompted during Cortex Code sessions or automated SQL calls.

**1a. Launch Cortex Code and create a connection**

From the cloned repository root, launch Cortex Code:

```bash
cortex
```

The first-run setup wizard will guide you through connecting to Snowflake. Select **"More options"** to create a new connection, then follow the prompts:

| Prompt | What to enter |
|--------|---------------|
| Connection name | `coco-hol` (or any name you prefer) |
| Account identifier | Provided by your instructor (format: `orgname-accountname`) |
| Username | Your assigned user — e.g. `HOL_USER_02` |
| Password | Provided by your instructor |
| Authentication method | Password (`snowflake`) |

Once authenticated, Cortex Code connects and drops you into an interactive session.

> **Note:** The connection is saved to `~/.snowflake/connections.toml` and can be reused by both Cortex Code CLI and Snow CLI.

**1b. Set your role, warehouse, database, and schema**

In the Cortex Code session, set your session context. Replace `02` with your assigned number (e.g. `HOL_ROLE_05`, `HOL_WH_05`, and `COCO_SDLC_HOL_05` for `HOL_USER_05`):

```
Set my role to HOL_ROLE_02, warehouse to HOL_WH_02, and use database COCO_SDLC_HOL_02 with schema MARTS.
```

Then verify your connection is configured correctly:

```
/status
```

**Expected output:** You should see `HOL_ROLE_NN` as the role, your assigned database (e.g. `COCO_SDLC_HOL_02`) as the database, and `MARTS` as the schema.

**1c. Configure local project files**

Ask Cortex Code to update the frontend config file with your Snowflake account identifier:

```
Update SNOWFLAKE_ACCOUNT in apps/frontend/.env.local with my account identifier <orgname-accountname>.
```

Replace `<orgname-accountname>` with the account identifier your instructor provided in Step 1a.

> **Note:** The dbt `profiles.yml` does not need updating. The dbt project runs inside Snowflake where authentication is handled by the session context -- no account credentials are stored in the profile.

### Step 2: Confirm Local App Runs

Ask Cortex Code to install the frontend dependencies and start the dev server:

```
Install the frontend dependencies and start the dev server from apps/frontend.
```

Open [http://localhost:3000](http://localhost:3000) in your browser. You should see the Payment Analytics dashboard populated with real transaction data -- charts, KPI cards, and a natural language query interface.

If the dashboard loads with data, your local environment is correctly connected to the Snowflake backend. You will restart the dev server during verification steps later.

---

## Section 2: Cortex Code Primer (~10 min)

In this section, you will learn the essential Cortex Code commands and set up the integrations needed for the lab tasks. By the end, you will be ready to use Cortex Code as your AI coding assistant throughout the development workflow.

### 2.1 What is Cortex Code

Cortex Code is Snowflake's AI coding assistant, generally available since February 2, 2026. Built on the Claude Code foundation, it runs directly in your terminal and provides AI-assisted development with Snowflake-native capabilities:

- **Automatic repo context:** Reads the `AGENTS.md` file at the repo root to understand your project's data architecture, business rules, and key file paths.
- **Snowflake-native features:** SQL execution, dbt skills, Snowflake object search, and RBAC awareness.
- **MCP integrations:** Connect to Jira, Confluence, and other tools directly from the coding assistant.

### 2.2 Key Slash Commands

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

### 2.3 Install Atlassian MCP

A single Atlassian MCP connection gives Cortex Code access to both Jira and Confluence. In this lab it is read-only -- you will use it to pull Jira ticket details and reference the Confluence data dictionary.

> **Beyond the lab:** With write access, Cortex Code can add comments to Jira tickets, transition ticket status, log time, and update Confluence pages -- completing the full development loop without leaving the terminal.

First, exit your Cortex Code session so you can run the MCP registration command in the terminal:

```
/exit
```

Then run the following command in your terminal:

```bash
cortex mcp add atlassian https://mcp.atlassian.com/v1/mcp -t http -H "Authorization: Basic dHJlbnQuZm9sZXlAZXZvbHZjb25zdWx0aW5nLmNvbTpBVEFUVDN4RmZHRjBzRlNUanJfUFhtcTNmXzZpUjNOZDdnSWtsMDUweG92Vk5Nc2xMTTZ1bTlyb1lLelBpU2NsbUFoQjEzdjUzVzdiQ2xvamk3MHQwcEFITUdkZE9VZEcwY3E0RnhqM1BCNmo5R0NKbjl2bTVUMENzMVpnOEdJQk5veXVrUDVoQXF0SFZSMWY0Qmo0X2pYOUw0YmNRd2x6cWZ1RWhHVVV6VndJS2FTYVgtRy1RZG89NzU1RUY3RDU="
```

> **Note:** `cortex mcp add` is a terminal command, not a Cortex Code prompt. You must exit the Cortex Code session first. You will relaunch Cortex Code at the start of Section 3.

---

## Section 3: Architecture Overview (~10 min)

Now that the MCP integration is registered, relaunch Cortex Code and use it to explore the lab's data architecture interactively. Rather than reading documentation, ask Cortex Code to explain the project -- this demonstrates how it uses the `AGENTS.md` context file to understand your codebase.

### 3.1 Explore the Architecture with Cortex Code

Relaunch Cortex Code from the repository root:

```bash
cortex
```

Once it starts, ask it to describe the project architecture:

```
Describe this project's data architecture and the Cortex Agent setup. What database, schemas, layers, domain tables, semantic view, and metrics are configured?
```

**Expected behavior:** Cortex Code should reference your assigned database (e.g. `COCO_SDLC_HOL_01`) and describe the medallion architecture (RAW → STAGING → INTERMEDIATE → MARTS), the domain tables, the materialization strategy, and the `PAYMENT_ANALYTICS` semantic view with its 10 metrics -- all sourced from `AGENTS.md`. If it does, the repo context is loaded correctly.

> **Note:** Suggested prompts throughout this lab are starting points -- feel free to rephrase in your own words. Cortex Code understands natural language variations.

### 3.2 Architecture Reference

The information below is what Cortex Code should have described. Use it as a reference throughout the lab.

**Medallion Pattern:**

```
RAW → STAGING (views) → INTERMEDIATE (dynamic tables) → MARTS (dynamic tables)
```

| Layer | Schema | Materialization | Purpose |
|-------|--------|-----------------|---------|
| **RAW** | `RAW` | Tables (loaded by infrastructure) | Source data as-is from upstream systems |
| **STAGING** | `STAGING` | Views | Light transformations: renaming, casting, basic filters |
| **INTERMEDIATE** | `INTERMEDIATE` | Dynamic Tables | Business logic: joins, enrichment, derived columns |
| **MARTS** | `MARTS` | Dynamic Tables | Final business-ready tables exposed to BI and AI |

> **Why dynamic tables?** Changes to upstream models propagate automatically — no scheduled jobs required.

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

- **Semantic View:** `<your-database>.MARTS.PAYMENT_ANALYTICS`
- **Cortex Agent:** `<your-database>.MARTS.PAYMENT_ANALYTICS_AGENT`
- **Tables:** All 7 marts tables
- **Relationships:** 6 foreign-key joins (all transaction tables → MERCHANTS via MERCHANT_ID)
- **Metrics:** 10 pre-defined calculations (approval_rate, chargeback_win_rate, effective_fee_rate, etc.)

During the lab, you will add a new metric (retry success rate) to this semantic view and verify that the Cortex Agent can answer questions about it.

---

## Section 4: Task 1 -- Add Retry Success Rate Metric (~30 min)

In this task, you will add a new business metric -- retry success rate -- that measures what percentage of initially declined transactions succeeded when the customer retried. You will modify the dbt data model, the semantic view, the Cortex Agent instructions, and verify the change locally. This is a complete SDLC cycle: from reading a Jira ticket to committing code and referencing project documentation.

### Step 4.1: Read the Jira Ticket

In your Cortex Code session (still running from Section 3), ask it to pull the ticket details:

```
Show me Jira ticket EPA-2. What does it ask me to implement?
```

> **Note:** EPA-2 is a placeholder -- your instructor will provide the actual Jira ticket ID (e.g., COCO-42).

Cortex Code will use the Jira MCP skill you configured in Section 2 to retrieve the ticket. You should see a description asking you to add a retry success rate metric to the authorizations domain. Review the acceptance criteria before proceeding.

### Step 4.2: Create a Git Branch

Ask Cortex Code to create a feature branch:

```
Create a new git branch called feature/retry-success-rate and switch to it.
```

This keeps your changes isolated from the main branch. You will push this branch after verifying the metric works.

### Step 4.3: Enable Plan Mode

In the Cortex Code terminal, enable plan mode so you can review the proposed changes before execution:

```
/plan
```

Then describe the task to Cortex Code. Suggested prompt:

```
Plan the implementation for the Jira ticket.
```

Cortex Code will generate a numbered plan showing each file it intends to modify. Review the plan and confirm it includes changes to:

- `packages/dbt/models/intermediate/payments/int_authorizations__enriched.sql`
- `packages/dbt/models/marts/payments/authorizations.sql`
- `packages/dbt/analyses/payment_analytics_semantic_view.sql`
- `packages/database/utilities/03_create_agent.sql`

If the plan does not include all four files, ask Cortex Code to expand the scope:

```
Please also include changes to the intermediate model (int_authorizations__enriched.sql) for the retry detection logic and the Cortex Agent instructions (03_create_agent.sql).
```

### Step 4.4: Confirm and Execute the Plan

Once the plan looks complete, Cortex Code will present a confirmation dialog. Select **Yes** to begin execution.

Cortex Code will proceed through each file modification, asking for your approval at each step (since plan mode is active). Review each change carefully as it is applied.

### Step 4.5: dbt Model Update -- Add Retry Detection Logic

This is the core data modeling change. Cortex Code should make the following updates:

**In `packages/dbt/models/intermediate/payments/int_authorizations__enriched.sql`:**

Add window function logic to detect retries. A retry is when the same card (`card_bin` + `card_last_four`) and the same `transaction_amount` appear from the same merchant within 5 minutes of a declined transaction. The intermediate model should add two new columns:

- `retry_attempt_flag` -- 1 if this transaction is a retry attempt (same card/amount/merchant within 5 minutes of a prior decline), 0 otherwise
- `retry_success_flag` -- 1 if this retry attempt was approved, 0 otherwise

If Cortex Code's plan does not include the SQL logic for computing retries, prompt it:

```
Add retry detection logic in int_authorizations__enriched.sql using a window function. Flag transactions where the same card and amount retry within 5 minutes of a decline. Add retry_attempt_flag and retry_success_flag columns.
```

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

> **Note:** In this lab environment, dbt tests are not run directly. The dbt project runs inside Snowflake (via `EXECUTE DBT PROJECT`), so there is no local `dbt test` step. You will push your changes and execute the dbt project in the verification step.

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

### Step 4.10: Deploy and Verify in Snowflake

Now use Cortex Code to deploy and verify the changes end-to-end in Snowflake. Type each prompt below directly into Cortex Code -- it will write and execute the necessary SQL for you.

**a) Upload changed dbt files to Snowflake stage and execute**

Ask Cortex Code to upload your changed dbt files and run the project:

```
Upload my changed dbt files to the Snowflake stage and execute the dbt project.
```

Cortex Code identifies the changed files and runs `snow stage put` to upload them directly to the internal stage, then executes the dbt project. No GitHub push is required -- files go straight to the Snowflake stage:

```bash
snow stage put packages/dbt/models/intermediate/payments/int_authorizations__enriched.sql \
  @COCO_SDLC_HOL_01.PUBLIC.DBT_FILES/models/intermediate/payments/ --overwrite
snow stage put packages/dbt/models/marts/payments/authorizations.sql \
  @COCO_SDLC_HOL_01.PUBLIC.DBT_FILES/models/marts/payments/ --overwrite
```

```sql
EXECUTE DBT PROJECT COCO_SDLC_HOL_01.MARTS.EVOLV_PAYMENT_ANALYTICS ARGS = 'run';
```

The `EXECUTE DBT PROJECT ... ARGS = 'run'` command runs dbt server-side inside Snowflake. It reads your models from the stage and applies the DDL directly. Dynamic tables will begin refreshing automatically on their configured schedule.

> **Note:** No GitHub push is needed. Your changed files are uploaded directly to the Snowflake internal stage, so Snowflake can read the latest version immediately.

**b) Rebuild the semantic view and verify**

```
Rebuild the semantic view from the updated DDL file and verify that RETRY_SUCCESS_RATE now appears as a metric.
```

Cortex Code will execute the semantic view DDL and show you the DESCRIBE output. Look for `RETRY_SUCCESS_RATE` in the results.

> **Note:** The semantic view is defined as a dbt `analysis` file, not a model. It is not executed by `EXECUTE DBT PROJECT` -- it must be applied separately via its DDL.

**c) Verify the metric data**

```
Query the authorizations mart and show me the retry success rate for the last 30 days.
```

Cortex Code will run a verification query and display the results. You should see a non-null retry success rate value -- a typical result is between 20% and 80%.

**d) Test the Cortex Agent**

```
What is the retry success rate for the last 30 days?
```

The Cortex Agent should generate a SQL query using the new `RETRY_SUCCESS_RATE` metric and return a meaningful answer. This confirms the full chain works: dbt model → dynamic table → semantic view → Cortex Agent.

### Step 4.11: Git Commit (Informational)

In a real workflow, changes would be committed and pushed to a Git repository for code review and CI/CD. For this lab, commit locally to preserve the history:

```bash
git commit -am "feat: add retry success rate metric"
```

No remote push is required. The stage upload in Step 4.10a already delivered your changes to Snowflake.

### Step 4.12: Reference the Confluence Data Dictionary

Before wrapping up this ticket, use Cortex Code to read the existing data dictionary from Confluence. This demonstrates how MCP integrations let you pull project documentation directly into your coding workflow for reference:

```
Read the Confluence data dictionary at https://evolv-coco-sdlc-hol.atlassian.net/wiki/spaces/EPA/pages/851970/Data+Dictionary+-+Authorizations. How should I document retry_success_rate to match the existing format?
```

> **Note:** https://evolv-coco-sdlc-hol.atlassian.net/wiki/spaces/EPA/pages/851970/Data+Dictionary+-+Authorizations is a placeholder -- your instructor will provide the actual Confluence page URL.

Cortex Code will use the Confluence MCP skill to retrieve the page content and show you the existing metric documentation format. Note the structure -- in a real workflow, you would update this page to include the new metric. For this lab, the Confluence connection is read-only.

This completes Ticket 1. You have added a new business metric end-to-end: from the intermediate dbt model through the mart, semantic view, and Cortex Agent.

---

## Section 5: Context Switch (~2 min)

Before starting Task 2, you will clear your Cortex Code context. This simulates a real-world context switch -- moving from one ticket to the next without carrying stale context from the previous task.

### Clear Context

In the Cortex Code terminal, start a fresh conversation:

```
/new
```

This starts a fresh conversation. Cortex Code no longer has Task 1's context loaded. This is intentional -- it demonstrates good AI workflow hygiene: bring only the context needed for the task at hand.

> **Note:** Plan mode is session-scoped. After `/new`, plan mode is off by default. You will re-enable it at the start of Task 2.

### Review What You Accomplished in Task 1

Take a moment to review what you completed:

- Added retry detection logic (window function) to the intermediate dbt model
- Passed `retry_attempt_flag` and `retry_success_flag` through to the authorizations mart
- Added the `RETRY_SUCCESS_RATE` metric to the semantic view
- Updated the Cortex Agent instructions to mention retry success rate
- Verified the metric end-to-end in Snowflake via Cortex Code (Git push, dbt project execution, SQL query)
- Referenced the Confluence data dictionary via Cortex Code MCP to review existing documentation format
- Committed and pushed your changes to the feature branch

You are now ready for Task 2.

---

## Section 6: Task 2 -- Add KPI Card to Dashboard (~20 min)

In this task, you will add a KPI card to the authorization dashboard that displays the retry success rate metric you created in Task 1. This demonstrates a frontend change driven by the backend metric you just built.

> **Node.js not available?** A Streamlit version of the dashboard is pre-deployed in your Snowsight environment (`COCO_SDLC_HOL_NN.PUBLIC.PAYMENT_ANALYTICS_DASHBOARD`). You can complete this task by editing `apps/streamlit/app.py` in the Snowsight workspace instead of the React app — the changes are equivalent. See `LAB_INSTRUCTIONS_UI.md` Section 6 for the Streamlit-specific steps.

### Step 6.1: Read the Jira Ticket

In Cortex Code, pull the ticket details for your second task:

```
Show me Jira ticket EPA-3. What does it ask me to implement?
```

> **Note:** EPA-3 is a placeholder -- your instructor will provide the actual Jira ticket ID.

Cortex Code will use the Jira MCP skill to retrieve the ticket. You should see a description asking you to add a KPI card for the retry success rate metric to the authorization dashboard. Review the acceptance criteria before proceeding.

### Step 6.2: Create a Git Branch

Ask Cortex Code to create a new feature branch:

```
Create a new git branch called feature/retry-success-kpi-card and switch to it.
```

This keeps the KPI card changes separate from the data model changes in Task 1.

### Step 6.3: Enable Plan Mode and Describe the Task

In the Cortex Code terminal, enable plan mode:

```
/plan
```

Then describe the task. Suggested prompt:

```
Plan the implementation for the Jira ticket.
```

Review the plan. Confirm it includes changes to:

- `apps/frontend/src/types/domain.ts` -- add `retrySuccessRate` to `AuthorizationKPIs` interface
- `apps/frontend/src/app/api/analytics/authorization/kpis/route.ts` -- add SQL column and return field
- `apps/frontend/src/app/analytics/authorization/page.tsx` -- add new `<Col>` and `<KPICard>`

> **Important:** The TypeScript interface must be updated BEFORE the API route and page component. If Cortex Code's plan shows the page change first, ask it to reorder.

### Step 6.4: Execute the Plan

Once the plan looks complete, Cortex Code will present a confirmation dialog. Select **Yes** to begin execution.

Cortex Code will make changes to three files. Review each change as it is applied:

**a) `apps/frontend/src/types/domain.ts`** -- add `retrySuccessRate: number` to the `AuthorizationKPIs` interface:

```typescript
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

**b) `apps/frontend/src/app/api/analytics/authorization/kpis/route.ts`** -- add to the SQL SELECT:

```sql
ROUND(
  SUM(CASE WHEN retry_success_flag = 1 THEN 1.0 ELSE 0 END) * 100.0 /
  NULLIF(SUM(CASE WHEN retry_attempt_flag = 1 THEN 1 ELSE 0 END), 0),
2) as retry_success_rate
```

And add to the return object:

```typescript
retrySuccessRate: Number(row.RETRY_SUCCESS_RATE) || 0,
```

**c) `apps/frontend/src/app/analytics/authorization/page.tsx`** -- add after the existing KPI cards in the `<Row gutter={[16, 16]}>` block:

```tsx
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

This follows the exact same pattern as the existing KPI cards -- same `Col` grid layout, same `KPICard` component props, same data fetching hook.

### Step 6.5: Verify Locally

Ask Cortex Code to start the dev server if it is not already running:

```
Start the frontend dev server from apps/frontend.
```

Open [http://localhost:3000/analytics/authorization](http://localhost:3000/analytics/authorization) in your browser. You should see a new "Retry Success Rate" KPI card alongside the existing authorization KPIs. The card displays a percentage value with a green color indicator.

If the card shows 0 or undefined, ask Cortex Code to help debug:

```
The retry success rate KPI card is showing 0. Check that the AuthorizationKPIs interface in domain.ts includes retrySuccessRate and that the API route in kpis/route.ts returns the field.
```

### Step 6.6: Git Commit (Informational)

Once the KPI card displays correctly, commit the changes locally to preserve the history:

```bash
git commit -am "feat: add retry success rate KPI card"
```

In a real workflow, these changes would be pushed to a Git repository for code review. For this lab, a local commit is sufficient.

### Step 6.7: Pull Request (Informational)

In a real workflow, you would open a pull request at this point to have the changes reviewed before merging. For this lab, there is no remote push, so this step is skipped.

This completes Ticket 2. You have added a frontend KPI card that visualizes the backend metric you built in Task 1, following the existing component patterns in the codebase.

---

## Section 7: Wrap-up (~5 min)

Congratulations! In this lab, you completed two full development cycles using Cortex Code:

### What You Accomplished

- **Task 1:** Added a new business metric (retry success rate) end-to-end through the data stack -- dbt intermediate model, marts dynamic table, semantic view, and Cortex Agent instructions. Verified the metric in Snowflake and referenced the Confluence data dictionary for documentation context.
- **Task 2:** Added a frontend KPI card to visualize the new metric, following existing component patterns. Committed and created a pull request.
- **Along the way:** Read Jira tickets and Confluence documentation via MCP, planned work with AI before executing, reviewed changes step-by-step, verified results locally and in Snowflake, committed code, and created a pull request -- all with Cortex Code as your AI coding assistant.

### Key Takeaways

1. **Automatic repo context:** Cortex Code reads `AGENTS.md` at the repo root automatically -- no manual setup needed. This gives the AI full awareness of your data architecture, business rules, and file paths.
2. **Plan mode for review:** The `/plan` command lets you review proposed changes before they happen. This is especially valuable when modifying multiple files across different layers of the stack.
3. **MCP skills for full SDLC:** Jira and Confluence MCP integrations connect Cortex Code to your project management and documentation tools, keeping the entire development workflow in one terminal.
4. **Extend existing patterns:** AI-assisted development works best when you follow established patterns in the codebase. Both tasks in this lab extended existing components and conventions rather than starting from scratch.
5. **Context hygiene matters:** Use `/new` between tasks to keep context focused. A fresh conversation with only the relevant context produces better AI suggestions than a long conversation with stale context from a previous task.

---

## Appendix

### A. Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| `cortex: command not found` | CLI not installed or not in PATH | Run install script: `curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh \| sh` then restart terminal |
| Dynamic table shows old data | Dynamic tables refresh on schedule, not immediately after `EXECUTE DBT PROJECT` | Ask Cortex Code to run `ALTER DYNAMIC TABLE ... REFRESH;` to trigger an immediate refresh |
| Semantic view metric not found | YAML updated but view not rebuilt | Ask Cortex Code to rerun the semantic view DDL from `payment_analytics_semantic_view.sql` (see Step 4.10b) |
| KPI card shows 0 or undefined | TypeScript interface not updated | Add `retrySuccessRate: number` to `AuthorizationKPIs` in `apps/frontend/src/types/domain.ts` |
| Cortex Agent gives generic answer | Agent instructions not updated | Rerun `03_create_agent.sql` with the updated `instructions.response` mentioning retry success rate |
| `/plan` mode off after `/new` | Plan mode is session-scoped | Re-enable with `/plan` in each new session after using `/new` |
| Verification query returns empty | Missing `clnt_id` filter | Add `WHERE clnt_id = 'dmcl'` to all verification queries |
| `EXECUTE DBT PROJECT` shows stale models | Git repository cache not refreshed after push | Run `ALTER GIT REPOSITORY COCO_SDLC_HOL.PUBLIC.HOL_REPO FETCH;` before executing the dbt project |
| New columns missing after dbt run | `EXECUTE DBT PROJECT` ran against a stale version — `ADD VERSION` was skipped after stage upload | Run `ALTER DBT PROJECT ... ADD VERSION FROM '@COCO_SDLC_HOL_NN.PUBLIC.DBT_FILES/'` first, then re-run with `ARGS = 'run --select int_authorizations__enriched+ --full-refresh'` |
| dbt run fails — permission denied on STAGING | `--full-refresh` without `--select` tries to recreate all models including staging views, but `HOL_ROLE_NN` lacks `CREATE VIEW` on STAGING | Always use `ARGS = 'run --select int_authorizations__enriched+ --full-refresh'` — scopes the run to changed models only and skips staging views |
| `EXECUTE DBT PROJECT` fails with package error | dbt packages not accessible from Snowflake | Verify the `DBT_HUB_EAI` external access integration is active and the network rule allows `hub.getdbt.com` |
| Branch path not found in Git stage | Branch name contains `/` and is not quoted | Use double quotes around the branch name in stage paths: `branches/"feature/dbt-in-snowflake"` |
| `EXECUTE DBT PROJECT` permission denied | Missing grants on dbt project object | Ensure `HOL_ROLE_NN` has USAGE on the dbt project: `GRANT USAGE ON DBT PROJECT ... TO ROLE HOL_ROLE_NN;` |

### B. Resources

- **Cortex Code CLI documentation:** [docs.snowflake.com/en/user-guide/cortex-code/cortex-code-cli](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code-cli)
- **Cortex Code CLI reference:** [docs.snowflake.com/en/user-guide/cortex-code/cli-reference](https://docs.snowflake.com/en/user-guide/cortex-code/cli-reference)
- **Cortex Code extensibility (MCP):** [docs.snowflake.com/en/user-guide/cortex-code/extensibility](https://docs.snowflake.com/en/user-guide/cortex-code/extensibility)
- **dbt documentation:** [docs.getdbt.com](https://docs.getdbt.com)
- **Snowflake Dynamic Tables:** [docs.snowflake.com/en/user-guide/dynamic-tables](https://docs.snowflake.com/en/user-guide/dynamic-tables)

### C. Glossary

- **Medallion architecture:** Data pipeline pattern with RAW (bronze), STAGING (silver), INTERMEDIATE/MARTS (gold) layers. Each layer progressively refines and enriches the data.
- **Dynamic table:** A Snowflake table that auto-refreshes based on upstream changes, configured with a target lag (e.g., every hour). Dynamic tables do not refresh on DDL changes -- a manual refresh is required after schema modifications.
- **Snowflake-native dbt:** A deployment model where the dbt project is created as a Snowflake object (`CREATE DBT PROJECT`) and executed server-side (`EXECUTE DBT PROJECT`). No local dbt CLI is required -- Snowflake reads models directly from a Git repository stage.
- **Git repository (Snowflake):** A Snowflake object that mirrors an external Git repository. Snowflake caches the repository state; use `ALTER GIT REPOSITORY ... FETCH` to pull the latest commits before referencing updated files.
- **Semantic view:** A YAML-defined metadata layer over tables that declares dimensions, facts, metrics, and relationships. It enables natural language queries by telling the Cortex Agent what data is available and how to query it.
- **Cortex Agent:** A Snowflake AI agent that answers natural language questions by generating SQL queries against semantic view metadata. Defined in SQL with configurable instructions.
- **MCP (Model Context Protocol):** A standard protocol for connecting AI tools to external services such as Jira, Confluence, and GitHub. Cortex Code uses MCP to integrate with project management and documentation tools.
- **Plan mode:** A Cortex Code mode (enabled with `/plan`) where changes are proposed and reviewed before execution. The AI presents a numbered action plan and requires approval at each step.

