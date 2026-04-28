-- SECTION 9.6: Per-user provisioning stored procedure
-- ============================================================
-- Handles everything that requires $$ inside a $$ block (which
-- causes Snowflake parser conflicts). Python SPs avoid this
-- because the $$ in agent SPECIFICATION is runtime string content,
-- not a lexical delimiter in the source.
-- Called by Section 10 for each cloned user database.
-- ============================================================
USE ROLE SYSADMIN;

CREATE OR REPLACE PROCEDURE COCO_SDLC_HOL_99.PUBLIC.PROVISION_HOL_USER(
    DB_NAME  VARCHAR,
    USERNAME VARCHAR
)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'provision_hol_user'
EXECUTE AS CALLER
AS
$$
def provision_hol_user(session, db_name: str, username: str) -> str:
    # Build dollar-dollar delimiter at runtime (avoids the two-dollar literal in this source)
    dd = '$' + '$'
    import re

    # 1. Zero-copy clone of template database
    session.sql(f"USE ROLE ACCOUNTADMIN").collect()
    # Per-user account role: each attendee gets HOL_ROLE_NN with a dedicated HOL_WH_NN warehouse
    # and grants only on their own database. ATTENDEE_ROLE is NOT inherited and is
    # revoked from the user at provisioning time — Snowsight will only show their
    # own database with no way to switch to a role that exposes others.
    # Username pattern: HOL_USER_NN  e.g. HOL_USER_02 -> suffix '02' -> role HOL_ROLE_02
    suffix = username[len('HOL_USER_'):]   # e.g. 'HOL_USER_02' -> '02'
    role_name = f'HOL_ROLE_{suffix}'      # -> 'HOL_ROLE_02'
    wh_name   = f'HOL_WH_{suffix}'        # -> 'HOL_WH_02'
    session.sql(f"CREATE ROLE IF NOT EXISTS {role_name}").collect()
    session.sql(
        f"CREATE OR REPLACE WAREHOUSE {wh_name}"
        f" WITH WAREHOUSE_SIZE = 'X-SMALL'"
        f" AUTO_SUSPEND = 60"
        f" AUTO_RESUME = TRUE"
        f" INITIALLY_SUSPENDED = TRUE"
        f" COMMENT = 'Dedicated compute for {username}'"
    ).collect()
    session.sql(f"GRANT USAGE ON WAREHOUSE {wh_name} TO ROLE {role_name}").collect()
    # SP runs EXECUTE AS CALLER — grant role to ACCOUNTADMIN so the caller can switch into it.
    session.sql(f"GRANT ROLE {role_name} TO ROLE ACCOUNTADMIN").collect()
    session.sql(
        f"CREATE DATABASE IF NOT EXISTS {db_name} CLONE COCO_SDLC_HOL_99"
        f" COMMENT = 'evolv HOL environment for {username}'"
    ).collect()
    session.sql(f"GRANT ALL PRIVILEGES ON DATABASE {db_name} TO ROLE {role_name}").collect()
    session.sql(f"GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE {db_name} TO ROLE {role_name}").collect()
    # HOL_ROLE_NN must be able to SELECT from RAW source tables when running dbt during the lab
    session.sql(f"GRANT SELECT ON ALL TABLES IN SCHEMA {db_name}.RAW TO ROLE {role_name}").collect()
    session.sql(f"GRANT SELECT ON FUTURE TABLES IN SCHEMA {db_name}.RAW TO ROLE {role_name}").collect()

    # 2. Per-user DBT_FILES stage
    session.sql("USE ROLE SYSADMIN").collect()
    session.sql(
        f"CREATE OR REPLACE STAGE {db_name}.PUBLIC.DBT_FILES"
        f" DIRECTORY = (ENABLE = TRUE)"
        f" COMMENT = 'dbt project files for {username} — upload changes here via snow stage put'"
    ).collect()
    session.sql(f"COPY FILES INTO @{db_name}.PUBLIC.DBT_FILES/ FROM @COCO_SDLC_HOL_99.PUBLIC.DBT_FILES/").collect()
    session.sql(f"REMOVE @{db_name}.PUBLIC.DBT_FILES/package-lock.yml").collect()

    # Write per-user profiles.yml via COPY INTO FROM SELECT
    # (CHR(10) produces newlines; no single quotes appear in profiles.yml content)
    profile_lines = [
        "dev:",
        "  target: dev",
        "  outputs:",
        "    dev:",
        "      type: snowflake",
        f"      database: {db_name}",
        f"      role: {role_name}",
        "      schema: STAGING",
        f"      warehouse: {wh_name}",
    ]
    sql_expr = " || CHR(10) || ".join(f"'{ln}'" for ln in profile_lines)
    session.sql(
        f"COPY INTO @{db_name}.PUBLIC.DBT_FILES/profiles.yml"
        f" FROM (SELECT {sql_expr} AS content)"
        f" FILE_FORMAT = (TYPE=CSV FIELD_DELIMITER='NONE' RECORD_DELIMITER='NONE'"
        f"                FIELD_OPTIONALLY_ENCLOSED_BY='NONE' COMPRESSION=NONE)"
        f" OVERWRITE=TRUE SINGLE=TRUE HEADER=FALSE"
    ).collect()
    # Write deploy_and_run_dbt.sql at the root of DBT_FILES so it appears
    # alongside the dbt project files when the workspace is seeded.
    # Uses versions/last — the most recently committed workspace snapshot —
    # which is reliable regardless of whether the workspace is actively open.
    redeploy_lines = [
        f"-- Edit dbt models in this workspace, then run the steps below to deploy and execute.",
        f"",
        f"-- Step 1: deploy your workspace edits into a new project version",
        f"ALTER DBT PROJECT {db_name}.MARTS.EVOLV_PAYMENT_ANALYTICS",
        f"  ADD VERSION",
        f"  FROM 'snow://workspace/{db_name}.MARTS.\"HOL_WORKSPACE\"/versions/last';",
        f"",
        f"-- Step 2: run the project",
        f"EXECUTE DBT PROJECT {db_name}.MARTS.EVOLV_PAYMENT_ANALYTICS",
        f"  ARGS = 'run';",
        f"",
        f"-- \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500",
        f"-- Optional: compile to generate the model DAG / lineage graph",
        f"-- \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500",
        f"",
        f"-- Step A: compile project (builds the manifest that powers the lineage graph)",
        f"-- EXECUTE DBT PROJECT {db_name}.MARTS.EVOLV_PAYMENT_ANALYTICS",
        f"--   ARGS = 'compile';",
    ]
    # Escape single quotes as '' so they survive SQL string wrapping
    redeploy_expr = " || CHR(10) || ".join(f"'{ln.replace(chr(39), chr(39)*2)}'" for ln in redeploy_lines)
    session.sql(
        f"COPY INTO @{db_name}.PUBLIC.DBT_FILES/deploy_and_run_dbt.sql"
        f" FROM (SELECT {redeploy_expr} AS content)"
        f" FILE_FORMAT = (TYPE=CSV FIELD_DELIMITER='NONE' RECORD_DELIMITER='NONE'"
        f"                FIELD_OPTIONALLY_ENCLOSED_BY='NONE' COMPRESSION=NONE)"
        f" OVERWRITE=TRUE SINGLE=TRUE HEADER=FALSE"
    ).collect()
    session.sql(f"ALTER STAGE {db_name}.PUBLIC.DBT_FILES REFRESH").collect()

    # 2b. Per-user STREAMLIT_FILES stage — populate as SYSADMIN (can read from template)
    session.sql(
        f"CREATE OR REPLACE STAGE {db_name}.PUBLIC.STREAMLIT_FILES"
        f" DIRECTORY = (ENABLE = TRUE)"
        f" COMMENT = 'Streamlit app files for {username}'"
    ).collect()
    session.sql(f"COPY FILES INTO @{db_name}.PUBLIC.STREAMLIT_FILES/ FROM @COCO_SDLC_HOL_99.PUBLIC.STREAMLIT_FILES/").collect()
    session.sql(f"ALTER STAGE {db_name}.PUBLIC.STREAMLIT_FILES REFRESH").collect()
    # Grant READ early so HOL_ROLE_NN can reference the stage when creating the Streamlit below
    session.sql(f"GRANT READ ON STAGE {db_name}.PUBLIC.STREAMLIT_FILES TO ROLE {role_name}").collect()
    # Create Streamlit as HOL_ROLE_NN — SiS executes SQL as the Streamlit owner's role.
    # HOL_ROLE_NN owns the MARTS dynamic tables, so no separate SYSADMIN grant is needed.
    session.sql("USE ROLE ACCOUNTADMIN").collect()
    session.sql(f"USE ROLE {role_name}").collect()
    session.sql(
        f"CREATE OR REPLACE STREAMLIT {db_name}.PUBLIC.PAYMENT_ANALYTICS_DASHBOARD"
        f" ROOT_LOCATION = '@{db_name}.PUBLIC.STREAMLIT_FILES'"
        f" MAIN_FILE = 'app.py'"
        f" QUERY_WAREHOUSE = {wh_name}"  # HOL_ROLE_NN has USAGE on HOL_WH_NN
        f" COMMENT = 'Payment Analytics Dashboard for {username}'"
    ).collect()
    session.sql("USE ROLE ACCOUNTADMIN").collect()
    # Stage grant (READ, WRITE) also added in section 6 grants loop below

    # 3. dbt project — DROP + CREATE forces fresh manifest compile
    #    so {{ target.database }} in sources.yml resolves to db_name
    session.sql(f"DROP DBT PROJECT IF EXISTS {db_name}.MARTS.EVOLV_PAYMENT_ANALYTICS").collect()
    session.sql(
        f"CREATE DBT PROJECT {db_name}.MARTS.EVOLV_PAYMENT_ANALYTICS"
        f" FROM '@{db_name}.PUBLIC.DBT_FILES/'"
        f" DEFAULT_TARGET = 'dev'"
        f" EXTERNAL_ACCESS_INTEGRATIONS = (DBT_HUB_EAI)"
        f" COMMENT = 'evolv Payment Analytics dbt project for {username}'"
    ).collect()
    session.sql("USE ROLE ACCOUNTADMIN").collect()
    # OWNERSHIP required for ALTER DBT PROJECT ADD VERSION (attendees redeploy from workspace)
    session.sql(
        f"GRANT OWNERSHIP ON DBT PROJECT {db_name}.MARTS.EVOLV_PAYMENT_ANALYTICS"
        f" TO ROLE {role_name} COPY CURRENT GRANTS"
    ).collect()
    # Fix all objects with wrong DB/warehouse references from zero-copy clone.
    # Processes in dependency order: STAGING views → INTERMEDIATE → MARTS.
    # Running as ACCOUNTADMIN — can CREATE OR REPLACE regardless of current ownership.
    # This replaces EXECUTE DBT PROJECT ARGS='run', eliminating the dbt Hub network call
    # and compilation step (~1-2 min saved per user).
    for schema, obj_kind in [
        ('STAGING',      'view'),
        ('INTERMEDIATE', 'dynamic_table'),
        ('MARTS',        'dynamic_table'),
    ]:
        # Set session context so unqualified object names from GET_DDL resolve to db_name.schema
        session.sql(f"USE SCHEMA {db_name}.{schema}").collect()
        if obj_kind == 'view':
            # Views show correctly as 'VIEW' in information_schema
            rows = session.sql(
                f"SELECT table_name FROM {db_name}.information_schema.tables "
                f"WHERE table_schema = '{schema}' AND table_type = 'VIEW' "
                f"ORDER BY table_name"
            ).collect()
            tnames = [row[0] for row in rows]
        else:
            # Cloned dynamic tables show as BASE TABLE in information_schema —
            # SHOW DYNAMIC TABLES correctly identifies them regardless of clone origin.
            rows = session.sql(f"SHOW DYNAMIC TABLES IN SCHEMA {db_name}.{schema}").collect()
            tnames = [row[1] for row in rows]  # column index 1 = 'name'
        for tname in tnames:
            ddl = session.sql(
                f"SELECT GET_DDL('{obj_kind}', '{db_name}.{schema}.{tname}')"
            ).collect()[0][0]
            # Replace any COCO_SDLC_HOL_NN reference (handles _01, _99, etc.)
            new_ddl = re.sub(r'COCO_SDLC_HOL_\d+', db_name, ddl)
            # Note: dynamic table refresh warehouse is kept as COMPUTE_WH (same as template).
            # HOL_WH_NN is used for interactive queries (dbt run, Streamlit, Cortex Analyst).
            session.sql(new_ddl).collect()
    # Re-grant ownership — CREATE OR REPLACE above transferred ownership to ACCOUNTADMIN.
    # HOL_ROLE_NN must own the dynamic tables so attendees can run dbt during the lab.
    session.sql(f"GRANT OWNERSHIP ON ALL DYNAMIC TABLES IN SCHEMA {db_name}.INTERMEDIATE TO ROLE {role_name} COPY CURRENT GRANTS").collect()
    session.sql(f"GRANT OWNERSHIP ON ALL DYNAMIC TABLES IN SCHEMA {db_name}.MARTS TO ROLE {role_name} COPY CURRENT GRANTS").collect()

    # 3b. Shared workspace — seeded with the full dbt project so attendees can
    #     edit models directly in the Snowsight IDE. deploy_and_run_dbt.sql
    #     (also at the root of DBT_FILES) deploys FROM this workspace's live
    #     version so workspace edits are what gets pushed to the DBT PROJECT.
    session.sql("USE ROLE ACCOUNTADMIN").collect()
    session.sql(
        f"CREATE OR REPLACE WORKSPACE {db_name}.MARTS.HOL_WORKSPACE"
        f" FROM '@{db_name}.PUBLIC.DBT_FILES/'"
    ).collect()
    session.sql(
        f"GRANT WRITE ON WORKSPACE {db_name}.MARTS.HOL_WORKSPACE TO ROLE {role_name}"
    ).collect()

    # 4. Semantic view — drop clone (wrong DB refs), recreate with correct refs
    # Read YAML as ACCOUNTADMIN (needs access to template DB), then create as HOL_ROLE_NN
    # so the attendee owns it and can CREATE OR REPLACE it during the lab.
    session.sql("USE ROLE ACCOUNTADMIN").collect()
    session.sql(f"DROP SEMANTIC VIEW IF EXISTS {db_name}.MARTS.PAYMENT_ANALYTICS").collect()
    rows = session.sql(
        "SELECT content FROM COCO_SDLC_HOL_99.PUBLIC.HOL_YAML_TEMPLATES"
        " WHERE template_name = 'semantic_view'"
    ).collect()
    sv_yaml = rows[0][0].replace('COCO_SDLC_HOL_99', db_name)
    session.sql(f"USE ROLE {role_name}").collect()
    session.sql(
        f"CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML('{db_name}.MARTS', {dd}{sv_yaml}{dd}, FALSE)"
    ).collect()
    session.sql("USE ROLE ACCOUNTADMIN").collect()

    # 5. Agent — drop clone, recreate pointing to per-user semantic view
    #    dd substituted at runtime so two dollar-signs never appear consecutively in source
    session.sql(f"DROP AGENT IF EXISTS {db_name}.MARTS.PAYMENT_ANALYTICS_AGENT").collect()
    agent_spec = f"""
models:
  orchestration: claude-sonnet-4-5
orchestration:
  budget:
    seconds: 60
    tokens: 16000
instructions:
  response: "You are a helpful payment analytics assistant. Provide clear, concise answers about payment transactions, settlements, funding, chargebacks, and merchant performance. Format numerical data appropriately with dollar signs and percentages where relevant."
  orchestration: "Use the PaymentAnalyst tool for all questions related to payment transactions, authorization volumes, settlement data, funding status, chargebacks, retrievals, adjustments, and merchant/store performance metrics."
  system: "You are a payment analytics expert helping users understand their transaction data, identify trends, and analyze merchant performance."
  sample_questions:
    - question: "What was our total authorization volume last month?"
      answer: "I will analyze the authorization data to calculate the total volume for last month."
    - question: "Which merchants have the highest chargeback rates?"
      answer: "Let me query the chargeback data to identify merchants with elevated dispute rates."
    - question: "Show me the funding status breakdown"
      answer: "I will retrieve the funding transaction data grouped by payment status."
tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "PaymentAnalyst"
      description: "Analyzes payment transaction data including authorizations, settlements, funding, chargebacks, retrievals, and adjustments across merchants and stores"
tool_resources:
  PaymentAnalyst:
    semantic_view: "{db_name}.MARTS.PAYMENT_ANALYTICS"
    execution_environment:
      type: warehouse
      warehouse: {wh_name}
"""
    session.sql(
        f"CREATE OR REPLACE AGENT {db_name}.MARTS.PAYMENT_ANALYTICS_AGENT"
        f" COMMENT = 'Cortex Agent for natural language queries on evolv Payment Analytics data'"
        f" PROFILE = '{{\"display_name\": \"Payment Analytics Assistant\", \"color\": \"blue\"}}'"
        f" FROM SPECIFICATION {dd}{agent_spec}{dd}"
    ).collect()

    # 5b. Transfer agent ownership to attendee role so ALTER AGENT SET SPECIFICATION works
    session.sql(
        f"GRANT OWNERSHIP ON AGENT {db_name}.MARTS.PAYMENT_ANALYTICS_AGENT"
        f" TO ROLE {role_name} COPY CURRENT GRANTS"
    ).collect()

    # 6. Per-user account role — final grants for objects created after initial clone.
    #    HOL_ROLE_NN already has ALL PRIVILEGES on the database/schemas (step 1).
    #    These add grants for objects created during provisioning (stage, agent, etc.)
    session.sql("USE ROLE ACCOUNTADMIN").collect()
    for sql in [
        f"GRANT READ, WRITE ON STAGE {db_name}.PUBLIC.DBT_FILES TO ROLE {role_name}",
        f"GRANT USAGE ON AGENT {db_name}.MARTS.PAYMENT_ANALYTICS_AGENT TO ROLE {role_name}",
        f"GRANT USAGE ON STREAMLIT {db_name}.PUBLIC.PAYMENT_ANALYTICS_DASHBOARD TO ROLE {role_name}",
        f"GRANT READ, WRITE ON STAGE {db_name}.PUBLIC.STREAMLIT_FILES TO ROLE {role_name}",
        f"GRANT SELECT ON ALL TABLES IN SCHEMA {db_name}.MARTS TO ROLE {role_name}",
        f"GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA {db_name}.MARTS TO ROLE {role_name}",
        f"GRANT SELECT ON ALL VIEWS IN SCHEMA {db_name}.STAGING TO ROLE {role_name}",
        f"GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA {db_name}.INTERMEDIATE TO ROLE {role_name}",
        # Required for ALTER DBT PROJECT ADD VERSION (runs dbt deps via external network)
        f"GRANT USAGE ON INTEGRATION DBT_HUB_EAI TO ROLE {role_name}",
        # Required for GET_JIRA_TICKET UDF (calls Atlassian REST API via external network)
        f"GRANT USAGE ON INTEGRATION ATLASSIAN_EAI TO ROLE {role_name}",
        # HOL_SHARED: allows attendees to reference the shared secret in their own UDFs
        f"GRANT USAGE ON DATABASE HOL_SHARED TO ROLE {role_name}",
        f"GRANT USAGE ON SCHEMA HOL_SHARED.PUBLIC TO ROLE {role_name}",
        f"GRANT READ ON SECRET HOL_SHARED.PUBLIC.ATLASSIAN_TOKEN_SECRET TO ROLE {role_name}",
        f"GRANT USAGE ON SECRET HOL_SHARED.PUBLIC.ATLASSIAN_TOKEN_SECRET TO ROLE {role_name}",
    ]:
        session.sql(sql).collect()

    # Assign per-user role to the attendee; set as default so Snowsight opens
    # with HOL_ROLE_NN active — only their own database appears in the catalog.
    # Revoke ATTENDEE_ROLE from the user so they cannot switch to it in Snowsight
    # and gain visibility into other attendees' databases.
    session.sql(f"GRANT ROLE {role_name} TO USER {username}").collect()
    session.sql(f"ALTER USER {username} SET DEFAULT_ROLE = '{role_name}'").collect()
    session.sql(f"ALTER USER {username} SET DEFAULT_WAREHOUSE = '{wh_name}'").collect()
    session.sql(f"ALTER USER {username} SET MINS_TO_BYPASS_MFA = 1200").collect()
    session.sql(f"REVOKE ROLE ATTENDEE_ROLE FROM USER {username}").collect()

    # Service user access: COCO_SDLC_HOL_SERVICE_USER uses ATTENDEE_ROLE for the
    # HOL frontend. Database roles are always active regardless of active account
    # role, so granting {db_name}.HOL_ATTENDEE directly to the service user lets it
    # query this database without holding HOL_ROLE_NN.
    session.sql(f"CREATE DATABASE ROLE IF NOT EXISTS {db_name}.HOL_ATTENDEE").collect()
    for sql in [
        f"GRANT ALL PRIVILEGES ON DATABASE {db_name} TO DATABASE ROLE {db_name}.HOL_ATTENDEE",
        f"GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE {db_name} TO DATABASE ROLE {db_name}.HOL_ATTENDEE",
        f"GRANT READ, WRITE ON STAGE {db_name}.PUBLIC.DBT_FILES TO DATABASE ROLE {db_name}.HOL_ATTENDEE",
        f"GRANT USAGE ON AGENT {db_name}.MARTS.PAYMENT_ANALYTICS_AGENT TO DATABASE ROLE {db_name}.HOL_ATTENDEE",
        f"GRANT USAGE ON STREAMLIT {db_name}.PUBLIC.PAYMENT_ANALYTICS_DASHBOARD TO DATABASE ROLE {db_name}.HOL_ATTENDEE",
        f"GRANT READ ON STAGE {db_name}.PUBLIC.STREAMLIT_FILES TO DATABASE ROLE {db_name}.HOL_ATTENDEE",
        f"GRANT USAGE ON DBT PROJECT {db_name}.MARTS.EVOLV_PAYMENT_ANALYTICS TO DATABASE ROLE {db_name}.HOL_ATTENDEE",
        f"GRANT SELECT ON ALL TABLES IN SCHEMA {db_name}.MARTS TO DATABASE ROLE {db_name}.HOL_ATTENDEE",
        f"GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA {db_name}.MARTS TO DATABASE ROLE {db_name}.HOL_ATTENDEE",
        f"GRANT SELECT ON ALL VIEWS IN SCHEMA {db_name}.STAGING TO DATABASE ROLE {db_name}.HOL_ATTENDEE",
        f"GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA {db_name}.INTERMEDIATE TO DATABASE ROLE {db_name}.HOL_ATTENDEE",
    ]:
        session.sql(sql).collect()
    try:
        session.sql(f"GRANT DATABASE ROLE {db_name}.HOL_ATTENDEE TO USER COCO_SDLC_HOL_SERVICE_USER").collect()
    except Exception:
        pass  # Service user may not exist if Section 7 (SPCS) was skipped

    return f"{db_name} provisioned for {username}"
$$;

GRANT USAGE ON PROCEDURE COCO_SDLC_HOL_99.PUBLIC.PROVISION_HOL_USER(VARCHAR, VARCHAR)
    TO ROLE ATTENDEE_ROLE;

