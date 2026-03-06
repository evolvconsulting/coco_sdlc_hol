# Phase 3: Generate Reference Content for Jira Tickets and Confluence Documentation - Research

**Researched:** 2026-03-06
**Domain:** Atlassian REST APIs (Jira Cloud v3, Confluence Cloud v1/v2), Jira/Confluence wiki markup, payment analytics domain content
**Confidence:** HIGH

## Summary

This phase produces reference `.wiki` files for Jira tickets and a Confluence data dictionary, then creates the actual artifacts in Atlassian Cloud via REST API. The research covers three domains: (1) the correct REST API endpoints and JSON structures for creating Jira issues and Confluence pages, (2) wiki markup syntax for both Jira descriptions and Confluence page bodies, and (3) the payment analytics semantic view data that populates the content.

The critical finding is that Jira Cloud REST API v3 uses Atlassian Document Format (ADF) -- a structured JSON format -- for the description field, NOT wiki markup. Wiki markup in `.wiki` files serves as the human-readable source of truth, but must be converted to ADF JSON when creating Jira issues via API. For Confluence, the v1 API (`/wiki/rest/api/content/`) accepts storage format (XHTML-based), with a conversion endpoint available to transform wiki markup to storage format. The v2 API also works but uses `spaceId` (numeric) instead of space `key`.

**Primary recommendation:** Write `.wiki` reference files in Jira wiki markup syntax. For API creation, build a script that either (a) converts wiki markup to ADF programmatically for Jira descriptions, or (b) constructs ADF JSON directly. For Confluence, use the v1 API with the wiki-to-storage conversion endpoint or write storage format XHTML directly.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- Full story format: user story, business context description, detailed acceptance criteria
- Business-only acceptance criteria -- describe WHAT the outcome should be, not HOW to implement it
- No technical hints, file paths, or implementation steps in tickets
- Full metadata: story points, priority, labels, components, sprint assignment
- Project key: EPA, Project name: 'evolv Payment Analytics'
- Ticket numbers should be higher (not EPA-1/EPA-2) -- project should feel like it has history
- Epic + two main tickets + 2-3 backlog items; backlog items unassigned, unprioritized
- Single Confluence page: 'Payment Analytics Data Dictionary' in EPA space
- Covers metrics AND key dimensions/facts from the semantic view
- Deliberately omits retry_success_rate from data dictionary
- Reference files in docs/jira/ (.wiki per artifact) and docs/confluence/ (.wiki)
- Jira wiki markup syntax for Jira content, Confluence wiki markup for Confluence content
- .wiki file extension, pure wiki markup (no markdown)
- Base URL: https://evolv-coco-sdlc-hol.atlassian.net
- Email: trent.foley@evolvconsulting.com
- API token: provided at execution time (NEVER stored in committed files)
- Create all artifacts via REST API after generating reference files
- No setup guide needed; no template variables; use concrete values

### Claude's Discretion
- Data dictionary format (table vs card vs hybrid)
- Exact backlog ticket topics (should be realistic payment analytics work)
- Ticket number assignments (higher numbers to suggest project history)
- Story point estimates
- Sprint naming

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope

</user_constraints>

## Standard Stack

### Core

| Tool | Purpose | Why Standard |
|------|---------|--------------|
| Jira Cloud REST API v3 | Create epics, stories in Jira | Current Atlassian Cloud API version |
| Confluence Cloud REST API v1 | Create pages in Confluence | v1 supports space key and storage format; simpler than v2 for page creation |
| curl / bash script | Execute API calls | No external dependencies; simple auth header |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| Confluence Content Body Convert API | Convert wiki markup to storage format | If writing wiki markup files and need to push to Confluence API |
| Jira Field Discovery API (`/rest/api/3/field`) | Discover custom field IDs for story points, sprint | Must call once to find the correct customfield_XXXXX IDs for the target instance |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| curl scripts | Python `requests` / `atlassian-python-api` | More dependencies; curl is simpler for one-shot creation |
| Confluence v1 API | Confluence v2 API | v2 requires numeric `spaceId` (must look up); v1 accepts space `key` directly |
| ADF JSON in .wiki files | Pure wiki markup in .wiki files | .wiki files should be human-readable wiki markup; ADF conversion happens at API call time |

