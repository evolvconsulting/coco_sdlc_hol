# Summary: 07-02 — Create Snowflake objects and deploy dbt project from Git

## What was done

Created all required Snowflake objects and deployed the dbt project from the GitHub repository. Fixed `package-lock.yml` format issue discovered during deployment (removed invalid `name` field).

### Objects created
1. **API Integration** `GITHUB_EVOLV_INTEGRATION` — connects Snowflake to GitHub
2. **Git Repository** `COCO_SDLC_HOL.PUBLIC.HOL_REPO` — points to evolvconsulting/coco_sdlc_hol
3. **Network Rule** `COCO_SDLC_HOL.PUBLIC.DBT_NETWORK_RULE` — allows egress to hub.getdbt.com and codeload.github.com
4. **External Access Integration** `DBT_HUB_EAI` — enables dbt package downloads
5. **dbt Project** `COCO_SDLC_HOL.MARTS.EVOLV_PAYMENT_ANALYTICS` — deployed from feature/dbt-in-snowflake branch

### Access grants
- `ATTENDEE_ROLE` has READ on Git Repository
- `ATTENDEE_ROLE` has USAGE on dbt Project

## Key files created/modified

| File | Change |
|------|--------|
| `packages/database/utilities/04_deploy_dbt_project.sql` | Created deployment script with all SQL |
| `packages/dbt/package-lock.yml` | Fixed format (removed invalid `name` field) |

## Issues encountered and resolved

1. **package-lock.yml format error** — Snowflake-native dbt rejected the lock file because it contained an invalid `name` field per entry. Fixed by removing the `name` field.
2. **Branch path with slashes** — Branch names containing `/` (e.g., `feature/dbt-in-snowflake`) require double-quoting in Git stage paths: `branches/"feature/dbt-in-snowflake"`.

## Verification

- [x] `SHOW INTEGRATIONS LIKE 'GITHUB_EVOLV_INTEGRATION'` — enabled API integration
- [x] `SHOW GIT REPOSITORIES IN SCHEMA COCO_SDLC_HOL.PUBLIC` — HOL_REPO with correct origin
- [x] `SHOW INTEGRATIONS LIKE 'DBT_HUB_EAI'` — enabled External Access integration
- [x] `SHOW DBT PROJECTS IN DATABASE COCO_SDLC_HOL` — EVOLV_PAYMENT_ANALYTICS with default_target=dev
- [x] `EXECUTE DBT PROJECT ... ARGS = 'run'` — 24/24 models succeeded
- [x] MARTS tables contain data: AUTHORIZATIONS (189,528), SETTLEMENTS (14,306), DEPOSITS (3,640), CHARGEBACKS (94,512)
