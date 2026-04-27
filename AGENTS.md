# evolv Payment Analytics - Agent Context

## Snowflake Connection

```
Connection: <attendee-specific> (configured via Cortex Code setup wizard in Section 1)
Database: <attendee-specific> (e.g. COCO_SDLC_HOL_01 for user HOL_USER01)
Schemas:
  - RAW (source data)
  - STAGING (views over RAW)
  - INTERMEDIATE (enriched dynamic tables)
  - MARTS (business-ready dynamic tables)
```

## Atlassian

```
Site URL:    https://evolv-coco-sdlc-hol.atlassian.net/
Cloud ID:    310bd229-0685-4130-a7cc-f994764ba475
REST API:    https://api.atlassian.com/ex/jira/310bd229-0685-4130-a7cc-f994764ba475/rest/api/3/issue/{issue_key}
Auth:        Basic auth — Base64(email:api_token) stored in HOL_SHARED.PUBLIC.ATLASSIAN_TOKEN_SECRET
Used by:     Jira MCP (CLI path), GET_JIRA_TICKET UDF (UI path), Confluence MCP
```

## Snowflake Atlassian Infrastructure (pre-provisioned by instructor)

```
External Access Integration : ATLASSIAN_EAI
Secret                      : HOL_SHARED.PUBLIC.ATLASSIAN_TOKEN_SECRET  (TYPE = GENERIC_STRING)
Network Rule                : HOL_SHARED.PUBLIC.ATLASSIAN_NETWORK_RULE
```

> Attendees have USAGE on ATLASSIAN_EAI and READ/USAGE on HOL_SHARED.PUBLIC.ATLASSIAN_TOKEN_SECRET.
> Create GET_JIRA_TICKET in your own PUBLIC schema referencing these shared objects.


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

- **Semantic View**: `<your-database>.MARTS.PAYMENT_ANALYTICS`
- **Agent**: `<your-database>.MARTS.PAYMENT_ANALYTICS_AGENT`
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

- **PAN Masking**: Card numbers masked (first 6 + last 4 only)

## Key Paths

| Path | Purpose |
|------|---------|
| `packages/database/utilities/` | SQL deployment scripts |
| `packages/dbt/` | dbt transformation project |
| `<your-database>.PUBLIC.DBT_FILES` | Per-user internal stage — attendees upload edited dbt files here via `snow stage put` |
| `packages/dbt/models/staging/` | Staging views (RAW → clean names) |
| `packages/dbt/models/intermediate/` | Enriched dynamic tables |
| `packages/dbt/models/marts/` | Business-ready dynamic tables |
| `packages/dbt/analyses/payment_analytics_semantic_view.sql` | Semantic View DDL |

## Deployment Rules

When deploying the dbt project from the HOL_WORKSPACE, always use **`versions/live`** — never `versions/last`.

- `versions/live` = the current live state of the workspace, including all Cortex Code file edits
- `versions/last` = the last explicitly committed workspace snapshot — **does not include Cortex Code edits**

### Correct deployment sequence

**Step 1 — Add a new version** (`ADD VERSION` auto-sets it as the default):
```sql
ALTER DBT PROJECT <your-database>.MARTS.EVOLV_PAYMENT_ANALYTICS
  ADD VERSION
  FROM 'snow://workspace/<your-database>.MARTS."HOL_WORKSPACE"/versions/live';
```

**Step 2 — Execute the project** (uses the new default version automatically):
```sql
EXECUTE DBT PROJECT <your-database>.MARTS.EVOLV_PAYMENT_ANALYTICS
  ARGS = 'run --select int_authorizations__enriched+ --full-refresh';
```

**Critical syntax rules:**
- Do **NOT** add a `VERSION` clause to `EXECUTE DBT PROJECT` — it is not valid syntax and will error. The `DBT_VERSION` parameter is for the dbt Core engine version only.
- `ADD VERSION` without a name alias is correct — Snowflake auto-generates the version name and sets it as the default.
- Do **NOT** use a version name alias like `VERSION V2` in `ADD VERSION` — the alias makes re-runs fail because the same alias cannot be added twice.
- Always scope with `--select int_authorizations__enriched+ --full-refresh` to avoid `CREATE VIEW` permission errors on the STAGING schema.

