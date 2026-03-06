#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# create-atlassian-artifacts.sh
#
# Creates all Jira and Confluence artifacts for the evolv Payment Analytics
# hands-on lab via Atlassian Cloud REST APIs.
#
# Artifacts created:
#   - 1 Jira Epic (Payment Analytics Platform Enhancements)
#   - 2 Jira Stories linked to the epic (retry success rate + KPI card)
#   - 3 Jira Backlog items linked to the epic
#   - 1 Confluence page (Payment Analytics Data Dictionary)
#
# Usage:
#   export ATLASSIAN_API_TOKEN="your-token"
#   bash scripts/create-atlassian-artifacts.sh
#
# Requirements:
#   - EPA Jira project must exist
#   - EPA Confluence space must exist
#   - curl must be available
###############################################################################

# --- Configuration -----------------------------------------------------------
BASE_URL="https://evolv-coco-sdlc-hol.atlassian.net"
EMAIL="trent.foley@evolvconsulting.com"
PROJECT_KEY="EPA"

# --- Auth --------------------------------------------------------------------
if [ -z "${ATLASSIAN_API_TOKEN:-}" ]; then
  echo ""
  echo "ATLASSIAN_API_TOKEN is not set."
  read -rsp "Enter your Atlassian API token: " ATLASSIAN_API_TOKEN
  echo ""
fi

AUTH_HEADER=$(printf '%s:%s' "$EMAIL" "$ATLASSIAN_API_TOKEN" | base64 | tr -d '\n')

# --- Helper functions --------------------------------------------------------

api_call() {
  # Usage: api_call METHOD URL [DATA]
  local method="$1" url="$2" data="${3:-}"
  local response http_code body

  if [ -n "$data" ]; then
    response=$(curl -s -w "\n%{http_code}" -X "$method" \
      -H "Authorization: Basic $AUTH_HEADER" \
      -H "Content-Type: application/json" \
      "$url" \
      -d "$data")
  else
    response=$(curl -s -w "\n%{http_code}" -X "$method" \
      -H "Authorization: Basic $AUTH_HEADER" \
      -H "Content-Type: application/json" \
      "$url")
  fi

  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | sed '$d')

  echo "$http_code"
  echo "$body"
}

check_response() {
  # Usage: check_response HTTP_CODE BODY CONTEXT [CRITICAL]
  local http_code="$1" body="$2" context="$3" critical="${4:-true}"

  if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
    return 0
  fi

  echo "ERROR [$http_code] $context"
  echo "$body" | head -20
  echo ""

  if [ "$critical" = "true" ]; then
    echo "Critical failure -- exiting."
    exit 1
  fi
  return 1
}

extract_json_value() {
  # Simple JSON value extraction without jq dependency
  # Usage: extract_json_value JSON KEY
  local json="$1" key="$2"
  echo "$json" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
}

extract_json_number() {
  # Extract a numeric JSON value
  local json="$1" key="$2"
  echo "$json" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p" | head -1
}

# --- Step 1: Validate authentication ----------------------------------------
echo "=== Validating authentication ==="

RESP=$(api_call GET "$BASE_URL/rest/api/3/myself")
HTTP_CODE=$(echo "$RESP" | head -1)
BODY=$(echo "$RESP" | tail -n +2)

check_response "$HTTP_CODE" "$BODY" "Authentication check (GET /rest/api/3/myself)"

DISPLAY_NAME=$(extract_json_value "$BODY" "displayName")
echo "Authenticated as: $DISPLAY_NAME"
echo ""

# --- Step 2: Pre-flight checks -----------------------------------------------
echo "=== Pre-flight checks ==="

# Verify EPA Jira project exists
RESP=$(api_call GET "$BASE_URL/rest/api/3/project/$PROJECT_KEY")
HTTP_CODE=$(echo "$RESP" | head -1)
BODY=$(echo "$RESP" | tail -n +2)
check_response "$HTTP_CODE" "$BODY" "Jira project $PROJECT_KEY check"
echo "Jira project $PROJECT_KEY exists"

# Verify EPA Confluence space exists
RESP=$(api_call GET "$BASE_URL/wiki/rest/api/space/$PROJECT_KEY")
HTTP_CODE=$(echo "$RESP" | head -1)
BODY=$(echo "$RESP" | tail -n +2)
check_response "$HTTP_CODE" "$BODY" "Confluence space $PROJECT_KEY check"
echo "Confluence space $PROJECT_KEY exists"

# Discover custom field IDs for Story Points
echo ""
echo "Discovering custom field IDs..."
RESP=$(api_call GET "$BASE_URL/rest/api/3/field")
HTTP_CODE=$(echo "$RESP" | head -1)
BODY=$(echo "$RESP" | tail -n +2)
check_response "$HTTP_CODE" "$BODY" "Field discovery"

# Parse Story Points field ID (look for "Story point" case-insensitive)
STORY_POINTS_FIELD=""
SPRINT_FIELD=""

