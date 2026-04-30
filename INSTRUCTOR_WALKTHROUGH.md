# Instructor Walkthrough — AI-Assisted SDLC Hands-On Lab

**Printable facilitation guide.** Primary track: CLI. Snowsight divergences called out inline with `[SNOWSIGHT]` tags. Kahoot engagement questions cued at natural break points.

**Duration:** ~90 min &nbsp;|&nbsp; **Tracks:** CLI (terminal + React) and Snowsight (browser-only + Streamlit)

---

## Before You Start

- [ ] Provisioning pipeline complete (see `INSTRUCTOR_GUIDE.md` Part 1)
- [ ] Each attendee slot verified: user login, dashboard loads, workspace/repo accessible
- [ ] Kahoot game loaded with "Engagement Questions.docx" questions (15 questions)
- [ ] Decide attendee path assignments (CLI vs Snowsight) and distribute credentials
- [ ] Have `INSTRUCTOR_GUIDE.md` Watch-Fors table open for live troubleshooting

---

## Section 1: Environment Setup (~5 min)

### What You Say

> "Log into Snowflake with the credentials on your card. We'll confirm the baseline dashboard works, then connect Cortex Code to your environment."

### Steps — CLI Track (Primary)

**Step 0 — Clone the repo**

```bash
git clone https://github.com/evolvconsulting/coco_sdlc_hol.git
cd coco_sdlc_hol
```

Fallback (no Git): download ZIP, extract, `git init && git add . && git commit -m "Initial commit"`.

**Step 1a — Create a Programmatic Access Token (PAT)**

Log into Snowsight → click your name (bottom-left) → **My Profile** → **Programmatic Access Tokens** → **+ Generate New Token**.

| Field | Value |
|-------|-------|
| Token name | `HOL_PAT` |
| Role | `HOL_ROLE_NN` |
| Expires in | 1 day |

Copy the token immediately — shown only once.

**Step 1b — Launch Cortex Code and create a connection**

```bash
cortex
```

First-run wizard prompts:

| Prompt | Value |
|--------|-------|
| Connection name | `HOL_USER_NN` |
| Account identifier | `orgname-accountname` (from instructor) |
| Username | `HOL_USER_NN` |
| Token | Paste the PAT from Step 1a |
| Auth method | Programmatic Access Token |

**Step 1c — Set session context** (replace `NN`):

```
Set my role to HOL_ROLE_NN, warehouse to HOL_WH_NN, and use database COCO_SDLC_HOL_NN with schema MARTS.
```

Verify:

```
/status
```

Expect: `HOL_ROLE_NN`, `COCO_SDLC_HOL_NN`, `MARTS`.

**Step 1d — Configure local frontend**

```
Update apps/frontend/.env.local with my Snowflake credentials: SNOWFLAKE_ACCOUNT=<orgname-accountname>, SNOWFLAKE_USER=HOL_USER_NN, SNOWFLAKE_ROLE=HOL_ROLE_NN, SNOWFLAKE_WAREHOUSE=HOL_WH_NN, SNOWFLAKE_PASSWORD=<password>, SNOWFLAKE_DATABASE=COCO_SDLC_HOL_NN.
```

**Step 2 — Confirm local app runs**

```
Install the frontend dependencies and start the dev server from apps/frontend.
```

Open http://localhost:3000 — dashboard should show real data with 4 KPI cards.

> **[SNOWSIGHT DIVERGENCE]**
> - Skip Steps 0, 1a, 1b, 1d, and 2 entirely (no repo clone, no PAT, no connection wizard, no `.env.local`, no local app).
> - **Step 1.1** — Log into Snowsight with HOL credentials.
> - **Step 1.2** — Go to **Projects > Streamlit**, open `PAYMENT_ANALYTICS_DASHBOARD` (under their database). Confirm 4 KPI cards with real data.
> - **Step 1.3** — Open **AI & ML > Cortex Code**. Paste the same session context prompt (`Set my role to HOL_ROLE_NN...`). Run `/status`.
> - **Step 1.4** — Paste `open HOL_WORKSPACE` to load the project file tree.

