# Phase 7: Deploy dbt Project to Snowflake from Git Repo - Research

## RESEARCH COMPLETE

**Researched:** 2026-04-09
**Phase:** 07 - Deploy dbt project to Snowflake from Git repo

## 1. Current dbt Project Structure

The dbt project lives at `packages/dbt/` with the following key files:

- **`dbt_project.yml`** — Project named `evolv_payment_analytics`, profile: `dev`
- **`profiles.yml`** — Currently configured with hardcoded credentials (account, user, password)
- **`packages.yml`** — Uses `dbt-labs/dbt_utils` version `>=1.0.0, <2.0.0`
- **`package-lock.yml`** — Locks `dbt_utils` at version `1.3.3`
- **`macros/generate_schema_name.sql`** — Custom schema routing macro
- **`dbt_internal_packages/`** — Contains `dbt-adapters` and `dbt-snowflake` bundled packages
- **`dbt_packages/dbt_utils/`** — Installed dbt_utils package (full source)

### Model Layers
- **staging/** — Views over RAW tables (`+materialized: view`, `+schema: staging`)
- **intermediate/** — Dynamic tables (`+materialized: dynamic_table`, `+schema: intermediate`, `target_lag: 1 hour`)
- **marts/** — Dynamic tables (`+materialized: dynamic_table`, `+schema: marts`, `target_lag: 1 hour`)

## 2. profiles.yml Requirements for Snowflake-Native dbt

**Critical Finding:** Snowflake-native dbt projects require a minimal `profiles.yml` with only:
- `database`
- `role`
- `schema`
- `type: snowflake`

Authentication (account, user, password) is handled by the Snowflake session — these fields are NOT needed and should be removed. The current `profiles.yml` has hardcoded credentials that must be stripped out.

**Required format:**
```yaml
dev:
  target: dev
  outputs:
    dev:
      type: snowflake
      database: COCO_SDLC_HOL
      role: ATTENDEE_ROLE
      schema: STAGING
      warehouse: COMPUTE_WH
```

**Note:** The `warehouse` field is needed because the dbt models reference `+snowflake_warehouse: COMPUTE_WH` and Snowflake uses it for execution. The `threads` field can be omitted (Snowflake manages parallelism).

**Important:** The target schema in profiles.yml must exist before creating the dbt project (unlike dbt Core, Snowflake requires pre-existing schemas).

## 3. External Access Integration for dbt Packages

Since the project uses `dbt-labs/dbt_utils` from dbt Hub, an External Access Integration is needed to allow Snowflake to download packages during `dbt deps`.

**Required network rule hosts:**
- `hub.getdbt.com` — dbt package hub
- `codeload.github.com` — GitHub package downloads

**SQL pattern:**
```sql
CREATE OR REPLACE NETWORK RULE COCO_SDLC_HOL.PUBLIC.DBT_NETWORK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('hub.getdbt.com', 'codeload.github.com');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION DBT_HUB_EAI
  ALLOWED_NETWORK_RULES = (COCO_SDLC_HOL.PUBLIC.DBT_NETWORK_RULE)
  ENABLED = TRUE;
```

## 4. Git Repository Integration

**API Integration** — needed for Snowflake to access GitHub:
```sql
CREATE OR REPLACE API INTEGRATION GITHUB_EVOLV_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/evolvconsulting')
  ENABLED = TRUE;
```

**Git Repository Object** — connects the repo to Snowflake:
```sql
CREATE OR REPLACE GIT REPOSITORY COCO_SDLC_HOL.PUBLIC.HOL_REPO
  API_INTEGRATION = GITHUB_EVOLV_INTEGRATION
  ORIGIN = 'https://github.com/evolvconsulting/coco_sdlc_hol.git';
```

**Note:** The repo is public, so no secret/authentication is needed for the API integration.

## 5. CREATE DBT PROJECT Syntax

```sql
CREATE OR REPLACE DBT PROJECT COCO_SDLC_HOL.MARTS.EVOLV_PAYMENT_ANALYTICS
  FROM '@COCO_SDLC_HOL.PUBLIC.HOL_REPO/branches/main/packages/dbt'
  DEFAULT_TARGET = 'dev'
  EXTERNAL_ACCESS_INTEGRATIONS = (DBT_HUB_EAI)
  COMMENT = 'evolv Payment Analytics - linked to GitHub main branch';
```

**Key points:**
- The `FROM` clause points to the Git stage path where `dbt_project.yml` lives
- `DEFAULT_TARGET` must match a target name in `profiles.yml`
- `EXTERNAL_ACCESS_INTEGRATIONS` enables `dbt deps` to download packages
- The branch reference uses `branches/main` — since we're on `feature/dbt-in-snowflake`, the profiles.yml fix must be merged to main OR we use the feature branch initially

## 6. package-lock.yml Considerations

The current `package-lock.yml` format appears correct:
```yaml
packages:
  - name: dbt_utils
    package: dbt-labs/dbt_utils
    version: 1.3.3
sha1_hash: dd1e1feb2d2bbce79e7a255cd309a60e6548df0b
```

This should work with Snowflake-native dbt. The `dbt deps` command will use the external access integration to resolve packages.

## 7. dbt_internal_packages and dbt_packages Directories

The project currently has:
- `dbt_internal_packages/` — Bundled `dbt-adapters` and `dbt-snowflake` macros
- `dbt_packages/dbt_utils/` — Full installed dbt_utils source

**For Snowflake-native dbt:** These directories may not be needed as Snowflake manages the dbt runtime and adapter internally. However, they should be kept for backward compatibility with local dbt CLI usage. The `dbt_packages` directory is normally in `.gitignore` but appears to be committed here.

## 8. Deployment SQL Script Location

Existing deployment scripts are at `packages/database/utilities/`:
- `00_create_raw_schema.sql`
- `01_reference_data.sql`
- `02_generate_transactions.sql`
- `03_create_agent.sql`

The new deployment SQL for the dbt project setup should follow this pattern as `04_deploy_dbt_project.sql`.

## 9. Access Control

Required grants:
```sql
GRANT READ ON GIT REPOSITORY COCO_SDLC_HOL.PUBLIC.HOL_REPO TO ROLE ATTENDEE_ROLE;
GRANT USAGE ON DBT PROJECT COCO_SDLC_HOL.MARTS.EVOLV_PAYMENT_ANALYTICS TO ROLE ATTENDEE_ROLE;
```

The role in profiles.yml (`ATTENDEE_ROLE`) must have privileges to:
- Use the warehouse (`COMPUTE_WH`)
- Operate on STAGING, INTERMEDIATE, and MARTS schemas
- Create/replace views and dynamic tables

## 10. Execution

```sql
EXECUTE DBT PROJECT COCO_SDLC_HOL.MARTS.EVOLV_PAYMENT_ANALYTICS
  ARGS = 'run';
```

Other useful commands:
- `ARGS = 'deps'` — Install packages
- `ARGS = 'compile'` — Compile without running
- `ARGS = 'test'` — Run tests
- `ARGS = 'build'` — Run + test

## 11. Risks and Pitfalls

1. **profiles.yml has hardcoded credentials** — Must be fixed before deploying. Snowflake-native dbt ignores user/password but having them in a Git repo is a security issue.
2. **Branch reference** — The `FROM` clause references a specific branch. Changes must be on that branch for deployment.
3. **Schema pre-existence** — STAGING, INTERMEDIATE, and MARTS schemas must exist before dbt project creation.
4. **The `account` and `user` fields** — While Snowflake ignores them for native execution, the docs show they can be left empty or omitted. Best to remove them.
5. **dbt_packages committed to repo** — This is unusual; normally dbt_packages is in .gitignore and resolved via `dbt deps`. For Snowflake-native dbt, having them committed provides a fallback but may cause version conflicts.

## Validation Architecture

### Test Strategy
1. **profiles.yml validation** — After editing, verify it contains only required fields (type, database, role, schema, warehouse)
2. **SQL deployment** — Run each SQL statement and verify objects exist via `SHOW` commands
3. **dbt execution** — Run `EXECUTE DBT PROJECT ... ARGS = 'compile'` first, then `'run'`
4. **Output verification** — Check that STAGING views, INTERMEDIATE dynamic tables, and MARTS dynamic tables are created/refreshed
