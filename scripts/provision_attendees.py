#!/usr/bin/env python3
"""
provision_attendees.py — Phase 3: Clone template DB + provision all attendee databases.

Calls COCO_SDLC_HOL_99.PUBLIC.PROVISION_HOL_USER for N users in parallel using
a dedicated snowflake.connector connection per thread.

Run directly (from repo root):
    uv run python3 scripts/provision_attendees.py
    uv run python3 scripts/provision_attendees.py --users 20 --workers 5

Or via master script:
    uv run python3 scripts/hol_setup.py --phase provision

Timing reference (X-SMALL warehouse per user):
    Sequential (hol_reset.sql loop) : ~2.5 min/user  → 20 users = ~50 min
    This script with --workers 5    : ~2.5 min/batch  → 20 users = ~10 min
"""
import argparse
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

import snowflake.connector

from config_loader import (
    TEMPLATE_DB, DB_PREFIX, USER_PREFIX, USER_COUNT, WORKERS,
)
from hol_util import check_credentials, conn_kwargs as _conn_kwargs


def provision_one(conn_kwargs: dict, db_name: str, username: str) -> str:
    """Open a dedicated connection, call PROVISION_HOL_USER, return a status line."""
    con = snowflake.connector.connect(**conn_kwargs)
    try:
        cur = con.cursor()
        cur.execute(
            f"CALL {TEMPLATE_DB}.PUBLIC.PROVISION_HOL_USER('{db_name}', '{username}')"
        )
        msg = cur.fetchone()[0]
        return f"  OK   {username}: {msg}"
    except Exception as exc:
        return f"  ERR  {username}: {exc}"
    finally:
        con.close()


def run(user_count: int = USER_COUNT, workers: int = WORKERS) -> bool:
    check_credentials()
    ckwargs = _conn_kwargs()

    # Template DB number (99) is never an attendee
    template_num = int(TEMPLATE_DB.replace(DB_PREFIX + "_", ""))
    targets = [
        (f"{DB_PREFIX}_{i:02d}", f"{USER_PREFIX}_{i:02d}")
        for i in range(1, user_count + 1)
        if i != template_num
    ]

    n_workers = min(workers, len(targets))
    print(f"=== Phase: Provision Attendees ===")
    print(f"  Provisioning {len(targets)} user(s) with {n_workers} parallel worker(s)...")
    print()

    all_ok = True
    with ThreadPoolExecutor(max_workers=n_workers) as pool:
        futures = {
            pool.submit(provision_one, ckwargs, db, usr): usr
            for db, usr in targets
        }
        for future in as_completed(futures):
            line = future.result()
            print(line, flush=True)
            if line.startswith("  ERR"):
                all_ok = False
    return all_ok


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Provision HOL attendee databases in parallel."
    )
    parser.add_argument(
        "--users", type=int, default=USER_COUNT,
        help=f"Highest attendee number to provision. Default: {USER_COUNT}",
    )
    parser.add_argument(
        "--workers", type=int, default=WORKERS,
        help=f"Parallel provisioning threads. Default: {WORKERS}",
    )
    args = parser.parse_args()
    if not run(user_count=args.users, workers=args.workers):
        sys.exit(1)
    print("\nPhase 'provision' complete.")


if __name__ == "__main__":
    main()
