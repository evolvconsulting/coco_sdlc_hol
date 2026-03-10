# Phase 6: Update Instructions to Include Fork Step (Option A) - Research

**Researched:** 2026-03-10
**Domain:** Documentation editing — GitHub fork workflow, HOL instruction guide updates
**Confidence:** HIGH

---

## Summary

This phase is a documentation-only update. The repository `evolvconsulting/coco_sdlc_hol` is public and now has branch protection on `main` (direct push restricted to admins team; CODEOWNERS requires admins team review on all PRs). Participants can no longer `clone → push to origin` — they must `fork → clone fork → push to fork → PR to upstream`.

Two participant-facing documents contain the affected steps: `LAB_INSTRUCTIONS.md` and `README.md`. The `INSTRUCTOR_GUIDE.md` mirrors participant-facing steps exactly (by design, per its own header) and must also be updated to track the new flow. No code changes are required; no other files are affected.

The core edit is in **Section 2, Step 0** of `LAB_INSTRUCTIONS.md`, which currently reads `git clone https://github.com/evolvconsulting/coco_sdlc_hol.git`. This must become: fork on GitHub first, then clone your fork. Every subsequent git operation (push, PR creation) already targets the fork/upstream correctly once the fork-clone is in place — no other steps require substantive change. The `README.md` Getting Started clone snippet also needs updating. The `INSTRUCTOR_GUIDE.md` Step 0 watch-for block needs a note about the fork prerequisite.

**Primary recommendation:** Edit three files (`LAB_INSTRUCTIONS.md`, `README.md`, `INSTRUCTOR_GUIDE.md`) to replace the direct-clone step with a fork-then-clone step. All other content remains unchanged.

---

## Affected Files Inventory

| File | Location | Affected Section | Nature of Change |
|------|----------|-----------------|-----------------|
| `LAB_INSTRUCTIONS.md` | repo root | Section 2, Step 0 | Replace `git clone` block with fork-first instructions |
| `README.md` | repo root | Prerequisites §5 Git + Getting Started | Update clone snippet; add fork note |
| `INSTRUCTOR_GUIDE.md` | repo root | Section 2, Step 0 watch-for | Add fork prerequisite watch-for note |

---

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| GitHub UI | N/A | Fork a public repo | Only way to fork; no CLI equivalent for initial fork creation |
| `git clone` | system git | Clone participant's own fork | Standard git; already used throughout the lab |
| `git remote` | system git | Verify remote URLs | Optional verification step; good practice |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `gh repo fork` | GitHub CLI | Fork + clone in one command | If `gh` CLI is available — cleaner UX than two-step UI+clone |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| GitHub UI fork + git clone (two steps) | `gh repo fork --clone` (one step) | `gh` CLI requires separate install; not listed in current prerequisites. Avoid adding new prerequisites. Keep the two-step approach. |

---

## Architecture Patterns

### Fork-then-Clone Pattern (Option A — Standard Open-Source Model)

**What:** Participant forks the upstream public repo on GitHub, clones their own fork locally, works in their fork, and opens a PR back to upstream if desired.

**When to use:** The upstream repo has branch protection; participants cannot push to branches directly. This is the standard open-source contribution model.

**The three-step sequence participants follow:**

```
1. Fork on GitHub
   https://github.com/evolvconsulting/coco_sdlc_hol → click Fork → create fork under own account

2. Clone your fork (not the upstream)
   git clone https://github.com/<your-username>/coco_sdlc_hol.git
   cd coco_sdlc_hol

3. (Optional) Verify remote points to your fork
   git remote -v
   # origin  https://github.com/<your-username>/coco_sdlc_hol.git (fetch)
   # origin  https://github.com/<your-username>/coco_sdlc_hol.git (push)
```

**Why this matters for the lab:**
- Step 4.11 asks participants to `push to origin` — this works unchanged, because `origin` is now their fork.
- Step 6.6 asks participants to `push to origin` — same, works unchanged.
- Step 6.7 asks Cortex Code to create a PR — the PR targets `evolvconsulting/coco_sdlc_hol:main` from `<participant-fork>/<branch>`. This is correct PR behavior.
- The `AGENTS.md` context file is present in the forked repo automatically — no impact.

### What Does NOT Change