### Watch-Fors

| Issue | Path | Fix |
|-------|------|-----|
| `/status` shows wrong role | Both | Re-send session context prompt |
| `HOL_WORKSPACE` not found | Snowsight | Re-run provisioning for that user |
| "Account not found" in wizard | CLI | Must be `orgname-accountname`, not a URL |
| App loads but no data | CLI | Check `SNOWFLAKE_ACCOUNT` in `.env.local` |

---

## KAHOOT BREAK — Questions 1 & 2

> **Q1:** What makes Cortex Code different from general-purpose AI coding assistants?
> *Answer: B — It can connect to and query your live Snowflake data warehouse*
>
> **Q2:** Why is MFA bypassed for lab participants?
> *Answer: B — MFA triggers interactive browser prompts that block CLI automation; the bypass is temporary*

---

## Section 2: Cortex Code Primer (~10 min CLI / ~5 min Snowsight)

### What You Say

> "Now let's learn the key commands and set up our Jira integration so we can pull tickets directly into our coding workflow."

### Steps — CLI Track

**2.1 — Key slash commands overview** (demonstrate or walk through):

| Command | Purpose |
|---------|---------|
| `/plan` | Show action plan before executing |
| `/plan-off` | Return to direct execution |
| `/new` | Fresh conversation (clears context) |
| `/model` | Select AI model |
| `/mcp` | Manage MCP integrations |
| `/status` | Session status |

**2.3 — Install Atlassian MCP**

First exit Cortex Code:

```
/quit
```

Then in the terminal:

```bash
cortex mcp add atlassian https://mcp.atlassian.com/v1/mcp -t http -H "Authorization: Basic <token>"
```

> **Common mistake:** Running `cortex mcp add` *inside* the Cortex Code session. Must run in the terminal.

> **[SNOWSIGHT DIVERGENCE]**
> - **No MCP setup.** Snowsight path uses a `GET_JIRA_TICKET` UDF instead (created in Section 4).
> - **2.2 Key features:** Plan mode = ask "use plan mode" (no `/plan` command). File context is automatic. Code edits show an Apply/Dismiss banner.
> - **2.3 Jira access:** Explain that they'll create a UDF in Section 4 since MCP isn't available in the Snowsight UI.

---

## Section 3: Architecture Overview (~10 min CLI / ~5 min Snowsight)

### What You Say

> "Let's see Cortex Code's killer feature — it already knows your entire project. Ask it to describe the architecture and watch what happens."

### Steps — Both Tracks (same prompt)

Relaunch Cortex Code (CLI) or continue in the Snowsight session:

```bash
cortex   # CLI only — relaunch from repo root
```

```
Describe this project's data architecture and the Cortex Agent setup. What database, schemas, layers, domain tables, semantic view, and metrics are configured?
```

**Expected:** Cortex Code describes the medallion architecture (RAW > STAGING > INTERMEDIATE > MARTS), 7 domain tables, 10 metrics, and the `PAYMENT_ANALYTICS` semantic view — all from `AGENTS.md`.

### Instructor Callout

> "Cortex Code reads `AGENTS.md` automatically from the workspace/repo root. This is how it knows the full architecture without being told. Think about what you'd put in an `AGENTS.md` for your own project."

### Watch-For

| Issue | Path | Fix |
|-------|------|-----|
| Generic response, no database name | CLI | Not launched from repo root — re-launch |
| Generic response, no database name | Snowsight | Workspace not opened — run `open HOL_WORKSPACE` |

---

## KAHOOT BREAK — Questions 3, 4 & 5

> **Q3:** How did Cortex Code know the architecture without being told?
> *Answer: C — It reads AGENTS.md in the workspace/repo root*
>
> **Q4:** What would you include in an AGENTS.md for your own project?
> *Answer: B — Connection details, schema layout, business rules, key file paths, security constraints*
>
> **Q5:** What is a medallion architecture?
> *Answer: B — RAW stores untouched source data, STAGING cleans, INTERMEDIATE enriches, MARTS provides business-ready output*

