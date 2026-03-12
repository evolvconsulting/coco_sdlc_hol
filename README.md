# AI-Assisted SDLC Hands-On Lab with Cortex Code

Work a Jira ticket through completion by adding a new metric to a payment analytics platform end-to-end across the full data stack, surfacing it on the dashboard, using Cortex Code CLI as your AI coding assistant throughout the entire development workflow.

## What You Will Do

Work through two Jira tickets using Cortex Code to add a new business metric end-to-end:

1. **Add retry success rate metric** -- dbt model, semantic view, Cortex Agent, and Snowflake verification
2. **Add a KPI card** -- React frontend component displaying the new metric

## Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Frontend | Next.js 14, Ant Design, AG Grid, ECharts | Dashboard UI |
| Backend | Next.js API Routes | Snowflake query endpoints |
| NL Queries | Snowflake Cortex Agent | Natural language to SQL |
| Data | Snowflake + dbt | Medallion architecture |
| AI Assistant | Cortex Code CLI | AI-assisted development |
| Infrastructure | Snowpark Container Services (SPCS) | Container orchestration |

## Project Structure

```
coco_sdlc_hol/
├── apps/
│   └── frontend/                    # Next.js dashboard application
│
├── packages/
│   ├── database/
│   │   └── hol_setup.sql            # Single consolidated HOL setup script
│   │
│   └── dbt/                         # dbt transformation project
│       ├── models/
│       │   ├── staging/             # Views over RAW tables
│       │   ├── intermediate/        # Enriched dynamic tables
│       │   └── marts/               # Business-ready dynamic tables
│       └── analyses/
│           └── payment_analytics_semantic_view_v2.sql
│
├── LAB_INSTRUCTIONS.md                  # Lab instructions (start here)
├── INFRASTRUCTURE.md                # Environment provisioning & deployment
└── Dockerfile                       # Container image for SPCS deployment
```

---

## Prerequisites

Install these tools before the lab. Full install instructions and verification steps are in [LAB_INSTRUCTIONS.md](LAB_INSTRUCTIONS.md#prerequisites).

- **Snowflake account** -- provided by your instructor
- **Snow CLI** -- [docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation](https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation)
- **Cortex Code CLI** -- [docs.snowflake.com/en/user-guide/cortex-code-cli](https://docs.snowflake.com/en/user-guide/cortex-code-cli)
- **Node.js 20.x** -- [nodejs.org/en/download](https://nodejs.org/en/download)
- **Git**
- **uv** (Python package manager) -- [docs.astral.sh/uv/getting-started/installation](https://docs.astral.sh/uv/getting-started/installation)
- **dbt** (dbt-snowflake) -- `uv tool install "dbt-snowflake>=1.9.0"` (after installing uv)

---

## Getting Started

### 1. [Hands-On Lab Instructions](LAB_INSTRUCTIONS.md)

Step-by-step guided lab (~90 minutes). Covers architecture overview, Cortex Code setup, and two development tasks driven entirely through Cortex Code CLI prompts.

### 2. [Infrastructure & Deployment Reference](INFRASTRUCTURE.md)

HOL setup script details, SPCS deployment, data architecture, and environment provisioning. Reference for instructors and facilitators.