# Use a more robust parsing approach with grep + sed
# Story Points field
SP_MATCH=$(echo "$BODY" | tr ',' '\n' | grep -i '"name"' | grep -i 'story.point' | head -1 || true)
if [ -n "$SP_MATCH" ]; then
  # Find the id that precedes this name in the JSON
  STORY_POINTS_FIELD=$(echo "$BODY" | tr '{' '\n' | grep -i 'story.point' | head -1 | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

# Sprint field
SPRINT_MATCH=$(echo "$BODY" | tr '{' '\n' | grep -i '"name"[[:space:]]*:[[:space:]]*"Sprint"' | head -1 || true)
if [ -n "$SPRINT_MATCH" ]; then
  SPRINT_FIELD=$(echo "$SPRINT_MATCH" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

if [ -n "$STORY_POINTS_FIELD" ]; then
  echo "Story Points field: $STORY_POINTS_FIELD"
else
  echo "WARNING: Could not discover Story Points field ID. Story points will not be set."
fi

if [ -n "$SPRINT_FIELD" ]; then
  echo "Sprint field: $SPRINT_FIELD"
else
  echo "WARNING: Could not discover Sprint field ID. Sprint assignment will not be set."
fi

# Discover board ID
echo ""
echo "Discovering board..."
RESP=$(api_call GET "$BASE_URL/rest/agile/1.0/board?projectKeyOrId=$PROJECT_KEY")
HTTP_CODE=$(echo "$RESP" | head -1)
BODY=$(echo "$RESP" | tail -n +2)

BOARD_ID=""
SPRINT_ID=""

if check_response "$HTTP_CODE" "$BODY" "Board discovery" "false"; then
  BOARD_ID=$(echo "$BODY" | sed -n 's/.*"values"[[:space:]]*:[[:space:]]*\[{[^}]*"id"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' | head -1)
  if [ -z "$BOARD_ID" ]; then
    BOARD_ID=$(extract_json_number "$BODY" "id")
  fi
fi

if [ -n "$BOARD_ID" ]; then
  echo "Board ID: $BOARD_ID"

  # Discover or create sprint
  RESP=$(api_call GET "$BASE_URL/rest/agile/1.0/board/$BOARD_ID/sprint?state=active,future")
  HTTP_CODE=$(echo "$RESP" | head -1)
  BODY=$(echo "$RESP" | tail -n +2)

  if check_response "$HTTP_CODE" "$BODY" "Sprint discovery" "false"; then
    # Look for an active sprint first, then future
    SPRINT_ID=$(echo "$BODY" | tr '{' '\n' | grep '"state"' | grep -i 'active' | head -1 | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p')
    if [ -z "$SPRINT_ID" ]; then
      SPRINT_ID=$(echo "$BODY" | tr '{' '\n' | grep '"state"' | grep -i 'future' | head -1 | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p')
    fi
  fi

  if [ -z "$SPRINT_ID" ]; then
    echo "No active/future sprint found. Creating Sprint 3..."
    RESP=$(api_call POST "$BASE_URL/rest/agile/1.0/sprint" \
      "{\"name\": \"Sprint 3\", \"originBoardId\": $BOARD_ID}")
    HTTP_CODE=$(echo "$RESP" | head -1)
    BODY=$(echo "$RESP" | tail -n +2)
    if check_response "$HTTP_CODE" "$BODY" "Sprint creation" "false"; then
      SPRINT_ID=$(extract_json_number "$BODY" "id")
      echo "Created Sprint 3 (ID: $SPRINT_ID)"
    else
      echo "WARNING: Could not create sprint. Sprint assignment will be skipped."
    fi
  else
    SPRINT_NAME=$(echo "$BODY" | tr '{' '\n' | grep "\"id\"[[:space:]]*:[[:space:]]*$SPRINT_ID" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    echo "Using sprint: ${SPRINT_NAME:-ID $SPRINT_ID} (ID: $SPRINT_ID)"
  fi
else
  echo "WARNING: Could not discover board ID. Sprint assignment will be skipped."
fi

# Create components (ignore errors if they already exist)
echo ""
echo "Ensuring components exist..."
for COMP_NAME in "Backend" "Frontend" "Data Platform"; do
  RESP=$(api_call POST "$BASE_URL/rest/api/3/component" \
    "{\"name\": \"$COMP_NAME\", \"project\": \"$PROJECT_KEY\"}")
  HTTP_CODE=$(echo "$RESP" | head -1)
  BODY=$(echo "$RESP" | tail -n +2)
  if check_response "$HTTP_CODE" "$BODY" "Create component '$COMP_NAME'" "false"; then
    echo "  Created component: $COMP_NAME"
  else
    echo "  Component '$COMP_NAME' may already exist (continuing)"
  fi
done

echo ""
echo "Pre-flight checks complete."
echo ""

# --- Step 3: Create Epic -----------------------------------------------------
echo "=== Creating Jira Epic ==="

EPIC_PAYLOAD=$(cat <<'EPICJSON'
{
  "fields": {
    "project": { "key": "EPA" },
    "issuetype": { "name": "Epic" },
    "summary": "Payment Analytics Platform Enhancements",
    "description": {
      "version": 1,
      "type": "doc",
      "content": [
        {
          "type": "heading",
          "attrs": { "level": 2 },
          "content": [{ "type": "text", "text": "Description" }]
        },
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "The Payment Analytics Platform Enhancements epic covers a set of improvements to the evolv Payment Analytics platform. This work focuses on expanding the metric library available through the Cortex Agent, improving dashboard visibility of key performance indicators, and strengthening data quality across payment domains." }
          ]
        },
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "The platform currently provides analytics across authorizations, settlements, deposits, chargebacks, retrievals, and adjustments. This epic introduces new metrics that help merchants better understand transaction recovery patterns and adds dashboard components to surface those insights at a glance." }
          ]
        },
        {
          "type": "panel",
          "attrs": { "panelType": "info" },
          "content": [
            {
              "type": "heading",
              "attrs": { "level": 3 },
              "content": [{ "type": "text", "text": "Platform Context" }]
            },
            {
              "type": "paragraph",
              "content": [
                { "type": "text", "text": "The evolv Payment Analytics platform serves merchant clients who need to monitor and analyze their payment processing performance. Data flows through a medallion architecture (RAW, STAGING, INTERMEDIATE, MARTS) and is queryable via the Cortex Agent using natural language. Dashboard components visualize key metrics from the MARTS layer." }
              ]
            }
          ]
        },
        {
          "type": "heading",
          "attrs": { "level": 2 },
          "content": [{ "type": "text", "text": "Scope" }]
        },
        {
          "type": "bulletList",
          "content": [
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "New business metrics for the authorizations domain" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "KPI card additions to the authorization dashboard" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Data dictionary updates to reflect new metric definitions" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Backlog items for future settlement, chargeback, and funding enhancements" }] }] }
          ]
        },
        {
          "type": "heading",
          "attrs": { "level": 2 },
          "content": [{ "type": "text", "text": "Goals" }]
        },
        {
          "type": "orderedList",
          "content": [
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Expand the analytical coverage of authorization transaction data" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Improve dashboard usability by surfacing critical metrics as KPI cards" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Maintain alignment between the data dictionary, semantic view, and dashboard" }] }] }
          ]
        }
      ]
    },
    "labels": ["platform", "analytics", "enhancements"],
    "priority": { "name": "Medium" }
  }
}
EPICJSON
)

