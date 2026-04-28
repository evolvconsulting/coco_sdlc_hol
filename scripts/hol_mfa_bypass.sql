-- Moderator Tool: MFA Bypass Management
-- Run as ACCOUNTADMIN in a Snowflake worksheet (Snowsight or Snow CLI).
--
-- SECTIONS:
--   A  : Check current bypass status for all HOL users
--   B  : Fix a SINGLE user (edit the username at the top)
--   C  : Fix ALL HOL users at once
--   D  : Reset bypass for all users (end-of-day cleanup)
--
-- WHEN TO USE:
--   - Attendee gets an MFA prompt and can't connect (Cortex Code, Snow CLI, etc.)
--   - Run section B for the affected user, or section C to fix everyone at once.

USE ROLE ACCOUNTADMIN;

-- ============================================================
-- CONFIGURATION — edit these values as needed
-- ============================================================

SET HOL_USERNAME   = 'HOL_USER_02';      -- used by Section B (single-user fix)
SET NUM_USERS      = 20;                  -- total users provisioned; used by sections C and D
SET BYPASS_MINUTES = 480;                 -- bypass duration in minutes (480 = 8 hours)

-- ============================================================
-- SECTION A: Check current MFA bypass status for all HOL users
-- ============================================================

SHOW USERS LIKE 'HOL_USER_%';

-- Look at the MINS_TO_BYPASS_MFA column in the results.
-- 0 or NULL = MFA is active (no bypass).  >0 = bypass still in effect.


-- ============================================================
-- SECTION B: Fix a single user
-- Edit SET HOL_USERNAME above, then run this one statement.
-- ============================================================

ALTER USER IDENTIFIER($HOL_USERNAME) SET MINS_TO_BYPASS_MFA = $BYPASS_MINUTES;

-- Confirm:
-- SELECT $HOL_USERNAME AS username, $BYPASS_MINUTES AS bypass_minutes_set;


-- ============================================================
-- SECTION C: Fix ALL HOL users at once
-- Loops HOL_USER_01 through HOL_USER_<NUM_USERS>.
-- ============================================================

EXECUTE IMMEDIATE $$
DECLARE
    num_users      INTEGER DEFAULT 20;
    bypass_minutes INTEGER DEFAULT 480;
    i              INTEGER;
    username       VARCHAR;
    suffix         VARCHAR;
BEGIN
    FOR i IN 1 TO :num_users DO
        suffix   := LPAD(i::VARCHAR, 2, '0');
        username := 'HOL_USER_' || :suffix;
        EXECUTE IMMEDIATE
            'ALTER USER ' || :username ||
            ' SET MINS_TO_BYPASS_MFA = ' || :bypass_minutes;
    END FOR;
    RETURN 'MFA bypass set to ' || :bypass_minutes || ' min for HOL_USER_01 … HOL_USER_' || LPAD(:num_users::VARCHAR, 2, '0');
END;
$$;


-- ============================================================
-- SECTION D: Reset — remove MFA bypass for all users (end of day)
-- Sets MINS_TO_BYPASS_MFA back to 0 (MFA resumes for enrolled users).
-- ============================================================

EXECUTE IMMEDIATE $$
DECLARE
    num_users INTEGER DEFAULT 20;
    i         INTEGER;
    username  VARCHAR;
    suffix    VARCHAR;
BEGIN
    FOR i IN 1 TO :num_users DO
        suffix   := LPAD(i::VARCHAR, 2, '0');
        username := 'HOL_USER_' || :suffix;
        EXECUTE IMMEDIATE
            'ALTER USER ' || :username ||
            ' SET MINS_TO_BYPASS_MFA = 0';
    END FOR;
    RETURN 'MFA bypass cleared for HOL_USER_01 … HOL_USER_' || LPAD(:num_users::VARCHAR, 2, '0');
END;
$$;
