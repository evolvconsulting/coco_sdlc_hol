#!/usr/bin/env python3
"""
hol_setup.py — Master HOL provisioning script.

Runs all setup phases in order, or a single phase when --phase is specified.
No Snowflake worksheet required — runs entirely from the command line.

Prerequisites:
    uv add snowflake-connector-python pyyaml   (already in pyproject.toml)
    Create config.local.yml with your credentials (see config.yml for shape)

Usage:
    # Full setup — all phases in order (run from repo root):
    uv run python3 scripts/hol_setup.py

    # Individual phases:
    uv run python3 scripts/hol_setup.py --phase account     # Sections 1-2: bootstrap + users
    uv run python3 scripts/hol_setup.py --phase template    # Sections 3-9.6: template DB
    uv run python3 scripts/hol_setup.py --phase provision   # Section 10: provision attendees

Phases:
    account    setup_account.py    — ATTENDEE_ROLE, COMPUTE_WH, HOL_USER_NN
    template   build_template.py   — COCO_SDLC_HOL_99 (all schemas, data, SP)
    provision  provision_attendees.py — per-user clone + PROVISION_HOL_USER (parallel)

For reset / reprovision:
    uv run python3 scripts/reset_attendees.py
    uv run python3 scripts/reset_attendees.py --drop-only
"""
import argparse
import sys

import setup_account
import build_template
import provision_attendees
from config_loader import USER_COUNT, WORKERS
from hol_util import connect


PHASES = {
    "account":   setup_account,
    "template":  build_template,
    "provision": provision_attendees,
}


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Full HOL environment setup — no Snowflake worksheet required."
    )
    parser.add_argument(
        "--phase",
        choices=list(PHASES.keys()),
        default=None,
        help="Run only this phase. Omit to run all phases in order.",
    )
    parser.add_argument(
        "--users", type=int, default=USER_COUNT,
        help=f"Number of attendees (applies to 'account' and 'provision' phases). Default: {USER_COUNT}",
    )
    parser.add_argument(
        "--workers", type=int, default=WORKERS,
        help=f"Parallel workers (phase 'provision' only). Default: {WORKERS}",
    )
    args = parser.parse_args()

    phases_to_run = [args.phase] if args.phase else list(PHASES.keys())

    # Reuse one connection across account + template phases (not provision — it opens per-thread)
    con = connect()
    try:
        for phase_name in phases_to_run:
            print()
            module = PHASES[phase_name]
            if phase_name == "provision":
                # provision_attendees manages its own connections (parallel)
                con.close()
                con = None
                ok = module.run(user_count=args.users, workers=args.workers)
            elif phase_name == "account":
                ok = module.run(con=con, user_count=args.users)
            else:
                ok = module.run(con=con)
            if not ok:
                sys.exit(f"\nPhase '{phase_name}' failed. Fix errors above and re-run with --phase {phase_name}.")
    finally:
        if con:
            con.close()

    print("\n=== Setup complete. ===")


if __name__ == "__main__":
    main()