- All git branch creation steps (4.2, 6.2) — unchanged, branches are created in the fork.
- All `push to origin` steps (4.11, 6.6) — unchanged, `origin` points to fork.
- All PR creation steps (6.7) — GitHub will automatically suggest the upstream repo as the PR target when creating a PR from a fork.
- Snowflake connection steps — unaffected.
- Cortex Code steps — unaffected.
- `AGENTS.md` repo context — present in fork, works identically.

### Anti-Patterns to Avoid

- **Mentioning upstream remote setup:** The lab does not need participants to add an `upstream` remote. That is for contributors who need to sync — not needed for a 90-min lab. Adding it creates unnecessary complexity.
- **Using `gh repo fork` without verifying prerequisite:** `gh` CLI is not in the current prerequisites list. Don't introduce it as the primary path.
- **Cloning upstream then changing remote:** Technically possible but confusing for participants. The clean path is fork-first, clone-fork.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fork creation | Custom script or API call | GitHub UI (browser) | Forking is a 3-click UI action; scripting adds complexity with no benefit in lab context |
| Checking fork exists | Manual verification step | Trust the participant; GitHub confirms on fork page | Over-engineering a doc-edit task |

---

## Common Pitfalls

### Pitfall 1: Participant Clones Upstream Instead of Fork
**What goes wrong:** Participant follows old habit and clones `evolvconsulting/coco_sdlc_hol` instead of their fork. Push in Step 4.11 fails with "remote: Permission denied" or "protected branch."
**Why it happens:** Muscle memory; the old instruction said `git clone https://github.com/evolvconsulting/coco_sdlc_hol.git`.
**How to avoid:** Instruction must explicitly state: "Clone YOUR FORK, not the upstream repository." Emphasize `<your-username>` in the clone URL.
**Warning signs for instructor:** Participant reports push failure in Step 4.11. Check `git remote -v` — if it shows `evolvconsulting/coco_sdlc_hol`, they cloned upstream. Fix: `git remote set-url origin https://github.com/<their-username>/coco_sdlc_hol.git`.

