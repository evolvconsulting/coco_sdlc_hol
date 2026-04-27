-- =============================================================================
-- HOL Reset Script
-- =============================================================================
-- Drops all per-user objects then reprovisiones each attendee from scratch.
-- Run the full script (both sections) for a clean reset, or run Section 1
-- alone to drop without reprovisioning.
--
-- What gets dropped (for each attendee NN = 01..NUM_USERS, skipping 99):
--   DATABASE  COCO_SDLC_HOL_NN   all dbt, workspace, streamlit, agent objects
--   ROLE      HOL_ROLE_NN        all permission and ownership grants
--   WAREHOUSE HOL_WH_NN          dedicated attendee compute
--
-- What is NOT touched:
--   Snowflake USER accounts (HOL_USER_NN)  passwords and MFA remain intact
--   COCO_SDLC_HOL_99                       template DB + PROVISION_HOL_USER
--   HOL_SHARED                             shared secrets, EAI, network rules
-- =============================================================================

-- Set the number of attendees (must match Section 0 of hol_setup.sql).
-- HOL_USER_99 is always skipped automatically.
SET NUM_USERS = 20;

-- =============================================================================
-- Section 1: Drop all per-user objects
-- =============================================================================
USE ROLE ACCOUNTADMIN;

EXECUTE IMMEDIATE $$
DECLARE
    num_users INTEGER DEFAULT 20;  -- keep in sync with SET NUM_USERS above
BEGIN
    FOR i IN 1 TO :num_users DO

        -- Skip 99 — template database, never drop
        IF (i = 99) THEN
            CONTINUE;
        END IF;

        LET suffix    VARCHAR := LPAD(i::VARCHAR, 2, '0');
        LET db_name   VARCHAR := 'COCO_SDLC_HOL_' || :suffix;
        LET role_name VARCHAR := 'HOL_ROLE_' || :suffix;
        LET wh_name   VARCHAR := 'HOL_WH_' || :suffix;

        DROP DATABASE  IF EXISTS IDENTIFIER(:db_name);
        DROP ROLE      IF EXISTS IDENTIFIER(:role_name);
        DROP WAREHOUSE IF EXISTS IDENTIFIER(:wh_name);

    END FOR;

    RETURN 'Dropped objects for HOL_USER_01 .. HOL_USER_'
        || LPAD(:num_users::VARCHAR, 2, '0')
        || ' (skipped 99 — template)';
END;
$$;


-- =============================================================================
-- Section 2: Reprovision all attendees
-- =============================================================================
-- Run this immediately after Section 1, or separately after fixing any setup
-- issues in COCO_SDLC_HOL_99.PUBLIC.PROVISION_HOL_USER.
--
-- RECOMMENDED: use the Python script instead — drops + reprovisiones in parallel,
-- no worksheet needed.  Set credentials in config.local.yml first, then:
--
--   uv run python3 reset_attendees.py               # drop + reprovision
--   uv run python3 reset_attendees.py --drop-only   # drop only
--   uv run python3 reset_attendees.py --users 20 --workers 5
--
-- Timing reference:
--   This SQL loop (~2.5 min/user) : 20 users ≈ 50 min
--   reset_attendees.py --workers 5: 20 users ≈ 10 min
-- =============================================================================
USE ROLE ACCOUNTADMIN;

EXECUTE IMMEDIATE $$
DECLARE
    num_users INTEGER DEFAULT 20;  -- keep in sync with SET NUM_USERS above
BEGIN
    FOR i IN 1 TO :num_users DO

        -- Skip 99 — template, never provision as attendee
        IF (i = 99) THEN
            CONTINUE;
        END IF;

        LET suffix   VARCHAR := LPAD(i::VARCHAR, 2, '0');
        LET db_name  VARCHAR := 'COCO_SDLC_HOL_' || :suffix;
        LET username VARCHAR := 'HOL_USER_' || :suffix;

        CALL COCO_SDLC_HOL_99.PUBLIC.PROVISION_HOL_USER(:db_name, :username);

    END FOR;

    RETURN 'Provisioned HOL_USER_01 .. HOL_USER_'
        || LPAD(:num_users::VARCHAR, 2, '0')
        || ' (skipped 99 — template)';
END;
$$;
