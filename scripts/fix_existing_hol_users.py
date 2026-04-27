#!/usr/bin/env python3
"""
fix_existing_hol_users.py

Migrates existing HOL databases (02, 05, 06, 07) from the shared ATTENDEE_ROLE
grant model to per-user HOL_ROLE_NN account roles, and renames users to the
HOL_USER_NN pattern.

Actions per database:
  1. Rename HOL_USER{NN} -> HOL_USER_{NN}
  2. Transfer OWNERSHIP of ATTENDEE_ROLE-owned objects to ACCOUNTADMIN
  3. Revoke all remaining ATTENDEE_ROLE grants on the database
  4. Create HOL_ROLE_{NN} and inherit ATTENDEE_ROLE (for warehouse / integrations)
  5. Grant database-specific privileges to HOL_ROLE_{NN}
  6. Grant HOL_ROLE_{NN} to user; set as default role (Snowsight isolation)
  7. Ensure DATABASE ROLE HOL_ATTENDEE exists and service user has it
"""

import snowflake.connector

USERS = [
    {'old_user': 'HOL_USER02', 'new_user': 'HOL_USER_02', 'db': 'COCO_SDLC_HOL_02', 'role': 'HOL_ROLE_02'},
    {'old_user': 'HOL_USER05', 'new_user': 'HOL_USER_05', 'db': 'COCO_SDLC_HOL_05', 'role': 'HOL_ROLE_05'},
    {'old_user': 'HOL_USER06', 'new_user': 'HOL_USER_06', 'db': 'COCO_SDLC_HOL_06', 'role': 'HOL_ROLE_06'},
    {'old_user': 'HOL_USER07', 'new_user': 'HOL_USER_07', 'db': 'COCO_SDLC_HOL_07', 'role': 'HOL_ROLE_07'},
]

# Map SHOW GRANTS 'granted_on' column values to SQL object-type syntax used in
# REVOKE / GRANT OWNERSHIP statements (Snowflake uses underscores in metadata
# but spaces in DDL).
OBJECT_TYPE_MAP = {
    'DYNAMIC_TABLE':     'DYNAMIC TABLE',
    'SEMANTIC_VIEW':     'SEMANTIC VIEW',
    'DBT_PROJECT':       'DBT PROJECT',
    'MATERIALIZED_VIEW': 'MATERIALIZED VIEW',
    'EXTERNAL_TABLE':    'EXTERNAL TABLE',
    'EVENT_TABLE':       'EVENT TABLE',
}


def sql_object_type(granted_on: str) -> str:
    return OBJECT_TYPE_MAP.get(granted_on.upper(), granted_on)


def run(cur, sql: str, label: str = '') -> bool:
    try:
        cur.execute(sql)
        print(f"  OK   {label or sql[:100]}")
        return True
    except Exception as e:
        msg = str(e)
        lowered = msg.lower()
        if any(k in lowered for k in ('already exists', 'not found', 'does not exist',
                                       'already been granted', 'is not granted')):
            print(f"  SKIP {label or sql[:80]} | {msg[:120]}")
        else:
            print(f"  ERR  {label or sql[:80]} | {msg[:120]}")
        return False


