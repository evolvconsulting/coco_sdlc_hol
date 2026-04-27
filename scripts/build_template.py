#!/usr/bin/env python3
"""
build_template.py — Phase 2: Build template database COCO_SDLC_HOL_99.

What this does (in order):
  Section 3  : DB, schemas, RAW tables
  Section 4  : Reference data (MERGE)
  Section 5  : Synthetic transaction data
  Section 6  : dbt project + Git repo + HOL_SHARED + Atlassian EAI + stage setup
  Section 7  : Service user + RSA key secret (optional — skipped if rsa keys not configured)
  Section 8  : Semantic view + Cortex Agent
  Section 9  : Final grants
  Section 9.5: YAML template table for per-user provisioning
  Section 9.6: PROVISION_HOL_USER stored procedure

Run directly (from repo root):
    uv run python3 scripts/build_template.py

Or via master script:
    uv run python3 scripts/hol_setup.py --phase template
"""
import sys
from hol_util import connect, run_sql_file, run_sql
from config_loader import RSA_PUBLIC_KEY, RSA_PRIVATE_KEY


def run(con=None) -> bool:
    close = con is None
    if con is None:
        con = connect()
    ok = True
    try:
        print("=== Phase: Build Template Database ===")

        ok = run_sql_file(con, "03_db_schemas.sql",       "Section 3a: DB + schemas") and ok
        ok = run_sql_file(con, "03_raw_tables.sql",       "Section 3b: RAW tables") and ok
        ok = run_sql_file(con, "04_reference_data.sql",   "Section 4:  reference data") and ok
        ok = run_sql_file(con, "05_synthetic_data.sql",   "Section 5:  synthetic data") and ok
        ok = run_sql_file(con, "06_dbt_setup.sql",        "Section 6:  dbt + Git + HOL_SHARED + EAI") and ok

        # Section 7 — service user + RSA key (optional SPCS feature)
        if RSA_PUBLIC_KEY and RSA_PRIVATE_KEY:
            import os
            sql_path = os.path.join(os.path.dirname(__file__), "sql", "07_service_user.sql")
            with open(sql_path) as f:
                sql = f.read()
            sql = sql.replace("<PASTE_YOUR_RSA_PUBLIC_KEY_HERE>", RSA_PUBLIC_KEY)
            sql = sql.replace("<PASTE_YOUR_UNENCRYPTED_PRIVATE_KEY_HERE>", RSA_PRIVATE_KEY)
            ok = run_sql(con, sql, "Section 7:  service user + RSA key") and ok
        else:
            print("  [SKIP] Section 7:  service user (rsa_public_key / rsa_private_key not set)")

        ok = run_sql_file(con, "08_semantic_agent.sql",   "Section 8:  semantic view + Cortex Agent") and ok
        ok = run_sql_file(con, "09_grants.sql",           "Section 9:  final grants") and ok
        ok = run_sql_file(con, "09_5_yaml_templates.sql", "Section 9.5: YAML templates") and ok
        ok = run_sql_file(con, "09_6_provision_sp.sql",   "Section 9.6: PROVISION_HOL_USER SP") and ok

    finally:
        if close:
            con.close()
    return ok


if __name__ == "__main__":
    if not run():
        sys.exit(1)
    print("\nPhase 'template' complete.")