## Architecture Patterns

### Recommended Project Structure

```
docs/
  jira/
    EPA-42-epic.wiki              # Epic: Payment Analytics Platform
    EPA-47-retry-success-rate.wiki # Story: Add retry success rate metric (TICKET-1)
    EPA-48-kpi-card.wiki          # Story: Add retry success rate KPI card (TICKET-2)
    EPA-43-backlog-1.wiki         # Backlog item 1
    EPA-44-backlog-2.wiki         # Backlog item 2
    EPA-45-backlog-3.wiki         # Backlog item 3 (optional)
  confluence/
    data-dictionary.wiki          # Payment Analytics Data Dictionary
scripts/
  create-atlassian-artifacts.sh   # API creation script (or inline in plan tasks)
```

### Pattern 1: Jira Wiki Markup File Structure

**What:** Each `.wiki` file contains pure Jira wiki markup for the ticket description/body.
**When to use:** All Jira ticket reference files.

```
h2. User Story

As a [persona], I want [capability] so that [benefit].

h2. Business Context

[2-3 paragraphs explaining the business need]

h2. Acceptance Criteria

# [Business outcome 1]
# [Business outcome 2]
# [Business outcome 3]

h2. Notes

{panel:title=Important|borderStyle=solid|borderColor=#ccc|bgColor=#FFFFCE}
[Any important context]
{panel}
```

### Pattern 2: Jira Cloud REST API v3 -- Create Issue

**What:** POST to `/rest/api/3/issue` with ADF-formatted description.
**When to use:** Creating every Jira issue (epic, story, backlog item).

```bash
curl -s -X POST \
  -H "Authorization: Basic $(echo -n 'email:token' | base64)" \
  -H "Content-Type: application/json" \
  "https://evolv-coco-sdlc-hol.atlassian.net/rest/api/3/issue" \
  -d '{
    "fields": {
      "project": { "key": "EPA" },
      "issuetype": { "name": "Story" },
      "summary": "Add retry success rate metric to authorizations domain",
      "description": {
        "version": 1,
        "type": "doc",
        "content": [
          {
            "type": "heading",
            "attrs": { "level": 2 },
            "content": [{ "type": "text", "text": "User Story" }]
          },
          {
            "type": "paragraph",
            "content": [{ "type": "text", "text": "As a payment analyst..." }]
          }
        ]
      },
      "priority": { "name": "High" },
      "labels": ["dbt", "semantic-view", "metric"],
      "parent": { "key": "EPA-42" }
    }
  }'
```

**Critical:** The `description` field in API v3 MUST be ADF JSON, not plain text or wiki markup. The `parent` field links a story to its epic (replaces deprecated `customfield_10014` / Epic Link).

### Pattern 3: Create Epic

**What:** Epics use `"issuetype": {"name": "Epic"}` and have a `summary` field (Epic Name field is deprecated in favor of Summary).

```bash
# Epic creation -- no parent field needed
{
  "fields": {
    "project": { "key": "EPA" },
    "issuetype": { "name": "Epic" },
    "summary": "Payment Analytics Platform Enhancements",
    "description": { ... ADF JSON ... },
    "priority": { "name": "Medium" },
    "labels": ["platform", "analytics"]
  }
}
```

### Pattern 4: Confluence Page Creation (v1 API)

**What:** POST to `/wiki/rest/api/content/` with storage format body.
**When to use:** Creating the data dictionary page.