---

## Section 4: Task 1 — Retry Success Rate Metric (~30 min)

### What You Say

> "Time for the main event. You'll take a Jira ticket from reading requirements to a deployed, queryable metric — all without leaving Cortex Code."

### Step 4.1: Read the Jira Ticket

**CLI:**

```
Show me Jira ticket EPA-2. What does it ask me to implement?
```

(Uses Atlassian MCP configured in Section 2.)

> **[SNOWSIGHT DIVERGENCE — Step 4.1]**
> Snowsight must first create the `GET_JIRA_TICKET` UDF. Three prompts in order:
>
> **Prompt 1 — Create the UDF:**
> > Create a Python UDF called `GET_JIRA_TICKET(issue_key VARCHAR)` in `COCO_SDLC_HOL_NN.PUBLIC`. It should call the Jira REST API and return the ticket type, summary, status, and description as plain text.
> > Use: REST API `https://api.atlassian.com/ex/jira/310bd229-0685-4130-a7cc-f994764ba475/rest/api/3/issue/{issue_key}`, Auth: Basic auth from `HOL_SHARED.PUBLIC.ATLASSIAN_TOKEN_SECRET`, EAI: `ATLASSIAN_EAI`, Runtime: Python 3.11.
>
> **Prompt 2 — Add JiraLookup tool to agent:**
> > Add a `JiraLookup` tool to `COCO_SDLC_HOL_NN.MARTS.PAYMENT_ANALYTICS_AGENT` that calls `COCO_SDLC_HOL_NN.PUBLIC.GET_JIRA_TICKET`.
>
> **Prompt 3 — Read the ticket:**
> > Show me Jira ticket EPA-2. What does it ask me to implement?
>
> **Watch-For:** If Cortex Code asks which database — select their `COCO_SDLC_HOL_NN`, not `HOL_SHARED`.

### Step 4.2: Implement the Metric (Both tracks — same prompt)

```
Based on the EPA-2 Jira ticket requirements, implement the retry success rate metric: add retry_attempt_flag and retry_success_flag columns to int_authorizations__enriched.sql using a window function (same card/amount/merchant within 5 minutes of a prior decline), pass both flags through in authorizations.sql, add the RETRY_SUCCESS_RATE metric to payment_analytics_semantic_view.sql, and update the Cortex Agent instructions in 03_create_agent.sql. Do not run dbt compile, dbt deps, or any dbt CLI commands after making the changes.
```

**4 files edited:**
1. `int_authorizations__enriched.sql` — retry flags via window function
2. `authorizations.sql` — pass-through to marts
3. `payment_analytics_semantic_view.sql` — `RETRY_SUCCESS_RATE` metric
4. `03_create_agent.sql` — agent instructions update

**CLI:** Confirm each file change as presented.
**Snowsight:** Click **Keep all** on the "Changed N files" banner.

### Step 4.3: Deploy to Snowflake

**CLI:**

```
Run:
  snow stage copy packages/dbt/ @COCO_SDLC_HOL_NN.PUBLIC.DBT_FILES --overwrite --parallel 4 --recursive -c HOL_USER_NN

Then add a new version of the dbt project from @COCO_SDLC_HOL_NN.PUBLIC.DBT_FILES/ and execute it with --select int_authorizations__enriched+ --full-refresh.
```

Three operations: `snow stage copy` > `ALTER DBT PROJECT ADD VERSION` > `EXECUTE DBT PROJECT`.

> **[SNOWSIGHT DIVERGENCE — Step 4.2 (Deploy)]**
> Different prompt — deploys from workspace, not stage:
> ```
> Deploy my workspace edits: add a new version (no alias) from HOL_WORKSPACE using versions/live, then execute the dbt project with ARGS = 'run --select int_authorizations__enriched+ --full-refresh'. Do not add a VERSION clause to EXECUTE DBT PROJECT.
> ```
> Two operations: `ALTER DBT PROJECT ADD VERSION FROM 'snow://workspace/.../versions/live'` > `EXECUTE DBT PROJECT`.
>
> **Critical:** Must use `versions/live` (includes Cortex Code edits), not `versions/last` (committed snapshots only).

