# Phase 2: Create the Hands-On Lab Instruction Guide - Context

**Gathered:** 2026-03-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce a single comprehensive markdown guide (`HANDS_ON_LAB.md`) that walks HOL participants through using Cortex Code to make code changes across the full SDLC — from reading a Jira ticket through committing and creating a PR. The guide demonstrates AI-assisted development workflows on a real payment analytics codebase.

**In scope:**
- Written lab guide with step-by-step instructions
- Architecture overview of pre-configured environment
- Cortex Code primer (installation, basic commands, skill setup)
- Two end-to-end development tasks using Cortex Code
- Verification steps after each task
- Appendix with resources and troubleshooting

**Out of scope:**
- Setup script execution (covered in Phase 1; guide assumes environment is ready)
- Creating Jira/Confluence infrastructure (pre-created by instructor)
- Automated testing of the guide itself

</domain>

<decisions>
## Implementation Decisions

### Guide structure
- **Linear sequence**: Overview → Setup verification → Task 1 → Task 2 → Wrap-up
- **Skip setup execution**: Guide provides overview of what's pre-configured but doesn't walk through `hol_setup.sql`
- **All optional sections included**: Cortex Code primer, architecture overview, appendix/resources, wrap-up
- **Time estimates**: Each section shows expected duration (e.g., "~10 min")
- **Verification steps**: After each task, show expected output/query results participants should see
- **Single feature branch**: All changes on one branch, commit as you go

### Task flow (two tickets)

**Ticket 1: Add Retry Success Rate metric to NLQ agent**
1. Read Jira ticket (pre-created in demo project)
2. Create local git branch
3. Use Cortex Code plan mode to plan the work
4. Confirm and execute plan
5. dbt model update — add `retry_success_rate` measure to authorizations
6. dbt materialization update — view → dynamic table
7. Update and run unit tests
8. Review and confirm semantic view update (add new metric)
9. Review and confirm Cortex Agent instruction change
10. Launch local app for human-in-the-loop verification
11. Commit and push change
12. Update Confluence data dictionary (existing page)

**Context switch — clear context window**

**Ticket 2: Add KPI card to dashboard using new metric**
1. Pull next Jira ticket
2. Create branch
3. Use Cortex Code plan mode to plan the update
4. Apply the update (new KPI card in frontend)
5. Launch local app for verification
6. Commit and push change
7. Submit PR

### Task specifics
- **Domain focus**: Authorizations (highest volume, most visible impact)
- **New metric**: Retry success rate — count of retry attempts that succeeded after initial decline
- **New visualization**: KPI card showing the retry success rate metric
- **Jira tickets**: Pre-created by instructor in a demo Jira project; guide references ticket IDs
- **Confluence**: Existing data dictionary page that participants update
- **Skills**: Jira and Confluence skills installed during lab as part of primer section

### Delivery format
- **Primary format**: Markdown file in repo root
- **Single file**: One comprehensive document with all sections
- **Location**: `HANDS_ON_LAB.md` at repo root
- **Visuals**: Mixed — diagrams for architecture, screenshots for verification points

### Tone and depth
- **Voice**: Third person instructional ("In this section, you will...")
- **Detail level**: Step-by-step with every command spelled out, copy-paste ready
- **Explanations**: Include context explaining why each step matters
- **Prompts**: Suggested prompts shown with note that variations work

</decisions>

<specifics>
## Specific Ideas

- HOL goal: demonstrate AI coding assistant (Cortex Code) throughout the SDLC
- Participants use Cortex Code to read tickets, plan work, make changes, verify, commit, and create PRs
- Two-ticket flow shows context switching between tasks
- Retry success rate is a meaningful business metric — shows resilience of payment processing
- Architecture overview helps participants understand what they're modifying
- Cortex Code primer ensures all participants start with same baseline knowledge

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `packages/dbt/models/marts/payments/authorizations.sql`: Target for new measure
- `packages/dbt/analyses/payment_analytics_semantic_view.sql`: Semantic view DDL to update
- `packages/database/utilities/03_create_agent.sql`: Cortex Agent definition
- `apps/frontend/src/app/analytics/authorization/page.tsx`: Frontend page to add KPI card
- `apps/frontend/src/components/ui/KPICard.tsx`: Existing KPI card component to reuse

### Established Patterns
- KPI cards use `useAnalyticsData` hook for data fetching
- Semantic view follows existing dimension/fact/metric structure
- dbt models use `{{ config(materialized='dynamic_table') }}` pattern
- Frontend follows Ant Design component patterns

### Integration Points
- New measure in dbt flows to semantic view → Cortex Agent
- Frontend API routes in `apps/frontend/src/app/api/analytics/authorization/`
- Config centralized in `apps/frontend/src/lib/config.ts`

</code_context>

<deferred>
## Deferred Ideas

- Video walkthrough companion to written guide — separate deliverable
- Multi-domain lab variant (chargebacks, settlements) — future enhancement
- Automated lab environment reset script — instructor tooling
- Participant progress tracking dashboard — future milestone

</deferred>

---

*Phase: 02-create-the-hands-on-lab-instruction-guide*
*Context gathered: 2026-03-03*
