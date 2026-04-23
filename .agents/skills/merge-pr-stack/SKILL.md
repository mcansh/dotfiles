---
name: merge-pr-stack
description: Use when merging a stack of approved Bitbucket PRs — auto-detects the stack from the repo, merges master into each feature branch (--no-ff), resolves conflicts intelligently, pushes, and merges each PR via API bottom-up.
---

<skill_overview>
Merge an entire PR stack in a single operation. PR stacks with rebase+squash merge strategy require conflict resolution for each PR because squashing changes commit hashes, causing every subsequent PR to conflict with the new master. This skill automates the tedious cycle: for each approved PR from the bottom of the stack upward, it merges the latest master into the feature branch with --no-ff (preserving approval status on the merge commit), resolves conflicts intelligently, pushes, and merges the PR via the Bitbucket API.
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM — The merge-master-then-merge-PR cycle is rigid. Stack detection and conflict resolution adapt to context.

**Rigid (no exceptions):**
- Always merge master with `--no-ff` (merge commits preserve PR approvals)
- Always re-fetch master after each PR merge (master changes after each squash)
- Always check PR approval status before merging
- Always stop on first unapproved or blocked PR
- Always parse git remote for project/repo (never hardcode)
- Always use the Bitbucket API to merge PRs (never merge locally)
- Never use blind `--ours` conflict resolution

**Flexible (adapt to context):**
- Stack detection method (auto-detect from open PRs, or user provides PR numbers)
- Conflict resolution approach (Claude reads and resolves intelligently, flags surprises)
- Merge strategy passed to API (default: squash)
</rigidity_level>

<when_to_use>
**Manual invocation:** User calls `/uwm-classic-sdlc:merge-pr-stack` or asks to "merge the PR stack" or "merge approved PRs".

