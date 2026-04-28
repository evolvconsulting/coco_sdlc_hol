-- SECTION 1: ACCOUNTADMIN Bootstrap
-- ============================================================
USE ROLE ACCOUNTADMIN;

-- Enable cross-region inference so Cortex LLM functions can route to available
-- capacity outside the account's home region. Required for Snowflake Cortex
-- inference (e.g. COMPLETE, CLASSIFY_TEXT) to work; out of scope for the lab
-- but must be enabled before lab exercises that use Cortex AI features.
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_US';

CREATE ROLE IF NOT EXISTS ATTENDEE_ROLE;
GRANT ROLE ATTENDEE_ROLE TO ROLE SYSADMIN;

GRANT CREATE DATABASE ON ACCOUNT TO ROLE ATTENDEE_ROLE;
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE ATTENDEE_ROLE;
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE ATTENDEE_ROLE;

CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  COMMENT = 'HOL warehouse for dbt dynamic tables and Cortex Agent';

GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ATTENDEE_ROLE;

