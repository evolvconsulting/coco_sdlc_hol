# Infrastructure & Deployment Reference

This document covers environment provisioning, deployment, and data architecture for the hands-on lab. It is intended for **instructors and facilitators** who need to stand up the lab environment before participants arrive.

For participant prerequisites (local dev tools), see [README.md](README.md#prerequisites).

---

## Snowflake Account Requirements

The Snowflake account used for the lab must have the following features enabled:

- **Cortex Analyst / Cortex Agent** (required for natural language queries)
- **Snowpark Container Services (SPCS)** (required for deploying the dashboard)
- **Dynamic Tables** (required for intermediate and marts layers)
- **Semantic Views** (required for the Cortex Agent semantic layer)

The account must be on **Enterprise tier or higher**. SPCS requires a region that supports it -- confirm with your Snowflake rep if unsure.

---

## HOL Setup Script

`hol_setup.sql` is a single consolidated, idempotent SQL script that provisions the entire Snowflake environment for the lab. Run it once at the start of the lab.

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
| 10. Semantic View + Cortex Agent | `PAYMENT_ANALYTICS` semantic view; `PAYMENT_ANALYTICS_AGENT` |
| 11. Final Grants | USAGE on agent + SELECT on all mart/staging/intermediate objects for ATTENDEE_ROLE |

### How to run it

**Option A -- Snowflake Worksheet (recommended for the lab)**

1. Open Snowsight and navigate to **Projects > Worksheets**
2. Create a new worksheet
3. Open `hol_setup.sql` from this repo and paste the full contents
4. Click **Run All** (or use the keyboard shortcut)

The script switches roles internally (`ACCOUNTADMIN` for Section 1, then `ATTENDEE_ROLE` for everything else). Make sure your Snowflake user has `ACCOUNTADMIN` or `SYSADMIN` access before running.

**Option B -- Snow CLI**

```bash
snow sql -f hol_setup.sql --connection <your-connection-name>
```

### Re-running the script

The script is **idempotent** -- all objects use `CREATE OR REPLACE` or `CREATE IF NOT EXISTS`, and reference data uses `MERGE INTO`. You can safely re-run it to reset the environment without dropping and recreating the database manually.

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

Open `.env.local` and set your Snowflake account identifier -- it's the only field that needs to be filled in:

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

Then run `spcs_setup.sql` (SPCS service spec) to create the service and get the public endpoint URL.

---

## dbt Transformations (reference)

The dbt models are already compiled into `hol_setup.sql` -- you do not need to run dbt to set up the lab environment. The dbt project is included for exploration:

```bash
# Install dbt-snowflake first (if not already installed)
uv tool install "dbt-core>=1.9.0" --with dbt-snowflake
# pip fallback: pip install "dbt-core>=1.9.0" dbt-snowflake

cd packages/dbt
dbt deps
dbt build
```

---

## Data Architecture

### Medallion Layers

```
RAW > STAGING (views) > INTERMEDIATE (dynamic tables) > MARTS (dynamic tables)
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
- 6 relationships (all transaction tables > MERCHANTS via MERCHANT_ID)
- 10 metrics (approval_rate, chargeback_win_rate, effective_fee_rate, etc.)

**Example queries:**
- "What is my authorization approval rate by card brand?"
- "Show me chargeback trends over the last 12 months"
- "What are my top 10 merchants by settlement volume?"

---

## Security

- **Row-Level Security**: All queries filter by `CLNT_ID = 'dmcl'`
- **PAN Masking**: Card numbers masked (first 6 + last 4 only)
