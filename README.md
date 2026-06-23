# AI-Assisted SDLC Hands-On Lab with Cortex Code

Work a Jira ticket through completion — adding a new metric to a payment analytics platform end-to-end across the full data stack and surfacing it on the dashboard — using Cortex Code as your AI coding assistant throughout the entire development workflow.

## What You Will Do

Work through two Jira tickets using Cortex Code to add a new business metric end-to-end:

1. **Add retry success rate metric** — dbt model, semantic view, Cortex Agent, and Snowflake verification
2. **Add a KPI card** — Streamlit dashboard (UI path) or React frontend (CLI path) displaying the new metric

## Lab Paths

| Path | Tools Required | Dashboard |
|------|---------------|-----------|
| **UI (Snowsight)** | Snowflake account only | Streamlit in Snowflake |
| **CLI** | Snow CLI, Cortex Code CLI, Node.js, Git | React (local dev server) |

Open `lab_flow.html` in your browser for an interactive comparison of both paths before starting.

## Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Dashboard (UI path) | Streamlit in Snowflake | KPI cards and charts, runs natively in Snowsight |
| Dashboard (CLI path) | Next.js, Ant Design, AG Grid, ECharts | React dashboard, runs as local dev server |
| Backend | Next.js API Routes | Snowflake query endpoints (CLI path) |
| NL Queries | Snowflake Cortex Agent | Natural language to SQL |
| Data | Snowflake + dbt | Medallion architecture (dynamic tables) |
| AI Assistant | Cortex Code | AI-assisted development |

## Project Structure

```
coco_sdlc_hol/
├── apps/
│   ├── frontend/                    # Next.js React dashboard (CLI path)
│   └── streamlit/                   # Streamlit dashboard (UI path)
│
├── packages/
│   ├── database/
│   │   └── utilities/               # SQL deployment scripts (semantic view, agent DDL)
│   │
│   └── dbt/                         # dbt transformation project
│       ├── models/
│       │   ├── staging/             # Views over RAW tables
│       │   ├── intermediate/        # Enriched dynamic tables
│       │   └── marts/               # Business-ready dynamic tables
│       └── analyses/
│           └── payment_analytics_semantic_view.sql
│
├── docs/
│   ├── confluence/                  # Confluence wiki reference content
│   └── jira/                        # Jira ticket reference content
│
├── scripts/                         # Instructor provisioning scripts (run before the lab)
│   ├── hol_setup.py                 # Master setup script — runs all three phases
│   ├── hol_setup.sql                # Snowsight worksheet alternative (3500+ lines)
│   ├── config.yml                   # Config defaults (non-sensitive)
│   ├── config.local.yml             # Local overrides with real credentials (gitignored)
│   └── sql/                         # Per-phase SQL files used by the Python pipeline
│
├── lab_flow.html                    # Interactive visual guide (open in browser)
├── LAB_INSTRUCTIONS_UI.md           # UI/Snowsight path lab instructions (start here — UI)
├── LAB_INSTRUCTIONS_CLI.md          # CLI path lab instructions (start here — CLI)
├── INSTRUCTOR_GUIDE.md              # Pre-lab setup, provisioning, and facilitation reference
└── AGENTS.md                        # Cortex Code workspace context (architecture, rules)
```

---

## Prerequisites

### UI Path (Snowsight)

No local tools required. You only need a Snowflake account provided by your instructor.

### CLI Path

Install these before the lab. Verification steps are in [LAB_INSTRUCTIONS_CLI.md](LAB_INSTRUCTIONS_CLI.md#prerequisites).

- **Snowflake account** — provided by your instructor
- **Snow CLI** (prerequisite for Cortex Code CLI) — [docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation](https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation)
- **Cortex Code CLI** — [docs.snowflake.com/en/user-guide/cortex-code-cli](https://docs.snowflake.com/en/user-guide/cortex-code-cli)
- **Node.js 20.x** — [nodejs.org/en/download](https://nodejs.org/en/download)
- **Git** — [git-scm.com/downloads](https://git-scm.com/downloads)
- **GitHub CLI** — [cli.github.com](https://cli.github.com/)

---

## Getting Started

### UI Path (Snowsight — no local tools required)

→ [LAB_INSTRUCTIONS_UI.md](LAB_INSTRUCTIONS_UI.md)

Step-by-step lab entirely in Snowsight (~90 minutes). Uses Cortex Code in the browser, deploys via HOL_WORKSPACE, and adds a KPI card to a Streamlit dashboard.

### CLI Path

→ [LAB_INSTRUCTIONS_CLI.md](LAB_INSTRUCTIONS_CLI.md)

Step-by-step lab using Cortex Code CLI (~90 minutes). Requires local tools. Deploys via Snow CLI stage upload, and adds a KPI card to a React frontend.

### Interactive Visual Guide

→ Open [lab_flow.html](lab_flow.html) in your browser

Side-by-side comparison of both paths with all prompts, expected outputs, and troubleshooting tips in one place.

---

### Instructor Reference

→ [INSTRUCTOR_GUIDE.md](INSTRUCTOR_GUIDE.md)

Pre-lab Snowflake environment setup, HOL provisioning, facilitation notes, and quick-reference troubleshooting for both paths.
