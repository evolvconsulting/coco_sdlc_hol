# Phase 1: Generate Hands-On Lab Setup Script - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce a single consolidated SQL script that provisions the complete Snowflake data environment for HOL participants — database, schemas, reference data, synthetic transactions, pre-built dbt model DDL (staging/intermediate/marts), and the Cortex Agent. SPCS deployment is explicitly out of scope; it becomes a lab task participants perform using Cortex Code.

The script must work for two delivery modes:
1. **Manual** — pasted into a Snowflake worksheet and run by a participant or instructor
2. **Automated** — run by dataops.live for bulk account provisioning when participants register

</domain>

<decisions>
## Implementation Decisions

### Setup scope
- Single consolidated SQL file (not 4 separate numbered files)
- Covers: CREATE DATABASE, RAW schema + tables, reference data load, synthetic transaction data generation, pre-built dbt model DDL (staging views + intermediate/marts dynamic tables), Cortex Agent
- dbt DDL is generated from `dbt compile` output — not hand-crafted — to stay accurate to the actual transformation logic
- SPCS deployment is NOT included — deferred to a lab task

### Role design
- ACCOUNTADMIN section: creates `ATTENDEE_ROLE`, grants it all necessary privileges (CREATE DATABASE, CREATE SCHEMA, CREATE TABLE, SPCS operations, CORTEX usage)
- ATTENDEE_ROLE performs all provisioning after the bootstrap section
- Script uses explicit `USE ROLE` switches between ACCOUNTADMIN (bootstrap only) and ATTENDEE_ROLE (everything else)

### Service user for SPCS auth
- Script creates `COCO_SDLC_HOL_SERVICE_USER` (RSA key-pair auth) within ATTENDEE_ROLE scope
- A shared RSA key pair is pre-generated for the lab; the unencrypted private key PEM is embedded directly in the script
- All participant accounts use the same key pair — acceptable for isolated HOL demo accounts
- Script creates the `coco_sdlc_hol_private_key` Snowflake Secret (TYPE = GENERIC_STRING) with the embedded PEM
- `SNOWFLAKE_ACCOUNT` resolved at runtime via `SELECT CURRENT_ACCOUNT()`

### Database and tenant configuration
- Fixed database name: `COCO_SDLC_HOL` across all participant accounts
- Fixed tenant: `CLNT_ID = 'dmcl'` — no participant-specific tenant IDs
- No parameterization needed — uniform setup across all accounts

### Idempotency
- DDL statements use `CREATE OR REPLACE` / `IF NOT EXISTS` throughout — safe to re-run for schema/tables
- Data insertion steps check if tables already contain rows before inserting — avoids duplicate data on re-run

### Script character
- Clean automation script — minimal comments, runs fast
- Section headers for navigation but no explanatory prose
- No verification/readiness queries at the end
- No teardown section

### dataops.live compatibility
- Script runs SQL directly — matches how dataops.live provisions accounts
- No external dependencies at run time (no shell, no dbt CLI needed — dbt DDL is pre-compiled inline)
- dataops.live handles account provisioning; script handles all Snowflake object creation

</decisions>

<specifics>
## Specific Ideas

- HOL goal: demonstrate AI coding assistant (Cortex Code) in the SDLC — read a Jira ticket, create branch, plan, implement, test, commit
- Lab tasks (performed AFTER setup): add new field to dbt model, add new metric to semantic view, add new KPI to the frontend, redeploy SPCS container image
- SPCS constraint: SPCS services can only pull from image repos within the same Snowflake account — cross-account image pull is not supported. Initial SPCS deploy is therefore a participant lab task, not a setup step.
- dataops.live registers participants and provisions their Snowflake accounts automatically — setup script is what runs in those accounts

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `packages/database/utilities/00_create_raw_schema.sql`: Creates COCO_SDLC_HOL database, RAW schema, all 7 raw tables (CLX_AUTH, CLX_SETTLE, CLX_FUND, CLX_CBK, CLX_RTRVL, CLX_ADJ, CLX_MRCH_MSTR) + 4 reference tables
- `packages/database/utilities/01_reference_data.sql`: Loads reference/dimension data (GLB_BIN, PLTF_REF, DCLN_RSN_CD, CBK_RSN_CD)
- `packages/database/utilities/02_generate_transactions.sql`: Generates synthetic transaction data for all 6 domains with CLNT_ID = 'dmcl'
- `packages/database/utilities/03_create_agent.sql`: Creates PAYMENT_ANALYTICS semantic view and PAYMENT_ANALYTICS_AGENT Cortex agent (requires MARTS tables to exist first)
- `setup.sql`: Existing SPCS deployment script — NOT part of setup script scope, but useful reference for ATTENDEE_ROLE privilege grants
- `packages/dbt/models/`: dbt models to compile — staging views + intermediate/marts dynamic tables over 7 domains

### Established Patterns
- Existing `setup.sql` uses ACCOUNTADMIN → SYSADMIN role switch pattern — new script follows ACCOUNTADMIN → ATTENDEE_ROLE instead
- Existing scripts use `CREATE OR REPLACE` consistently — maintain this pattern
- Cortex agent (`03_create_agent.sql`) must run after MARTS tables exist — ordering constraint in consolidated script

### Integration Points
- Script must produce the same Snowflake object names that `apps/frontend/src/lib/config.ts` references (COCO_SDLC_HOL, MARTS schema, all 7 MARTS table names)
- Service user `SNOWFLAKE_USER` must match what the SPCS service spec `env.SNOWFLAKE_USER` will reference when participants deploy SPCS

</code_context>

<deferred>
## Deferred Ideas

- SPCS deployment script updates (e.g., using ATTENDEE_ROLE, updated image URL) — participant lab task
- Lab guide / participant instructions document — separate deliverable
- Teardown/reset script for instructor cohort resets — out of scope for this phase

</deferred>

---

*Phase: 01-generate-hands-on-lab-setup-script*
*Context gathered: 2026-03-01*