### Pitfall 2: Participant Doesn't Fork First
**What goes wrong:** Participant jumps straight to `git clone` without forking. They clone upstream successfully (it's public) but then cannot push.
**Why it happens:** Participants skim instructions; "fork" is a new step not in the previous flow.
**How to avoid:** Place the fork step before the clone step with a clear visual separator. Add a checkpoint: "You should see your fork at `https://github.com/<your-username>/coco_sdlc_hol`."
**Warning signs for instructor:** `git remote -v` shows `evolvconsulting` as origin.

### Pitfall 3: PR Target Is Wrong
**What goes wrong:** Participant creates PR from their fork branch to their own fork's main instead of upstream main.
**Why it happens:** Cortex Code prompt in Step 6.7 says "Create a GitHub pull request" — GitHub defaults to the correct upstream target when the repo is a fork, but it's worth confirming.
**How to avoid:** The instructor guide watch-for for Step 6.7 should note: "PR should target `evolvconsulting/coco_sdlc_hol:main`, not `<participant>/coco_sdlc_hol:main`."

### Pitfall 4: Instructor Guide Step Numbers Drift
**What goes wrong:** If a step is added to `LAB_INSTRUCTIONS.md` and not reflected in `INSTRUCTOR_GUIDE.md`, the "step numbers mirror exactly" contract breaks.
**How to avoid:** The fork step should be numbered identically in both documents (it replaces Step 0 content — the step number stays 0, but content expands). No new step number is introduced.

---

## Code Examples

### Step 0 Replacement (LAB_INSTRUCTIONS.md)

```markdown
### Step 0: Fork and Clone the Lab Repository

**0a. Fork the repository**

Navigate to [https://github.com/evolvconsulting/coco_sdlc_hol](https://github.com/evolvconsulting/coco_sdlc_hol) in your browser and click **Fork** (top-right). Accept the defaults and click **Create fork**.

You now have your own copy of the repository at `https://github.com/<your-username>/coco_sdlc_hol`.

**0b. Clone YOUR fork (not the upstream)**

```bash
git clone https://github.com/<your-username>/coco_sdlc_hol.git
cd coco_sdlc_hol
```

Replace `<your-username>` with your GitHub username.

> **Why fork?** The upstream repository restricts direct pushes to main. By working in your own fork, you can push your branches freely and submit pull requests back to the upstream repository when ready.

All subsequent steps and tool invocations assume you are working from this directory.
```

### README.md Prerequisite §5 Replacement

```markdown
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
```

### INSTRUCTOR_GUIDE.md Step 0 Watch-For Addition

```markdown
> Watch for: Participants who clone the upstream URL (`evolvconsulting/coco_sdlc_hol`) instead of their fork will hit a "permission denied" push error in Step 4.11. Check with `git remote -v` — origin must show their username. Fix: `git remote set-url origin https://github.com/<their-username>/coco_sdlc_hol.git`.
> Watch for: Participants who skip forking entirely — same symptom. Have them fork first on GitHub, then re-clone or update their remote.
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `git clone evolvconsulting/coco_sdlc_hol` then push to feature branch | Fork → clone fork → push to fork | Phase 6 (2026-03-10) | Branch protection on main + CODEOWNERS prevents direct branch pushes; fork model is now required |

**Why this changed:** Branch protection was applied to `main` (admins-only direct push) and a CODEOWNERS file added requiring admins team review on all PRs. This makes the standard open-source fork model the correct participant workflow.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None (documentation-only phase) |
| Config file | N/A |
| Quick run command | Manual review of edited files |
| Full suite command | Manual walkthrough of Section 2 fork steps |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HOL-FORK-01 | Step 0 in LAB_INSTRUCTIONS.md describes fork-then-clone | manual | Inspect file diff | ❌ Wave 0 |
| HOL-FORK-02 | README.md Getting Started clone snippet updated | manual | Inspect file diff | ❌ Wave 0 |
| HOL-FORK-03 | INSTRUCTOR_GUIDE.md Step 0 watch-for includes fork failure pattern | manual | Inspect file diff | ❌ Wave 0 |
| HOL-FORK-04 | All push steps (4.11, 6.6) and PR step (6.7) remain functionally correct under fork model | manual | Read steps in context | ❌ Wave 0 |
| HOL-FORK-05 | No new prerequisite tools added beyond existing list | manual | Inspect Prerequisites section | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** Manual review — confirm edited sections are internally consistent
- **Per wave merge:** Full read-through of modified sections in all three files
- **Phase gate:** All three files updated; no step number drift between LAB_INSTRUCTIONS.md and INSTRUCTOR_GUIDE.md

### Wave 0 Gaps
- These are documentation edits with no automated test framework. Validation is manual review only.

---

## Open Questions

1. **Does the lab need a `git remote add upstream` step?**
   - What we know: The lab has no "sync with upstream" task. The 90-min lab is self-contained.
   - What's unclear: Whether future lab iterations will need participants to pull instructor changes mid-session.
   - Recommendation: Omit upstream remote for now. It adds complexity without lab benefit. Note can be added as a "Beyond the lab" callout if desired.

2. **Should the README Getting Started section link to the fork or directly to the repo?**
   - What we know: README currently has `git clone <repo-url>` (placeholder).
   - Recommendation: Update to match the fork-first pattern for consistency with LAB_INSTRUCTIONS.md.

---

## Sources

### Primary (HIGH confidence)
- Direct inspection of `LAB_INSTRUCTIONS.md` (repo root) — full content read
- Direct inspection of `README.md` (repo root) — full content read
- Direct inspection of `INSTRUCTOR_GUIDE.md` (repo root) — sections 1-3 read
- `.github/CODEOWNERS` — confirmed `* @evolvconsulting/admins` (read directly)
- `STATE.md` context — branch protection confirmed applied, Option A confirmed as chosen approach

### Secondary (MEDIUM confidence)
- GitHub documentation on fork workflow — standard open-source contribution model; behavior of fork → PR is well-established and unchanged

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Affected files: HIGH — all three files directly inspected
- Required content changes: HIGH — fork-then-clone pattern is standard and unambiguous
- No-impact assessment (push/PR steps unchanged): HIGH — `origin` semantics confirmed correct under fork model
- Validation approach: HIGH — documentation phase, manual review is correct

**Research date:** 2026-03-10
**Valid until:** 2026-04-10 (stable — file content won't change until planning begins)