RESP=$(api_call POST "$BASE_URL/rest/api/3/issue" "$EPIC_PAYLOAD")
HTTP_CODE=$(echo "$RESP" | head -1)
BODY=$(echo "$RESP" | tail -n +2)
check_response "$HTTP_CODE" "$BODY" "Create Epic"

EPIC_KEY=$(extract_json_value "$BODY" "key")
echo "Created epic: $EPIC_KEY"
echo ""

# --- Step 4: Create two main stories ----------------------------------------
echo "=== Creating Main Stories ==="

# --- Story 1: Retry Success Rate Metric (TICKET-1) ---
build_story1_payload() {
  cat <<STORY1JSON
{
  "fields": {
    "project": { "key": "EPA" },
    "issuetype": { "name": "Story" },
    "summary": "Add retry success rate metric to authorizations domain",
    "parent": { "key": "$EPIC_KEY" },
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
          "content": [
            { "type": "text", "text": "As a " },
            { "type": "text", "text": "payment analyst", "marks": [{ "type": "strong" }] },
            { "type": "text", "text": ", I want to see a retry success rate metric so that I can understand how many declined transactions are recovered through customer retries." }
          ]
        },
        {
          "type": "heading",
          "attrs": { "level": 2 },
          "content": [{ "type": "text", "text": "Business Context" }]
        },
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "When a cardholder's transaction is declined, merchants lose revenue unless the customer retries the purchase successfully. Understanding the retry success rate is critical for evaluating decline management strategies and identifying opportunities to recover lost sales. A high retry success rate indicates that many declines are soft declines (temporary issues like insufficient funds or processor timeouts) that resolve on a second attempt, while a low rate may signal systemic issues such as fraud blocks or expired cards." }
          ]
        },
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "Retry tracking also provides insight into customer experience. Customers who encounter a decline and successfully retry represent a recovered conversion that would otherwise be lost. Merchants use this data to assess whether their payment routing, retry prompting, and decline messaging are effective at keeping customers engaged through the checkout process." }
          ]
        },
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "By surfacing the retry success rate as a queryable metric, payment analysts can monitor recovery trends over time, compare performance across card brands and entry modes, and correlate retry patterns with decline reason codes to prioritize improvement efforts." }
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
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "A retry success rate metric is available for natural language queries about authorization performance" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "The metric captures the percentage of declined transactions that were subsequently retried and approved" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "A \"retry\" is defined as when the same card is used for the same amount at the same merchant within a short window after a decline" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "The Cortex Agent can answer questions like \"What is our retry success rate?\" and \"How many declined transactions were recovered?\"" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "The data dictionary is updated to include the new metric definition" }] }] }
          ]
        },
        {
          "type": "panel",
          "attrs": { "panelType": "info" },
          "content": [
            {
              "type": "heading",
              "attrs": { "level": 3 },
              "content": [{ "type": "text", "text": "Business Definition" }]
            },
            {
              "type": "paragraph",
              "content": [
                { "type": "text", "text": "In payment processing, a " },
                { "type": "text", "text": "retry", "marks": [{ "type": "em" }] },
                { "type": "text", "text": " occurs when a cardholder attempts the same transaction again after an initial decline. Specifically, this means the same card (identified by card BIN and last four digits) is used for the same transaction amount at the same merchant within a short time window following a declined authorization. The " },
                { "type": "text", "text": "retry success rate", "marks": [{ "type": "em" }] },
                { "type": "text", "text": " is the percentage of these retry attempts that result in an approved authorization." }
              ]
            }
          ]
        }
      ]
    },
    "priority": { "name": "High" },
    "labels": ["dbt", "semantic-view", "metric", "cortex-agent"],
    "components": [{ "name": "Data Platform" }]
STORY1JSON

  # Add story points if field discovered
  if [ -n "$STORY_POINTS_FIELD" ]; then
    echo "    ,\"$STORY_POINTS_FIELD\": 5"
  fi

  # Add sprint if discovered
  if [ -n "$SPRINT_FIELD" ] && [ -n "$SPRINT_ID" ]; then
    echo "    ,\"$SPRINT_FIELD\": $SPRINT_ID"
  fi

  echo "  }"
  echo "}"
}

STORY1_PAYLOAD=$(build_story1_payload)

RESP=$(api_call POST "$BASE_URL/rest/api/3/issue" "$STORY1_PAYLOAD")
HTTP_CODE=$(echo "$RESP" | head -1)
BODY=$(echo "$RESP" | tail -n +2)
check_response "$HTTP_CODE" "$BODY" "Create Story 1 (retry success rate)"

TICKET1_KEY=$(extract_json_value "$BODY" "key")
echo "Created story: $TICKET1_KEY (retry success rate)"

