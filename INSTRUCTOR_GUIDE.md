# Instructor Guide — AI-Assisted SDLC Hands-On Lab

**Instructor-only.** Pre-lab setup reference, environment provisioning, and live facilitation notes for both lab paths.

**Total duration:** ~90 min  
**Two paths:** UI (Snowsight, no local tools, Streamlit) and CLI (Cortex Code CLI, React frontend)

Step numbers here mirror `LAB_INSTRUCTIONS_UI.md` and `LAB_INSTRUCTIONS_CLI.md` exactly — when a participant says "I'm on step 4.3," look it up here instantly.

---

## Part 1: Pre-Lab Setup

### Snowflake Account Requirements

The lab account must have the following features enabled:

- **Cortex Analyst / Cortex Agent** — required for natural language queries
- **Dynamic Tables** — required for INTERMEDIATE and MARTS layers
- **Semantic Views** — required for the Cortex Agent semantic layer
- **Streamlit in Snowflake** — required for UI path Task 2

The account must be on **Enterprise tier or higher**.

---

### HOL Setup

The lab environment is provisioned using a Python-based setup pipeline. `scripts/hol_setup.sql` also exists as a Snowsight worksheet alternative for accounts where Python tooling is unavailable.

#### Recommended: Python setup script

```bash
# Full setup — all three phases in order:
uv run python3 scripts/hol_setup.py

# Or run individual phases:
uv run python3 scripts/hol_setup.py --phase account     # Phase 1: bootstrap + users
uv run python3 scripts/hol_setup.py --phase template    # Phase 2: template DB (COCO_SDLC_HOL_99)
uv run python3 scripts/hol_setup.py --phase provision   # Phase 3: provision attendee databases
```

Configure credentials in `scripts/config.local.yml` before running (see `scripts/config.yml` for the shape).

| Phase | Script | What it does |
|-------|--------|--------------|
| account | `setup_account.py` | Account bootstrap: `ATTENDEE_ROLE`, `COMPUTE_WH`, Atlassian EAI + secret; creates `HOL_USER_01` … `HOL_USER_NN` with password + MFA bypass (20 hours) |
| template | `build_template.py` | Builds template database `COCO_SDLC_HOL_99`: schemas, raw tables, synthetic data, staging views, dynamic tables, dbt project, workspace, Streamlit app, semantic view, Cortex Agent, `PROVISION_HOL_USER` SP |
| provision | `provision_attendees.py` | Clones template → provisions `COCO_SDLC_HOL_01` … `NN` in parallel; much faster than sequential SQL for large cohorts |

> **Dependency:** `account` phase must complete before `provision`. The `provision` phase calls `PROVISION_HOL_USER` for each user — but it does not create users. If users don't exist, provisioning will fail.

#### Alternative: Snowsight worksheet

`scripts/hol_setup.sql` (3500+ lines) contains the same setup as a single SQL script. Run all sections in order in a Snowsight worksheet as `ACCOUNTADMIN`.

```
Section 0   → Set HOL_PASSWORD and NUM_USERS
Section 1   → Account-level bootstrap
Section 2   → Create HOL_USER_NN with password + MFA bypass
Sections 3–9 → Build template database COCO_SDLC_HOL_99
Section 10  → Clone template → provision attendee databases
```

> **Note:** Section 2 must run before Section 10 — same dependency as the Python approach.

#### What each attendee database contains

| Object | Pattern |
|--------|---------|
| Database | `COCO_SDLC_HOL_NN` |
| Role | `HOL_ROLE_NN` |
| Warehouse | `HOL_WH_NN` |
| dbt project | `COCO_SDLC_HOL_NN.MARTS.EVOLV_PAYMENT_ANALYTICS` |
| Workspace | `COCO_SDLC_HOL_NN.MARTS.HOL_WORKSPACE` |
| dbt stage | `COCO_SDLC_HOL_NN.PUBLIC.DBT_FILES` |
| Streamlit stage | `COCO_SDLC_HOL_NN.PUBLIC.STREAMLIT_FILES` |
| Streamlit app | `COCO_SDLC_HOL_NN.PUBLIC.PAYMENT_ANALYTICS_DASHBOARD` |
| Semantic view | `COCO_SDLC_HOL_NN.MARTS.PAYMENT_ANALYTICS` |
| Cortex Agent | `COCO_SDLC_HOL_NN.MARTS.PAYMENT_ANALYTICS_AGENT` |

#### Re-provisioning a single user

To reprovision one attendee's database without touching others:

```sql
CALL COCO_SDLC_HOL_99.PUBLIC.PROVISION_HOL_USER('COCO_SDLC_HOL_02', 'HOL_USER_02');
```

This only reprovisiones the database — it does not recreate the user or reset the password.

---

### Running the Dashboard Locally (optional pre-validation)

Before the lab, you can validate the app against your Snowflake environment:

```bash
cd apps/frontend
cp .env.example .env.local
```

Open `.env.local` and set your account identifier:

```
SNOWFLAKE_ACCOUNT=<orgname>-<accountname>
```

Then install and start:

```bash
npm install
npm run dev
```