### Step 4.4: Rebuild Semantic View and Agent (Both tracks — same prompt)

```
Execute the semantic view DDL from packages/dbt/analyses/payment_analytics_semantic_view.sql and the Cortex Agent DDL from packages/database/utilities/03_create_agent.sql against my database.
```

### Step 4.5: Verify End-to-End (Both tracks — same prompt)

```
Verify the retry success rate metric end-to-end: query MARTS.AUTHORIZATIONS directly for the retry success rate over the last 30 days using retry_attempt_flag and retry_success_flag, then ask the PAYMENT_ANALYTICS_AGENT the same question and confirm both return a consistent non-null percentage.
```

**Expected:** Percentage between 20% and 80%. If null, dynamic table still refreshing — wait 2-3 min.

### Step 4.6: Git Commit (CLI only)

```bash
git commit -am "feat: add retry success rate metric"
```

> **[SNOWSIGHT]** — No git step. Changes are already persisted in the workspace.

### Step 4.7: Confluence Reference (CLI only)

```
Read the Confluence data dictionary at https://evolv-coco-sdlc-hol.atlassian.net/wiki/spaces/EPA/pages/851970/Data+Dictionary+-+Authorizations. How should I document retry_success_rate to match the existing format?
```

> **[SNOWSIGHT]** — This step is skipped (no MCP / Confluence access).

### Watch-Fors

| Issue | Path | Fix |
|-------|------|-----|
| Only 2-3 files edited | Both | Re-prompt to include all 4 files |
| `versions/last` used | Snowsight | Re-run deploy prompt verbatim |
| Permission denied on STAGING | Both | Missing `--select` scope — re-run with it |
| `snow stage put` fails | CLI | Verify `DBT_FILES` stage exists |
| Metric not found after rebuild | Both | Re-execute the semantic view DDL |
| Dynamic table shows old data | Both | Wait 2-3 min or `ALTER DYNAMIC TABLE ... REFRESH;` |

### Instructor Callouts

> - `ADD VERSION` auto-sets the new version as default — no `SET DEFAULT_VERSION` needed.
> - Cortex Code validates the agent via Cortex Analyst (same engine). Seeing "Cortex Analyst" in output is expected.

---

## KAHOOT BREAK — Questions 6, 7, 8, 9 & 10

> **Q6:** How many files need to change to add a metric end-to-end?
> *Answer: C — Four (intermediate model, marts model, semantic view DDL, agent instructions)*
>
> **Q7:** Why is reviewing proposed changes before execution important?
> *Answer: B — Without review, AI could edit wrong files or deploy incorrect SQL*
>
> **Q8:** What are potential edge cases in the retry detection window function?
> *Answer: B — Partial amount retries, same card/amount at different merchant, retries after 5-min window, chained retries*
>
> **Q9:** How many tools did you context-switch between?
> *Answer: C — Just Cortex Code (plus a browser to verify)*
>
> **Q10:** Cortex Agent vs writing SQL yourself?
> *Answer: C — Agent: faster for ad-hoc, curated metrics, non-SQL users. SQL: more control, easier to debug*

---

## Section 5: Context Switch (~2 min)

### What You Say

> "Before we start the next ticket, clear your context. This is real-world hygiene — you don't want stale dbt context bleeding into your frontend task."

### Steps

**CLI:**

```
/new
```

> **[SNOWSIGHT]** — Click **New Conversation** (or the `+` icon).

### Instructor Callout

> "Plan mode is session-scoped. CLI users: you'll need to re-enable `/plan` if you want it for Task 2."

### Review What Task 1 Accomplished

- Retry detection logic (window function) in intermediate dbt model
- `retry_attempt_flag` and `retry_success_flag` passed through to marts
- `RETRY_SUCCESS_RATE` metric in semantic view
- Cortex Agent instructions updated
- Deployed and verified end-to-end via SQL and natural language

---

## KAHOOT BREAK — Question 11