# --- Story 2: KPI Card (TICKET-2) ---
build_story2_payload() {
  cat <<STORY2JSON
{
  "fields": {
    "project": { "key": "EPA" },
    "issuetype": { "name": "Story" },
    "summary": "Add retry success rate KPI card to authorization dashboard",
    "parent": { "key": "$EPIC_KEY" },
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
          "content": [
            { "type": "text", "text": "As a " },
            { "type": "text", "text": "payment analyst", "marks": [{ "type": "strong" }] },
            { "type": "text", "text": ", I want to see the retry success rate prominently displayed on the authorization dashboard so that I can monitor retry performance at a glance." }
          ]
        },
        {
          "type": "heading",
          "attrs": { "level": 2 },
          "content": [{ "type": "text", "text": "Business Context" }]
        },
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "KPI cards provide immediate visibility into critical metrics without requiring analysts to run queries or navigate to detailed reports. Adding a retry success rate KPI card to the authorization dashboard ensures that recovery performance is always visible alongside existing authorization metrics such as approval rate and total volume." }
          ]
        },
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "Operational teams use KPI cards for daily monitoring. A sudden drop in retry success rate could indicate a processing issue, a change in decline patterns, or a shift in customer behavior that warrants investigation. Having this metric front and center on the dashboard reduces the time between a problem occurring and the team becoming aware of it." }
          ]
        },
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "The retry success rate card complements the existing approval rate card by showing not just how many transactions are approved on the first attempt, but how many are recovered after an initial failure. Together, these metrics provide a more complete picture of authorization performance." }
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
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "A KPI card for retry success rate is visible on the authorization dashboard" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "The card displays the metric as a percentage" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "The card follows the same visual style and layout as existing KPI cards on the dashboard" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "The data powering the card comes from the authorization metrics" }] }] }
          ]
        },
        {
          "type": "panel",
          "attrs": { "panelType": "info" },
          "content": [
            {
              "type": "heading",
              "attrs": { "level": 3 },
              "content": [{ "type": "text", "text": "Design Note" }]
            },
            {
              "type": "paragraph",
              "content": [
                { "type": "text", "text": "The retry success rate KPI card should match the existing card pattern on the authorization dashboard. It should use the same component, the same grid layout, and the same data fetching approach as the other KPI cards already on the page." }
              ]
            }
          ]
        }
      ]
    },
    "priority": { "name": "Medium" },
    "labels": ["frontend", "dashboard", "kpi"],
    "components": [{ "name": "Frontend" }]
STORY2JSON

  if [ -n "$STORY_POINTS_FIELD" ]; then
    echo "    ,\"$STORY_POINTS_FIELD\": 3"
  fi

  if [ -n "$SPRINT_FIELD" ] && [ -n "$SPRINT_ID" ]; then
    echo "    ,\"$SPRINT_FIELD\": $SPRINT_ID"
  fi

  echo "  }"
  echo "}"
}

STORY2_PAYLOAD=$(build_story2_payload)

RESP=$(api_call POST "$BASE_URL/rest/api/3/issue" "$STORY2_PAYLOAD")
HTTP_CODE=$(echo "$RESP" | head -1)
BODY=$(echo "$RESP" | tail -n +2)
check_response "$HTTP_CODE" "$BODY" "Create Story 2 (KPI card)"

TICKET2_KEY=$(extract_json_value "$BODY" "key")
echo "Created story: $TICKET2_KEY (KPI card)"
echo ""

# --- Step 5: Create three backlog stories ------------------------------------
echo "=== Creating Backlog Items ==="

# Backlog 1: Settlement dispute tracking breakdown
BACKLOG1_PAYLOAD=$(cat <<BACKLOG1JSON
{
  "fields": {
    "project": { "key": "EPA" },
    "issuetype": { "name": "Story" },
    "summary": "Add settlement dispute breakdown by reason code and outcome",
    "parent": { "key": "$EPIC_KEY" },
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
          "content": [
            { "type": "text", "text": "As a " },
            { "type": "text", "text": "payment analyst", "marks": [{ "type": "strong" }] },
            { "type": "text", "text": ", I want to see settlement disputes broken down by reason code and outcome so that I can identify the most common dispute causes and track resolution effectiveness." }
          ]
        },
        {
          "type": "heading",
          "attrs": { "level": 2 },
          "content": [{ "type": "text", "text": "Business Context" }]
        },
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "Settlement disputes arise when there is a discrepancy between what the merchant expected to receive and what was actually settled. Currently, dispute data is available at an aggregate level, but analysts lack visibility into the distribution of disputes by reason code (e.g., processing error, duplicate transaction, late presentment) and their outcomes (won, lost, pending). This breakdown is essential for identifying systemic issues in the settlement process and prioritizing operational improvements." }
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
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "A breakdown of settlement disputes is available by reason code" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Each reason code shows the count, total amount, and win/loss outcome distribution" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "The data is queryable through the Cortex Agent using natural language" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "The breakdown covers at least the last 12 months of dispute data" }] }] }
          ]
        }
      ]
    },
    "priority": { "name": "Low" },
    "labels": ["settlements", "reporting"]
  }
}
BACKLOG1JSON
)

RESP=$(api_call POST "$BASE_URL/rest/api/3/issue" "$BACKLOG1_PAYLOAD")
HTTP_CODE=$(echo "$RESP" | head -1)
BODY=$(echo "$RESP" | tail -n +2)
check_response "$HTTP_CODE" "$BODY" "Create Backlog 1 (settlement disputes)"

BACKLOG1_KEY=$(extract_json_value "$BODY" "key")
echo "Created backlog: $BACKLOG1_KEY (settlement dispute breakdown)"

# Backlog 2: Chargeback alert threshold notifications
BACKLOG2_PAYLOAD=$(cat <<BACKLOG2JSON
{
  "fields": {
    "project": { "key": "EPA" },
    "issuetype": { "name": "Story" },
    "summary": "Add chargeback alert threshold notifications by card brand",
    "parent": { "key": "$EPIC_KEY" },
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
          "content": [
            { "type": "text", "text": "As a " },
            { "type": "text", "text": "risk operations manager", "marks": [{ "type": "strong" }] },
            { "type": "text", "text": ", I want to receive alerts when chargeback rates exceed configurable thresholds so that I can take proactive action before card brand monitoring programs are triggered." }
          ]
        },
        {
          "type": "heading",
          "attrs": { "level": 2 },
          "content": [{ "type": "text", "text": "Business Context" }]
        },
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "Card brands (Visa, Mastercard) operate chargeback monitoring programs that impose penalties on merchants exceeding defined thresholds. Visa's Dispute Monitoring Program triggers at a 0.9% chargeback rate, while Mastercard's Excessive Chargeback Program triggers at 1.5%. Being placed in these programs results in fines, increased processing fees, and potential account termination. Early warning alerts based on configurable thresholds allow risk teams to intervene before breaching card brand limits." }
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
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Alert thresholds are configurable per card brand (e.g., 0.75% for Visa, 1.2% for Mastercard)" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Alerts trigger when the rolling 30-day chargeback rate approaches or exceeds a threshold" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Alert notifications include the current chargeback rate, the threshold, and the card brand" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Historical threshold breach events are logged for audit purposes" }] }] }
          ]
        }
      ]
    },
    "priority": { "name": "Low" },
    "labels": ["chargebacks", "alerting"]
  }
}
BACKLOG2JSON
)

