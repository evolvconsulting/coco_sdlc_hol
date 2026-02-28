# Performance Intelligence - Agent Context

## Snowflake Connection

```
Connection: ennovate
Database: COCO_SDLC_HOL
Schemas:
  - RAW (source data)
  - STAGING (views over RAW)
  - INTERMEDIATE (enriched dynamic tables)
  - MARTS (business-ready dynamic tables)
Client Filter: CLNT_ID = 'dmcl'
```

## Data Architecture

### Medallion Layers

```
RAW → STAGING (views) → INTERMEDIATE (dynamic tables) → MARTS (dynamic tables)
```

### MARTS Tables (7 tables)

| Domain | RAW Table | MARTS Table | Key Measures |
|--------|-----------|-------------|--------------|
| Authorization | `CLX_AUTH` | `AUTHORIZATIONS` | transaction_amount, approval_status, transactions_count |
| Settlement | `CLX_SETTLE` | `SETTLEMENTS` | net_amount, sales_count, refund_count, sales_amount |
| Funding | `CLX_FUND` | `DEPOSITS` | deposit_amount, net_sales_amount, total_fees_amount |
| Chargeback | `CLX_CBK` | `CHARGEBACKS` | dispute_amount, disputes_count, outcome |
| Retrieval | `CLX_RTRVL` | `RETRIEVALS` | retrieval_amount, retrievals_count, retrieval_status |
| Adjustment | `CLX_ADJ` | `ADJUSTMENTS` | adjustment_amount, adjustment_type |
| Merchants | `CLX_MRCH_MSTR` | `DIM_MERCHANTS` | merchant_name, city, state, mcc_code |

### Reference Tables (RAW schema)

| RAW Table | Purpose |
|-----------|---------|
| `CLX_MRCH_MSTR` | Merchant master data |
| `GLB_BIN` | Card/BIN enrichment data |
| `PLTF_REF` | Platform/processor reference |
| `DCLN_RSN_CD` | Decline reason codes |
| `CBK_RSN_CD` | Chargeback reason codes |

## Cortex Agent

- **Semantic View**: `COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS`
- **Agent**: `COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS_AGENT`
- **Definition**: `packages/database/utilities/03_create_agent.sql`

### Semantic View Features

- 7 tables with MERCHANTS dimension for relationships
- 6 relationships (all transaction tables → MERCHANTS via MERCHANT_ID)
- 10 metrics (approval_rate, chargeback_win_rate, effective_fee_rate, etc.)

## Business Rules

### Approval Codes (Authorization)
- `0` = Unknown
- `1` = Approved
- `2` = Declined

### Chargeback Cycles
- Chargeback
- Pre-Arbitration
- Pre-Compliance
- Filed Arbitration

### Retrieval Status
- OPEN
- CLOSED
- EXPIRED

### Processors
- `1` = North
- `8` = TeleCheck
- Others as configured

## Security

- **Row-Level Security**: All queries filter by `CLNT_ID = 'dmcl'`
- **PAN Masking**: Card numbers masked (first 6 + last 4 only)

## Key Paths

| Path | Purpose |
|------|---------|
| `packages/database/utilities/` | SQL deployment scripts |
| `packages/dbt/` | dbt transformation project |
| `packages/dbt/models/staging/` | Staging views (RAW → clean names) |
| `packages/dbt/models/intermediate/` | Enriched dynamic tables |
| `packages/dbt/models/marts/` | Business-ready dynamic tables |
| `packages/dbt/analyses/payment_analytics_semantic_view.sql` | Semantic View DDL |
