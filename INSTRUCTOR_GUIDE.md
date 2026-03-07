# Instructor Reference Guide — AI-Assisted SDLC HOL

**Instructor-only.** Live-use reference during the session. Companion to LAB_INSTRUCTIONS.md (participant guide) and INFRASTRUCTURE.md (pre-lab setup).

**How to use:** Step numbers here mirror LAB_INSTRUCTIONS.md exactly — when a participant says "I'm on step 4.3," look it up here instantly.

**Total duration:** ~90 min

---

## Section 1: Architecture Overview (~10 min)

Instructor-led architecture walkthrough — no participant inputs.

---

## Section 2: Environment Setup Verification (~5 min)

**Step 1 — Confirm Snowflake Connection**

```bash
snow sql -c ennovate -q "SELECT CURRENT_ROLE(), CURRENT_DATABASE(), CURRENT_SCHEMA();"
```

Expected output:
```
+----------------+--------------------+------------------+
| CURRENT_ROLE() | CURRENT_DATABASE() | CURRENT_SCHEMA() |
+----------------+--------------------+------------------+
| ATTENDEE_ROLE  | COCO_SDLC_HOL      | MARTS            |
+----------------+--------------------+------------------+
```

> Watch for: Role must be ATTENDEE_ROLE — if SYSADMIN, connection profile is wrong.

---

**Step 2 — Confirm Local App Runs**

```bash
cd apps/frontend && npm install && npm run dev
```

Expected output: `> Ready on http://localhost:3000`

> Watch for: Dashboard loads but shows no data — check `.env.local` SNOWFLAKE_ACCOUNT value.

---

**Step 3 — Confirm Cortex Code CLI Installed**

```bash
cortex --version
```

Expected output: version string (e.g., `cortex 1.x.x`)

> Watch for: "command not found" after install — instruct to restart terminal.

[If not installed — fallback]:
```bash
curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh
```

---

## Section 3: Cortex Code Primer (~10 min)

Sections 3.1 and 3.2 are instructor-led explanations — no participant inputs.

**Step 3.3 — Install Jira MCP Skill**

```bash
cortex mcp add jira --url https://evolv-coco-sdlc-hol.atlassian.net --auth-token ATATT3xFfGF0D7Aiugi8RrvbyL4UHnMz-wrOpVZkykXnM7OQcUWgruzWN1HreG_iWhaVD9vfsuE_ZAtDIgTHG3xjRmue861sVE3v2nVs1_uqhjQ_XRsx4eSKVV1Zr8FFLZ1BMOdtusft0jPXZcrZkzmbA_KfOLjXOGDWqoNiKFkw-bRxuM5-iCU=64649D40
```

[Alternative — interactive]:
```
/mcp
```
(then follow prompts to add Jira server)

---

**Step 3.4 — Install Confluence MCP Skill**

```bash
cortex mcp add confluence --url https://evolv-coco-sdlc-hol.atlassian.net --auth-token ATATT3xFfGF0JmTTc6yxUOmZbKA0ZlbDtsH8KZv3pijAYQ3Su0tUGnz7xODTQiYe16J1Xvz7nl6o-GtkOgkX0LWGcl-VcjygrFz9KNcAqDJqvOZlNyvmGn_ozYe5Bedn8QRqi2_nAMOaUNniftWkIYqNrHke4d09m0BnOJGfpUdLDOjwO-TWDq0=363884CD
```

---

**Step 3.5 — Quick Test — Verify Cortex Code Reads Repo Context**

```bash
cortex
```

Then in Cortex Code:
```
What database and schema does this project use?
```

Expected behavior: Response mentions `COCO_SDLC_HOL` and the medallion architecture (RAW, STAGING, INTERMEDIATE, MARTS).

> Watch for: Response is generic and doesn't mention COCO_SDLC_HOL — Cortex Code must be launched from repo root, not a subdirectory.

---