```bash
curl -s -X POST \
  -H "Authorization: Basic $(echo -n 'email:token' | base64)" \
  -H "Content-Type: application/json" \
  "https://evolv-coco-sdlc-hol.atlassian.net/wiki/rest/api/content/" \
  -d '{
    "type": "page",
    "title": "Payment Analytics Data Dictionary",
    "space": { "key": "EPA" },
    "body": {
      "storage": {
        "value": "<h1>Payment Analytics Data Dictionary</h1><p>...</p>",
        "representation": "storage"
      }
    }
  }'
```

### Pattern 5: Wiki Markup to Storage Format Conversion

**What:** Convert wiki markup to Confluence storage format via API.
**When to use:** If writing the Confluence .wiki file in wiki markup and need to convert for API upload.

```bash
# Convert wiki markup to storage format
curl -s -X POST \
  -H "Authorization: Basic $(echo -n 'email:token' | base64)" \
  -H "Content-Type: application/json" \
  "https://evolv-coco-sdlc-hol.atlassian.net/wiki/rest/api/contentbody/convert/storage" \
  -d '{
    "value": "h1. Data Dictionary\n\n||Metric||Description||Formula||\n|Approval Rate|Percentage of auths approved|...|",
    "representation": "wiki"
  }'
```

**Note:** The synchronous conversion endpoint (`/contentbody/convert/storage`) was scheduled for deprecation in April 2025 but may still be available. If deprecated, use the async endpoint or write storage format XHTML directly.

### Anti-Patterns to Avoid

- **Sending wiki markup as plain text in Jira v3 description:** The API will accept it but render it as literal text, not formatted content. Must use ADF JSON.
- **Hardcoding custom field IDs:** Story points field ID (`customfield_XXXXX`) varies per Jira instance. Must discover via `/rest/api/3/field` endpoint first.
- **Using EPA-1, EPA-2 for ticket numbers:** Context requires higher numbers to simulate project history. Ticket numbers are auto-assigned by Jira -- cannot be controlled directly. The plan must create filler issues or accept Jira's auto-numbering.
- **Including retry_success_rate in the data dictionary:** Deliberately omitted to create the "aha" moment in the lab.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Wiki-to-ADF conversion | Custom parser | Build ADF JSON directly in the creation script | Wiki markup to ADF is complex; easier to construct ADF programmatically |
| Wiki-to-storage-format conversion | Custom XHTML builder | Confluence `/contentbody/convert/storage` endpoint OR write XHTML directly | Confluence storage format has custom elements (`ac:structured-macro`) that are hard to hand-build |
| Base64 auth encoding | Manual encoding | `echo -n 'email:token' \| base64` in bash | Standard pattern, no library needed |
| Jira ticket numbering | Fake numbers in API | Accept Jira's auto-increment; create epic first, then stories | Jira assigns numbers sequentially; cannot specify a custom number via API |

**Key insight:** Jira does NOT allow specifying ticket numbers. EPA-42, EPA-47, etc. cannot be set via API -- Jira auto-increments. To get higher numbers, you would need to either (a) accept whatever numbers Jira assigns (likely EPA-1, EPA-2, etc. for a fresh project) or (b) create and delete placeholder issues to advance the counter. The simpler approach: accept the auto-assigned numbers and update the lab guide with the actual IDs after creation.

## Common Pitfalls

### Pitfall 1: Jira API v3 Description Format
**What goes wrong:** Sending wiki markup or plain text string in the `description` field results in unformatted text displayed literally in the ticket.
**Why it happens:** Jira Cloud REST API v3 requires Atlassian Document Format (ADF) JSON for the description field. The v2 API accepted wiki markup, but v3 does not.
**How to avoid:** Construct ADF JSON objects for all description content. Use the ADF structure: `{"version": 1, "type": "doc", "content": [...]}` with proper node types (heading, paragraph, bulletList, orderedList, table, panel, codeBlock).
**Warning signs:** Description appears as raw markup text in the Jira UI after creation.