def fix_database(cur, entry: dict) -> None:
    old_user = entry['old_user']
    new_user = entry['new_user']
    db       = entry['db']
    role     = entry['role']

    print(f"\n{'='*62}")
    print(f"  {db}  |  user: {old_user} -> {new_user}  |  role: {role}")
    print(f"{'='*62}")

    # ------------------------------------------------------------------ #
    # 1. Rename user to HOL_USER_NN pattern; also update login_name so    #
    #    attendees can log in with the new name (RENAME does not update   #
    #    LOGIN_NAME automatically).                                       #
    # ------------------------------------------------------------------ #
    run(cur, f"ALTER USER IF EXISTS {old_user} RENAME TO {new_user}",
        f"rename {old_user} -> {new_user}")
    run(cur, f"ALTER USER IF EXISTS {new_user} SET LOGIN_NAME = '{new_user}'",
        f"set login_name {new_user}")

    # ------------------------------------------------------------------ #
    # 2. Transfer OWNERSHIP of ATTENDEE_ROLE objects -> ACCOUNTADMIN      #
    #    then collect remaining (non-ownership) grants for revocation      #
    # ------------------------------------------------------------------ #
    print("\n  -- transfer ATTENDEE_ROLE ownership --")
    cur.execute("SHOW GRANTS TO ROLE ATTENDEE_ROLE")
    grants = cur.fetchall()
    cols   = [d[0] for d in cur.description]

    ownership_rows = []
    other_rows     = []
    for row in grants:
        g         = dict(zip(cols, row))
        name      = str(g.get('name', ''))
        privilege = str(g.get('privilege', ''))
        granted_on = str(g.get('granted_on', ''))

        # Only care about objects inside this database
        db_prefix = db.upper() + '.'
        if name.upper() != db.upper() and not name.upper().startswith(db_prefix):
            continue

        obj_type = sql_object_type(granted_on)
        if privilege == 'OWNERSHIP':
            ownership_rows.append((obj_type, name))
        else:
            other_rows.append((privilege, obj_type, name))

    for obj_type, name in ownership_rows:
        run(cur,
            f"GRANT OWNERSHIP ON {obj_type} {name} TO ROLE ACCOUNTADMIN COPY CURRENT GRANTS",
            f"ownership transfer: {obj_type} {name}")

    # ------------------------------------------------------------------ #
    # 3. Revoke remaining grants (non-ownership) from ATTENDEE_ROLE       #
    # ------------------------------------------------------------------ #
    print("\n  -- revoke remaining ATTENDEE_ROLE grants --")
    for privilege, obj_type, name in other_rows:
        run(cur,
            f"REVOKE {privilege} ON {obj_type} {name} FROM ROLE ATTENDEE_ROLE",
            f"revoke {privilege} on {obj_type} {name}")

    # Belt-and-suspenders bulk revokes for any objects not surfaced above
    for schema in ['RAW', 'STAGING', 'INTERMEDIATE', 'MARTS', 'PUBLIC']:
        for stmt in [
            f"REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA {db}.{schema} FROM ROLE ATTENDEE_ROLE",
            f"REVOKE ALL PRIVILEGES ON ALL VIEWS IN SCHEMA {db}.{schema} FROM ROLE ATTENDEE_ROLE",
            f"REVOKE ALL PRIVILEGES ON ALL STAGES IN SCHEMA {db}.{schema} FROM ROLE ATTENDEE_ROLE",
            f"REVOKE ALL PRIVILEGES ON ALL DYNAMIC TABLES IN SCHEMA {db}.{schema} FROM ROLE ATTENDEE_ROLE",
        ]:
            run(cur, stmt)

    # ------------------------------------------------------------------ #
    # 4. Create per-user role; grant COMPUTE_WH directly (no ATTENDEE_ROLE #
    #    inheritance — that would re-expose other databases).             #
    # ------------------------------------------------------------------ #
    print(f"\n  -- create {role} --")
    run(cur, f"CREATE ROLE IF NOT EXISTS {role}")
    run(cur, f"GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE {role}")

    # ------------------------------------------------------------------ #
    # 5. Grant database-specific privileges to per-user role              #
    # ------------------------------------------------------------------ #
    print(f"\n  -- grant {db} privileges to {role} --")
    for sql in [
        f"GRANT ALL PRIVILEGES ON DATABASE {db} TO ROLE {role}",
        f"GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE {db} TO ROLE {role}",
        f"GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA {db}.RAW TO ROLE {role}",
        f"GRANT SELECT ON ALL TABLES IN SCHEMA {db}.MARTS TO ROLE {role}",
        f"GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA {db}.MARTS TO ROLE {role}",
        f"GRANT SELECT ON ALL VIEWS IN SCHEMA {db}.STAGING TO ROLE {role}",
        f"GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA {db}.INTERMEDIATE TO ROLE {role}",
        f"GRANT READ, WRITE ON STAGE {db}.PUBLIC.DBT_FILES TO ROLE {role}",
        f"GRANT USAGE ON AGENT {db}.MARTS.PAYMENT_ANALYTICS_AGENT TO ROLE {role}",
        f"GRANT USAGE ON DBT PROJECT {db}.MARTS.EVOLV_PAYMENT_ANALYTICS TO ROLE {role}",
    ]:
        run(cur, sql)

    # ------------------------------------------------------------------ #
    # 6. Assign per-user role to attendee; set as default; revoke         #
    #    ATTENDEE_ROLE so the user cannot switch to it in Snowsight.      #
    # ------------------------------------------------------------------ #
    print(f"\n  -- assign {role} to {new_user}, revoke ATTENDEE_ROLE --")
    run(cur, f"GRANT ROLE {role} TO USER {new_user}")
    run(cur, f"ALTER USER {new_user} SET DEFAULT_ROLE = '{role}'")
    run(cur, f"REVOKE ROLE ATTENDEE_ROLE FROM USER {new_user}")

    # ------------------------------------------------------------------ #
    # 7. Service user: database role (active regardless of account role)  #
    # ------------------------------------------------------------------ #
    print(f"\n  -- service user database role for {db} --")
    run(cur, f"CREATE DATABASE ROLE IF NOT EXISTS {db}.HOL_ATTENDEE")
    for sql in [
        f"GRANT ALL PRIVILEGES ON DATABASE {db} TO DATABASE ROLE {db}.HOL_ATTENDEE",
        f"GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE {db} TO DATABASE ROLE {db}.HOL_ATTENDEE",
        f"GRANT READ, WRITE ON STAGE {db}.PUBLIC.DBT_FILES TO DATABASE ROLE {db}.HOL_ATTENDEE",
        f"GRANT USAGE ON AGENT {db}.MARTS.PAYMENT_ANALYTICS_AGENT TO DATABASE ROLE {db}.HOL_ATTENDEE",
        f"GRANT USAGE ON DBT PROJECT {db}.MARTS.EVOLV_PAYMENT_ANALYTICS TO DATABASE ROLE {db}.HOL_ATTENDEE",
        f"GRANT SELECT ON ALL TABLES IN SCHEMA {db}.MARTS TO DATABASE ROLE {db}.HOL_ATTENDEE",
        f"GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA {db}.MARTS TO DATABASE ROLE {db}.HOL_ATTENDEE",
        f"GRANT SELECT ON ALL VIEWS IN SCHEMA {db}.STAGING TO DATABASE ROLE {db}.HOL_ATTENDEE",
        f"GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA {db}.INTERMEDIATE TO DATABASE ROLE {db}.HOL_ATTENDEE",
    ]:
        run(cur, sql)
    run(cur, f"GRANT DATABASE ROLE {db}.HOL_ATTENDEE TO USER COCO_SDLC_HOL_SERVICE_USER")


def main() -> None:
    conn = snowflake.connector.connect(
        account='hdb72179.us-east-1',
        user='VDASILVA',
        authenticator='SNOWFLAKE_JWT',
        private_key_file='/Users/vlaunir/.snowflake/keys/rsa_key.p8',
        role='ACCOUNTADMIN',
    )
    cur = conn.cursor()
    try:
        for entry in USERS:
            fix_database(cur, entry)
        print("\n\nAll databases processed successfully.")
    finally:
        cur.close()
        conn.close()


if __name__ == '__main__':
    main()
