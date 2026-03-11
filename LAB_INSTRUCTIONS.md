# Hands-On Lab: AI-Assisted SDLC with Cortex Code

**Duration:** ~90 minutes
**Format:** Guided, hands-on development using Cortex Code CLI

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

The Snowflake CLI (`snow`) is used to verify your Snowflake connection and run SQL from the terminal.

**Install:** https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation

```bash
# Verify installation
snow --version
```

> **Corporate machine note:** Snow CLI installation may require elevated privileges. If your IT policy blocks the installer, request a pre-approved install or ask your facilitator for a pre-configured machine.

### 3. Cortex Code CLI

The primary tool for this lab -- Snowflake's AI coding assistant.

**Install:** https://docs.snowflake.com/en/user-guide/cortex-code-cli

```bash
# Verify installation
cortex --version
```

> **Corporate machine note:** The Cortex Code CLI may be flagged by endpoint security tools or require Python 3.9+. If you cannot install it, the lab facilitator can provide a shared environment.

### 4. Node.js 20.x

Required for running the frontend application locally.

**Install:** https://nodejs.org/en/download (use the LTS version, 20.x)

```bash
node --version   # should print v20.x.x
npm --version
```

### 5. Git

```bash
git --version
```

Fork and clone the lab repository -- instructions are in Section 2, Step 0.

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

In this section, you will clone the lab repository and verify that your pre-configured environment is working correctly. Each step includes the expected output so you can confirm everything is ready before starting the development tasks.

### Step 0: Fork and Clone the Lab Repository

**0a. Fork the repository**

