# Phase 1: Generate Hands-On Lab Setup Script - Research

**Researched:** 2026-03-01
**Domain:** Snowflake SQL scripting, dbt compiled DDL assembly, Cortex Agent provisioning
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Setup scope**
- Single consolidated SQL file (not 4 separate numbered files)
- Covers: CREATE DATABASE, RAW schema + tables, reference data load, synthetic transaction data generation, pre-built dbt model DDL (staging views + intermediate/marts dynamic tables), Cortex Agent
- dbt DDL is generated from `dbt compile` output — not hand-crafted — to stay accurate to the actual transformation logic
- SPCS deployment is NOT included — deferred to a lab task

**Role design**
- ACCOUNTADMIN section: creates `ATTENDEE_ROLE`, grants it all necessary privileges (CREATE DATABASE, CREATE SCHEMA, CREATE TABLE, SPCS operations, CORTEX usage)
- ATTENDEE_ROLE performs all provisioning after the bootstrap section
- Script uses explicit `USE ROLE` switches between ACCOUNTADMIN (bootstrap only) and ATTENDEE_ROLE (everything else)

**Service user for SPCS auth**
- Script creates `COCO_SDLC_HOL_SERVICE_USER` (RSA key-pair auth) within ATTENDEE_ROLE scope
- A shared RSA key pair is pre-generated for the lab; the unencrypted private key PEM is embedded directly in the script
- All participant accounts use the same key pair — acceptable for isolated HOL demo accounts
- Script creates the `coco_sdlc_hol_private_key` Snowflake Secret (TYPE = GENERIC_STRING) with the embedded PEM
- `SNOWFLAKE_ACCOUNT` resolved at runtime via `SELECT CURRENT_ACCOUNT()`

**Database and tenant configuration**
- Fixed database name: `COCO_SDLC_HOL` across all participant accounts
- Fixed tenant: `CLNT_ID = 'dmcl'` — no participant-specific tenant IDs
- No parameterization needed — uniform setup across all accounts

**Idempotency**
- DDL statements use `CREATE OR REPLACE` / `IF NOT EXISTS` throughout — safe to re-run for schema/tables
- Data insertion steps check if tables already contain rows before inserting — avoids duplicate data on re-run

**Script character**
- Clean automation script — minimal comments, runs fast
- Section headers for navigation but no explanatory prose
- No verification/readiness queries at the end
- No teardown section

**dataops.live compatibility**
- Script runs SQL directly — matches how dataops.live provisions accounts
- No external dependencies at run time (no shell, no dbt CLI needed — dbt DDL is pre-compiled inline)
- dataops.live handles account provisioning; script handles all Snowflake object creation

### Claude's Discretion
(None specified — all decisions are locked)

### Deferred Ideas (OUT OF SCOPE)
- SPCS deployment script updates (e.g., using ATTENDEE_ROLE, updated image URL) — participant lab task
- Lab guide / participant instructions document — separate deliverable
- Teardown/reset script for instructor cohort resets — out of scope for this phase
</user_constraints>

---

## Summary

This phase produces a single `hol_setup.sql` file that a Snowflake worksheet or dataops.live can run to fully provision a participant's account for the COCO SDLC HOL. All four existing utility scripts (`00_create_raw_schema.sql`, `01_reference_data.sql`, `02_generate_transactions.sql`, `03_create_agent.sql`) plus the compiled dbt DDL are assembled into a single, ordered, idempotent SQL file.

