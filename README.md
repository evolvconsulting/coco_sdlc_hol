# Performance Intelligence Dashboard

Hands-on lab for building a self-service payment analytics dashboard powered by Snowflake Cortex Agent and a dbt medallion architecture.

## Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Frontend | Next.js 14, Ant Design, AG Grid, ECharts | Dashboard UI |
| Backend | Node.js 20 + Express | API service |
| NL Queries | Snowflake Cortex Agent | Natural language to SQL |
| Data | Snowflake + dbt | Medallion architecture |
| Infrastructure | Snowpark Container Services (SPCS) | Container orchestration |

## Project Structure

```
coco_sdlc_hol/
├── apps/
│   └── frontend/                    # Next.js dashboard application
│
├── packages/
│   ├── database/
│   │   └── hol_setup.sql            # Single consolidated HOL setup script
│   │
│   └── dbt/                         # dbt transformation project
│       ├── models/
│       │   ├── staging/             # Views over RAW tables
│       │   ├── intermediate/        # Enriched dynamic tables
│       │   └── marts/               # Business-ready dynamic tables
│       └── analyses/
│           └── payment_analytics_semantic_view_v2.sql
│
└── Dockerfile                       # Container image for SPCS deployment
```

---

## Lab Participant Prerequisites

**Complete these before the lab.** Several tools require admin rights or may be blocked on corporate-managed machines — flag any blockers to your facilitator in advance.

### 1. Snowflake Account

You need a Snowflake account with the following features enabled. Contact your account team if any are not active:

- **Cortex Analyst / Cortex Agent** (required for natural language queries)
- **Snowpark Container Services (SPCS)** (required for deploying the dashboard)
- **Dynamic Tables** (required for intermediate and marts layers)
- **Semantic Views** (required for the Cortex Agent semantic layer)

Your account must be on **Enterprise tier or higher**. SPCS requires a region that supports it — confirm with your Snowflake rep if unsure.

### 2. Snow CLI

The Snowflake CLI (`snow`) is used to push the Docker image to the Snowflake image registry.

**Install:** https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation

```bash
# Verify installation
snow --version
```

> **Corporate machine note:** Snow CLI installation may require elevated privileges. If your IT policy blocks the installer, request a pre-approved install or ask your facilitator for a pre-configured machine.

After installing, configure a connection:

```bash
snow connection add
# Follow prompts: account identifier, username, authenticator (use "externalbrowser" for SSO)
```

### 3. Cortex Code CLI (optional — only for lab sections using it)

If the lab includes exercises with the Cortex Code CLI, install it separately:

**Install:** https://docs.snowflake.com/en/user-guide/cortex-code-cli

> **Corporate machine note:** The Cortex Code CLI may be flagged by endpoint security tools or require Python 3.9+. If you cannot install it, the lab facilitator can provide a shared environment for those exercises.

### 4. dbt (dbt-snowflake)

dbt is used in the lab to explore the transformation layer. Install via pip:

```bash
pip install dbt-snowflake
dbt --version
```

> **Requires Python 3.9–3.12.** If `pip` is not available, install Python first from https://www.python.org/downloads/

Configure your dbt profile (`~/.dbt/profiles.yml`) to point to your Snowflake account:

```yaml
evolv_pi:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <your-account-identifier>
      user: <your-snowflake-username>
      authenticator: externalbrowser
      role: ATTENDEE_ROLE
      database: COCO_SDLC_HOL
      warehouse: COMPUTE_WH
      schema: STAGING
      threads: 4
```

### 5. Docker Desktop

Docker is required to build and push the container image for SPCS deployment.

**Install:** https://www.docker.com/products/docker-desktop/

```bash
# Verify installation
docker --version
docker buildx version   # must support linux/amd64 cross-platform builds
```

> **Corporate machine note:** Docker Desktop requires virtualization support and admin rights on Windows. It is frequently blocked on corporate-managed machines by IT policy. If you cannot install Docker Desktop:
> - Check if **Rancher Desktop** or **Podman Desktop** is an approved alternative at your organization
> - Ask your facilitator — this step can be demonstrated on a shared screen if needed

