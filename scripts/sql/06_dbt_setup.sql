-- SECTION 6: dbt Project Deployment from Git
-- ============================================================
-- Instead of creating staging views, intermediate dynamic tables,
-- and marts dynamic tables manually, we deploy a dbt project from
-- Git that creates all transformation objects automatically.
-- ============================================================

-- Step 6a: GitHub API Integration (requires ACCOUNTADMIN)
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE API INTEGRATION GITHUB_EVOLV_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/evolvconsulting')
  ENABLED = TRUE;

-- Step 6b: Git Repository Object
CREATE OR REPLACE GIT REPOSITORY COCO_SDLC_HOL_99.PUBLIC.HOL_REPO
  API_INTEGRATION = GITHUB_EVOLV_INTEGRATION
  ORIGIN = 'https://github.com/evolvconsulting/coco_sdlc_hol.git';

GRANT READ ON GIT REPOSITORY COCO_SDLC_HOL_99.PUBLIC.HOL_REPO
  TO ROLE ATTENDEE_ROLE;

-- Step 6c: External Access Integration for dbt packages (hub.getdbt.com)
CREATE OR REPLACE NETWORK RULE COCO_SDLC_HOL_99.PUBLIC.DBT_NETWORK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('hub.getdbt.com', 'codeload.github.com');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION DBT_HUB_EAI
  ALLOWED_NETWORK_RULES = (COCO_SDLC_HOL_99.PUBLIC.DBT_NETWORK_RULE)
  ENABLED = TRUE;

-- Step 6c-ii: HOL_SHARED database — shared infrastructure accessible to all attendees
-- Network rules, secrets, and EAIs live here so every HOL_ROLE_NN can reference them
-- without needing access to another attendee's database.
USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS HOL_SHARED
  COMMENT = 'Shared HOL infrastructure — secrets, network rules, EAIs accessible to all attendees';

CREATE SCHEMA IF NOT EXISTS HOL_SHARED.PUBLIC;

-- Grant ATTENDEE_ROLE access to HOL_SHARED so:
--   (a) the initial template setup (which runs as ATTENDEE_ROLE) can reference these objects
--   (b) COCO_SDLC_HOL_SERVICE_USER (which uses ATTENDEE_ROLE) can resolve the objects
-- Note: HOL_ROLE_NN does NOT inherit from ATTENDEE_ROLE — each attendee role gets explicit
--       grants via the provisioning stored procedure loop (see Section 10).
GRANT USAGE ON DATABASE HOL_SHARED TO ROLE ATTENDEE_ROLE;
GRANT USAGE ON SCHEMA HOL_SHARED.PUBLIC TO ROLE ATTENDEE_ROLE;

-- Network rule and secret for Atlassian REST API
CREATE OR REPLACE NETWORK RULE HOL_SHARED.PUBLIC.ATLASSIAN_NETWORK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('api.atlassian.com', 'evolv-coco-sdlc-hol.atlassian.net');

CREATE OR REPLACE SECRET HOL_SHARED.PUBLIC.ATLASSIAN_TOKEN_SECRET
  TYPE = GENERIC_STRING
  SECRET_STRING = 'dHJlbnQuZm9sZXlAZXZvbHZjb25zdWx0aW5nLmNvbTpBVEFUVDN4RmZHRjBzRlNUanJfUFhtcTNmXzZpUjNOZDdnSWtsMDUweG92Vk5Nc2xMTTZ1bTlyb1lLelBpU2NsbUFoQjEzdjUzVzdiQ2xvamk3MHQwcEFITUdkZE9VZEcwY3E0RnhqM1BCNmo5R0NKbjl2bTVUMENzMVpnOEdJQk5veXVrUDVoQXF0SFZSMWY0Qmo0X2pYOUw0YmNRd2x6cWZ1RWhHVVV6VndJS2FTYVgtRy1RZG89NzU1RUY3RDU='
  COMMENT = 'Base64-encoded email:api_token for Atlassian Basic auth';

-- Grant attendees READ + USAGE so they can create UDFs referencing this secret
GRANT READ ON SECRET HOL_SHARED.PUBLIC.ATLASSIAN_TOKEN_SECRET TO ROLE ATTENDEE_ROLE;
GRANT USAGE ON SECRET HOL_SHARED.PUBLIC.ATLASSIAN_TOKEN_SECRET TO ROLE ATTENDEE_ROLE;

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION ATLASSIAN_EAI
  ALLOWED_NETWORK_RULES = (HOL_SHARED.PUBLIC.ATLASSIAN_NETWORK_RULE)
  ALLOWED_AUTHENTICATION_SECRETS = (HOL_SHARED.PUBLIC.ATLASSIAN_TOKEN_SECRET)
  ENABLED = TRUE
  COMMENT = 'Atlassian REST API access for Jira ticket lookup — shared across all HOL attendees';

-- ATTENDEE_ROLE needs USAGE on the EAI for initial template setup and service user;
-- HOL_ROLE_NN gets this grant explicitly in the provisioning SP loop
GRANT USAGE ON INTEGRATION ATLASSIAN_EAI TO ROLE ATTENDEE_ROLE;

-- GET_JIRA_TICKET is not pre-built centrally.
-- UI path attendees create it in their own PUBLIC schema as a lab exercise via Cortex Code.
-- CLI path attendees use the Atlassian MCP directly.

-- Step 6d: Internal stage for per-user dbt file edits
-- Each HOL user gets their own isolated copy of the dbt project files.
-- Attendees upload changes via 'snow stage put' during the lab — no GitHub push required.
USE ROLE SYSADMIN;

