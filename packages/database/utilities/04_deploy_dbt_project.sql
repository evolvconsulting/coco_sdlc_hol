-- =============================================================================
-- EVOLV PAYMENT ANALYTICS - dbt Project Deployment from Internal Stage
-- =============================================================================
-- This script creates the Snowflake objects needed to deploy and run the dbt
-- project from an internal Snowflake stage (no GitHub push required).
--
-- Usage:
--   1. Set DB_NAME to your HOL database before running (default: COCO_SDLC_HOL_01).
--   2. Run as ACCOUNTADMIN for Steps 1–3; SYSADMIN for Steps 4–7.
--
-- Prerequisites:
--   - ACCOUNTADMIN role (for API/external integrations)
--   - Database $DB_NAME exists with schemas RAW, STAGING, INTERMEDIATE, MARTS
--   - Stage $DB_NAME.PUBLIC.DBT_FILES populated by hol_setup.sql Section 6d
-- =============================================================================

SET DB_NAME = 'COCO_SDLC_HOL_01'; -- set to your HOL database (e.g. COCO_SDLC_HOL_01)

-- =============================================================================
-- Step 1: GitHub API Integration (requires ACCOUNTADMIN)
-- Note: Still needed so the instructor can populate the DBT_FILES stage
--       from the Git repository via COPY FILES.
-- =============================================================================
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE API INTEGRATION GITHUB_EVOLV_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/evolvconsulting')
  ENABLED = TRUE;

-- =============================================================================
-- Step 2: Git Repository Object (instructor use — source for COPY FILES)
-- =============================================================================
CREATE OR REPLACE GIT REPOSITORY $DB_NAME.PUBLIC.HOL_REPO
  API_INTEGRATION = GITHUB_EVOLV_INTEGRATION
  ORIGIN = 'https://github.com/evolvconsulting/coco_sdlc_hol.git';

GRANT READ ON GIT REPOSITORY $DB_NAME.PUBLIC.HOL_REPO
  TO ROLE ATTENDEE_ROLE;

-- =============================================================================
-- Step 3: External Access Integration for dbt packages (hub.getdbt.com)
-- =============================================================================
CREATE OR REPLACE NETWORK RULE $DB_NAME.PUBLIC.DBT_NETWORK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('hub.getdbt.com', 'codeload.github.com');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION DBT_HUB_EAI
  ALLOWED_NETWORK_RULES = ($DB_NAME.PUBLIC.DBT_NETWORK_RULE)
  ENABLED = TRUE;

-- =============================================================================
-- Step 4: Create internal stage and populate from Git repository
-- Attendees PUT their edited files here during the lab — no GitHub push needed.
-- =============================================================================
USE ROLE SYSADMIN;

CREATE OR REPLACE STAGE $DB_NAME.PUBLIC.DBT_FILES
  DIRECTORY = (ENABLE = TRUE)
  COMMENT = 'dbt project files — attendees upload changes here via snow stage put';

COPY FILES
  INTO @$DB_NAME.PUBLIC.DBT_FILES/
  FROM @$DB_NAME.PUBLIC.HOL_REPO/branches/main/packages/dbt/;

GRANT READ, WRITE ON STAGE $DB_NAME.PUBLIC.DBT_FILES TO ROLE ATTENDEE_ROLE;

-- =============================================================================
-- Step 5: Deploy dbt Project from internal stage
-- =============================================================================
CREATE OR REPLACE DBT PROJECT $DB_NAME.MARTS.EVOLV_PAYMENT_ANALYTICS
  FROM '@$DB_NAME.PUBLIC.DBT_FILES/'
  DEFAULT_TARGET = 'dev'
  EXTERNAL_ACCESS_INTEGRATIONS = (DBT_HUB_EAI)
  COMMENT = 'evolv Payment Analytics - dbt project from internal stage';

-- =============================================================================
-- Step 6: Grant Access
-- =============================================================================
GRANT USAGE ON DBT PROJECT $DB_NAME.MARTS.EVOLV_PAYMENT_ANALYTICS
  TO ROLE ATTENDEE_ROLE;

-- =============================================================================
-- Step 7: Verify deployment
-- =============================================================================
SHOW DBT PROJECTS IN DATABASE $DB_NAME;

-- =============================================================================
-- Step 8: Execute dbt project (run)
-- =============================================================================
-- EXECUTE DBT PROJECT $DB_NAME.MARTS.EVOLV_PAYMENT_ANALYTICS
--   ARGS = 'run';
--
-- Note: Uncomment and run Step 8 after verifying the deployment succeeded.
-- You can also run:
--   ARGS = 'compile' — to validate without materializing
--   ARGS = 'deps'    — to install packages
--   ARGS = 'test'    — to run dbt tests
--   ARGS = 'build'   — to run + test
-- =============================================================================

-- =============================================================================
-- Attendee deployment workflow (during the HOL):
-- After editing dbt files locally with Cortex Code, upload to the stage:
--
--   snow stage put packages/dbt/models/marts/payments/authorizations.sql \
--     @$DB_NAME.PUBLIC.DBT_FILES/models/marts/payments/ --overwrite
--
-- Then re-execute the dbt project:
--   EXECUTE DBT PROJECT $DB_NAME.MARTS.EVOLV_PAYMENT_ANALYTICS ARGS = 'run';
-- =============================================================================

