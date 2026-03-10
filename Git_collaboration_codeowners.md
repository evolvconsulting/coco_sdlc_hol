# GitHub Repository Management Guide (Code Owners)

This guide is for **repository administrators and code owners** responsible for setting up and managing the Lab2 project.

**Repository**: `https://github.com/DanielPhillipsSanchez/Lab2.git`

---

## 1. Creating a New Repository

### Step 1.1: Create Repository on GitHub

1. Go to [github.com](https://github.com) and sign in
2. Click the **+** icon (top-right) → **New repository**
3. Configure:
   - **Repository name**: `Lab2`
   - **Description**: "Performance Intelligence - Payment Analytics Platform"
   - **Visibility**: Private (recommended) or Public
   - **Initialize**: Check "Add a README file"
   - **Add .gitignore**: Select `Node` or `Python` template
4. Click **Create repository**

### Step 1.2: Clone and Initialize Locally

```bash
git clone https://github.com/YOUR_USERNAME/Lab2.git
cd Lab2
```

---

## 2. Granting Access to Collaborators

### Step 2.1: Add Individual Collaborators

1. Go to **Settings → Collaborators and teams** (left sidebar under "Access")
2. Click **Add people**
3. Search by GitHub username or email
4. Select the appropriate role:

| Role | Permissions |
|------|-------------|
| **Read** | View and clone repository |
| **Triage** | Read + manage issues and PRs |
| **Write** | Triage + push to non-protected branches |
| **Maintain** | Write + manage settings (except destructive) |
| **Admin** | Full access including dangerous operations |

5. Click **Add [username] to this repository**

### Step 2.2: Create and Manage Teams (Organizations)

For organization repositories:

1. Go to **Organization Settings → Teams**
2. Click **New team**
3. Name the team (e.g., `lab2-developers`, `lab2-reviewers`)
4. Add members to the team
5. Go to **Repository Settings → Collaborators and teams**
6. Click **Add teams** and assign repository permissions

### Step 2.3: Recommended Team Structure

| Team | Role | Purpose |
|------|------|---------|
| `lab2-admins` | Admin | Repository owners and maintainers |
| `lab2-reviewers` | Maintain | Code review and PR approval |
| `lab2-developers` | Write | Active contributors |
| `lab2-readonly` | Read | Observers and stakeholders |

---

## 3. Protecting the Main Branch

### Step 3.1: Access Branch Protection

1. Go to **Settings → Branches** (under "Code and automation")
2. Click **Add branch protection rule**

### Step 3.2: Configure Protection Rules

1. **Branch name pattern**: `main`

2. Enable these settings:

| Setting | Configuration |
|---------|---------------|
| **Require a pull request before merging** | ✓ Enable |
| → Require approvals | `1` or `2` |
| → Dismiss stale pull request approvals when new commits are pushed | ✓ Enable |
| → Require review from Code Owners | ✓ Enable (if CODEOWNERS file exists) |
| **Require status checks to pass before merging** | ✓ Enable |
| → Require branches to be up to date before merging | ✓ Enable |
| **Require conversation resolution before merging** | ✓ Enable |
| **Do not allow bypassing the above settings** | ✓ Enable |
| **Restrict who can push to matching branches** | Optional - limit to specific teams |
| **Allow force pushes** | ✗ Disable |
| **Allow deletions** | ✗ Disable |

3. Click **Create**

### Step 3.3: Create CODEOWNERS File

Create `.github/CODEOWNERS` to automatically request reviews:

```
# Default owners for everything
* @DanielPhillipsSanchez

# dbt models require data team review
/packages/dbt/ @DanielPhillipsSanchez

# Database scripts require admin review
/packages/database/ @DanielPhillipsSanchez

# Apps require frontend team review
/apps/ @DanielPhillipsSanchez
```

---

## 4. Repository Settings Configuration

### Step 4.1: General Settings

Go to **Settings → General**:

| Setting | Recommended Value |
|---------|-------------------|
| **Default branch** | `main` |
| **Features** | Enable Issues, Projects as needed |
| **Pull Requests** | ✓ Allow squash merging (preferred) |
| | ✓ Allow merge commits |
| | ✗ Allow rebase merging (optional) |
| | ✓ Automatically delete head branches |

### Step 4.2: Configure Merge Button

Under **Pull Requests**:
- **Default to PR title for squash commits**: Enabled
- **Suggest updating PR branches**: Enabled

---

## 5. Setting Up CI/CD

### Step 5.1: Add Repository Secrets

1. Go to **Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Add required secrets:

| Secret | Description |
|--------|-------------|
| `SNOWFLAKE_ACCOUNT` | Snowflake account identifier |
| `SNOWFLAKE_USER` | Service account username |
| `SNOWFLAKE_PASSWORD` | Service account password |
| `SNOWFLAKE_ROLE` | CI role (e.g., `TRANSFORM_ROLE`) |
| `SNOWFLAKE_WAREHOUSE` | CI warehouse |

### Step 5.2: Create CI Workflow

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: pip install dbt-snowflake
      - run: cd packages/dbt && dbt compile
        env:
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_USER }}
          SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_PASSWORD }}