The primary assembly challenge is schema correctness: the existing `target/run/` compiled DDL places all objects in `COCO_SDLC_HOL.STAGING` (the profile's default schema at compile time), but the semantic view and frontend require objects in `COCO_SDLC_HOL.MARTS`. The staging views must be rewritten to target the `STAGING` schema, while intermediate and marts dynamic tables must target `INTERMEDIATE` and `MARTS` schemas respectively. The existing run/ output cannot be used verbatim — it must be corrected for schema placement and materialization type.

A second critical finding: the `stg_clx_auth.sql` source model references a `risk_score` column, but this column does not exist in the `CLX_AUTH` RAW table DDL. The compiled run/ output omits it, confirming it was already dropped during a prior compile. The consolidated script should not include `risk_score` in the staging view or any dependent model.

**Primary recommendation:** Assemble the script by concatenating source SQL in dependency order, correcting schema placement in dbt DDL, adding the ACCOUNTADMIN bootstrap and ATTENDEE_ROLE sections, embedding the pre-generated RSA key PEM, and writing idempotent data-insert guards. Use the `target/compiled/` SQL (not `target/run/`) as the source for correct query logic, then wrap in proper `CREATE OR REPLACE VIEW` / `CREATE OR REPLACE DYNAMIC TABLE` DDL targeting the correct schemas.

---

## Standard Stack

### Core
| Component | Version/Pattern | Purpose | Why Standard |
|-----------|----------------|---------|--------------|
| Snowflake SQL | Native | All DDL and DML | No external dependencies — runs in any Snowflake worksheet |
| dbt compiled output | `target/compiled/` | Source of truth for transformation SQL | Guarantees query logic matches actual dbt models |
| Snowflake Scripting (anonymous block) | Native | Data generation procedure call | Single `CALL GENERATE_SYNTHETIC_DATA()` for data population |
| MERGE INTO | Native Snowflake | Idempotent reference data load | Already established in 01_reference_data.sql |

### Supporting
| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `CREATE OR REPLACE DYNAMIC TABLE ... TARGET_LAG = '1 hour' WAREHOUSE = COMPUTE_WH` | Intermediate and marts materialization | All intermediate and mart layer models |
| `CREATE OR REPLACE VIEW` | Staging layer materialization | All staging models |
| `CREATE OR REPLACE SECRET ... TYPE = GENERIC_STRING` | RSA private key storage | SPCS service user key pair embedding |
| `SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML` | Semantic view creation | PAYMENT_ANALYTICS semantic view |

### No External Libraries Needed
This phase produces pure SQL — no npm packages, no Python, no shell scripting.

---

## Architecture Patterns

### Recommended Script Structure
```
hol_setup.sql
├── SECTION 1: ACCOUNTADMIN Bootstrap
│   ├── USE ROLE ACCOUNTADMIN
│   ├── CREATE ROLE ATTENDEE_ROLE
│   └── GRANT privileges to ATTENDEE_ROLE
│
├── SECTION 2: Database + Schema Setup (ATTENDEE_ROLE)
│   ├── USE ROLE ATTENDEE_ROLE
│   ├── CREATE DATABASE IF NOT EXISTS COCO_SDLC_HOL
│   └── CREATE SCHEMA IF NOT EXISTS RAW / STAGING / INTERMEDIATE / MARTS / PUBLIC
│
├── SECTION 3: RAW Schema Tables (from 00_create_raw_schema.sql)
│   └── CREATE OR REPLACE TABLE for 11 tables
│
├── SECTION 4: Reference Data (from 01_reference_data.sql)
│   └── MERGE INTO for PLTF_REF, GLB_BIN, DCLN_RSN_CD, CBK_RSN_CD, CLX_MRCH_MSTR
│
├── SECTION 5: Synthetic Transaction Data (from 02_generate_transactions.sql)
│   ├── CREATE OR REPLACE FUNCTION GENERATE_REALISTIC_AMOUNT
│   ├── CREATE OR REPLACE FUNCTION GET_CHARGEBACK_RATE
│   ├── CREATE OR REPLACE PROCEDURE GENERATE_SYNTHETIC_DATA
│   └── CALL GENERATE_SYNTHETIC_DATA() [with idempotency guard]
│
├── SECTION 6: Staging Views (dbt compiled, targeting STAGING schema)
│   └── CREATE OR REPLACE VIEW for 11 staging models
│
├── SECTION 7: Intermediate Dynamic Tables (dbt compiled, targeting INTERMEDIATE schema)
│   └── CREATE OR REPLACE DYNAMIC TABLE for 6 int_*__enriched models
│
├── SECTION 8: Marts Dynamic Tables (dbt compiled, targeting MARTS schema)
│   └── CREATE OR REPLACE DYNAMIC TABLE for 7 mart models (incl. DIM_MERCHANTS)
│
├── SECTION 9: Service User + RSA Secret
│   ├── CREATE USER IF NOT EXISTS COCO_SDLC_HOL_SERVICE_USER
│   └── CREATE OR REPLACE SECRET coco_sdlc_hol_private_key
│
├── SECTION 10: Image Repository
│   └── CREATE IMAGE REPOSITORY IF NOT EXISTS coco_sdlc_hol_repo
│
├── SECTION 11: Cortex Agent (from 03_create_agent.sql)
│   ├── USE SCHEMA COCO_SDLC_HOL.MARTS
│   ├── CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(...)
│   └── CREATE OR REPLACE AGENT PAYMENT_ANALYTICS_AGENT
│
└── SECTION 12: Grants
    └── GRANT USAGE ON AGENT to ATTENDEE_ROLE
```

### Pattern 1: ACCOUNTADMIN Bootstrap Block
**What:** Minimal ACCOUNTADMIN section for privilege grants only — no object creation
**When to use:** Opening section of the script before switching to ATTENDEE_ROLE
```sql
-- ============================================================
-- SECTION 1: Bootstrap (ACCOUNTADMIN)
-- ============================================================
USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS ATTENDEE_ROLE;
GRANT ROLE ATTENDEE_ROLE TO ROLE SYSADMIN;

-- Database and schema creation
GRANT CREATE DATABASE ON ACCOUNT TO ROLE ATTENDEE_ROLE;

-- SPCS privileges
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE ATTENDEE_ROLE;
GRANT CREATE COMPUTE POOL ON ACCOUNT TO ROLE ATTENDEE_ROLE;

-- Cortex
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE ATTENDEE_ROLE;

USE ROLE ATTENDEE_ROLE;
```

### Pattern 2: Idempotent Data Generation Guard
**What:** Check for existing rows before calling GENERATE_SYNTHETIC_DATA
**When to use:** Section 5 — prevents duplicate data on re-run
```sql
-- Only generate if tables are empty
EXECUTE IMMEDIATE $$
BEGIN
    IF ((SELECT COUNT(*) FROM COCO_SDLC_HOL.RAW.CLX_AUTH) = 0) THEN
        CALL COCO_SDLC_HOL.RAW.GENERATE_SYNTHETIC_DATA();
    END IF;
END;
$$;
```

### Pattern 3: Dynamic Table DDL Wrapping (for dbt compiled SQL)
**What:** Wrap compiled SELECT from `target/compiled/` in proper Snowflake DDL
**When to use:** All intermediate and marts models
```sql
CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.INTERMEDIATE.int_authorizations__enriched
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
  -- [compiled SQL from target/compiled/models/intermediate/payments/int_authorizations__enriched.sql]
  -- NOTE: Replace all COCO_SDLC_HOL.STAGING.stg_* references with COCO_SDLC_HOL.STAGING.stg_*
  -- (staging views stay in STAGING; intermediate/marts are placed in their own schemas)
```

### Pattern 4: Staging View DDL Wrapping
**What:** Wrap compiled SELECT from `target/compiled/` in VIEW DDL
**When to use:** All 11 staging models
```sql
CREATE OR REPLACE VIEW COCO_SDLC_HOL.STAGING.stg_clx_auth AS (
  -- [compiled SQL from target/compiled/models/staging/clx/stg_clx_auth.sql]
);
```

### Pattern 5: Service User Creation
**What:** Create service user with RSA key-pair auth and embed private key as Secret
```sql
-- Service user for SPCS JWT auth
CREATE USER IF NOT EXISTS COCO_SDLC_HOL_SERVICE_USER
  RSA_PUBLIC_KEY = '<PUBLIC_KEY_CONTENT>'
  DEFAULT_ROLE = ATTENDEE_ROLE
  COMMENT = 'Service user for SPCS container key-pair auth';

GRANT ROLE ATTENDEE_ROLE TO USER COCO_SDLC_HOL_SERVICE_USER;

-- Secret holds the private key for the container to use
CREATE OR REPLACE SECRET COCO_SDLC_HOL.PUBLIC.coco_sdlc_hol_private_key
  TYPE = GENERIC_STRING
  SECRET_STRING = '-----BEGIN PRIVATE KEY-----
<PRIVATE_KEY_PEM_CONTENT>
-----END PRIVATE KEY-----'
  COMMENT = 'Unencrypted RSA private key for SPCS JWT key-pair auth';
```

### Anti-Patterns to Avoid
- **Using `target/run/` DDL verbatim:** Those files place everything in `COCO_SDLC_HOL.STAGING` and materialize as views. Use `target/compiled/` for the SELECT logic, then wrap in correct DDL.
- **Including `risk_score` column:** The `stg_clx_auth.sql` source model references `risk_score` but `CLX_AUTH` has no such column. The compiled run/ already omitted it. Do not include it.
- **Hand-crafting mart SQL:** Never write mart transformation SQL manually — always derive it from `target/compiled/` models to stay in sync with dbt model logic.
- **Verification queries at script end:** Explicitly out of scope per CONTEXT.md.
- **Comments/explanatory prose in output:** Script character calls for section headers only — no explanatory prose.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Transformation SQL for intermediate/marts | Custom transformation SQL | Compiled output from `target/compiled/` | dbt compile already resolved all Jinja refs and produces clean SQL |
| RSA key pair generation | Shell scripting in SQL | Pre-generate once, embed as literal string | Script must run in Snowflake worksheet with no external tools |
| Data generation logic | New stored proc | Existing `GENERATE_SYNTHETIC_DATA` proc from `02_generate_transactions.sql` | Tested, realistic data with proper distributions already exists |
| Idempotent reference data | Custom INSERT...IF NOT EXISTS | `MERGE INTO` pattern from `01_reference_data.sql` | Already handles upsert correctly |
| Semantic view YAML | Custom SQL | `SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML` call from `analyses/payment_analytics_semantic_view.sql` | Already written and correct |

**Key insight:** Every piece of SQL already exists in the codebase — this phase is assembly, not authoring.

---

## Common Pitfalls

### Pitfall 1: Schema Mismatch in run/ Output
**What goes wrong:** `target/run/` DDL places all objects in `COCO_SDLC_HOL.STAGING` (the profile's default schema), materializing even mart models as views. Using run/ output verbatim means MARTS tables won't exist, the semantic view fails, and the frontend returns 404s.
**Why it happens:** dbt profile `evolv_pi` likely has `schema: staging` as default, so all run/ output goes there.
**How to avoid:** Use `target/compiled/` for SELECT logic only. Write proper `CREATE OR REPLACE VIEW ... COCO_SDLC_HOL.STAGING.*` and `CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.MARTS.*` wrappers manually.
**Warning signs:** Any run/ file that reads `COCO_SDLC_HOL.STAGING.authorizations` — mart models belong in MARTS schema.

### Pitfall 2: risk_score Column Reference
**What goes wrong:** The `stg_clx_auth.sql` source model includes `risk_score` in its SELECT. The `CLX_AUTH` RAW table has no such column. If included in the staging view DDL, the view will fail to resolve.
**Why it happens:** Model was updated to reference a column that was never added to the DDL.
**How to avoid:** Use the `target/run/stg_clx_auth.sql` as the DDL reference — it omits `risk_score`. Confirm the same for `int_authorizations__enriched` and `authorizations` mart model.
**Warning signs:** `risk_score` appearing in any staging or intermediate compiled SQL.

### Pitfall 3: Cortex Agent Ordering Dependency
**What goes wrong:** `CREATE AGENT PAYMENT_ANALYTICS_AGENT` references `COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS` semantic view and `COCO_SDLC_HOL.MARTS.DIM_MERCHANTS`. If the semantic view call or mart DDL hasn't run yet, agent creation fails.
**Why it happens:** `03_create_agent.sql` was designed to run after all marts exist.
**How to avoid:** Sections must execute in this order: RAW tables → Reference data → Transactions → Staging views → Intermediate dynamic tables → Marts dynamic tables → Semantic view → Cortex Agent.
**Warning signs:** Agent creation appearing before any mart DDL.

### Pitfall 4: ACCOUNTADMIN Privilege Grants for SPCS
**What goes wrong:** `BIND SERVICE ENDPOINT ON ACCOUNT` requires ACCOUNTADMIN. If ATTENDEE_ROLE tries to create a service without this grant, it fails silently or with a cryptic privilege error.
**Why it happens:** SPCS endpoint binding is an account-level privilege.
**How to avoid:** `GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE ATTENDEE_ROLE` must be in the ACCOUNTADMIN bootstrap section. Reference `setup.sql` line 27 which already demonstrates this.
**Warning signs:** Any SPCS grants appearing after `USE ROLE ATTENDEE_ROLE`.

### Pitfall 5: GENERATE_SYNTHETIC_DATA Truncates Tables
**What goes wrong:** The procedure opens with `TRUNCATE TABLE IF EXISTS CLX_AUTH` (and all other fact tables) before inserting. On re-run without a guard, all transaction data is wiped and regenerated with new UUIDs, breaking any stored references.
**Why it happens:** Procedure was designed for fresh generation, not incremental.
**How to avoid:** Wrap `CALL GENERATE_SYNTHETIC_DATA()` in the idempotency guard (Pattern 2 above) — only call if CLX_AUTH is empty.
**Warning signs:** No row-count check before the CALL statement.

### Pitfall 6: Dynamic Table Dependencies Must Be Schema-Qualified
**What goes wrong:** The compiled SQL for intermediate models references `COCO_SDLC_HOL.STAGING.stg_*` views. If staging views are placed in a different schema, dynamic table creation fails with object-not-found.
**Why it happens:** Dynamic tables resolve references at creation time.
**How to avoid:** Staging views MUST be in `COCO_SDLC_HOL.STAGING`. Intermediate dynamic tables reference those staging views by full path. Marts dynamic tables reference intermediate tables by full path (`COCO_SDLC_HOL.INTERMEDIATE.*`).
**Warning signs:** Any intermediate DDL referencing `COCO_SDLC_HOL.MARTS.*` staging objects — marts depend on intermediate, not staging.

---

## Code Examples

Verified patterns from existing codebase:

### Existing ACCOUNTADMIN → Role Switch Pattern (from setup.sql)
```sql
-- Source: packages/database/utilities/setup.sql
USE ROLE ACCOUNTADMIN;
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE SYSADMIN;

USE ROLE SYSADMIN;
-- all object creation here
```
For the HOL setup script: replace SYSADMIN with ATTENDEE_ROLE.

### Idempotent Reference Data Load (from 01_reference_data.sql)
```sql
-- Source: packages/database/utilities/01_reference_data.sql
MERGE INTO PLTF_REF AS tgt
USING (
    SELECT * FROM VALUES
        ('OMAHA', 'Omaha Platform', 'OMH', TRUE),
        ...
    AS src(PLTF_ID, PLTF_NM, PLTF_CD, ACTV_FLG)
) AS src
ON tgt.PLTF_ID = src.PLTF_ID
WHEN MATCHED THEN UPDATE SET ...
WHEN NOT MATCHED THEN INSERT ...
```

### Dynamic Table DDL Pattern (from dbt_project.yml config + Snowflake docs)
```sql
-- Correct DDL for intermediate/marts layer objects
CREATE OR REPLACE DYNAMIC TABLE COCO_SDLC_HOL.INTERMEDIATE.int_authorizations__enriched
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
AS
  [compiled SQL from target/compiled/models/intermediate/payments/int_authorizations__enriched.sql];
```

### Semantic View Creation (from analyses/payment_analytics_semantic_view.sql)
```sql
USE DATABASE COCO_SDLC_HOL;
USE SCHEMA MARTS;

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
  'COCO_SDLC_HOL.MARTS',
  $$
  [YAML content from payment_analytics_semantic_view.sql]
  $$,
  FALSE  -- FALSE = create (not just validate)
);
```

### Cortex Agent Creation (from 03_create_agent.sql)
```sql
-- Source: packages/database/utilities/03_create_agent.sql
USE SCHEMA COCO_SDLC_HOL.MARTS;

CREATE OR REPLACE AGENT PAYMENT_ANALYTICS_AGENT
  COMMENT = '...'
  PROFILE = '{"display_name": "Payment Analytics Assistant", "color": "blue"}'
  FROM SPECIFICATION $$
  models:
    orchestration: claude-sonnet-4-5
  ...
  tool_resources:
    PaymentAnalyst:
      semantic_view: "COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS"
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH
  $$;
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| 4 separate numbered SQL files | Single consolidated SQL | dataops.live can run a single script; participants have one file |
| ACCOUNTADMIN → SYSADMIN role switch | ACCOUNTADMIN → ATTENDEE_ROLE | Participants use a dedicated role, not SYSADMIN |
| dbt-managed schema placement | Pre-compiled DDL with explicit schema targets | No dbt CLI dependency at run time |
| Dynamic tables in INTERMEDIATE/MARTS | Run/ output incorrectly placed all in STAGING as views | Needs correction in assembled script |

**Current compile state of target/run/:** All objects materialized as views in `COCO_SDLC_HOL.STAGING`. This is NOT the target state for the setup script. The setup script must correct this by writing proper dynamic table DDL targeting the correct schemas.

---

## Open Questions

1. **RSA Key Pair Values**
   - What we know: Script must embed the unencrypted private key PEM and set the RSA public key on the service user. The decision is locked to a shared pre-generated key pair.
   - What's unclear: The actual PEM values are not in the codebase (correctly — they should not be committed). The planner will need to know how/where the implementer obtains these.
   - Recommendation: The plan should include a task step: "Obtain pre-generated RSA key pair (public + private PEM). Insert public key into `CREATE USER` statement and private key PEM into `CREATE SECRET` statement." Treat as a fill-in placeholder in the initial script.

2. **ATTENDEE_ROLE Privilege Scope**
   - What we know: Needs CREATE DATABASE, CREATE SCHEMA, CREATE TABLE, BIND SERVICE ENDPOINT, CREATE COMPUTE POOL, CORTEX usage, CREATE AGENT.
   - What's unclear: Whether `GRANT CREATE AGENT ON ACCOUNT` or `GRANT CORTEX AGENT USAGE` is the correct privilege syntax for the Cortex Agent feature.
   - Recommendation: Reference `GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE ATTENDEE_ROLE` as the standard Cortex access grant. Verify agent-specific grants in Snowflake docs if Cortex Agent creation fails during testing.

3. **COMPUTE_WH Existence**
   - What we know: Dynamic table DDL references `WAREHOUSE = COMPUTE_WH`. The agent also references `COMPUTE_WH`. The existing `setup.sql` and `03_create_agent.sql` both reference `COMPUTE_WH` without creating it.
   - What's unclear: Whether participant accounts created by dataops.live always have a `COMPUTE_WH` warehouse, or if the setup script needs to create one.
   - Recommendation: Add `CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH WAREHOUSE_SIZE = XSMALL AUTO_SUSPEND = 60` to the ATTENDEE_ROLE section. Safe to include — idempotent and ensures self-contained provisioning.

---

## Sources

### Primary (HIGH confidence)
- Codebase: `packages/database/utilities/00_create_raw_schema.sql` — complete RAW schema DDL, verified column list
- Codebase: `packages/database/utilities/01_reference_data.sql` — MERGE INTO idempotent load pattern
- Codebase: `packages/database/utilities/02_generate_transactions.sql` — GENERATE_SYNTHETIC_DATA procedure, truncate-before-insert behavior
- Codebase: `packages/database/utilities/03_create_agent.sql` — Cortex Agent creation DDL, semantic view YAML
- Codebase: `packages/database/utilities/setup.sql` — ACCOUNTADMIN bootstrap pattern, BIND SERVICE ENDPOINT grant, SECRET creation pattern
- Codebase: `packages/dbt/target/run/*.sql` — materialization state (all objects in STAGING as views — need correction)
- Codebase: `packages/dbt/target/compiled/models/**/*.sql` — clean SELECT SQL for each model
- Codebase: `packages/dbt/dbt_project.yml` — intended materialization (views for staging, dynamic tables for int/marts)
- Codebase: `packages/dbt/analyses/payment_analytics_semantic_view.sql` — PAYMENT_ANALYTICS semantic view YAML
- Codebase: `apps/frontend/src/lib/config.ts` — confirmed expected object names: COCO_SDLC_HOL.MARTS.{AUTHORIZATIONS, SETTLEMENTS, DEPOSITS, CHARGEBACKS, RETRIEVALS, ADJUSTMENTS}

### Secondary (MEDIUM confidence)
- `setup.sql` SPCS service spec — SNOWFLAKE_USER env var name confirms service user name the container will reference

---

## Metadata

**Confidence breakdown:**
- Assembly order and structure: HIGH — all source files fully read, dependency order clear
- Schema correction needed: HIGH — confirmed by reading run/ output vs frontend config
- risk_score omission: HIGH — confirmed column absent from RAW DDL and omitted from run/ output
- ATTENDEE_ROLE privilege list: MEDIUM — BIND SERVICE ENDPOINT and CORTEX usage confirmed from setup.sql/Snowflake docs knowledge; CREATE AGENT privilege syntax needs verification
- COMPUTE_WH assumption: MEDIUM — referenced throughout codebase but never created; verify with dataops.live account baseline

**Research date:** 2026-03-01
**Valid until:** 2026-04-01 (stable Snowflake SQL, no fast-moving dependencies)
