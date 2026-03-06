# Phase 3: Generate Reference Content for Jira Tickets and Confluence Documentation - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce reference content for Jira tickets and a Confluence data dictionary page, then create the actual artifacts in Atlassian Cloud via API. The content supports the two development tasks in HANDS_ON_LAB.md (retry success rate metric + KPI card) and makes the Jira board feel like a real project with an epic and backlog items.

**In scope:**
- Jira: Epic, two main tickets (TICKET-1 and TICKET-2 from lab guide), 2-3 backlog items
- Confluence: Data dictionary page (metrics + key dimensions from semantic view)
- Reference .wiki files in docs/jira/ and docs/confluence/
- API creation of all artifacts in Atlassian Cloud

**Out of scope:**
- Jira board configuration or workflow customization
- Confluence space creation (assumed to exist)
- Additional Confluence pages (architecture wiki, runbook, etc.)

</domain>

<decisions>
## Implementation Decisions

### Jira ticket content
- Full story format: user story, business context description, detailed acceptance criteria
- Business-only acceptance criteria — describe WHAT the outcome should be, not HOW to implement it (Cortex Code + AGENTS.md figures out implementation)
- No technical hints, file paths, or implementation steps in tickets
- Full metadata: story points, priority, labels (e.g., 'dbt', 'frontend', 'semantic-view'), components, sprint assignment

### Jira project structure
- Epic + two main tickets + 2-3 backlog items to make the board feel lived-in
- Project key: EPA, Project name: 'evolv Payment Analytics'
- Ticket numbers should be higher (not EPA-1/EPA-2) — project should feel like it has history
- Backlog items are unassigned, unprioritized — just there for realism

### Confluence data dictionary
- Single page: 'Payment Analytics Data Dictionary' in EPA space
- Covers metrics AND key dimensions/facts from the semantic view (not full lineage)
- Deliberately omits retry_success_rate — participants see the documentation gap when they read it during the lab
- Format: Claude's discretion (pick what works best for participants reading via MCP)

### Delivery format
- Reference files in docs/jira/ (one .wiki file per artifact) and docs/confluence/ (one .wiki file)
- Jira wiki markup syntax for Jira content
- Confluence wiki markup syntax for Confluence content (matching Jira choice)
- .wiki file extension (not .md)
- Pure wiki markup — no markdown headers or summaries in the files

### Atlassian API creation
- Base URL: https://evolv-coco-sdlc-hol.atlassian.net
- Email: trent.foley@evolvconsulting.com
- API token: provided at execution time via environment or direct input (NEVER stored in committed files)
- Create all Jira tickets and Confluence page via REST API after generating reference files
- Jira project EPA and Confluence space EPA assumed to already exist

### Instructor workflow
- No setup guide needed — instructor knows Jira/Confluence
- No template variables — use concrete values (EPA project key, actual ticket numbers)
- Reference files serve as source of truth; API creation is the delivery mechanism

### Claude's Discretion
- Data dictionary format (table vs card vs hybrid)
- Exact backlog ticket topics (should be realistic payment analytics work)
- Ticket number assignments (higher numbers to suggest project history)
- Story point estimates
- Sprint naming

</decisions>

<specifics>
## Specific Ideas

- HANDS_ON_LAB.md references [TICKET-1] and [TICKET-2] as placeholders — the actual EPA ticket IDs created here should be what instructors substitute into the lab guide
- Data dictionary omitting retry_success_rate creates a deliberate "aha" moment when participants read it via Confluence MCP during Task 1 step 4.12
- Backlog items should be realistic payment analytics work (e.g., add settlement dispute tracking, chargeback alert threshold, funding reconciliation report) — things that feel like a real product backlog

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `HANDS_ON_LAB.md`: Defines exact acceptance criteria and workflow for both tickets — content must align
- `INFRASTRUCTURE.md`: Data architecture reference for data dictionary accuracy
- `packages/dbt/analyses/payment_analytics_semantic_view.sql`: Source of truth for metrics, dimensions, and relationships in the semantic view
- `packages/database/utilities/03_create_agent.sql`: Cortex Agent definition with metric list

### Established Patterns
- Lab guide uses [TICKET-1], [TICKET-2], [CONFLUENCE-DATA-DICTIONARY-URL] as instructor-substituted placeholders
- Jira/Confluence MCP is read-only in the lab — participants read but don't write
- All 10 existing semantic view metrics documented in INFRASTRUCTURE.md (approval_rate, chargeback_win_rate, effective_fee_rate, etc.)

### Integration Points
- Ticket IDs created here replace [TICKET-1] and [TICKET-2] placeholders in HANDS_ON_LAB.md
- Confluence page URL replaces [CONFLUENCE-DATA-DICTIONARY-URL] in HANDS_ON_LAB.md
- Data dictionary content must match the actual semantic view metrics/dimensions in Snowflake

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-generate-reference-content-for-jira-tickets-and-confluence-documentation*
*Context gathered: 2026-03-06*