### Pitfall 2: Custom Field ID Discovery
**What goes wrong:** Using `customfield_10016` (common default for Story Points) fails because the actual ID differs per instance.
**Why it happens:** Custom field IDs are instance-specific. Story Points, Sprint, and other "standard" custom fields have different IDs on every Jira Cloud instance.
**How to avoid:** Call `GET /rest/api/3/field` to list all fields and find the correct IDs for Story Points and Sprint before creating issues. Cache these IDs for the creation script.
**Warning signs:** `400 Bad Request` or `Field 'customfield_XXXXX' cannot be set` errors.

### Pitfall 3: Sprint Assignment Requires Board/Sprint ID
**What goes wrong:** Cannot set sprint by name; requires the sprint's numeric ID.
**Why it happens:** Sprint is a custom field that expects an integer ID, not a string name.
**How to avoid:** First find the board ID via Jira Software REST API (`/rest/agile/1.0/board?projectKeyOrId=EPA`), then list sprints for that board (`/rest/agile/1.0/board/{boardId}/sprint`), then use the sprint ID in the issue creation payload.
**Warning signs:** Sprint field silently ignored or error on creation.

### Pitfall 4: Confluence Space Must Exist
**What goes wrong:** API returns 404 when creating a page in space "EPA" if the space doesn't exist.
**Why it happens:** CONTEXT.md states "Confluence space EPA assumed to already exist" but this must be verified.
**How to avoid:** Before creating the page, verify the space exists with `GET /wiki/rest/api/space/EPA`. Create it if missing.
**Warning signs:** `404 Not Found` or `com.atlassian.confluence.api.service.exceptions.NotFoundException`.

### Pitfall 5: Ticket Number Control
**What goes wrong:** Wanting EPA-42 but getting EPA-1 because Jira auto-assigns sequential IDs.
**Why it happens:** Jira Cloud does not allow specifying the issue number via API. Numbers are auto-incremented per project.
**How to avoid:** Accept auto-assigned numbers. The creation script should capture returned issue keys and output them for the instructor to substitute into HANDS_ON_LAB.md. Alternatively, create throwaway issues first to advance the counter, but this adds complexity.
**Warning signs:** Created issues have unexpected low numbers.

### Pitfall 6: Components Must Exist Before Assignment
**What goes wrong:** Setting `"components": [{"name": "Backend"}]` fails if the component doesn't exist in the EPA project.
**Why it happens:** Components must be pre-created in the project settings before they can be assigned to issues.
**How to avoid:** Create components first via `POST /rest/api/3/component` or manually in Jira project settings before running the issue creation script.
**Warning signs:** `400 Bad Request` with component-related error.

## Code Examples

### ADF JSON for a Complete Jira Story Description

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "type": "text", "text": "User Story" }]
    },
    {
      "type": "paragraph",
      "content": [
        { "type": "text", "text": "As a ", "marks": [] },
        { "type": "text", "text": "payment analyst", "marks": [{ "type": "strong" }] },
        { "type": "text", "text": ", I want to see the retry success rate metric so that I can understand how many declined transactions are recovered through customer retries." }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "type": "text", "text": "Acceptance Criteria" }]
    },
    {
      "type": "orderedList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "type": "text", "text": "The retry success rate metric is available in the semantic view for natural language queries" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "type": "text", "text": "The Cortex Agent can answer questions about retry success rates" }]
            }
          ]
        }
      ]
    },
    {
      "type": "panel",
      "attrs": { "panelType": "info" },
      "content": [
        {
          "type": "paragraph",
          "content": [{ "type": "text", "text": "A retry is when the same card and amount appear within 5 minutes of a declined transaction at the same merchant." }]
        }
      ]
    }
  ]
}
```

### Confluence Storage Format for Data Dictionary Table

```xml
<h1>Payment Analytics Data Dictionary</h1>
<p>Metrics available in the PAYMENT_ANALYTICS semantic view.</p>
<h2>Metrics</h2>
<table>
  <tr>
    <th>Metric</th>
    <th>Description</th>
    <th>Formula</th>
    <th>Data Type</th>
  </tr>
  <tr>
    <td>APPROVAL_RATE</td>
    <td>Percentage of authorizations approved</td>
    <td>Approved count / Total count * 100</td>
    <td>NUMBER (%)</td>
  </tr>
  <tr>
    <td>TOTAL_AUTHORIZATION_VOLUME</td>
    <td>Total authorization amount in USD</td>
    <td>SUM(transaction_amount)</td>
    <td>NUMBER ($)</td>
  </tr>
