# AI-Assisted SDLC Hands-On Lab with Cortex Code

Build a self-service payment analytics dashboard powered by Snowflake Cortex Agent and a dbt medallion architecture -- using Cortex Code CLI as your AI coding assistant throughout the entire development workflow.

## What You Will Do

Work through two Jira tickets using Cortex Code to add a new business metric end-to-end:

1. **Add retry success rate metric** -- dbt model, semantic view, Cortex Agent, and Snowflake verification
2. **Add a KPI card** -- React frontend component displaying the new metric

## Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Frontend | Next.js 14, Ant Design, AG Grid, ECharts | Dashboard UI |
| Backend | Node.js 20 + Express | API service |
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

**Complete these before the lab.** The Snowflake environment and application infrastructure will be pre-provisioned by your instructor -- you only need the local development tools below.

Several tools require admin rights or may be blocked on corporate-managed machines -- flag any blockers to your facilitator in advance.

### 1. Snowflake Account

Your instructor will provide a Snowflake account pre-configured for the lab. You need credentials to connect to it.

### 2. Snow CLI

The Snowflake CLI (`snow`) is used to verify your Snowflake connection.

**Install:** https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation

```bash
# Verify installation
snow --version
```

> **Corporate machine note:** Snow CLI installation may require elevated privileges. If your IT policy blocks the installer, request a pre-approved install or ask your facilitator for a pre-configured machine.

After installing, configure a connection:

```bash
snow connection add
# Follow prompts: account identifier, username, authenticator (use "externalbrowser" for SSO)
```

### 3. Cortex Code CLI

The primary tool for this lab -- Snowflake's AI coding assistant.

**Install:** https://docs.snowflake.com/en/user-guide/cortex-code-cli

```bash
# Verify installation
cortex --version
```

> **Corporate machine note:** The Cortex Code CLI may be flagged by endpoint security tools or require Python 3.9+. If you cannot install it, the lab facilitator can provide a shared environment.

### 4. Node.js 20.x

Required for running the frontend application locally.

**Install:** https://nodejs.org/en/download (use the LTS version, 20.x)

```bash
node --version   # should print v20.x.x
npm --version
```

### 5. Git

```bash
git --version
```

Fork and clone the lab repository:

1. Fork: [https://github.com/evolvconsulting/coco_sdlc_hol](https://github.com/evolvconsulting/coco_sdlc_hol) → click **Fork**
2. Clone your fork:

```bash
git clone https://github.com/<your-username>/coco_sdlc_hol.git
cd coco_sdlc_hol
```

---

## Getting Started

### 1. [Hands-On Lab Instructions](LAB_INSTRUCTIONS.md)

Step-by-step guided lab (~90 minutes). Covers architecture overview, Cortex Code setup, and two development tasks driven entirely through Cortex Code CLI prompts.

### 2. [Infrastructure & Deployment Reference](INFRASTRUCTURE.md)

HOL setup script details, SPCS deployment, data architecture, and environment provisioning. Reference for instructors and facilitators.
