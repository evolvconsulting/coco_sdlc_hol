# GitHub Collaboration Guide (Lab Collaborators)

This guide is for **developers and collaborators** working on the Lab2 project.

**Repository**: `https://github.com/DanielPhillipsSanchez/Lab2.git`

---

## 1. Getting Started

### Step 1.1: Accept Your Invitation

1. Check your email for a GitHub repository invitation
2. Click **Accept invitation**
3. You now have access to the Lab2 repository

### Step 1.2: Clone the Repository

```bash
# Clone the repository to your local machine
git clone https://github.com/DanielPhillipsSanchez/Lab2.git

# Navigate into the project folder
cd Lab2
```

### Step 1.3: Verify Your Setup

```bash
# Check you're connected to the remote
git remote -v

# Expected output:
# origin  https://github.com/DanielPhillipsSanchez/Lab2.git (fetch)
# origin  https://github.com/DanielPhillipsSanchez/Lab2.git (push)
```

---

## 2. Before You Start Working

### Step 2.1: Always Sync First

Before starting any new work, get the latest changes:

```bash
git checkout main
git pull origin main
```

### Step 2.2: Create a Feature Branch

**Never work directly on `main`.** Create a branch for your work:

```bash
git checkout -b feature/your-feature-name
```

**Branch naming conventions:**

| Prefix | Use For | Example |
|--------|---------|---------|
| `feature/` | New functionality | `feature/add-refund-metrics` |
| `bugfix/` | Bug fixes | `bugfix/fix-null-amounts` |
| `docs/` | Documentation | `docs/update-readme` |

---

## 3. Making Changes

### Step 3.1: Make Your Edits

Edit files as needed for your task. Key project folders:

```
Lab2/
├── packages/dbt/models/     # dbt SQL models
├── packages/database/       # SQL scripts
├── apps/                    # Application code
└── AGENTS.md                # Project documentation
```

### Step 3.2: Check Your Changes

```bash
# See what files changed
git status

# See the actual changes
git diff
```

### Step 3.3: Stage and Commit

```bash
# Stage all changes
git add .

# Commit with a descriptive message
git commit -m "Add settlement amount validation"
```

**Good commit messages:**
- Start with a verb: "Add", "Fix", "Update", "Remove"
- Be specific: "Fix null handling in deposit calculations"
- Keep under 72 characters

### Step 3.4: Push Your Branch

```bash
git push origin feature/your-feature-name
```

---

## 4. Creating a Pull Request

### Step 4.1: Open the PR

1. Go to [github.com/DanielPhillipsSanchez/Lab2](https://github.com/DanielPhillipsSanchez/Lab2)
2. You'll see a banner: **"feature/your-feature-name had recent pushes"**
3. Click **Compare & pull request**

### Step 4.2: Fill in the PR Details

```markdown
## Summary
Brief description of what this PR does.

## Changes
- Added X
- Fixed Y
- Updated Z

## Testing
- [ ] Tested locally
- [ ] dbt models compile
```

### Step 4.3: Request Review

1. On the right sidebar, click **Reviewers**
2. Select appropriate reviewer(s)
3. Click **Create pull request**

### Step 4.4: Address Feedback

If reviewers request changes:

1. Make the requested edits locally
2. Commit and push again:
   ```bash
   git add .
   git commit -m "Address review feedback"
   git push origin feature/your-feature-name
   ```
3. Reply to comments and mark as resolved

### Step 4.5: After Merge

Once approved and merged:

```bash
# Switch back to main
git checkout main

# Get the merged changes
git pull origin main

# Delete your local branch
git branch -d feature/your-feature-name
```

---

## 5. Daily Workflow Summary

```bash
# 1. Start of day - sync with main
git checkout main
git pull origin main

# 2. Create branch for your task
git checkout -b feature/my-task

# 3. Work on your changes...

# 4. Save your work
git add .
git commit -m "Description of changes"

# 5. Push to GitHub
git push origin feature/my-task

# 6. Create PR on GitHub website

# 7. After PR is merged - cleanup
git checkout main
git pull origin main
git branch -d feature/my-task
```

---

## 6. Common Situations

### Updating Your Branch with Latest Main

If `main` has new changes while you're working:

```bash
git checkout main
git pull origin main
git checkout feature/your-feature-name
git merge main
```

### Fixing Merge Conflicts

If you see conflict markers (`<<<<<<<`):

1. Open the conflicting file
2. Choose which changes to keep
3. Remove the conflict markers
4. Save, then:
   ```bash
   git add .
   git commit -m "Resolve merge conflicts"
   git push origin feature/your-feature-name
   ```

### Undoing Mistakes

```bash
# Discard uncommitted changes to a file
git checkout -- path/to/file

# Undo your last commit (keep changes)
git reset --soft HEAD~1

# Discard all uncommitted changes (careful!)
git checkout .
```

### Starting Over on Your Branch

If your branch is messy and you want to restart:

```bash
git checkout main
git pull origin main
git branch -D feature/your-feature-name   # Delete old branch
git checkout -b feature/your-feature-name  # Start fresh
```

---

## 7. Quick Reference

| What You Want | Command |
|---------------|---------|
| Get latest code | `git pull origin main` |
| Create branch | `git checkout -b feature/name` |
| See changes | `git status` |
| Save changes | `git add . && git commit -m "msg"` |
| Push to GitHub | `git push origin feature/name` |
| Switch branches | `git checkout branch-name` |
| Delete branch | `git branch -d branch-name` |
| View history | `git log --oneline -10` |

---

## 8. Getting Help

- **Git issues**: Ask in the team chat or create a GitHub issue
- **Access problems**: Contact the repository administrator
- **Review delays**: Ping reviewers on the PR

**Remember**: The `main` branch is protected. All changes must go through a pull request with approval.
