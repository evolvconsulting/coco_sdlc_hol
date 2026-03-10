# Lab 2 - Payment Analytics Platform

## Project Overview

Lab 2 is a comprehensive Payment Analytics Platform built on Snowflake, demonstrating the full SDLC (Software Development Lifecycle) workflow using Cortex Code and modern data engineering practices.

**Based on:** [evolvconsulting/coco_sdlc_hol](https://github.com/evolvconsulting/coco_sdlc_hol)

## Quick Links

| Resource | URL |
|----------|-----|
| GitHub Repository | https://github.com/DanielPhillipsSanchez/Lab2 |
| Jira Project | https://evolvconsulting-team-u2rm5pfv.atlassian.net/browse/LAB2 |
| Confluence Space | https://evolvconsulting-team-u2rm5pfv.atlassian.net/wiki/spaces/LAB2 |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SNOWFLAKE PLATFORM                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐  │
│  │   RAW   │ -> │ STAGING │ -> │  INT    │ -> │  MARTS  │  │
│  │ (OLTP)  │    │  (dbt)  │    │  (dbt)  │    │  (dbt)  │  │
│  └─────────┘    └─────────┘    └─────────┘    └────┬────┘  │
│                                                     │       │
│                                         ┌───────────▼─────┐ │
│                                         │ CORTEX AGENT    │ │
│                                         │ (Semantic View) │ │
│                                         └───────────┬─────┘ │
├─────────────────────────────────────────────────────┼───────┤
│  ┌────────────────────────────────────────────────┐ │       │
│  │           SPCS (Container Services)            │ │       │
│  │  ┌──────────────────────────────────────────┐  │ │       │
│  │  │         Next.js Frontend App             │◄─┼─┘       │
│  │  └──────────────────────────────────────────┘  │         │
│  └────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## Snowflake Skills & Plugins Used

### Cortex Code Skills

| Skill | Purpose | Usage |
|-------|---------|-------|
| **analyzing-data** | Query data warehouse | SQL analysis, metrics, trends |
| **developing-with-streamlit** | Build Streamlit apps | Dashboard development |
| **cortex-ai-functions** | AI text/image analytics | AI_CLASSIFY, AI_COMPLETE, AI_EXTRACT |
| **cortex-agent** | Manage Cortex Agents | PAYMENT_ANALYTICS_AGENT |
| **semantic-view** | Create semantic views | PAYMENT_ANALYTICS view |
| **dynamic-tables** | Dynamic Table operations | Incremental pipelines |
| **dbt-projects-on-snowflake** | dbt deployment | snow dbt commands |
| **deploy-to-spcs** | Container deployment | SPCS services |
| **lineage** | Data lineage analysis | Impact analysis |
| **data-governance** | Access control | Masking, classification |

### Snowflake Objects Created

#### Database Structure

| Schema | Purpose | Objects |
|--------|---------|---------|
| RAW | Raw OLTP-style tables | 11 tables |
| STAGING | dbt staging models | 11 models |
| INTERMEDIATE | dbt enriched models | 6 models |
| MARTS | Business-ready tables | 7 models |
| PUBLIC | SPCS deployment | Service, Compute Pool |

#### Cortex Agent

- **PAYMENT_ANALYTICS_AGENT**: Natural language query interface
- **PAYMENT_ANALYTICS**: Semantic view with business definitions

#### SPCS Objects

- **coco_sdlc_hol_repo**: Docker image repository
- **coco_sdlc_hol_compute_pool**: Container runtime (STANDARD_1)
- **coco_sdlc_hol_service**: Next.js frontend service

## Database Schema

### RAW Schema - Dimension Tables

| Table | Description |
|-------|-------------|
| PLTF_REF | Platform/Processor reference (Omaha, CardNet, TSYS) |
| GLB_BIN | Global BIN reference with card metadata |
| DCLN_RSN_CD | Authorization decline reason codes |
| CBK_RSN_CD | Chargeback reason codes by card brand |
| CLX_MRCH_MSTR | Merchant master data |

### RAW Schema - Fact Tables

| Table | Description |
|-------|-------------|
| CLX_AUTH | Authorization transactions |
| CLX_SETTLE | Settlement transactions |
| CLX_FUND | Funding/deposit transactions |
| CLX_CBK | Chargeback transactions |
| CLX_RTRVL | Retrieval requests |
| CLX_ADJ | Adjustment transactions |

### MARTS Schema - Analytics Tables

| Model | Description |
|-------|-------------|
| authorizations | Authorization analytics |
| settlements | Settlement analytics |
| deposits | Deposit/funding analytics |
| chargebacks | Chargeback analytics |
| retrievals | Retrieval analytics |
| adjustments | Adjustment analytics |
| dim_merchants | Merchant dimension |

## Setup Instructions

### Prerequisites

- Snowflake account with ACCOUNTADMIN privileges
- Node.js 18+ and npm
- Docker (for SPCS deployment)
- dbt-snowflake adapter
- Python 3.8+

### Step 1: Clone Repository

```bash
git clone https://github.com/DanielPhillipsSanchez/Lab2.git
cd Lab2
```

### Step 2: Snowflake Setup

```sql
-- Run in Snowflake worksheet
USE ROLE ACCOUNTADMIN;
!source packages/database/hol_setup.sql
```

### Step 3: dbt Setup

```bash
cd packages/dbt
cp profiles.yml.example profiles.yml
# Edit profiles.yml with your credentials
dbt deps
dbt build
```

### Step 4: Cortex Agent Setup

```sql
!source packages/database/utilities/03_create_agent.sql
```

### Step 5: Frontend Setup

```bash
cd apps/frontend
npm install
cp .env.example .env.local
# Edit .env.local with your Snowflake connection
npm run dev
```

## Atlassian Integration

This project includes direct API integration with Atlassian Cloud for Jira and Confluence.

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| /api/jira/projects | GET | List Jira projects |
| /api/jira/issues | GET/POST | Search/create issues |
| /api/jira/issues/[key] | GET | Get issue by key |
| /api/confluence/spaces | GET | List Confluence spaces |
| /api/confluence/pages | GET/POST | Search/create pages |
| /api/confluence/pages/[id] | GET | Get page by ID |

### Configuration

```bash
# .env.atlassian (local only)
ATLASSIAN_DOMAIN=your-domain.atlassian.net
ATLASSIAN_EMAIL=your-email@company.com
ATLASSIAN_API_TOKEN=your-api-token
```

## Project Tracking

All database tables and dbt models are tracked as Jira issues in the LAB2 project:

- **LAB2-1 to LAB2-11**: RAW schema tables
- **LAB2-12 to LAB2-22**: STAGING dbt models
- **LAB2-23 to LAB2-28**: INTERMEDIATE dbt models
- **LAB2-29 to LAB2-35**: MARTS dbt models

## Documentation

Full documentation is available in Confluence:

- [Project Overview](https://evolvconsulting-team-u2rm5pfv.atlassian.net/wiki/spaces/LAB2)
- [Snowflake Skills & Plugins](https://evolvconsulting-team-u2rm5pfv.atlassian.net/wiki/spaces/LAB2)
- [Database Schema & Data Dictionary](https://evolvconsulting-team-u2rm5pfv.atlassian.net/wiki/spaces/LAB2)
- [Setup Instructions](https://evolvconsulting-team-u2rm5pfv.atlassian.net/wiki/spaces/LAB2)

---

*Generated with [Cortex Code](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code)*
