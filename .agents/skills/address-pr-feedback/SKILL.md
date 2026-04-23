---
name: address-pr-feedback
description: Use when responding to code review comments on a Bitbucket PR — walks through each comment with Socratic discussion, researches when needed, makes code changes, pushes, and posts threaded replies.
---

<skill_overview>
Respond to code review feedback on a Bitbucket pull request you authored. The skill loads all reviewer comments, presents them one-by-one for Socratic discussion using AskUserQuestion, dispatches research agents when needed, accumulates code changes, then batch-commits/pushes and posts threaded replies to each comment.

This is the **author's response workflow** — the complement to `review-bitbucket-pr` (reviewer's workflow) and `create-pr` (PR creation).

**PR lifecycle in uwm-classic-sdlc:** `create-pr` → `review-bitbucket-pr` → **`address-pr-feedback`**
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM — Comment iteration and threaded replies are rigid. Research depth and code change approach adapt to context.

**Rigid (no exceptions):**
- Always use `get_pull_request_comments` to load comments (abort if it fails)
- Always present comments one-by-one with AskUserQuestion
- Always post threaded replies using `parentCommentId` (never summary-only)
- Always batch code changes into a single commit+push at the end
- Never skip a comment without presenting it to the user

**Flexible (adapt to context):**
- Research depth per comment (quick lookup vs. full agent dispatch)
- AskUserQuestion option labels and descriptions (adapt to comment type)
- Commit message format (adapt to volume of changes)
- Whether to checkout the PR branch (skip if already on it)
</rigidity_level>

<quick_reference>
| Step | Action | Deliverable |
|------|--------|-------------|
| 1 | Resolve PR | projectKey, repoSlug, prNumber, PR state |
| 2 | Load comments + diff | Comment list with IDs, unified diff |
| 3 | Iterate comments (one-by-one) | Decision per comment (accept/reject/research/skip) |
| 4 | Execute code changes | Modified files on PR branch |
| 5 | Commit + push | Single commit with summary of all changes |
| 6 | Post threaded replies | One reply per comment via parentCommentId |
| 7 | Summary | Decision table printed to user |
</quick_reference>

<when_to_use>
**Use when:**
- You authored a PR and received review comments
- User says "respond to PR feedback", "address review comments", "handle PR comments"
- User provides a Bitbucket PR URL and asks to work through comments

**Do NOT use when:**
- You are reviewing someone else's PR (use `review-bitbucket-pr`)
- You are creating a new PR (use `create-pr`)
- The PR is already merged (inform the user and stop)
- There are no comments to address
</when_to_use>

<the_process>

## Step 1: Resolve the PR

**If an argument was provided**, parse it as a Bitbucket PR URL or `PROJECT/REPO/NUMBER` identifier:

**URL format:** `https://code.uwm.com/projects/{projectKey}/repos/{repoSlug}/pull-requests/{prNumber}`
- Extract `projectKey`, `repoSlug`, `prNumber` from the URL path segments.

**Short format:** `PROJECT/REPO/NUMBER` (e.g., `CYBORG/cy-meridian-apim-infrastructure/1`)
- Split by `/` to extract the three components.

**If no argument was provided**, auto-detect from the current git context:

```bash
git remote get-url origin
git branch --show-current
```

Parse the remote URL to get `projectKey` and `repoSlug`:

| Format | Pattern |
|--------|---------|
| SSH | `ssh://git@code.uwm.com:7999/{key}/{slug}.git` |
| SSH (personal) | `ssh://git@code.uwm.com:7999/~{user}/{slug}.git` |
| HTTPS | `https://code.uwm.com/scm/{key}/{slug}.git` |

Then find the open PR for the current branch using `mcp__plugin_uwm-enterprise-mcp_bitbucket__list_pull_requests`:
- Pass `projectKey`, `repositorySlug`, `state: "OPEN"`
- Find the PR whose source branch matches the current branch
- If no matching PR found: stop and report "No open PR found for branch '{branch}'. Provide a PR URL as argument."

**Fetch PR details** using `mcp__plugin_uwm-enterprise-mcp_bitbucket__get_pull_request_details`:
- If the PR is **MERGED**: stop and report "PR #{prNumber} is already merged. Nothing to address."
- If the PR is **DECLINED**: warn but continue (user may want to respond before reopening).
- Display PR summary:
  ```
  Addressing feedback on PR #{prNumber}: {title}
  Branch: {sourceBranch} → {targetBranch}
  State: {state}
  Reviewers: {reviewer names and approval status}
  ```

---

## Step 2: Load Comments and Diff

**Load comments** using `mcp__plugin_uwm-enterprise-mcp_bitbucket__get_pull_request_comments`:
- If the API call fails: **abort**. Report: "Cannot load PR comments (API returned an error). Try again or check Bitbucket access."
- Do NOT fall back to activities or post general comments. Threaded replies require comment IDs.