RESP=$(api_call POST "$BASE_URL/rest/api/3/issue" "$BACKLOG2_PAYLOAD")
HTTP_CODE=$(echo "$RESP" | head -1)
BODY=$(echo "$RESP" | tail -n +2)
check_response "$HTTP_CODE" "$BODY" "Create Backlog 2 (chargeback alerts)"

BACKLOG2_KEY=$(extract_json_value "$BODY" "key")
echo "Created backlog: $BACKLOG2_KEY (chargeback alert thresholds)"

# Backlog 3: Funding reconciliation summary report
BACKLOG3_PAYLOAD=$(cat <<BACKLOG3JSON
{
  "fields": {
    "project": { "key": "EPA" },
    "issuetype": { "name": "Story" },
    "summary": "Add funding reconciliation summary report",
    "parent": { "key": "$EPIC_KEY" },
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
          "content": [
            { "type": "text", "text": "As a " },
            { "type": "text", "text": "finance operations analyst", "marks": [{ "type": "strong" }] },
            { "type": "text", "text": ", I want a funding reconciliation summary report that compares expected settlement amounts with actual deposit amounts so that I can quickly identify and investigate funding discrepancies." }
          ]
        },
        {
          "type": "heading",
          "attrs": { "level": 2 },
          "content": [{ "type": "text", "text": "Business Context" }]
        },
        {
          "type": "paragraph",
          "content": [
            { "type": "text", "text": "Merchants receive funding (deposits) based on their settled transactions, minus fees, chargebacks, and adjustments. Discrepancies between the expected funding amount (calculated from settlements) and the actual deposit amount can arise from timing differences, fee calculation errors, or missed adjustments. A reconciliation summary report that highlights these discrepancies by date and merchant enables the finance team to resolve issues quickly and maintain accurate cash flow forecasting." }
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
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "A summary report shows expected vs actual funding amounts by date" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Discrepancies exceeding a configurable threshold are flagged for review" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "The report is queryable through the Cortex Agent using natural language" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "The reconciliation covers settlements, fees, chargebacks, and adjustments that affect the final deposit amount" }] }] }
          ]
        }
      ]
    },
    "priority": { "name": "Low" },
    "labels": ["funding", "reporting", "reconciliation"]
  }
}
BACKLOG3JSON
)

RESP=$(api_call POST "$BASE_URL/rest/api/3/issue" "$BACKLOG3_PAYLOAD")
HTTP_CODE=$(echo "$RESP" | head -1)
BODY=$(echo "$RESP" | tail -n +2)
check_response "$HTTP_CODE" "$BODY" "Create Backlog 3 (funding reconciliation)"

BACKLOG3_KEY=$(extract_json_value "$BODY" "key")
echo "Created backlog: $BACKLOG3_KEY (funding reconciliation)"
echo ""

# --- Step 6: Create Confluence data dictionary page --------------------------
echo "=== Creating Confluence Data Dictionary Page ==="

# Read the wiki content from the reference file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIKI_FILE="$SCRIPT_DIR/../docs/confluence/data-dictionary.wiki"

if [ ! -f "$WIKI_FILE" ]; then
  echo "ERROR: Wiki file not found at $WIKI_FILE"
  echo "Looking relative to working directory..."
  WIKI_FILE="docs/confluence/data-dictionary.wiki"
  if [ ! -f "$WIKI_FILE" ]; then
    echo "ERROR: Wiki file not found. Cannot create Confluence page."
    exit 1
  fi
fi

WIKI_CONTENT=$(cat "$WIKI_FILE")

# Try the wiki-to-storage conversion endpoint first
echo "Attempting wiki-to-storage conversion..."

