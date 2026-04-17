-- =============================================================================
-- EVOLV PAYMENT ANALYTICS - dbt Project Deployment from Git
-- =============================================================================
-- This script creates the Snowflake objects needed to deploy and run the dbt
-- project directly from the GitHub repository.
--
-- Prerequisites:
--   - ACCOUNTADMIN role (for API/external integrations)
--   - Database COCO_SDLC_HOL exists
--   - Schemas RAW, STAGING, INTERMEDIATE, MARTS exist
--   - profiles.yml has been updated for Snowflake-native format
-- =============================================================================

-- =============================================================================
-- Step 1: GitHub API Integration (requires ACCOUNTADMIN)
-- =============================================================================
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE API INTEGRATION GITHUB_EVOLV_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/evolvconsulting')
  ENABLED = TRUE;

-- =============================================================================
-- Step 2: Git Repository Object
-- =============================================================================
CREATE OR REPLACE GIT REPOSITORY COCO_SDLC_HOL.PUBLIC.HOL_REPO
  API_INTEGRATION = GITHUB_EVOLV_INTEGRATION
  ORIGIN = 'https://github.com/evolvconsulting/coco_sdlc_hol.git';

GRANT READ ON GIT REPOSITORY COCO_SDLC_HOL.PUBLIC.HOL_REPO
  TO ROLE ATTENDEE_ROLE;

-- =============================================================================
-- Step 3: External Access Integration for dbt packages (hub.getdbt.com)
-- =============================================================================
CREATE OR REPLACE NETWORK RULE COCO_SDLC_HOL.PUBLIC.DBT_NETWORK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('hub.getdbt.com', 'codeload.github.com');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION DBT_HUB_EAI
  ALLOWED_NETWORK_RULES = (COCO_SDLC_HOL.PUBLIC.DBT_NETWORK_RULE)
  ENABLED = TRUE;

-- =============================================================================
-- Step 4: Deploy dbt Project from Git Repository
-- =============================================================================
USE ROLE SYSADMIN;

CREATE OR REPLACE DBT PROJECT COCO_SDLC_HOL.MARTS.EVOLV_PAYMENT_ANALYTICS
  FROM '@COCO_SDLC_HOL.PUBLIC.HOL_REPO/branches/"feature/dbt-in-snowflake"/packages/dbt'
  DEFAULT_TARGET = 'dev'
  EXTERNAL_ACCESS_INTEGRATIONS = (DBT_HUB_EAI)
  COMMENT = 'evolv Payment Analytics - linked to GitHub feature/dbt-in-snowflake branch';

-- =============================================================================
-- Step 5: Grant Access
-- =============================================================================
GRANT USAGE ON DBT PROJECT COCO_SDLC_HOL.MARTS.EVOLV_PAYMENT_ANALYTICS
  TO ROLE ATTENDEE_ROLE;

-- =============================================================================
-- Step 6: Verify deployment
-- =============================================================================
SHOW DBT PROJECTS IN DATABASE COCO_SDLC_HOL;

-- =============================================================================
-- Step 7: Execute dbt project (run)
-- =============================================================================
-- EXECUTE DBT PROJECT COCO_SDLC_HOL.MARTS.EVOLV_PAYMENT_ANALYTICS
--   ARGS = 'run';
--
-- Note: Uncomment and run Step 7 after verifying the deployment succeeded.
-- You can also run:
--   ARGS = 'compile' — to validate without materializing
--   ARGS = 'deps'    — to install packages
--   ARGS = 'test'    — to run dbt tests
--   ARGS = 'build'   — to run + test
-- =============================================================================