**Parse the response.** The tool returns markdown with this structure:
```
Found {n} comments on PR #{id}:

**Comment #{id}** by {author} ({date})
{comment text, truncated to 200 chars}
📍 Inline: {path}:{line} ({lineType})        ← present only for inline comments
  └─ **Reply #{id}** by {author} ({date})    ← threaded replies, indented
     {reply text}
```

Extract from each top-level `**Comment #{id}**` entry:
- `id` — The comment ID (numeric, from `#{id}`) — used as `parentCommentId` for threaded replies
- `author` — The reviewer name
- `text` — The comment body (may be truncated to 200 chars)
- **Inline anchor** (if `📍 Inline:` line is present):
  - `path` — File path (e.g., `src/main.ts`)
  - `line` — Line number in the file
  - `lineType` — One of `ADDED`, `REMOVED`, or `CONTEXT`
- **No anchor** = general comment (not tied to a specific file/line)

**Classify each comment:**

| Type | Detection | Example |
|------|-----------|---------|
| **Inline** | Has `📍 Inline: {path}:{line}` | Comment on a specific code line |
| **General** | No `📍 Inline:` line | PR-level feedback, summary, or question |

**Filter comments** to only those requiring a response:
- Exclude comments authored by the PR author (you don't respond to your own comments)
- Only process top-level comments (lines matching `**Comment #{id}**`), not threaded replies (`└─ **Reply #...`)
- Include comments that have tasks attached (these need resolution)
- Sort: inline comments first (grouped by file path, then line number), then general comments last

**Count and report:**
```
Found {N} reviewer comments from {reviewer names}.
  - {X} inline (on specific code lines)
  - {Y} general (PR-level)
```

If no comments found: report "No reviewer comments to address." and stop.

**Load diff** using `mcp__plugin_uwm-enterprise-mcp_bitbucket__get_pull_request_diff`:
- Store for code context when presenting inline comments.
- If diff fails: continue without it (comments can still be addressed, just without surrounding code context).

**Checkout the PR branch** if not already on it:
```bash
git checkout {sourceBranch}
git pull origin {sourceBranch}
```

---

## Step 3: Iterate Comments (Socratic Discussion)

For each comment, present it to the user with context and ask what to do. **One comment at a time.**

### Presenting a Comment

**For inline comments** (have `📍 Inline: {path}:{line}`):

1. Read the referenced file from the local checkout to get the actual source code:
   ```bash
   sed -n '{line-3},{line+3}p' {path}
   ```
2. Present with code context:
   ```
   **Comment {N}/{total} — {reviewer name}**
   📍 `{path}:{line}`

   ```{language}
   {lines line-3 through line+3, with line {line} highlighted with ← marker}
   ```

   > {full comment text}
   ```

**For general comments** (no inline anchor):

```
**Comment {N}/{total} — {reviewer name}**

> {full comment text}
```

If the comment text was truncated (200 char limit from API), and the full text is needed for understanding, use `get_pull_request_diff` with `filePath` to get more context, or ask the user if the truncated version is sufficient.

### AskUserQuestion Options

Adapt the options to the comment type, but always include these core choices:

```
AskUserQuestion:
  question: "{reviewer name} says: '{truncated comment}' — What do you want to do?"
  header: "Comment {N}/{total}"
  options:
    - label: "Accept — make the change"
      description: "Agree with the feedback and modify the code accordingly"
    - label: "Reject — explain why"
      description: "Disagree with the feedback — I'll ask you for the reason to include in the reply"
    - label: "Research first"
      description: "Dispatch a research agent (codebase or internet) to validate the claim before deciding"
    - label: "Already addressed"
      description: "This was already fixed in a previous commit or another change — reply noting that"
```

### Handling Each Decision

**Accept:**
- Ask the user what change to make (or propose one based on the comment)
- Record the change for batch execution in Step 4
- Record the reply text: "Fixed in commit {hash} — {description of change}"

**Reject:**
- Ask the user: "What's your reasoning?" (free text or AskUserQuestion with common reasons)
- Record the reply text with the explanation

**Research:**
- Dispatch `hyperpowers:codebase-investigator` or `hyperpowers:internet-researcher` as appropriate
- Present findings to the user
- Re-ask the Accept/Reject question with the new information

**Already addressed:**
- Ask which commit or change addresses it
- Record the reply text: "Already addressed in {commit/change description}"

**Record each decision** in a tracking table:

| # | Reviewer | Comment (truncated) | Decision | Reply | Code Change |
|---|----------|---------------------|----------|-------|-------------|

---

## Step 4: Execute Code Changes

After all comments have been discussed:

1. **Apply all accepted code changes** to the files on the PR branch
2. **Stage changed files** by name (not `git add -A`)
3. **Commit** by invoking `/uwm-cyborg-sdlc:commit` to generate the commit message from the staged diff. The commit skill will produce a Conventional Commits-compliant message with an Implemented-By trailer. Ensure the JIRA key is included as an issue reference prefix.

4. **Push to the remote:**
```bash
git push origin {sourceBranch}
```

If there are no code changes (all comments were rejected or already addressed), skip this step.

---

## Step 5: Post Threaded Replies

For each comment that was discussed (not skipped), post a threaded reply:

```
Use mcp__plugin_uwm-enterprise-mcp_bitbucket__add_pull_request_comment
  projectKey: {projectKey}
  repositorySlug: {repoSlug}
  pullRequestId: {prNumber}
  text: {reply text from Step 3}
  parentCommentId: {comment.id from Step 2}
```

**Reply format by decision type:**

- **Accept:** "Fixed in `{commit_hash}` — {description of what changed}."
- **Reject:** "{explanation of why the feedback doesn't apply or why the current approach is correct}."
- **Already addressed:** "Already addressed — {description of existing fix}."
- **Research result:** "{research findings summary}. Based on this, {action taken}."

**If a reply fails to post:** log a warning and continue. Do not abort.

**Resolve tasks:** If a comment has an attached task and the decision was Accept or Already Addressed, resolve it:
```
Use mcp__plugin_uwm-enterprise-mcp_bitbucket__update_pull_request_task
  taskId: {task.id}
  state: "RESOLVED"
```

---

## Step 6: Summary

Print the decision table to the user:

```
## PR #{prNumber} Feedback Summary

| # | Reviewer | Comment | Decision | Reply Posted |
|---|----------|---------|----------|--------------|
| 1 | {name}   | {text}  | Accept   | Yes          |
| 2 | {name}   | {text}  | Reject   | Yes          |
| ...

Changes: {N} file(s) modified, committed as {commit_hash}
Replies: {N} posted, {N} failed
Tasks resolved: {N}
```

</the_process>

<critical_rules>

## Rules That Have No Exceptions

1. **Abort if `get_pull_request_comments` fails** — Threaded replies require comment IDs. No comment IDs = no threaded replies = don't proceed.
2. **One comment at a time** — Never batch-present comments. Each gets its own AskUserQuestion round.
3. **Always use `parentCommentId`** — Every reply must thread under the original comment. Never post standalone comments as responses.
4. **Batch commit at the end** — Accumulate all code changes, then commit+push once. Never commit after each individual comment.
5. **Never skip a comment silently** — Every reviewer comment must be presented to the user, even if it seems trivial.
6. **Never auto-decide** — The user decides what to do with each comment. The skill proposes options but never acts without the user choosing.
7. **Parse git remote for repo context** — Never hardcode project keys or repo slugs. Always extract from `git remote get-url origin`.

## Comment Filtering

- **Include:** Top-level comments from reviewers (not the PR author)
- **Include:** Comments with tasks (these need resolution)
- **Exclude:** The PR author's own comments
- **Exclude:** Nested replies (only process the parent comment)
- **Exclude:** PR summary/description comments from automated review tools (process only human reviewer comments and the substantive auto-review findings, not the summary headers)

## Research Dispatch

When the user chooses "Research first":
- Use `hyperpowers:codebase-investigator` for questions about existing code, patterns, or conventions
- Use `hyperpowers:internet-researcher` for questions about external APIs, library behavior, or documentation
- Present research results, then re-ask the Accept/Reject question
- Never research without the user requesting it

</critical_rules>

<integration>

**This skill is called by:**
- Direct user invocation via `/uwm-classic-sdlc:address-pr-feedback` or `/address-pr-feedback`
- Optionally with argument: `/address-pr-feedback CYBORG/cy-meridian-apim-infrastructure/1` or a full Bitbucket PR URL

**This skill uses these MCP tools (from uwm-enterprise-mcp plugin):**
- `mcp__plugin_uwm-enterprise-mcp_bitbucket__get_pull_request_details` — Get PR state, branches, reviewers
- `mcp__plugin_uwm-enterprise-mcp_bitbucket__get_pull_request_comments` — Load all comments with IDs (required)
- `mcp__plugin_uwm-enterprise-mcp_bitbucket__get_pull_request_diff` — Get code diff for context
- `mcp__plugin_uwm-enterprise-mcp_bitbucket__add_pull_request_comment` — Post threaded replies via parentCommentId
- `mcp__plugin_uwm-enterprise-mcp_bitbucket__update_pull_request_task` — Resolve tasks on accepted comments
- `mcp__plugin_uwm-enterprise-mcp_bitbucket__list_pull_requests` — Find open PR for current branch (auto-detect mode)

**This skill dispatches these agents (on user request):**
- `hyperpowers:codebase-investigator` — Research existing code patterns
- `hyperpowers:internet-researcher` — Research external docs, APIs, libraries

**Prerequisites:**
- The `uwm-enterprise-mcp` plugin must be installed (provides Bitbucket MCP tools)
- A valid `BITBUCKET_TOKEN` must be configured in `~/.uwm-mcp-shared/config.json`
- The PR branch must be checked out locally (or the skill will checkout for you)

**Related skills:**
- `uwm-classic-sdlc:create-pr` — Creates the PR (upstream in lifecycle)
- `uwm-classic-sdlc:review-bitbucket-pr` — Reviews someone else's PR (complementary workflow)

</integration>