# Escape the wiki content for JSON
ESCAPED_WIKI=$(echo "$WIKI_CONTENT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null || \
  echo "$WIKI_CONTENT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' '\\' | sed 's/\\/\\n/g' | sed 's/\\n$//')

# Build conversion payload
CONVERT_PAYLOAD="{\"value\": $ESCAPED_WIKI, \"representation\": \"wiki\"}"

RESP=$(api_call POST "$BASE_URL/wiki/rest/api/contentbody/convert/storage" "$CONVERT_PAYLOAD")
HTTP_CODE=$(echo "$RESP" | head -1)
BODY=$(echo "$RESP" | tail -n +2)

STORAGE_CONTENT=""
if check_response "$HTTP_CODE" "$BODY" "Wiki-to-storage conversion" "false"; then
  echo "Wiki-to-storage conversion succeeded"
  # Extract the converted value
  STORAGE_CONTENT=$(echo "$BODY" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('value',''))" 2>/dev/null || true)
fi

# Fallback: construct storage format XHTML directly
if [ -z "$STORAGE_CONTENT" ]; then
  echo "Falling back to direct XHTML storage format..."
  STORAGE_CONTENT='<h1>Payment Analytics Data Dictionary</h1>
<p>This data dictionary documents the metrics, dimensions, and facts available in the Payment Analytics semantic view. Use this reference when querying data through the Cortex Agent or building dashboard components.</p>
<ac:structured-macro ac:name="info"><ac:rich-text-body><p>The semantic view is defined at COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS and covers 7 domain tables with merchant relationships enabling cross-domain analysis.</p></ac:rich-text-body></ac:structured-macro>
<h2>Metrics</h2>
<p>The following metrics are pre-defined calculations available for natural language queries through the Cortex Agent.</p>
<table><tbody>
<tr><th>Metric</th><th>Description</th><th>Formula</th><th>Data Type</th><th>Source Domain</th></tr>
<tr><td>APPROVAL_RATE</td><td>Percentage of authorizations approved</td><td>Approved count / Total count * 100</td><td>NUMBER (%)</td><td>Authorizations</td></tr>
<tr><td>TOTAL_AUTHORIZATION_VOLUME</td><td>Total authorization amount in USD</td><td>SUM(transaction_amount)</td><td>NUMBER ($)</td><td>Authorizations</td></tr>
<tr><td>AVERAGE_TRANSACTION_AMOUNT</td><td>Average transaction amount in USD</td><td>AVG(transaction_amount)</td><td>NUMBER ($)</td><td>Authorizations</td></tr>
<tr><td>NET_SETTLEMENT_VOLUME</td><td>Total net settlement amount</td><td>SUM(net_amount)</td><td>NUMBER ($)</td><td>Settlements</td></tr>
<tr><td>TOTAL_DEPOSITS</td><td>Total deposit amount</td><td>SUM(deposit_amount)</td><td>NUMBER ($)</td><td>Deposits</td></tr>
<tr><td>EFFECTIVE_FEE_RATE</td><td>Processing fees as percentage of sales</td><td>Total fees / Sales amount * 100</td><td>NUMBER (%)</td><td>Deposits</td></tr>
<tr><td>CHARGEBACK_VOLUME</td><td>Total chargeback dispute amount</td><td>SUM(dispute_amount)</td><td>NUMBER ($)</td><td>Chargebacks</td></tr>
<tr><td>CHARGEBACK_WIN_RATE</td><td>Percentage of chargebacks won by merchant</td><td>Won disputes / Total disputes * 100</td><td>NUMBER (%)</td><td>Chargebacks</td></tr>
<tr><td>CHARGEBACK_RATE</td><td>Chargeback count as percentage of total transactions</td><td>Chargeback count / Authorization count * 100</td><td>NUMBER (%)</td><td>Chargebacks + Authorizations</td></tr>
<tr><td>NET_ADJUSTMENTS</td><td>Net adjustment amount</td><td>SUM(adjustment_amount)</td><td>NUMBER ($)</td><td>Adjustments</td></tr>
<tr><td>RETRIEVAL_FULFILLMENT_RATE</td><td>Percentage of retrieval requests fulfilled</td><td>Closed retrievals / Total retrievals * 100</td><td>NUMBER (%)</td><td>Retrievals</td></tr>
</tbody></table>
<h2>Dimensions by Domain</h2>
<p>Dimensions are the categorical attributes available for filtering, grouping, and drill-down in queries.</p>
<h3>Authorizations</h3>
<table><tbody>
<tr><th>Dimension</th><th>Description</th><th>Example Values</th></tr>
<tr><td>TRANSACTION_DATE</td><td>Date of the authorization transaction</td><td>2025-01-15, 2025-02-28</td></tr>
<tr><td>MERCHANT_ID</td><td>Unique merchant identifier</td><td>M001, M042</td></tr>
<tr><td>CARD_BRAND</td><td>Card network brand</td><td>Visa, Mastercard, Amex, Discover</td></tr>
<tr><td>CARD_TYPE</td><td>Type of card product</td><td>Credit, Debit, Prepaid</td></tr>
<tr><td>CARD_CATEGORY</td><td>Card category</td><td>Consumer, Commercial</td></tr>
<tr><td>ENTRY_MODE</td><td>Point of sale entry mode</td><td>Swipe, Dip, Tap, Keyed, E-commerce</td></tr>
<tr><td>APPROVAL_STATUS</td><td>Authorization approval status</td><td>Approved, Declined</td></tr>
<tr><td>DECLINE_REASON</td><td>Reason for declined authorization</td><td>Insufficient Funds, Do Not Honor, Expired Card</td></tr>
<tr><td>PROCESSOR_NAME</td><td>Payment processor name</td><td>First Data, TSYS, Worldpay</td></tr>
</tbody></table>
<h3>Settlements</h3>
<table><tbody>
<tr><th>Dimension</th><th>Description</th><th>Example Values</th></tr>
<tr><td>SETTLEMENT_DATE</td><td>Date of settlement</td><td>2025-01-15, 2025-02-28</td></tr>
<tr><td>MERCHANT_ID</td><td>Merchant identifier</td><td>M001, M042</td></tr>
<tr><td>CARD_BRAND</td><td>Card brand</td><td>Visa, Mastercard</td></tr>
<tr><td>CARD_TYPE</td><td>Card type</td><td>Credit, Debit</td></tr>
</tbody></table>
<h3>Deposits</h3>
<table><tbody>
<tr><th>Dimension</th><th>Description</th><th>Example Values</th></tr>
<tr><td>DEPOSIT_DATE</td><td>Date of deposit</td><td>2025-01-15, 2025-02-28</td></tr>
<tr><td>MERCHANT_ID</td><td>Merchant identifier</td><td>M001, M042</td></tr>
<tr><td>PAYMENT_STATUS</td><td>Status of payment</td><td>Completed, Pending, Failed</td></tr>
<tr><td>PAYMENT_METHOD</td><td>Method of payment</td><td>ACH, Wire, Check</td></tr>
</tbody></table>
<h3>Chargebacks</h3>
<table><tbody>
<tr><th>Dimension</th><th>Description</th><th>Example Values</th></tr>
<tr><td>DISPUTE_RECEIVED_DATE</td><td>Date dispute was received</td><td>2025-01-15, 2025-02-28</td></tr>
<tr><td>RESPONSE_DUE_DATE</td><td>Due date for response</td><td>2025-02-15</td></tr>
<tr><td>ORIGINAL_TRANSACTION_DATE</td><td>Date of original transaction</td><td>2025-01-10</td></tr>
<tr><td>MERCHANT_ID</td><td>Merchant identifier</td><td>M001, M042</td></tr>
<tr><td>CHARGEBACK_STATUS</td><td>Current status of chargeback</td><td>Open, Closed, Pending</td></tr>
<tr><td>OUTCOME</td><td>Chargeback outcome</td><td>Won, Lost, Pending</td></tr>
<tr><td>LIFECYCLE_STAGE</td><td>Current stage in dispute lifecycle</td><td>First Chargeback, Pre-Arbitration, Arbitration</td></tr>
<tr><td>REASON_CODE</td><td>Chargeback reason code</td><td>4837, 10.4, 13.1</td></tr>
<tr><td>REASON_DESCRIPTION</td><td>Description of chargeback reason</td><td>Fraud, Not As Described, Duplicate Processing</td></tr>
<tr><td>CARD_BRAND</td><td>Card brand</td><td>Visa, Mastercard</td></tr>
</tbody></table>
<h3>Retrievals</h3>
<table><tbody>
<tr><th>Dimension</th><th>Description</th><th>Example Values</th></tr>
<tr><td>ORIGINAL_SALE_DATE</td><td>Date of original sale</td><td>2025-01-10</td></tr>
<tr><td>RESPONSE_DUE_DATE</td><td>Due date for response</td><td>2025-02-15</td></tr>
<tr><td>MERCHANT_ID</td><td>Merchant identifier</td><td>M001, M042</td></tr>
<tr><td>RETRIEVAL_STATUS</td><td>Current retrieval status</td><td>Open, Closed, Expired</td></tr>
<tr><td>REASON_CODE</td><td>Retrieval reason code</td><td>28, 30, 34</td></tr>
<tr><td>CARD_BRAND</td><td>Card brand</td><td>Visa, Mastercard</td></tr>
</tbody></table>
<h3>Adjustments</h3>
<table><tbody>
<tr><th>Dimension</th><th>Description</th><th>Example Values</th></tr>
<tr><td>ADJUSTMENT_DATE</td><td>Date of adjustment</td><td>2025-01-15, 2025-02-28</td></tr>
<tr><td>MERCHANT_ID</td><td>Merchant identifier</td><td>M001, M042</td></tr>
<tr><td>ADJUSTMENT_TYPE</td><td>Type of adjustment</td><td>Credit, Debit</td></tr>
<tr><td>ADJUSTMENT_CODE</td><td>Adjustment reason code</td><td>FEE_ADJ, RATE_CORRECTION</td></tr>
<tr><td>ADJUSTMENT_CATEGORY</td><td>Category of adjustment</td><td>Fee Adjustment, Rate Correction, Settlement Adjustment</td></tr>
</tbody></table>
<h3>Merchants (DIM_MERCHANTS)</h3>
<table><tbody>
<tr><th>Dimension</th><th>Description</th><th>Example Values</th></tr>
<tr><td>MERCHANT_ID</td><td>Unique merchant identifier</td><td>M001, M042</td></tr>
<tr><td>MERCHANT_NAME</td><td>Merchant DBA name</td><td>Quick Stop Shop, Metro Electronics</td></tr>
<tr><td>CORPORATE_NAME</td><td>Corporate parent name</td><td>Quick Stop Inc., Metro Group</td></tr>
<tr><td>CITY</td><td>Merchant city</td><td>Denver, Austin, Chicago</td></tr>
<tr><td>STATE</td><td>Merchant state</td><td>CO, TX, IL</td></tr>
<tr><td>ZIP_CODE</td><td>Merchant ZIP code</td><td>80202, 73301</td></tr>
<tr><td>MCC_CODE</td><td>Merchant Category Code</td><td>5411, 5812, 5999</td></tr>
<tr><td>MCC_DESCRIPTION</td><td>Merchant category description</td><td>Grocery Stores, Eating Places, Retail</td></tr>
<tr><td>BUSINESS_TYPE</td><td>Type of business</td><td>Retail, Restaurant, E-commerce</td></tr>
<tr><td>STATUS</td><td>Merchant status</td><td>Active, Inactive</td></tr>
<tr><td>ONBOARDING_DATE</td><td>Date merchant was onboarded</td><td>2023-06-15</td></tr>
</tbody></table>
<h2>Fact Columns by Domain</h2>
<p>Fact columns are the numeric values available for aggregation in queries.</p>
<h3>Authorizations</h3>
<table><tbody>
<tr><th>Fact Column</th><th>Description</th><th>Data Type</th></tr>
<tr><td>TRANSACTION_AMOUNT</td><td>Transaction amount in USD</td><td>NUMBER</td></tr>
<tr><td>TRANSACTIONS_COUNT</td><td>Count of transactions (1 per row)</td><td>NUMBER</td></tr>
</tbody></table>
<h3>Settlements</h3>
<table><tbody>
<tr><th>Fact Column</th><th>Description</th><th>Data Type</th></tr>
<tr><td>SALES_COUNT</td><td>Number of sales transactions</td><td>NUMBER</td></tr>
<tr><td>SALES_AMOUNT</td><td>Total sales amount</td><td>NUMBER</td></tr>
<tr><td>REFUND_COUNT</td><td>Number of refunds</td><td>NUMBER</td></tr>
<tr><td>REFUND_AMOUNT</td><td>Total refund amount</td><td>NUMBER</td></tr>
<tr><td>NET_AMOUNT</td><td>Net processed amount</td><td>NUMBER</td></tr>
<tr><td>INTERCHANGE_AMOUNT</td><td>Interchange fees</td><td>NUMBER</td></tr>
</tbody></table>
<h3>Deposits</h3>
<table><tbody>
<tr><th>Fact Column</th><th>Description</th><th>Data Type</th></tr>
<tr><td>DEPOSIT_AMOUNT</td><td>Deposit amount</td><td>NUMBER</td></tr>
<tr><td>NET_SALES_AMOUNT</td><td>Net sales amount</td><td>NUMBER</td></tr>
<tr><td>TOTAL_FEES_AMOUNT</td><td>Total fees</td><td>NUMBER</td></tr>
<tr><td>CHARGEBACK_AMOUNT</td><td>Chargeback deductions</td><td>NUMBER</td></tr>
</tbody></table>
<h3>Chargebacks</h3>
<table><tbody>
<tr><th>Fact Column</th><th>Description</th><th>Data Type</th></tr>
<tr><td>DISPUTE_AMOUNT</td><td>Dispute amount</td><td>NUMBER</td></tr>
<tr><td>TRANSACTION_AMOUNT</td><td>Original transaction amount</td><td>NUMBER</td></tr>
<tr><td>DISPUTES_COUNT</td><td>Count of disputes (1 per row)</td><td>NUMBER</td></tr>
</tbody></table>
<h3>Retrievals</h3>
<table><tbody>
<tr><th>Fact Column</th><th>Description</th><th>Data Type</th></tr>
<tr><td>RETRIEVAL_AMOUNT</td><td>Retrieval dollar amount</td><td>NUMBER</td></tr>
<tr><td>RETRIEVALS_COUNT</td><td>Count of retrievals (1 per row)</td><td>NUMBER</td></tr>
</tbody></table>
<h3>Adjustments</h3>
<table><tbody>
<tr><th>Fact Column</th><th>Description</th><th>Data Type</th></tr>
<tr><td>ADJUSTMENT_AMOUNT</td><td>Adjustment amount</td><td>NUMBER</td></tr>
</tbody></table>
<h3>Merchants (DIM_MERCHANTS)</h3>
<p>Dimension table -- no fact columns. Used for relationship joins from all transaction domains via MERCHANT_ID.</p>
<h2>Relationships</h2>
<p>All transaction tables join to the MERCHANTS dimension table through MERCHANT_ID using left outer joins (many-to-one).</p>
<table><tbody>
<tr><th>Relationship</th><th>Left Table</th><th>Right Table</th><th>Join Column</th></tr>
<tr><td>AUTH_TO_MERCHANT</td><td>AUTHORIZATIONS</td><td>MERCHANTS</td><td>MERCHANT_ID</td></tr>
<tr><td>SETTLEMENT_TO_MERCHANT</td><td>SETTLEMENTS</td><td>MERCHANTS</td><td>MERCHANT_ID</td></tr>
<tr><td>DEPOSIT_TO_MERCHANT</td><td>DEPOSITS</td><td>MERCHANTS</td><td>MERCHANT_ID</td></tr>
<tr><td>CHARGEBACK_TO_MERCHANT</td><td>CHARGEBACKS</td><td>MERCHANTS</td><td>MERCHANT_ID</td></tr>
<tr><td>RETRIEVAL_TO_MERCHANT</td><td>RETRIEVALS</td><td>MERCHANTS</td><td>MERCHANT_ID</td></tr>
<tr><td>ADJUSTMENT_TO_MERCHANT</td><td>ADJUSTMENTS</td><td>MERCHANTS</td><td>MERCHANT_ID</td></tr>
</tbody></table>
<h2>Notes</h2>
<ac:structured-macro ac:name="info"><ac:rich-text-body><p>This dictionary reflects the current semantic view configuration. New metrics should be added to both the semantic view definition and this dictionary. All queries filter by clnt_id = '"'"'dmcl'"'"' for row-level security.</p></ac:rich-text-body></ac:structured-macro>
<ac:structured-macro ac:name="note"><ac:rich-text-body><p>The semantic view supports natural language queries through the Cortex Agent (COCO_SDLC_HOL.MARTS.PAYMENT_ANALYTICS_AGENT). Ask questions like &quot;What is our approval rate by card brand?&quot; or &quot;Show me chargeback trends over the last 12 months.&quot;</p></ac:rich-text-body></ac:structured-macro>'
fi

# Escape storage content for JSON
ESCAPED_STORAGE=$(echo "$STORAGE_CONTENT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null || \
  echo "$STORAGE_CONTENT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' '\\' | sed 's/\\/\\n/g' | sed 's/\\n$//')

PAGE_PAYLOAD="{
  \"type\": \"page\",
  \"title\": \"Payment Analytics Data Dictionary\",
  \"space\": { \"key\": \"$PROJECT_KEY\" },
  \"body\": {
    \"storage\": {
      \"value\": $ESCAPED_STORAGE,
      \"representation\": \"storage\"
    }
  }
}"

