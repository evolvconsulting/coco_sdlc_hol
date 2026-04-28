#!/usr/bin/env python3
"""
reset_attendees.py — Drop all attendee databases/roles/warehouses and optionally reprovision.

What gets dropped (for each NN = 01..USER_COUNT, skipping 99):
  DATABASE  COCO_SDLC_HOL_NN
  ROLE      HOL_ROLE_NN
  WAREHOUSE HOL_WH_NN

What is NOT touched:
  HOL_USER_NN accounts   (passwords and MFA bypass remain intact)
  COCO_SDLC_HOL_99       (template DB + PROVISION_HOL_USER SP)
  HOL_SHARED             (shared secrets, EAI, network rules)

Usage (from repo root):
    uv run python3 scripts/reset_attendees.py               # drop + reprovision all
    uv run python3 scripts/reset_attendees.py --drop-only   # drop only
    uv run python3 scripts/reset_attendees.py --users 5     # drop+reprovision first 5
"""
import argparse
import sys

from hol_util import connect, run_sql
from config_loader import USER_COUNT, WORKERS, DB_PREFIX, USER_PREFIX, TEMPLATE_DB
import provision_attendees


def drop_all(user_count: int, con=None) -> bool:
    close = con is None
    if con is None:
        con = connect()
    ok = True
    template_num = int(TEMPLATE_DB.replace(DB_PREFIX + "_", ""))
    try:
        print(f"=== Drop: {user_count} attendee environment(s) ===")
        for i in range(1, user_count + 1):
            if i == template_num:
                continue
            nn = f"{i:02d}"
            ok = run_sql(con, f"DROP DATABASE  IF EXISTS {DB_PREFIX}_{nn}",      f"DROP DB   {DB_PREFIX}_{nn}") and ok
            ok = run_sql(con, f"DROP ROLE      IF EXISTS HOL_ROLE_{nn}",          f"DROP ROLE HOL_ROLE_{nn}") and ok
            ok = run_sql(con, f"DROP WAREHOUSE IF EXISTS HOL_WH_{nn}",            f"DROP WH   HOL_WH_{nn}") and ok
    finally:
        if close:
            con.close()
    return ok


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Drop HOL attendee environments and optionally reprovision."
    )
    parser.add_argument(
        "--users", type=int, default=USER_COUNT,
        help=f"Number of attendees to reset. Default: {USER_COUNT}",
    )
    parser.add_argument(
        "--workers", type=int, default=WORKERS,
        help=f"Parallel workers for reprovisioning. Default: {WORKERS}",
    )
    parser.add_argument(
        "--drop-only", action="store_true",
        help="Drop environments without reprovisioning.",
    )
    args = parser.parse_args()

    if not drop_all(args.users):
        sys.exit(1)

    if args.drop_only:
        print("\nDrop complete (skipping reprovision — pass without --drop-only to reprovision).")
        return

    print()
    if not provision_attendees.run(user_count=args.users, workers=args.workers):
        sys.exit(1)
    print("\nReset complete.")


if __name__ == "__main__":
    main()
