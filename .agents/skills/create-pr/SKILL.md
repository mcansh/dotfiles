---
name: create-pr
description: Use when finishing development work or when a bd epic is closed — creates a Bitbucket pull request with the original user prompt and commit notes in the PR body.
---

<skill_overview>
Create a Bitbucket pull request with a standardized body format. The PR description includes the original user prompt that started the development session and a list of commit messages as Claude notes. The skill parses the git remote URL to determine the Bitbucket project and repository, detects source and target branches, and calls the MCP tool to create the PR.
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM — The PR body headings and git remote parsing are rigid. The PR title and commit formatting adapt to context.

**Rigid (no exceptions):**
- Always include `#### Original prompt` heading with verbatim user text
- Always include `##### Claude notes` heading with commit messages
- Always parse git remote for project/repo (never hardcode)
- Never create a PR from main/master to main/master

**Flexible (adapt to context):**
- PR title (epic title, branch name, or user-specified)
- Target branch detection (symbolic-ref with master fallback)
- Additional context in the PR body beyond the two required headings
</rigidity_level>

<when_to_use>
**Activated by hook:** This skill is mentioned in the `[bd-event]` hook message when `bd done` or `bd close` is run. If the item being closed is an epic and you are on a feature branch, use this skill to create a PR.

**Manual invocation:** User calls `/uwm-classic-sdlc:create-pr` explicitly when ready to submit work for review.

**Use when ALL of these are true:**
1. You are on a feature branch (not main/master)
2. The branch has commits that diverge from the target branch
3. Development work is complete and ready for review

**Do NOT use when:**
- You are on main or master branch
- There are no commits to review (branch matches target)
- The user has already created a PR manually
- The user explicitly says they don't want a PR
</when_to_use>

<the_process>

## Step 1: Verify Branch Safety

Check that you are NOT on main/master:

```bash
git branch --show-current
```

**If the current branch is `main` or `master`:** Stop immediately. Report: "Cannot create a PR from the default branch. Switch to a feature branch first."

---

## Step 2: Determine Repository Context

Parse the git remote URL to extract projectKey and repositorySlug:

```bash
git remote get-url origin
```

**SSH format:** `ssh://git@code.uwm.com:7999/{projectKey}/{repoSlug}.git`
- Extract the path after `:7999/`
- Split on `/` to get projectKey and repoSlug
- Strip `.git` suffix from repoSlug
- Example: `ssh://git@code.uwm.com:7999/EH/allin-ui.git` → projectKey=`EH`, repoSlug=`allin-ui`
- Personal repos: `ssh://git@code.uwm.com:7999/~ykopstein/cy-claude-mcp.git` → projectKey=`~ykopstein`, repoSlug=`cy-claude-mcp`

**HTTPS format:** `https://code.uwm.com/scm/{projectKey}/{repoSlug}.git`
- Extract the path after `/scm/`
- Split on `/` to get projectKey and repoSlug
- Strip `.git` suffix from repoSlug
- Example: `https://code.uwm.com/scm/EH/allin-ui.git` → projectKey=`EH`, repoSlug=`allin-ui`

**If the URL doesn't match either format:** Stop and report: "Cannot parse git remote URL. Please provide projectKey and repositorySlug manually."

---

## Step 3: Determine Branches

**Source branch** (the branch with your changes):
```bash
git branch --show-current
```

**Target branch** (where the PR merges into):
```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
```

If `symbolic-ref` fails (remote HEAD not set), default to `master`.

---

## Step 4: Gather PR Content

**Title:** Use the bd epic title if an epic is associated with this work. Otherwise, derive a title from the branch name (e.g., `feature/add-auth` → "Add auth").

**Original prompt:** The verbatim first user message that started this development session. This is the text the user typed to kick off the work. Copy it exactly — do not summarize or rephrase.

**Commit messages:**
```bash
git log {targetBranch}..HEAD --format="%s"
```

If no commits diverge from the target branch, note "No new commits" under Claude notes.

---

## Step 5: Format PR Body

Build the PR description with these exact headings:

```markdown
#### Original prompt
{verbatim initial user request — the exact text the user typed}

##### Claude notes
- {commit message 1}
- {commit message 2}
- {commit message 3}
```

Each commit message becomes a bullet point under Claude notes. List them in chronological order (oldest first).

---

## Step 6: Create the PR

Call the Bitbucket MCP tool:

```
Use mcp__plugin_uwm-enterprise-mcp_bitbucket__create_pull_request
projectKey: {extracted projectKey}
repositorySlug: {extracted repoSlug}
title: {PR title}
sourceBranch: {current branch name}
targetBranch: {target branch name}
description: {formatted PR body from Step 5}
```

---

## Step 7: Report

On success, report: "Created PR #{id}: {title}\nURL: {url}"

Then continue with any remaining work — PR creation should be minimally disruptive.

</the_process>

<critical_rules>

## Rules That Have No Exceptions

1. **Always include `#### Original prompt` heading** — The verbatim user text, not a summary
2. **Always include `##### Claude notes` heading** — Commit messages as bullet points
3. **Always parse git remote** — Never hardcode project keys or repo slugs
4. **Never create PR from main/master** — Check current branch before proceeding
5. **Never add reviewers** — Bitbucket's default reviewer rules handle reviewer assignment
6. **Push before creating PR** — Ensure the source branch exists on the remote

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
- The jira-sync-hook.sh hook (fires on PostToolUse for Bash commands containing `bd done` or `bd close`)
- The hook outputs a `[bd-event]` message that mentions this skill for epic closures
- Direct user invocation via `/uwm-classic-sdlc:create-pr`

**This skill uses these MCP tools (from uwm-enterprise-mcp plugin):**
- `mcp__plugin_uwm-enterprise-mcp_bitbucket__create_pull_request` — Create the Bitbucket PR

**Prerequisites:**
- The `uwm-enterprise-mcp` plugin must be installed (provides Bitbucket MCP tools)
- A valid `BITBUCKET_TOKEN` must be configured in `~/.uwm-mcp-shared/config.json`
- The source branch must be pushed to the remote before creating the PR

</integration>