RESP=$(api_call POST "$BASE_URL/wiki/rest/api/content/" "$PAGE_PAYLOAD")
HTTP_CODE=$(echo "$RESP" | head -1)
BODY=$(echo "$RESP" | tail -n +2)
check_response "$HTTP_CODE" "$BODY" "Create Confluence page"

PAGE_ID=$(extract_json_value "$BODY" "id")
PAGE_URL="$BASE_URL/wiki/spaces/$PROJECT_KEY/pages/$PAGE_ID"

# Try to extract the actual URL from the response
SELF_LINK=$(echo "$BODY" | python3 -c "import sys,json; data=json.load(sys.stdin); links=data.get('_links',{}); print(links.get('base','') + links.get('webui',''))" 2>/dev/null || true)
if [ -n "$SELF_LINK" ]; then
  PAGE_URL="$SELF_LINK"
fi

echo "Created Confluence page: $PAGE_URL"
echo ""

# --- Step 7: Summary output --------------------------------------------------
echo ""
echo "============================================="
echo "=== Atlassian Artifacts Created ==="
echo "============================================="
echo ""
echo "Epic:       $EPIC_KEY"
echo "Ticket 1:   $TICKET1_KEY (retry success rate metric)"
echo "Ticket 2:   $TICKET2_KEY (KPI card)"
echo "Backlog:    $BACKLOG1_KEY, $BACKLOG2_KEY, $BACKLOG3_KEY"
echo "Confluence: $PAGE_URL"
echo ""
echo "============================================="
echo "Update HANDS_ON_LAB.md:"
echo "  [TICKET-1]                     -> $TICKET1_KEY"
echo "  [TICKET-2]                     -> $TICKET2_KEY"
echo "  [CONFLUENCE-DATA-DICTIONARY-URL] -> $PAGE_URL"
echo "============================================="
echo ""
echo "Jira Board: $BASE_URL/jira/software/projects/$PROJECT_KEY/boards"
echo "Done."
