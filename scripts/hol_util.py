"""
HOL shared utilities — Snowflake connection and SQL execution helpers.

All phase scripts (setup_account, build_template, provision_attendees, reset_attendees)
import from this module. No Snow CLI dependency — pure snowflake.connector.

Authentication (in priority order):
  1. private_key_path  — RSA key pair (SNOWFLAKE_JWT), e.g. ~/.snowflake/keys/rsa_key.p8
  2. password          — username/password fallback
"""
import os
import sys
from typing import Optional

try:
    import snowflake.connector
    from snowflake.connector import SnowflakeConnection
except ImportError:
    sys.exit("snowflake-connector-python not found. Run: uv add snowflake-connector-python")

try:
    from config_loader import (
        SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_PASSWORD,
        SNOWFLAKE_PRIVATE_KEY_PATH, SNOWFLAKE_ROLE, SNOWFLAKE_WAREHOUSE,
    )
except ImportError:
    sys.exit("config_loader.py not found. Run as: uv run python3 scripts/hol_setup.py (from repo root) or cd scripts/ first.")

_SQL_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sql")


def _load_private_key(path: str) -> bytes:
    """Load an unencrypted PEM private key and return DER bytes for snowflake.connector."""
    from cryptography.hazmat.primitives.serialization import (
        load_pem_private_key, Encoding, PrivateFormat, NoEncryption,
    )
    with open(os.path.expanduser(path), "rb") as f:
        key = load_pem_private_key(f.read(), password=None)
    return key.private_bytes(Encoding.DER, PrivateFormat.PKCS8, NoEncryption())


def check_credentials() -> None:
    """Exit with a clear message if required credentials are missing."""
    missing = []
    if not SNOWFLAKE_ACCOUNT:
        missing.append("snowflake.account")
    if not SNOWFLAKE_USER:
        missing.append("snowflake.user")
    if not SNOWFLAKE_PRIVATE_KEY_PATH and not SNOWFLAKE_PASSWORD:
        missing.append("snowflake.private_key_path (or snowflake.password)")
    if missing:
        sys.exit(
            "Missing required config values: " + ", ".join(missing) + "\n"
            "Set them in config.local.yml (gitignored) or as environment variables."
        )


def conn_kwargs(role: Optional[str] = None) -> dict:
    """Build connector kwargs, preferring key pair auth over password."""
    kwargs = dict(
        account=SNOWFLAKE_ACCOUNT,
        user=SNOWFLAKE_USER,
        role=role or SNOWFLAKE_ROLE,
        warehouse=SNOWFLAKE_WAREHOUSE,
    )
    if SNOWFLAKE_PRIVATE_KEY_PATH:
        kwargs["private_key"] = _load_private_key(SNOWFLAKE_PRIVATE_KEY_PATH)
    else:
        kwargs["password"] = SNOWFLAKE_PASSWORD
    return kwargs


def connect(role: Optional[str] = None) -> SnowflakeConnection:
    """Open a Snowflake connection using credentials from config."""
    check_credentials()
    return snowflake.connector.connect(**conn_kwargs(role))


def run_sql(con: SnowflakeConnection, sql: str, label: str) -> bool:
    """Execute a single SQL statement. Print [OK] or [FAIL] with label."""
    try:
        con.cursor().execute(sql)
        print(f"  [OK]   {label}", flush=True)
        return True
    except Exception as exc:
        print(f"  [FAIL] {label}")
        print(f"         {str(exc)[:300]}")
        return False


def run_sql_file(con: SnowflakeConnection, filename: str, label: str) -> bool:
    """
    Read a .sql file from the sql/ directory and execute all statements via
    execute_string(), which handles multi-statement files and $$ delimiters.
    """
    path = os.path.join(_SQL_DIR, filename)
    if not os.path.exists(path):
        print(f"  [SKIP] {label} (file not found: {path})")
        return True
    with open(path) as f:
        sql = f.read()
    try:
        for _ in con.cursor().execute_string(sql):
            pass
        print(f"  [OK]   {label}", flush=True)
        return True
    except Exception as exc:
        print(f"  [FAIL] {label}")
        print(f"         {str(exc)[:300]}")
        return False