### 6. Node.js 20.x

Required for running the frontend application locally.

**Install:** https://nodejs.org/en/download (use the LTS version, 20.x)

```bash
node --version   # should print v20.x.x
npm --version
```

### 7. Git

```bash
git --version
```

Clone the lab repository:

```bash
git clone <repo-url>
cd coco_sdlc_hol
```

---

## HOL Setup Script

`packages/database/hol_setup.sql` is a single consolidated, idempotent SQL script that provisions the entire Snowflake environment for the lab. Run it once at the start of the lab.

### What the script provisions

| Section | What it creates |
|---------|----------------|
| 1. ACCOUNTADMIN Bootstrap | `ATTENDEE_ROLE` with all required account-level grants; `COMPUTE_WH` warehouse |
| 2. Database & Schemas | `COCO_SDLC_HOL` database with 5 schemas: RAW, STAGING, INTERMEDIATE, MARTS, PUBLIC |
| 3. RAW Schema Tables | 11 tables (4 dimension, 7 fact) using `CREATE OR REPLACE TABLE` |
| 4. Reference Data | 5 dimension tables loaded via idempotent `MERGE INTO` statements |
| 5. Synthetic Transactions | Stored procedure `GENERATE_SYNTHETIC_DATA` + guarded `EXECUTE IMMEDIATE` |
| 6. Staging Views | 11 `CREATE OR REPLACE VIEW` in `COCO_SDLC_HOL.STAGING` |
| 7. Intermediate Dynamic Tables | 6 dynamic tables in `COCO_SDLC_HOL.INTERMEDIATE` (1-hour lag) |
| 8. Marts Dynamic Tables | 7 dynamic tables in `COCO_SDLC_HOL.MARTS` (1-hour lag) |
| 9. Service User + RSA Secret | `COCO_SDLC_HOL_SERVICE_USER` for SPCS JWT auth; private key stored as a Secret |
| 10. Image Repository | `COCO_SDLC_HOL.PUBLIC.coco_sdlc_hol_repo` for the Docker image |
| 11. Semantic View + Cortex Agent | `PAYMENT_ANALYTICS` semantic view; `PAYMENT_ANALYTICS_AGENT` |
| 12. Final Grants | USAGE on agent + SELECT on all mart/staging/intermediate objects for ATTENDEE_ROLE |

### How to run it

**Option A — Snowflake Worksheet (recommended for the lab)**

1. Open Snowsight and navigate to **Projects → Worksheets**
2. Create a new worksheet
3. Open `packages/database/hol_setup.sql` from this repo and paste the full contents
4. Click **Run All** (or use the keyboard shortcut)

The script switches roles internally (`ACCOUNTADMIN` for Section 1, then `ATTENDEE_ROLE` for everything else). Make sure your Snowflake user has `ACCOUNTADMIN` or `SYSADMIN` access before running.

**Option B — Snow CLI**

```bash
snow sql -f packages/database/hol_setup.sql --connection <your-connection-name>
```

### Re-running the script

The script is **idempotent** — all objects use `CREATE OR REPLACE` or `CREATE IF NOT EXISTS`, and reference data uses `MERGE INTO`. You can safely re-run it to reset the environment without dropping and recreating the database manually.

### RSA key pair

Section 9 of the script creates `COCO_SDLC_HOL_SERVICE_USER` and stores the RSA private key as a Snowflake Secret for SPCS container injection. The key pair in the script was generated specifically for this lab. If you need to rotate the keys:

```bash
# Generate a new 2048-bit RSA key pair
openssl genrsa -out hol_rsa_private.pem 2048
openssl rsa -in hol_rsa_private.pem -pubout -out hol_rsa_public.pem

# Extract the public key body (no headers) for the ALTER USER / CREATE USER statement
grep -v "BEGIN\|END" hol_rsa_public.pem | tr -d '\n'
```