</table>
```

### Discover Custom Field IDs

```bash
# Find Story Points and Sprint field IDs
curl -s -X GET \
  -H "Authorization: Basic $(echo -n "$EMAIL:$API_TOKEN" | base64)" \
  "https://evolv-coco-sdlc-hol.atlassian.net/rest/api/3/field" \
  | python3 -c "
import json, sys
fields = json.load(sys.stdin)
for f in fields:
    if 'story point' in f['name'].lower() or 'sprint' in f['name'].lower():
        print(f'{f[\"id\"]:30s} {f[\"name\"]}')"
```

### Find Board and Sprint IDs

```bash
# Get board ID for EPA project
curl -s -X GET \
  -H "Authorization: Basic $(echo -n "$EMAIL:$API_TOKEN" | base64)" \
  "https://evolv-coco-sdlc-hol.atlassian.net/rest/agile/1.0/board?projectKeyOrId=EPA"

# List sprints for board
curl -s -X GET \
  -H "Authorization: Basic $(echo -n "$EMAIL:$API_TOKEN" | base64)" \
  "https://evolv-coco-sdlc-hol.atlassian.net/rest/agile/1.0/board/{BOARD_ID}/sprint"
```

### Create Component

```bash
curl -s -X POST \
  -H "Authorization: Basic $(echo -n "$EMAIL:$API_TOKEN" | base64)" \
  -H "Content-Type: application/json" \
  "https://evolv-coco-sdlc-hol.atlassian.net/rest/api/3/component" \
  -d '{"name": "Backend", "project": "EPA"}'
