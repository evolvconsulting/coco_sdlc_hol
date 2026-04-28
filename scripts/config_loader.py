"""
HOL configuration loader.

Resolution order for every value (highest priority first):
  1. Environment variable  (SCREAMING_SNAKE_CASE, see variable names below)
  2. config.local.yml      (gitignored — safe for real passwords and account-specific values)
  3. config.yml            (committed — non-sensitive defaults only)

Usage:
    from config_loader import SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, HOL_PASSWORD, USER_COUNT
"""
import os
import sys

try:
    import yaml
except ImportError:
    sys.exit("ERROR: PyYAML not installed. Run: uv run python3 -c 'import yaml'  (or: uv add pyyaml)")

_DIR = os.path.dirname(os.path.abspath(__file__))


def _load_yaml() -> dict:
    """Load config.local.yml if present, otherwise fall back to config.yml."""
    for name in ("config.local.yml", "config.yml"):
        path = os.path.join(_DIR, name)
        if os.path.exists(path):
            with open(path) as f:
                return yaml.safe_load(f) or {}
    return {}


_cfg = _load_yaml()


def _get(keys: list, env_var: str = None, default=""):
    """Return env_var (if set) > YAML nested key > default."""
    if env_var:
        val = os.environ.get(env_var, "")
        if val:
            return val
    node = _cfg
    for k in keys:
        if not isinstance(node, dict):
            return default
        node = node.get(k)
        if node is None:
            return default
    return node if node != "" else default


# ── Snowflake connection ───────────────────────────────────────────────────────
SNOWFLAKE_ACCOUNT        = _get(["snowflake", "account"],          "SNOWFLAKE_ACCOUNT")
SNOWFLAKE_USER           = _get(["snowflake", "user"],             "SNOWFLAKE_USER")
SNOWFLAKE_PASSWORD       = _get(["snowflake", "password"],         "SNOWFLAKE_PASSWORD")
SNOWFLAKE_PRIVATE_KEY_PATH = _get(["snowflake", "private_key_path"], "SNOWFLAKE_PRIVATE_KEY_PATH")
SNOWFLAKE_ROLE           = _get(["snowflake", "role"],             "SNOWFLAKE_ROLE",      "ACCOUNTADMIN")
SNOWFLAKE_WAREHOUSE      = _get(["snowflake", "warehouse"],        "SNOWFLAKE_WAREHOUSE", "COMPUTE_WH")

# ── RSA key pair (optional — Section 7, SPCS only) ────────────────────────────
RSA_PUBLIC_KEY  = _get(["snowflake", "rsa_public_key"],  "HOL_RSA_PUBLIC_KEY",  "")
RSA_PRIVATE_KEY = _get(["snowflake", "rsa_private_key"], "HOL_RSA_PRIVATE_KEY", "")

# ── HOL parameters ────────────────────────────────────────────────────────────
TEMPLATE_DB   = _get(["hol", "template_db"],  "HOL_TEMPLATE_DB",  "COCO_SDLC_HOL_99")
DB_PREFIX     = _get(["hol", "db_prefix"],    "HOL_DB_PREFIX",    "COCO_SDLC_HOL")
USER_PREFIX   = _get(["hol", "user_prefix"],  "HOL_USER_PREFIX",  "HOL_USER")
USER_COUNT    = int(_get(["hol", "user_count"], "HOL_USER_COUNT", 3))
WORKERS       = int(_get(["hol", "workers"],    "HOL_WORKERS",    5))
HOL_PASSWORD  = _get(["hol", "password"],     "HOL_PASSWORD",     "")
