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