The app is available at [http://localhost:3000](http://localhost:3000). Dashboard should load with real transaction data.

---

## Part 2: Lab Facilitation

**Participant guides:** [`LAB_INSTRUCTIONS_UI.md`](LAB_INSTRUCTIONS_UI.md) (Snowsight path) · [`LAB_INSTRUCTIONS_CLI.md`](LAB_INSTRUCTIONS_CLI.md) (CLI path)  
**Visual overview:** Open [`lab_flow.html`](lab_flow.html) in a browser — side-by-side step comparison for both paths.

### Two Paths at a Glance

| | UI Path | CLI Path |
|-|---------|----------|
| Tool | Cortex Code in Snowsight | Cortex Code CLI in terminal |
| Repo setup | None — HOL_WORKSPACE pre-loaded | Clone from GitHub |
| Jira access | GET_JIRA_TICKET UDF + Cortex Agent tool | Atlassian MCP |
| dbt deploy | Workspace → ADD VERSION → EXECUTE | `snow stage put` → EXECUTE |
| Task 2 dashboard | Streamlit in Snowflake | React (local dev server) |
| Plan mode | Not used | `/plan` used in Task 2 |

---

### Pre-Lab Checklist

Run the provisioning pipeline before participants arrive (see Part 1 — HOL Setup).

After provisioning, verify for each attendee slot:
- `HOL_USER_NN` can log into Snowsight with the shared password
- `PAYMENT_ANALYTICS_DASHBOARD` loads and shows data (Streamlit baseline)
- `COCO_SDLC_HOL_NN.MARTS.HOL_WORKSPACE` exists and contains the project files

Distribute to attendees:
- Snowflake account URL
- Assigned `HOL_USER_NN` username and password
- Which path they are on (UI or CLI)

---

### Watch-Fors by Section

Step-by-step prompts and expected outputs are in the participant guides. Watch for these common issues during the session.

#### Section 1 — Environment Setup

| Watch for | Path | Fix |
|-----------|------|-----|
| `/status` shows `SYSADMIN` or empty role | UI | Re-send the session context prompt (`Set my role to HOL_ROLE_NN...`) |
| `HOL_WORKSPACE` not found | UI | Check that provisioning ran for this user's database |
| "Account not found" in connection wizard | CLI | Account identifier must be `orgname-accountname`, not a URL |
| Local app loads but shows no data | CLI | Check `SNOWFLAKE_ACCOUNT` value in `apps/frontend/.env.local` |

#### Section 2 — Cortex Code Primer

| Watch for | Path | Fix |
|-----------|------|-----|
| `cortex mcp add` run inside Cortex Code | CLI | Must be run in the terminal — have them `/exit` first, then relaunch `cortex` for Section 3 |

#### Section 3 — Architecture Overview

| Watch for | Path | Fix |
|-----------|------|-----|
| Response is generic, no `COCO_SDLC_HOL_NN` mentioned | Both | CLI: not launched from repo root. UI: workspace not opened. Fix first, then re-prompt. |

> Call out: Cortex Code reads `AGENTS.md` automatically from the workspace. This is how it knows the full architecture.

#### Section 4 — Task 1 (Retry Success Rate Metric)

| Watch for | Path | Fix |
|-----------|------|-----|
| Cortex Code asks which database to use for the UDF | UI | Select `COCO_SDLC_HOL_NN` (their HOL database, not `HOL_SHARED`) |
| `GET_JIRA_TICKET` returns auth error | UI | Confirm role is `HOL_ROLE_NN`; re-run the UDF creation prompt |
| Only 2–3 files edited (missing model or agent file) | Both | Re-prompt to include `int_authorizations__enriched.sql` and `03_create_agent.sql` |
| Cortex Code runs `dbt deps` or `dbt compile` (triggers EAI dialog) | Both | The implementation prompt already includes "Do not run dbt CLI commands" — re-send verbatim |
| `versions/last` used instead of `versions/live` | UI | Re-run the deploy prompt verbatim; new columns won't appear until `versions/live` is used |
| `EXECUTE DBT PROJECT` permission denied on STAGING | UI | `--select` scope missing — ask Cortex Code to re-run with `--select int_authorizations__enriched+ --full-refresh` |
| `snow stage put` fails — stage not found | CLI | Verify `DBT_FILES` stage exists: `SHOW STAGES IN DATABASE COCO_SDLC_HOL_NN` |
| `EXECUTE DBT PROJECT` fails | CLI | Confirm `HOL_ROLE_NN` has USAGE on the dbt project |
| Metric not found after semantic view rebuild | Both | Ask Cortex Code to re-execute the DDL specifying the full file path |
| Dynamic table shows old data after dbt run | Both | Wait 2–3 min, or ask Cortex Code: `ALTER DYNAMIC TABLE COCO_SDLC_HOL_NN.MARTS.AUTHORIZATIONS REFRESH;` |

> Call out: `ADD VERSION` auto-sets the new version as default — no `SET DEFAULT_VERSION` needed.  
> Call out: Cortex Code validates the agent via Cortex Analyst (same engine). Participants will see "Cortex Analyst" in the output — this is expected.

#### Section 5 — Context Switch

> Call out: Plan mode (CLI) is session-scoped — participants must re-enable `/plan` in the new session for Task 2.

#### Section 6 — Task 2 (KPI Card)

| Watch for | Path | Fix |
|-----------|------|-----|
| Streamlit still shows 4 cards after implementation | UI | Click the refresh button in the top-right of the Streamlit app |
| Plan order wrong (`page.tsx` before `domain.ts`) | CLI | Ask Cortex Code to reorder — `domain.ts` (TypeScript interface) must come first |
| React KPI card shows 0 or undefined | CLI | Check `AuthorizationKPIs` in `domain.ts` includes `retrySuccessRate: number` and `kpis/route.ts` returns the field |

> Call out (CLI): Jira ticket read at the start, PR created at the end — full development loop without leaving the terminal.
