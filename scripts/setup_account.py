#!/usr/bin/env python3
"""
setup_account.py — Phase 1: Account-level bootstrap + attendee user creation.

What this does:
  Section 1 : Creates ATTENDEE_ROLE, COMPUTE_WH, account-level grants (sql/01_account_bootstrap.sql)
  Section 2 : Creates HOL_USER_NN (01..user_count) with password + MFA bypass

Run directly (from repo root):
    uv run python3 scripts/setup_account.py
    uv run python3 scripts/setup_account.py --users 20

Or via master script:
    uv run python3 scripts/hol_setup.py --phase account --users 20
"""
import argparse
import sys
from hol_util import connect, run_sql, run_sql_file
from config_loader import USER_COUNT, USER_PREFIX, HOL_PASSWORD


def run(con=None, user_count: int = USER_COUNT) -> bool:
    close = con is None
    if con is None:
        con = connect()
    ok = True
    try:
        print("=== Phase: Account Bootstrap ===")

        # Section 1 — account-level objects (role, warehouse, grants, cross-region inference)
        ok = run_sql_file(con, "01_account_bootstrap.sql", "Section 1: account bootstrap") and ok

        # Section 2 — create attendee users with password + MFA bypass
        print(f"  Creating {user_count} HOL user(s)...", flush=True)
        for i in range(1, user_count + 1):
            nn       = f"{i:02d}"
            username = f"{USER_PREFIX}_{nn}"
            ok = run_sql(con,
                f"CREATE USER IF NOT EXISTS {username}"
                f" PASSWORD = '{HOL_PASSWORD}'"
                f" DEFAULT_ROLE = ATTENDEE_ROLE"
                f" DEFAULT_WAREHOUSE = COMPUTE_WH"
                f" MUST_CHANGE_PASSWORD = FALSE"
                f" COMMENT = 'HOL attendee user'",
                f"Section 2: CREATE USER {username}",
            ) and ok
            ok = run_sql(con,
                f"ALTER USER {username} SET MINS_TO_BYPASS_MFA = 1200",
                f"Section 2: MFA bypass {username}",
            ) and ok
            ok = run_sql(con,
                f"GRANT ROLE ATTENDEE_ROLE TO USER {username}",
                f"Section 2: grant role {username}",
            ) and ok

        print(f"  Created {user_count} user(s).", flush=True)
    finally:
        if close:
            con.close()
    return ok


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Account bootstrap + create HOL attendee users.")
    parser.add_argument(
        "--users", type=int, default=USER_COUNT,
        help=f"Number of attendee users to create. Default: {USER_COUNT}",
    )
    args = parser.parse_args()
    if not run(user_count=args.users):
        sys.exit(1)
    print("\nPhase 'account' complete.")