**Use when ALL of these are true:**
1. A repository has multiple open PRs forming a stack (each PR targets the previous PR's source branch, with the bottom PR targeting master)
2. PRs in the stack are approved and ready to merge
3. The repo uses a rebase+squash merge strategy (or any strategy where merging changes commit hashes)

**Do NOT use when:**
- There is only a single PR to merge (just merge it directly)
- PRs are independent (not stacked — they all target master independently)
- PRs are not yet approved
- The user wants to merge a specific single PR (use the merge tool directly)
</when_to_use>

<the_process>

## Step 1: Determine Repository Context

Parse the git remote URL to extract projectKey and repositorySlug:

```bash
git remote get-url origin
```

**SSH format:** `ssh://git@code.uwm.com:7999/{projectKey}/{repoSlug}.git`
- Extract the path after `:7999/`
- Split on `/` to get projectKey and repoSlug
- Strip `.git` suffix from repoSlug
- Personal repos: `ssh://git@code.uwm.com:7999/~ykopstein/cy-claude-mcp.git` -> projectKey=`~ykopstein`, repoSlug=`cy-claude-mcp`

**HTTPS format:** `https://code.uwm.com/scm/{projectKey}/{repoSlug}.git`
- Extract the path after `/scm/`
- Split on `/` to get projectKey and repoSlug
- Strip `.git` suffix from repoSlug

**If the URL doesn't match either format:** Stop and report: "Cannot parse git remote URL. Please provide projectKey and repositorySlug manually."

---

## Step 2: Discover the PR Stack

List all open PRs in the repository:

```
Use mcp__plugin_uwm-enterprise-mcp_bitbucket__list_pull_requests
projectKey: {extracted projectKey}
repositorySlug: {extracted repoSlug}
state: OPEN
```

**Determine the default branch:**

```bash
git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
```

If this fails (e.g., `origin/HEAD` is not set), fall back to `master`. Store the result as `{defaultBranch}`.

**Build the stack by following target branches:**

1. Find all PRs whose target branch is `{defaultBranch}`. These are potential stack bottoms.
2. For each candidate bottom PR, walk upward: find PRs whose target branch matches this PR's source branch. Continue until no more PRs target the current source branch.
3. The longest chain starting from master is the stack.

**Example:** Given these open PRs:
- PR #1: `feature/A` -> `master`
- PR #2: `feature/B` -> `feature/A`
- PR #3: `feature/C` -> `feature/B`
- PR #4: `feature/D` -> `master` (independent, not in this stack)

The stack is: [PR #1, PR #2, PR #3] (bottom to top).

**If no stack found:** Report "No PR stack detected. Found {N} independent PRs targeting master." and list them.

**If multiple stacks found:** Report the stacks and ask the user which one to merge.

---

## Step 3: Check Approval Status

For each PR in the stack (bottom to top), use `get_pull_request_details` to check:
- PR state is OPEN
- PR has at least one APPROVED reviewer
- PR has no open tasks/blockers (check the activities or task count if available)

**Report the stack status:**

```
PR Stack ({N} PRs):
  1. PR #{id}: {title} [{source} -> {target}] - APPROVED / NOT APPROVED
  2. PR #{id}: {title} [{source} -> {target}] - APPROVED / NOT APPROVED
  ...
```

**Determine mergeable PRs:** Starting from the bottom, find the longest contiguous run of approved PRs. Only these will be merged.

**If the bottom PR is not approved:** Stop and report: "Cannot merge stack. The bottom PR #{id} is not approved."

**If some middle PRs are not approved:** Report: "Will merge {N} of {total} PRs. Stopping at PR #{id} (not approved)."

**Ask for confirmation before proceeding:**

```
Use AskUserQuestion
question: "Ready to merge {N} approved PRs? This will merge master into each feature branch (--no-ff), resolve conflicts, push, and merge each PR via API with squash strategy."
options:
  - label: "Merge all {N} approved PRs"
  - label: "Cancel"
```

---

## Step 4: Merge Each PR (Bottom-Up Loop)

For each approved PR in the stack, from bottom to top:

### 4a. Fetch latest master

```bash
git fetch origin master
```

**This MUST happen before every PR merge** — master changes after each squash merge. A fetch from the previous iteration is stale.

### 4b. Checkout the feature branch

First, check for uncommitted changes:

```bash
git status --porcelain
```

If the output is non-empty, **abort** and report: "Working tree has uncommitted changes. Stash or commit them before proceeding."

Then checkout and reset:

```bash
git fetch origin {sourceBranch}
git checkout {sourceBranch}
git reset --hard origin/{sourceBranch}
```

### 4c. Merge master into the feature branch

```bash
git merge origin/master --no-ff -m "Merge origin/master into {sourceBranch}"
```

**If no conflicts:** Proceed to step 4e.

### 4d. Resolve conflicts intelligently

**DO NOT use blind `git checkout --ours` or `--theirs`.**

Instead:
1. List conflicting files: `git diff --name-only --diff-filter=U`
2. For each conflicting file, read the conflict markers
3. Understand the intent of both sides:
   - The "ours" side (feature branch) contains the original work
   - The "theirs" side (master) typically contains the squashed version of a previously-merged PR from this stack
4. Resolve by keeping the feature branch's version when the conflict is between the original commits and their squashed equivalent
5. For genuine content conflicts (different changes to the same lines), resolve based on understanding the code's intent

**Flag unexpected deviations:** If a conflict involves changes that don't look like a squash-vs-original mismatch (e.g., someone else committed to master independently), report this to the user before resolving:

```
UNEXPECTED CONFLICT in {file}:
  - Feature branch has: {description}
  - Master has: {description}
  This doesn't look like a squash-related conflict. Resolving as: {decision and reasoning}
```

After resolving all conflicts:

1. Verify no conflict markers remain in the resolved files:
```bash
git diff --check
```
If this reports conflict markers, resolution is incomplete — go back and fix.

2. Stage only the resolved files (not all files in the worktree):
```bash
git add {resolved_file_1} {resolved_file_2} ...
```
Use the file paths from step 4d.1 (the conflict list). Do **not** use `git add -A` — it stages untracked files, editor swap files, IDE metadata, and build artifacts.

3. Verify no unmerged files remain:
```bash
git ls-files -u
```
If this returns any output, there are still unresolved conflicts — go back and fix.

4. Complete the merge commit:
```bash
git commit --no-edit
```

### 4e. Push the feature branch

```bash
git push origin {sourceBranch}
```

**If the push fails** (non-zero exit code — e.g., force-push protection, pre-receive hook rejection, auth expired), **stop immediately**. Report the error and do not proceed to Step 4f. Merging the PR with stale code on the remote would produce incorrect results.

### 4f. Merge the PR via Bitbucket API

```
Use mcp__plugin_uwm-enterprise-mcp_bitbucket__merge_pull_request
projectKey: {projectKey}
repositorySlug: {repoSlug}
pullRequestId: {prId}
strategyId: {mergeStrategy}  # Default: squash. Adapt to the repo's configured merge strategy.
```

**If merge fails:** Stop immediately. Report the error and which PR failed. Do not continue with the remaining stack.

**If merge succeeds:** Report progress:
```
Merged PR #{id}: {title} ({current}/{total})
```

### 4g. Repeat

Go back to step 4a for the next PR in the stack. Master must be re-fetched because the squash merge changed it.

---

## Step 5: Report Results

After all PRs are merged (or on failure), report:

```
PR Stack Merge Complete:
  Merged: {N} of {total} PRs
  1. PR #{id}: {title} - MERGED
  2. PR #{id}: {title} - MERGED
  ...

  Remaining (not merged):
  {N+1}. PR #{id}: {title} - {reason: not approved / blocked / error}
```

If all PRs merged successfully:
```
PR Stack Merge Complete: All {N} PRs merged successfully.
```

</the_process>

<critical_rules>

## Rules That Have No Exceptions

1. **Always use `--no-ff` when merging master into feature branches** — Merge commits preserve PR approval status. Fast-forward merges lose the approval association.
2. **Always re-fetch master before each PR merge** — After a squash merge, master has different commit hashes. Using a stale master causes incorrect conflict resolution.
3. **Always check approval status before merging** — Never merge unapproved PRs. Stop at the first unapproved PR in the stack.
4. **Always use the Bitbucket API to merge PRs** — Never use `git merge` locally to merge into master. The API enforces merge policies, updates PR status, and triggers hooks.
5. **Never use blind `--ours` or `--theirs`** — Read each conflict, understand both sides, and resolve intelligently. Flag unexpected conflicts for user review.
6. **Always stop on failure** — If any PR merge fails (API error, unresolvable conflict, blocked), stop the entire stack merge. Do not skip PRs.
7. **Always parse git remote** — Never hardcode project keys or repo slugs.
8. **Always build stack from PR target branches** — Never assume stack order from branch naming conventions or alphabetical order.
9. **Always ask for confirmation** — Before merging, show the stack and get user approval.

## Git Remote Parsing

The skill must handle these URL formats:

| Format | Pattern | Example |
|--------|---------|---------|
| SSH | `ssh://git@code.uwm.com:7999/{key}/{slug}.git` | `ssh://git@code.uwm.com:7999/EH/allin-ui.git` |
| SSH (personal) | `ssh://git@code.uwm.com:7999/~{user}/{slug}.git` | `ssh://git@code.uwm.com:7999/~ykopstein/cy-claude-mcp.git` |
| HTTPS | `https://code.uwm.com/scm/{key}/{slug}.git` | `https://code.uwm.com/scm/EH/allin-ui.git` |

Always strip `.git` suffix from the slug. Personal repo project keys start with `~`.

</critical_rules>

<integration>

**This skill is called by:**
- Direct user invocation via `/uwm-classic-sdlc:merge-pr-stack`
- User requests like "merge the PR stack", "merge approved PRs in the stack"

**This skill uses these MCP tools (from uwm-enterprise-mcp plugin):**
- `mcp__plugin_uwm-enterprise-mcp_bitbucket__list_pull_requests` — Discover all open PRs in the repository
- `mcp__plugin_uwm-enterprise-mcp_bitbucket__get_pull_request_details` — Check approval status and get branch info for each PR
- `mcp__plugin_uwm-enterprise-mcp_bitbucket__merge_pull_request` — Merge each PR via Bitbucket API with squash strategy

**Prerequisites:**
- The `uwm-enterprise-mcp` plugin must be installed (provides Bitbucket MCP tools)
- A valid `BITBUCKET_TOKEN` must be configured in `~/.uwm-mcp-shared/config.json`
- The token must have merge permissions on the target repository
- Git must be configured with push access to the repository

**This skill replaces:**
- The old `.claude/commands/merge-from-master.md` workspace command (which only merged master into a single PR's branch without merging the PR itself)

</integration>
