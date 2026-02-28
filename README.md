# Performance Intelligence Dashboard

Custom React analytics dashboard for the DMCL client, providing self-service analytics across 6 payment processing domains with natural language query capabilities powered by Snowflake Cortex Agent.

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
│   │   └── utilities/               # Database deployment scripts
│   │       ├── 00_create_raw_schema.sql
│   │       ├── 01_reference_data.sql
│   │       ├── 02_generate_transactions.sql
│   │       └── 03_create_agent.sql
│   │
│   └── dbt/                         # dbt transformation project
│       ├── models/
│       │   ├── staging/             # Views over RAW tables
│       │   ├── intermediate/        # Enriched dynamic tables
│       │   └── marts/               # Business-ready dynamic tables
│       │       ├── authorizations.sql
│       │       ├── settlements.sql
│       │       ├── deposits.sql
│       │       ├── chargebacks.sql
│       │       ├── retrievals.sql
│       │       ├── adjustments.sql
│       │       └── dim_merchants.sql
│       └── analyses/
│           └── payment_analytics_semantic_view_v2.sql
│
└── spcs/                            # SPCS service specifications
```

## Quick Start

### Prerequisites

- Node.js 20.x
- Snowflake connection (`ennovate`)
- dbt CLI with externalbrowser authentication

### Database Setup

Run the SQL scripts in order against Snowflake:

```bash
# 1. Create database and RAW schema with all tables
snowsql -c ennovate -f packages/database/utilities/00_create_raw_schema.sql

# 2. Load reference/dimension data
snowsql -c ennovate -f packages/database/utilities/01_reference_data.sql

# 3. Generate synthetic transaction data
snowsql -c ennovate -f packages/database/utilities/02_generate_transactions.sql

# 4. Create Cortex Agent (after dbt models exist)
snowsql -c ennovate -f packages/database/utilities/03_create_agent.sql
```

### dbt Transformations

```bash
cd packages/dbt
dbt deps
dbt build
```

### Frontend Development

```bash
cd apps/frontend
npm install
npm run dev
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