CREATE OR REPLACE STAGE COCO_SDLC_HOL_99.PUBLIC.DBT_FILES
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Template dbt project files — cloned into each user database by Section 10';

COPY FILES
    INTO @COCO_SDLC_HOL_99.PUBLIC.DBT_FILES/
    FROM @COCO_SDLC_HOL_99.PUBLIC.HOL_REPO/branches/main/packages/dbt/;

-- Remove stale package lock (pinned version from repo causes dbt Fusion validation error;
-- dbt regenerates it automatically on first run)
REMOVE @COCO_SDLC_HOL_99.PUBLIC.DBT_FILES/package-lock.yml;

-- Overwrite profiles.yml with correct template database name
-- (repo copy may have placeholder; COPY INTO writes clean YAML without compression)
COPY INTO @COCO_SDLC_HOL_99.PUBLIC.DBT_FILES/profiles.yml
FROM (
    SELECT
        'dev:' || CHR(10) ||
        '  target: dev' || CHR(10) ||
        '  outputs:' || CHR(10) ||
        '    dev:' || CHR(10) ||
        '      type: snowflake' || CHR(10) ||
        '      database: COCO_SDLC_HOL_99' || CHR(10) ||
        '      role: ATTENDEE_ROLE' || CHR(10) ||
        '      schema: STAGING' || CHR(10) ||
        '      warehouse: COMPUTE_WH' AS content
)
FILE_FORMAT = (TYPE=CSV FIELD_DELIMITER='NONE' RECORD_DELIMITER='NONE'
               FIELD_OPTIONALLY_ENCLOSED_BY='NONE' COMPRESSION=NONE)
OVERWRITE=TRUE SINGLE=TRUE HEADER=FALSE;

ALTER STAGE COCO_SDLC_HOL_99.PUBLIC.DBT_FILES REFRESH;

GRANT READ, WRITE ON STAGE COCO_SDLC_HOL_99.PUBLIC.DBT_FILES TO ROLE ATTENDEE_ROLE;

-- Step 6d-ii: Streamlit app — template files stage + HOL_01 app
-- apps/streamlit/app.py and environment.yml live in the repo under apps/streamlit/
-- If running before those files are committed to the repo branch, upload manually first:
--   snow stage put apps/streamlit/app.py @COCO_SDLC_HOL_99.PUBLIC.STREAMLIT_FILES/ --overwrite
--   snow stage put apps/streamlit/environment.yml @COCO_SDLC_HOL_99.PUBLIC.STREAMLIT_FILES/ --overwrite
USE ROLE SYSADMIN;

CREATE OR REPLACE STAGE COCO_SDLC_HOL_99.PUBLIC.STREAMLIT_FILES
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Streamlit app files — cloned into each user database by Section 10';

COPY FILES
    INTO @COCO_SDLC_HOL_99.PUBLIC.STREAMLIT_FILES/
    FROM @COCO_SDLC_HOL_99.PUBLIC.HOL_REPO/branches/main/apps/streamlit/;

ALTER STAGE COCO_SDLC_HOL_99.PUBLIC.STREAMLIT_FILES REFRESH;

GRANT READ ON STAGE COCO_SDLC_HOL_99.PUBLIC.STREAMLIT_FILES TO ROLE ATTENDEE_ROLE;

CREATE OR REPLACE STREAMLIT COCO_SDLC_HOL_99.PUBLIC.PAYMENT_ANALYTICS_DASHBOARD
    ROOT_LOCATION = '@COCO_SDLC_HOL_99.PUBLIC.STREAMLIT_FILES'
    MAIN_FILE = 'app.py'
    QUERY_WAREHOUSE = COMPUTE_WH
    COMMENT = 'Payment Analytics Dashboard — Authorization overview (Streamlit in Snowflake)';

GRANT USAGE ON STREAMLIT COCO_SDLC_HOL_99.PUBLIC.PAYMENT_ANALYTICS_DASHBOARD TO ROLE ATTENDEE_ROLE;

-- Step 6e: Deploy dbt Project from internal stage
-- DROP + CREATE (not CREATE OR REPLACE) ensures a fresh manifest compile
-- so {{ target.database }} in sources.yml resolves correctly to COCO_SDLC_HOL_99
DROP DBT PROJECT IF EXISTS COCO_SDLC_HOL_99.MARTS.EVOLV_PAYMENT_ANALYTICS;
CREATE DBT PROJECT COCO_SDLC_HOL_99.MARTS.EVOLV_PAYMENT_ANALYTICS
  FROM '@COCO_SDLC_HOL_99.PUBLIC.DBT_FILES/'
  DEFAULT_TARGET = 'dev'
  EXTERNAL_ACCESS_INTEGRATIONS = (DBT_HUB_EAI)
  COMMENT = 'evolv Payment Analytics - dbt project from internal stage';

-- Step 6f: Grant Access
GRANT USAGE ON DBT PROJECT COCO_SDLC_HOL_99.MARTS.EVOLV_PAYMENT_ANALYTICS
  TO ROLE ATTENDEE_ROLE;

-- Step 6g: Execute dbt project to create staging views, intermediate
-- dynamic tables, and marts dynamic tables
EXECUTE DBT PROJECT COCO_SDLC_HOL_99.MARTS.EVOLV_PAYMENT_ANALYTICS
  ARGS = 'run';

USE ROLE ATTENDEE_ROLE;