> **Q11:** Why start a fresh conversation before Task 2?
> *Answer: B — Task 1 context (dbt/SQL/retry logic) is irrelevant to Task 2 (dashboard code) — stale context confuses the AI*

---

## Section 6: Task 2 — Add KPI Card to Dashboard (~20 min)

### What You Say

> "Now the metric exists in the data layer. Your next ticket is to surface it in the dashboard. Watch how Cortex Code switches from SQL/dbt to frontend code seamlessly."

### Step 6.1: Read the Jira Ticket

**CLI:**

```
Using the Jira MCP, show me ticket EPA-3. What does it ask me to implement?
```

> **[SNOWSIGHT DIVERGENCE — Step 6.1]**
> Ask the Cortex Agent (under **AI & ML > Cortex Agents**):
> ```
> Show me Jira ticket EPA-3. What does it ask me to implement?
> ```
> The agent uses the `JiraLookup` tool created in Section 4.

### Step 6.2: Create a Git Branch (CLI only)

```
Create a new git branch called feature/retry-success-kpi-card and switch to it.
```

> **[SNOWSIGHT]** — No git branch step.

### Step 6.3: Implement the KPI Card

**CLI:**

```
Using the Jira MCP, read EPA-3 and implement the KPI card changes.
```

Edits 3 files:
- `apps/frontend/src/types/domain.ts` — adds `retrySuccessRate: number` to `AuthorizationKPIs`
- `apps/frontend/src/app/api/analytics/authorization/kpis/route.ts` — adds SQL + return field
- `apps/frontend/src/app/analytics/authorization/page.tsx` — adds `<KPICard>`

> **[SNOWSIGHT DIVERGENCE — Step 6.2]**
> Different prompt, different file:
> ```
> Based on the EPA-3 Jira ticket, implement the Retry Success Rate KPI card in apps/streamlit/app.py.
> ```
> Edits **1 file** (`apps/streamlit/app.py`):
> - Adds retry success rate column to the KPI SQL query
> - Uncomments the fifth `st.metric()` card

### Step 6.4: Verify

**CLI:**

```
Restart the frontend dev server from apps/frontend.
```

Open http://localhost:3000/analytics/authorization — expect 5 KPI cards including "Retry Success Rate".

> **[SNOWSIGHT DIVERGENCE — Step 6.3]**
> Navigate to **Projects > Streamlit**, open `PAYMENT_ANALYTICS_DASHBOARD`. Expect 5 KPI cards. If still showing 4, click the refresh button in the top-right.

### Step 6.5: PR (CLI only, informational)

In a real workflow, you'd open a pull request here. For the lab, no remote push is required.

> **[SNOWSIGHT]** — No PR step.

### Watch-Fors

| Issue | Path | Fix |
|-------|------|-----|
| Streamlit still shows 4 cards | Snowsight | Click refresh in Streamlit app |
| Plan order wrong (page.tsx before domain.ts) | CLI | Reorder — `domain.ts` must come first |
| KPI card shows 0 or undefined | CLI | Check `AuthorizationKPIs` includes `retrySuccessRate: number` |

### Instructor Callout (CLI)

> "Notice the full loop: Jira ticket read at the start, code changes, local verification, and a PR at the end — all without leaving the terminal."

---

## KAHOOT BREAK — Questions 12 & 13

> **Q12:** Comparing Task 1 and Task 2 — what stayed the same and what changed?
> *Answer: B — Same workflow (read ticket > implement > verify), different files (SQL/dbt vs dashboard code) — the workflow is language-agnostic*
>
> **Q13:** Task 1 metric is the data source for Task 2's KPI card. How does that mirror real sprint work?
> *Answer: B — Backend work in one ticket unblocks frontend work in another — normal dependency chain*

---

## Section 7: Wrap-up (~5 min)

### What You Say

> "Let's recap. You just completed two full development cycles — backend data metric and frontend dashboard card — using AI-assisted development. Let me highlight the key takeaways."

### Key Takeaways to Emphasize