```

---

## 6. Monitoring and Maintenance

### Step 6.1: Review Access Regularly

1. Go to **Settings → Collaborators and teams**
2. Remove users who no longer need access
3. Audit admin permissions quarterly

### Step 6.2: Monitor Branch Protection

1. Go to **Settings → Branches**
2. Verify rules are active (lock icon visible)
3. Review bypass attempts in **Security → Audit log** (organizations)

### Step 6.3: Manage Pending Invitations

1. Go to **Settings → Collaborators and teams**
2. Check **Pending invitations** section
3. Resend or cancel stale invitations

---

## 7. Quick Reference

| Task | Location |
|------|----------|
| Add collaborators | Settings → Collaborators and teams |
| Protect branches | Settings → Branches |
| Add secrets | Settings → Secrets and variables → Actions |
| View audit log | Settings → Security → Audit log |
| Manage webhooks | Settings → Webhooks |
| Configure Pages | Settings → Pages |
| Set up Jira MCP | See Section 8 below |

---

## 8. Setting Up Jira MCP Integration

Connect Jira to your development environment via MCP (Model Context Protocol) to manage tickets directly from your CLI/agent.

### Step 8.1: Generate a Jira API Token

1. Go to [Atlassian API Tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Click **Create API token**
3. Give it a label (e.g., `Cortex Code MCP`)
4. Copy the token — you won't see it again

### Step 8.2: Configure the Jira MCP Connection

Provide your credentials to the MCP Jira tool:

| Parameter | Value |
|-----------|-------|
| **Base URL** | `https://evolvconsulting-team-u2rm5pfv.atlassian.net/` |
| **Email** | Your Atlassian account email |
| **API Token** | The token generated in Step 8.1 |
| **Auth Method** | Basic Auth |

In Cortex Code, the connection is set via `jira_set_auth`:

```
Base URL:  https://evolvconsulting-team-u2rm5pfv.atlassian.net/
Email:     your.email@evolvconsulting.com
API Token: <your-api-token>
```

### Step 8.3: Verify the Connection

Run these commands to confirm the integration is working:

1. **Check auth status** — `jira_auth_status` to verify credentials are loaded
2. **Check identity** — `jira_whoami` to confirm the authenticated user
3. **List projects** — `jira_list_projects` to verify project access
4. **View your tickets** — `jira_get_my_open_issues` to see assigned issues

### Step 8.4: Common Jira MCP Operations

Once connected, you can perform these operations directly from your agent:

| Operation | MCP Tool | Example |
|-----------|----------|---------|
| View your open tickets | `jira_get_my_open_issues` | "Show my Jira tickets" |
| Get issue details | `jira_get_issue` | "Tell me about LAB2-17" |
| Search issues (JQL) | `jira_search_issues` | "Find all STAGING tickets" |
| Transition an issue | `jira_transition_issue` | "Move LAB2-17 to In Progress" |
| Add a comment | `jira_add_comment` | "Add a comment to LAB2-17" |
| Create an issue | `jira_create_issue` | "Create a bug in LAB2" |
| Update an issue | `jira_update_issue` | "Assign LAB2-17 to me" |

### Step 8.5: Project Board Overview

Our Jira project **LAB2** maps to the medallion data architecture:

| Layer | Tickets | Description |
|-------|---------|-------------|
| STAGING | LAB2-16 to LAB2-22 | Staging models (stg_clx_*) |
| INTERMEDIATE | LAB2-23 to LAB2-28 | Enriched dynamic tables (int_*__enriched) |
| MARTS | LAB2-29 to LAB2-35 | Business-ready analytics tables |

### Step 8.6: Security Notes

- **Never commit API tokens** to the repository
- API tokens are session-scoped — re-authenticate when starting a new session
- Use environment variables or secret managers for CI/CD Jira integrations
- Rotate tokens periodically via the Atlassian account settings

---

## 9. Troubleshooting

**Collaborator can't push:**
- Verify they have Write access or higher
- Check branch protection isn't blocking their push
- Ensure they're pushing to a feature branch, not `main`

**PR can't be merged:**
- Check required status checks are passing
- Verify required approvals are met
- Ensure conversations are resolved

**CODEOWNERS not working:**
- File must be in `.github/CODEOWNERS`, `CODEOWNERS`, or `docs/CODEOWNERS`
- Users must have Write access to be valid code owners
- Check file syntax (no trailing spaces)