Navigate to [https://github.com/evolvconsulting/coco_sdlc_hol](https://github.com/evolvconsulting/coco_sdlc_hol) in your browser and click **Fork** (top-right). Accept the defaults and click **Create fork**.

You now have your own copy of the repository at `https://github.com/<your-username>/coco_sdlc_hol`.

**0b. Clone YOUR fork (not the upstream)**

```bash
git clone https://github.com/<your-username>/coco_sdlc_hol.git
cd coco_sdlc_hol
```

Replace `<your-username>` with your GitHub username.

> **Why fork?** The upstream repository restricts direct pushes to main. By working in your own fork, you can push your branches freely and submit pull requests back to the upstream repository when ready.

All subsequent steps and tool invocations assume you are working from this directory.

### Step 1: Configure and Confirm Snowflake Connection

Each attendee connects to their own Snowflake account. You will create a named connection profile, then verify it works.

**1a. Add a named connection**

Run the following and respond to each prompt as shown:

```bash
snow connection add
```

| Prompt | What to enter |
|--------|---------------|
| Name for this connection | `coco-hol` (or any name you prefer) |
| Snowflake account name | Provided by your instructor (format: `orgname-accountname`) |
| Snowflake username | Provided by your instructor |
| Password | Provided by your instructor |
| Authenticator | `snowflake` |
| Role | `ATTENDEE_ROLE` |
| Warehouse | `COMPUTE_WH` |
| Database | `COCO_SDLC_HOL` |
| Schema | `MARTS` |

> **Note:** Role, warehouse, database, and schema are optional during setup but entering them now avoids needing to specify them on every command.

**1b. Verify the connection**

Replace `<your-connection>` with the name you chose above (e.g., `coco-hol`):

```bash
snow sql -c <your-connection> -q "SELECT CURRENT_ROLE(), CURRENT_DATABASE(), CURRENT_SCHEMA();"
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

**1c. Set your account in the frontend environment file**

The repository includes a pre-configured `apps/frontend/.env.local` with the service account credentials. You only need to fill in your account identifier.

Open `apps/frontend/.env.local` and set `SNOWFLAKE_ACCOUNT` to the same account identifier you used in Step 1a (format: `orgname-accountname`):

```
SNOWFLAKE_ACCOUNT=orgname-accountname
```

All other values (service user, private key, database, schema, Cortex Agent name) are pre-populated and do not need to change.

### Step 2: Confirm Local App Runs

Start the frontend application to verify it can connect to Snowflake and display real data:

```bash
cd apps/frontend && npm install && npm run dev
```

**Expected output:**

```
  > Ready on http://localhost:3000
```

Open [http://localhost:3000](http://localhost:3000) in your browser. You should see the Payment Analytics dashboard populated with real transaction data -- charts, KPI cards, and a natural language query interface.

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

### 3.3 Install Atlassian MCP

A single Atlassian MCP connection gives Cortex Code access to both Jira and Confluence. In this lab it is read-only -- you will use it to pull Jira ticket details and reference the Confluence data dictionary.

> **Beyond the lab:** With write access, Cortex Code can add comments to Jira tickets, transition ticket status, log time, and update Confluence pages -- completing the full development loop without leaving the terminal.

Run the following command in your terminal:

```bash
cortex mcp add atlassian https://mcp.atlassian.com/v1/mcp -t http -H "Authorization: Basic dHJlbnQuZm9sZXlAZXZvbHZjb25zdWx0aW5nLmNvbTpBVEFUVDN4RmZHRjBzRlNUanJfUFhtcTNmXzZpUjNOZDdnSWtsMDUweG92Vk5Nc2xMTTZ1bTlyb1lLelBpU2NsbUFoQjEzdjUzVzdiQ2xvamk3MHQwcEFITUdkZE9VZEcwY3E0RnhqM1BCNmo5R0NKbjl2bTVUMENzMVpnOEdJQk5veXVrUDVoQXF0SFZSMWY0Qmo0X2pYOUw0YmNRd2x6cWZ1RWhHVVV6VndJS2FTYVgtRy1RZG89NzU1RUY3RDU="
```

### 3.4 Quick Test -- Verify Cortex Code Reads Repo Context

From your cloned repository root (from Step 0), launch Cortex Code:

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

In this task, you will add a new business metric -- retry success rate -- that measures what percentage of initially declined transactions succeeded when the customer retried. You will modify the dbt data model, the semantic view, the Cortex Agent instructions, and verify the change locally. This is a complete SDLC cycle: from reading a Jira ticket to committing code and referencing project documentation.

### Step 4.1: Read the Jira Ticket

Launch Cortex Code from the repository root:

```bash
cortex
```

Once Cortex Code starts, ask it to pull the ticket details:

> Show me Jira ticket EPA-2. What does it ask me to implement?

> **Note:** EPA-2 is a placeholder -- your instructor will provide the actual Jira ticket ID (e.g., COCO-42).

Cortex Code will use the Jira MCP skill you configured in Section 3 to retrieve the ticket. You should see a description asking you to add a retry success rate metric to the authorizations domain. Review the acceptance criteria before proceeding.

### Step 4.2: Create a Git Branch

Ask Cortex Code to create a feature branch:

> Create a new git branch called feature/retry-success-rate and switch to it.

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

> **Note:** In this lab environment, dbt tests are not run directly -- the compiled DDL is what matters. You will ask Cortex Code to apply the DDL changes to Snowflake in the verification step.

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

**a) Apply DDL changes and refresh dynamic tables**

> Deploy my dbt model changes to Snowflake and manually refresh the intermediate and marts dynamic tables so the new retry columns have data right away.

Cortex Code will apply the DDL and trigger a refresh on both tables. You should see confirmation that both were updated.

> **Why the refresh?** Dynamic tables refresh on a schedule (e.g., every hour). Without a manual refresh, you would have to wait for the next scheduled cycle before the new columns contain data.

**b) Rebuild the semantic view and verify**

> Rebuild the semantic view from the updated DDL file and verify that RETRY_SUCCESS_RATE now appears as a metric.

Cortex Code will execute the semantic view DDL and show you the DESCRIBE output. Look for `RETRY_SUCCESS_RATE` in the results.

**c) Verify the metric data**

> Query the authorizations mart and show me the retry success rate for the last 30 days.

Cortex Code will run a verification query and display the results. You should see a non-null retry success rate value -- a typical result is between 20% and 80%.

**d) Test the Cortex Agent**

> What is the retry success rate for the last 30 days?

The Cortex Agent should generate a SQL query using the new `RETRY_SUCCESS_RATE` metric and return a meaningful answer. This confirms the full chain works: dbt model → dynamic table → semantic view → Cortex Agent.

### Step 4.11: Commit and Push

Once verification passes, ask Cortex Code to commit and push:

> Commit all changes in packages/dbt/ and packages/database/ with the message "feat(dbt): add retry_success_rate to authorizations mart and semantic view". Then push to origin.

Cortex Code will stage the files, create the commit, and push to the remote. This commits all dbt model changes, the semantic view update, and the Cortex Agent instruction change together as a single logical unit.

### Step 4.12: Reference the Confluence Data Dictionary

Before wrapping up this ticket, use Cortex Code to read the existing data dictionary from Confluence. This demonstrates how MCP integrations let you pull project documentation directly into your coding workflow for reference:

> Read the Confluence data dictionary page at https://evolv-coco-sdlc-hol.atlassian.net/wiki/spaces/EPA/pages/851970/Data+Dictionary+-+Authorizations. What metrics are currently documented? How should I document the new retry_success_rate metric to match the existing format?

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
- Verified the metric end-to-end in Snowflake via Cortex Code (DDL deploy, dynamic table refresh, SQL query)
- Referenced the Confluence data dictionary via Cortex Code MCP to review existing documentation format
- Committed and pushed your changes to the feature branch

You are now ready for Task 2.

---

## Section 6: Task 2 -- Add KPI Card to Dashboard (~20 min)

In this task, you will add a KPI card to the authorization dashboard that displays the retry success rate metric you created in Task 1. This demonstrates a frontend change driven by the backend metric you just built.

### Step 6.1: Read the Jira Ticket

In Cortex Code, pull the ticket details for your second task:

> Show me Jira ticket EPA-3. What does it ask me to implement?

> **Note:** EPA-3 is a placeholder -- your instructor will provide the actual Jira ticket ID.

Cortex Code will use the Jira MCP skill to retrieve the ticket. You should see a description asking you to add a KPI card for the retry success rate metric to the authorization dashboard. Review the acceptance criteria before proceeding.

### Step 6.2: Create a Git Branch

Ask Cortex Code to create a new feature branch:

> Create a new git branch called feature/retry-success-kpi-card and switch to it.

This keeps the KPI card changes separate from the data model changes in Task 1.

### Step 6.3: Enable Plan Mode and Describe the Task

In the Cortex Code terminal, enable plan mode:

```
/plan
```

Then describe the task. Suggested prompt:

> Read Jira ticket EPA-3. Look at apps/frontend/src/app/analytics/authorization/page.tsx, apps/frontend/src/components/ui/KPICard.tsx, and apps/frontend/src/types/domain.ts. Add a KPI card that shows the retry_success_rate from the authorization KPIs API. Follow the exact same pattern as the existing KPI cards.

Review the plan. Confirm it includes changes to:

- `apps/frontend/src/types/domain.ts` -- add `retrySuccessRate` to `AuthorizationKPIs` interface
- `apps/frontend/src/app/api/analytics/authorization/kpis/route.ts` -- add SQL column and return field
- `apps/frontend/src/app/analytics/authorization/page.tsx` -- add new `<Col>` and `<KPICard>`

> **Important:** The TypeScript interface must be updated BEFORE the API route and page component. If Cortex Code's plan shows the page change first, ask it to reorder.

### Step 6.4: Execute the Plan

Once the plan looks complete, confirm execution:

> The plan looks good. Execute it.

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

> Start the frontend dev server from apps/frontend.

Open [http://localhost:3000/analytics/authorization](http://localhost:3000/analytics/authorization) in your browser. You should see a new "Retry Success Rate" KPI card alongside the existing authorization KPIs. The card displays a percentage value with a green color indicator.

If the card shows 0 or undefined, ask Cortex Code to help debug:

> The retry success rate KPI card is showing 0. Check that the AuthorizationKPIs interface in domain.ts includes retrySuccessRate and that the API route in kpis/route.ts returns the field.

### Step 6.6: Commit and Push

Once the KPI card displays correctly, ask Cortex Code to commit and push:

> Commit all changes in apps/frontend/ with the message "feat(frontend): add retry success rate KPI card to authorization dashboard". Then push to origin.

### Step 6.7: Create a Pull Request

Ask Cortex Code to create the pull request:

> Create a GitHub pull request for this branch. Title: "Add retry success rate KPI card". Describe what was changed and why.

Cortex Code will create the PR and return the URL. This completes Ticket 2. You have added a frontend KPI card that visualizes the backend metric you built in Task 1, following the existing component patterns in the codebase.

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
| Dynamic table shows old data | Dynamic tables refresh on schedule, not on DDL change | Ask Cortex Code to run `ALTER DYNAMIC TABLE ... REFRESH;` (see Step 4.10a) |
| Semantic view metric not found | YAML updated but view not rebuilt | Ask Cortex Code to rerun the semantic view DDL from `payment_analytics_semantic_view.sql` (see Step 4.10b) |
| KPI card shows 0 or undefined | TypeScript interface not updated | Add `retrySuccessRate: number` to `AuthorizationKPIs` in `apps/frontend/src/types/domain.ts` |
| Cortex Agent gives generic answer | Agent instructions not updated | Rerun `03_create_agent.sql` with the updated `instructions.response` mentioning retry success rate |
| `/plan` mode off after `/new` | Plan mode is session-scoped | Re-enable with `/plan` in each new session after using `/new` |
| Verification query returns empty | Missing `clnt_id` filter | Add `WHERE clnt_id = 'dmcl'` to all verification queries |

### B. Resources

- **Cortex Code CLI documentation:** [docs.snowflake.com/en/user-guide/cortex-code/cortex-code-cli](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code-cli)
- **Cortex Code CLI reference:** [docs.snowflake.com/en/user-guide/cortex-code/cli-reference](https://docs.snowflake.com/en/user-guide/cortex-code/cli-reference)
- **Cortex Code extensibility (MCP):** [docs.snowflake.com/en/user-guide/cortex-code/extensibility](https://docs.snowflake.com/en/user-guide/cortex-code/extensibility)
- **dbt documentation:** [docs.getdbt.com](https://docs.getdbt.com)
- **Snowflake Dynamic Tables:** [docs.snowflake.com/en/user-guide/dynamic-tables](https://docs.snowflake.com/en/user-guide/dynamic-tables)

### C. Glossary

- **Medallion architecture:** Data pipeline pattern with RAW (bronze), STAGING (silver), INTERMEDIATE/MARTS (gold) layers. Each layer progressively refines and enriches the data.
- **Dynamic table:** A Snowflake table that auto-refreshes based on upstream changes, configured with a target lag (e.g., every hour). Dynamic tables do not refresh on DDL changes -- a manual refresh is required after schema modifications.
- **Semantic view:** A YAML-defined metadata layer over tables that declares dimensions, facts, metrics, and relationships. It enables natural language queries by telling the Cortex Agent what data is available and how to query it.
- **Cortex Agent:** A Snowflake AI agent that answers natural language questions by generating SQL queries against semantic view metadata. Defined in SQL with configurable instructions.
- **MCP (Model Context Protocol):** A standard protocol for connecting AI tools to external services such as Jira, Confluence, and GitHub. Cortex Code uses MCP to integrate with project management and documentation tools.
- **Plan mode:** A Cortex Code mode (enabled with `/plan`) where changes are proposed and reviewed before execution. The AI presents a numbered action plan and requires approval at each step.