1. **Automatic file context** — `AGENTS.md` gives the AI full project awareness without manual setup
2. **Plan mode for review** — `/plan` (CLI) or "use plan mode" (Snowsight) is a human checkpoint before code is written
3. **MCP / tool integrations** — Jira and Confluence access without leaving the coding assistant
4. **Extend existing patterns** — AI works best when following established conventions in the codebase
5. **Context hygiene** — `/new` between tasks keeps context focused and produces better suggestions

### What They Accomplished

- **Task 1:** Retry success rate metric end-to-end: dbt intermediate > marts > semantic view > Cortex Agent. Verified via SQL and natural language.
- **Task 2:** Frontend KPI card displaying the new metric. CLI: React (3 files). Snowsight: Streamlit (1 file).
- **Throughout:** Read Jira tickets, planned with AI, reviewed changes step-by-step, deployed, verified — entirely within Cortex Code.

---

## KAHOOT BREAK — Questions 14 & 15 (General / Closing)

> **Q14:** Where did AI save the most time, and where did human judgment matter most?
> *Answer: B — AI saved time on boilerplate, file discovery, SQL generation; human judgment for plan review, edge cases, verifying correctness*
>
> **Q15:** What would you trust the AI to do unsupervised, and what would you always review?
> *Answer: C — Trust: branch creation, scaffolding, simple queries. Always review: SQL that modifies data, business logic, security code, production changes*

---

## Section 8: Bonus — Semantic View as dbt Model (Optional)

> Only if attendees finish early. Same prompt for both tracks.

### Step 8.1: Implement

```
Can you implement the semantic view using dbt_semantic_view? https://www.snowflake.com/en/engineering-blog/dbt-semantic-view-package/
```

Cortex Code will:
1. Add `Snowflake-Labs/dbt_semantic_view` to `packages.yml`
2. Install with `dbt deps`
3. Create `packages/dbt/models/marts/payments/payment_analytics.sql`

### Step 8.2: Deploy and Verify

**CLI:**

```
Upload the updated dbt project files to the DBT_FILES stage, add a new version, execute the dbt project with --select payment_analytics, and ask the PAYMENT_ANALYTICS_AGENT for the retry success rate to confirm the semantic view still works correctly.
```

> **[SNOWSIGHT DIVERGENCE]**
> ```
> Deploy my workspace edits: add a new version (no alias) from HOL_WORKSPACE using versions/live, execute the dbt project with --select payment_analytics, and ask the PAYMENT_ANALYTICS_AGENT for the retry success rate to confirm the semantic view still works correctly.
> ```

---

## Quick Reference: Kahoot Question Placement

| After Section | Questions | Topic |
|---------------|-----------|-------|
| Section 1 (Setup) | Q1, Q2 | Cortex Code differentiation, MFA bypass |
| Section 3 (Architecture) | Q3, Q4, Q5 | AGENTS.md, medallion architecture |
| Section 4 (Task 1) | Q6, Q7, Q8, Q9, Q10 | End-to-end changes, review importance, edge cases, tool consolidation, Agent vs SQL |
| Section 5 (Context Switch) | Q11 | Context hygiene |
| Section 6 (Task 2) | Q12, Q13 | Workflow consistency, sprint dependencies |
| Section 7 (Wrap-up) | Q14, Q15 | AI trust boundaries, human judgment |

---

## Quick Reference: Track Divergence Summary

| Aspect | CLI | Snowsight |
|--------|-----|-----------|
| Repo access | `git clone` locally | `open HOL_WORKSPACE` |
| Jira access | Atlassian MCP | `GET_JIRA_TICKET` UDF + Agent tool |
| dbt deploy | `snow stage copy` > `ADD VERSION` > `EXECUTE` | Workspace `versions/live` > `ADD VERSION` > `EXECUTE` |
| Task 2 dashboard | React (3 TypeScript files) | Streamlit (1 Python file) |
| Plan mode | `/plan` slash command | "Use plan mode" prompt |
| Git workflow | Feature branch + local commit | Not used |
| Confluence | MCP read in Step 4.7 | Skipped |

---

*Generated for instructor use. Not for distribution to attendees.*