```

## Semantic View Data for Content

### 10 Existing Metrics (for data dictionary -- omit retry_success_rate)

| Metric Name | Description | Source Table | Formula Pattern |
|-------------|-------------|-------------|-----------------|
| APPROVAL_RATE | Percentage of authorizations approved | AUTHORIZATIONS | approved / total * 100 |
| TOTAL_AUTHORIZATION_VOLUME | Total authorization amount | AUTHORIZATIONS | SUM(transaction_amount) |
| AVERAGE_TRANSACTION_AMOUNT | Average transaction amount | AUTHORIZATIONS | AVG(transaction_amount) |
| NET_SETTLEMENT_VOLUME | Total net settlement amount | SETTLEMENTS | SUM(net_amount) |
| TOTAL_DEPOSITS | Total deposit amount | DEPOSITS | SUM(deposit_amount) |
| EFFECTIVE_FEE_RATE | Processing fees as % of sales | DEPOSITS | fees / sales * 100 |
| CHARGEBACK_VOLUME | Total chargeback amount | CHARGEBACKS | SUM(dispute_amount) |
| CHARGEBACK_WIN_RATE | Percentage of chargebacks won | CHARGEBACKS | won / total * 100 |
| CHARGEBACK_RATE | Chargeback count as % of total txns | CHARGEBACKS + AUTHORIZATIONS | cbk count / auth count * 100 |
| NET_ADJUSTMENTS | Net adjustment amount | ADJUSTMENTS | SUM(adjustment_amount) |
| RETRIEVAL_FULFILLMENT_RATE | Percentage of retrievals fulfilled | RETRIEVALS | closed / total * 100 |

Note: There are 11 metrics listed in the semantic view YAML, not 10. INFRASTRUCTURE.md says 10, but the actual YAML has 11. The data dictionary should include all 11 existing metrics (everything except retry_success_rate which doesn't exist yet at this phase).

### 7 MARTS Tables (for data dictionary dimensions/facts)

| Table | Key Dimensions | Key Facts |
|-------|---------------|-----------|
| AUTHORIZATIONS | transaction_date, merchant_id, card_brand, card_type, entry_mode, approval_status, decline_reason | transaction_amount, transactions_count |
| SETTLEMENTS | settlement_date, merchant_id, card_brand, card_type | sales_count, sales_amount, refund_count, refund_amount, net_amount, interchange_amount |
| DEPOSITS | deposit_date, merchant_id, payment_status, payment_method | deposit_amount, net_sales_amount, total_fees_amount, chargeback_amount |
| CHARGEBACKS | dispute_received_date, merchant_id, chargeback_status, outcome, lifecycle_stage, reason_code, card_brand | dispute_amount, transaction_amount, disputes_count |
| RETRIEVALS | original_sale_date, response_due_date, merchant_id, retrieval_status, reason_code, card_brand | retrieval_amount, retrievals_count |
| ADJUSTMENTS | adjustment_date, merchant_id, adjustment_type, adjustment_code, adjustment_category | adjustment_amount |
| DIM_MERCHANTS | merchant_id, merchant_name, corporate_name, city, state, zip_code, mcc_code, mcc_description, business_type, status, onboarding_date | (dimension table -- no facts) |

### Ticket Content Alignment with HANDS_ON_LAB.md

**TICKET-1 (Retry Success Rate Metric):** Must describe adding a retry success rate metric to the authorizations domain. Business-only AC should cover:
- Metric queryable via natural language (Cortex Agent)
- Retry defined as same card retried within short window after decline
- Metric appears in semantic view
- Agent instructions updated

**TICKET-2 (KPI Card):** Must describe adding a KPI card for retry success rate to the authorization dashboard. Business-only AC should cover:
- KPI card visible on authorization dashboard
- Displays percentage format
- Follows existing card layout/style
- Data sourced from authorization metrics

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Jira REST API v2 (wiki markup in description) | Jira REST API v3 (ADF JSON in description) | 2019-2020 | Description must be ADF JSON, not wiki markup string |
| Epic Link custom field (`customfield_10014`) | Parent field (`"parent": {"key": "EPA-42"}`) | 2023-2024 | Use `parent` field to link stories to epics |
| Epic Name custom field | Summary field for epics | 2023-2024 | Just use `summary` for the epic name |
| Confluence sync content body convert | Async content body convert | April 2025 (scheduled) | May need to use async endpoint; sync may still work |

## Open Questions

1. **Custom field IDs for Story Points and Sprint on the target instance**
   - What we know: Field IDs are instance-specific; common defaults are customfield_10016 (Story Points) and customfield_10020 (Sprint)
   - What's unclear: The actual field IDs on https://evolv-coco-sdlc-hol.atlassian.net
   - Recommendation: The creation script must call `/rest/api/3/field` first to discover IDs. Build this as step 1 of the API creation flow.

2. **Whether Confluence wiki-to-storage sync endpoint is still available**
   - What we know: Deprecation was scheduled for April 2025
   - What's unclear: Whether it's actually removed or still functional
   - Recommendation: Write the Confluence content in storage format (XHTML) directly rather than depending on the conversion endpoint. This avoids the deprecation risk entirely.

3. **Whether EPA Jira project and Confluence space exist**
   - What we know: CONTEXT.md says "assumed to already exist"
   - What's unclear: Whether they actually exist on the target instance
   - Recommendation: Script should verify existence first and provide clear error message if missing.

4. **Ticket auto-numbering**
   - What we know: Jira auto-assigns sequential numbers; cannot specify arbitrary numbers via API
   - What's unclear: Current highest issue number in EPA project (may already have issues)
   - Recommendation: Accept auto-assigned numbers. Script outputs the actual IDs for instructor to note. If higher numbers are truly needed, create and delete placeholder issues (adds complexity).

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual validation (content files + API responses) |
| Config file | none |
| Quick run command | `cat docs/jira/*.wiki` (visual inspection) |
| Full suite command | API creation script with response code checking |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CONTENT-01 | .wiki files contain valid Jira wiki markup | manual | Visual inspection of docs/jira/*.wiki | Wave 0 |
| CONTENT-02 | .wiki file contains valid Confluence content | manual | Visual inspection of docs/confluence/*.wiki | Wave 0 |
| API-01 | Epic created in Jira with correct metadata | smoke | curl GET /rest/api/3/issue/EPA-XX | Wave 0 |
| API-02 | Stories linked to epic via parent field | smoke | curl GET /rest/api/3/issue/EPA-XX?fields=parent | Wave 0 |
| API-03 | Confluence page created in EPA space | smoke | curl GET /wiki/rest/api/content?spaceKey=EPA&title=Payment+Analytics+Data+Dictionary | Wave 0 |
| API-04 | Data dictionary omits retry_success_rate | manual | Search page content for "retry" | Wave 0 |

### Sampling Rate
- **Per task commit:** Visual review of .wiki files
- **Per wave merge:** Run API creation script, verify responses
- **Phase gate:** All Jira issues and Confluence page exist with correct content

### Wave 0 Gaps
- [ ] `docs/jira/` directory -- does not exist yet
- [ ] `docs/confluence/` directory -- does not exist yet
- [ ] API creation script (bash or similar) -- does not exist yet

## Sources

### Primary (HIGH confidence)
- [Atlassian Document Format structure](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/) -- ADF JSON node types and structure
- [Jira Cloud REST API v3 Issues](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/) -- Create issue endpoint
- [Confluence Cloud REST API examples](https://developer.atlassian.com/cloud/confluence/rest-api-examples/) -- Page creation with storage format
- [Confluence Cloud REST API v2 Pages](https://developer.atlassian.com/cloud/confluence/rest/v2/api-group-page/) -- v2 page creation
- Semantic view YAML (`packages/dbt/analyses/payment_analytics_semantic_view.sql`) -- All 11 metrics, dimensions, facts, relationships

### Secondary (MEDIUM confidence)
- [Jira wiki markup reference](https://www.bcgsc.ca/jira/secure/WikiRendererHelpAction.jspa?section=all) (via WebFetch) -- Complete markup syntax
- [Atlassian Community: Epic parent field](https://community.atlassian.com/forums/Jira-questions/Create-an-Issue-with-Epic-as-parent-using-REST-API/qaq-p/1409874) -- Parent field replaces Epic Link
- [Confluence content body convert deprecation](https://community.developer.atlassian.com/t/new-async-convert-content-body-api-does-not-support-wiki-conversion-to-storage-but-old-api-does/87658) -- Sync endpoint deprecation notice

### Tertiary (LOW confidence)
- Custom field IDs (instance-specific -- must be discovered at runtime)

## Metadata

**Confidence breakdown:**
- Jira REST API structure: HIGH -- official Atlassian docs confirm ADF requirement, parent field, and endpoint
- Confluence REST API structure: HIGH -- official examples show v1 page creation with storage format
- Wiki markup syntax: HIGH -- verified via public Jira wiki renderer reference
- Semantic view content: HIGH -- read directly from source SQL file
- Custom field IDs: LOW -- must be discovered per-instance at runtime
- Ticket numbering: HIGH -- confirmed Jira auto-assigns; cannot specify via API

**Research date:** 2026-03-06
**Valid until:** 2026-04-06 (Atlassian APIs are stable; ADF format is settled)