Replace the `RSA_PUBLIC_KEY` value and the `SECRET_STRING` PEM content in Section 9, then re-run the script.

---

## Running the App Locally

After running `hol_setup.sql`, you can run the dashboard locally against your Snowflake environment.

### 1. Configure the environment

```bash
cd apps/frontend
cp .env.example .env.local
```

Open `.env.local` and set your Snowflake account identifier — it's the only field that needs to be filled in:

```
SNOWFLAKE_ACCOUNT=<orgname>-<accountname>
```

Everything else is pre-configured: the app connects as `COCO_SDLC_HOL_SERVICE_USER` using the RSA key pair that `hol_setup.sql` provisioned.

### 2. Install dependencies and start

```bash
npm install
npm run dev
```

The app will be available at http://localhost:3000.

---

## SPCS Deployment

After the setup script completes, deploy the dashboard container to SPCS:

```bash
# 1. Build the image (must be linux/amd64 for SPCS)
docker build --platform linux/amd64 -t coco-portal:latest .

# 2. Authenticate with the Snowflake image registry
snow spcs image-registry login --connection <your-connection-name>

# 3. Get the registry URL
snow sql -q "SHOW IMAGE REPOSITORIES IN SCHEMA COCO_SDLC_HOL.PUBLIC" --connection <your-connection-name>

# 4. Tag and push the image
docker tag coco-portal:latest <REPO_URL>/coco-portal:latest
docker push <REPO_URL>/coco-portal:latest
```

Then run `setup.sql` (SPCS service spec) to create the service and get the public endpoint URL.

---

## dbt Transformations (reference)

The dbt models are already compiled into `hol_setup.sql` — you do not need to run dbt to set up the lab environment. The dbt project is included for exploration:

```bash
cd packages/dbt
dbt deps
dbt build
```

## Data Architecture

### Medallion Layers

```
RAW → STAGING (views) → INTERMEDIATE (dynamic tables) → MARTS (dynamic tables)
```

### MARTS Tables (7 tables)

| Domain | RAW Table | MARTS Table | Key Measures |
|--------|-----------|-------------|--------------|
| Authorization | `CLX_AUTH` | `AUTHORIZATIONS` | transaction_amount, approval_status |
| Settlement | `CLX_SETTLE` | `SETTLEMENTS` | net_amount, sales_count |
| Funding | `CLX_FUND` | `DEPOSITS` | deposit_amount, total_fees_amount |
| Chargeback | `CLX_CBK` | `CHARGEBACKS` | dispute_amount, outcome |
| Retrieval | `CLX_RTRVL` | `RETRIEVALS` | retrieval_amount, retrieval_status |
| Adjustment | `CLX_ADJ` | `ADJUSTMENTS` | adjustment_amount, adjustment_type |
| Merchants | `CLX_MRCH_MSTR` | `DIM_MERCHANTS` | merchant_name, city, state |

### Reference Tables (RAW Schema)

| RAW Table | Purpose |
|-----------|---------|
| `CLX_MRCH_MSTR` | Merchant master data |
| `GLB_BIN` | Card/BIN enrichment |
| `PLTF_REF` | Platform/processor reference |
| `DCLN_RSN_CD` | Decline reason codes |
| `CBK_RSN_CD` | Chargeback reason codes |

### Cortex Agent

The Cortex Agent enables natural language queries against payment data:

- **Semantic View**: `COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS`
- **Agent**: `COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS_AGENT`

**Semantic View Features:**
- 7 tables with MERCHANTS dimension for relationships
- 6 relationships (all transaction tables → MERCHANTS via MERCHANT_ID)
- 10 metrics (approval_rate, chargeback_win_rate, effective_fee_rate, etc.)

**Example queries:**
- "What is my authorization approval rate by card brand?"
- "Show me chargeback trends over the last 12 months"
- "What are my top 10 merchants by settlement volume?"

## Security

- **Row-Level Security**: All queries filter by `CLNT_ID = 'dmcl'`
- **PAN Masking**: Card numbers masked (first 6 + last 4 only)
