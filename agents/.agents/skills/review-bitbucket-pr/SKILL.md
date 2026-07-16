---
name: review-bitbucket-pr
description: "Review a Bitbucket PR using specialized agents and post findings as inline comments"
---

<skill_overview>
Review a Bitbucket pull request using specialized pr-review-toolkit agents and post findings as inline Bitbucket comments. Dispatches up to 7 parallel agents — each analyzing a different aspect (code quality, tests, comments, errors, types, simplification, requirements validation) — then posts inline findings and a summary comment.

This is the **reviewer's workflow** — the complement to `create-pr` (author creates PR) and `address-pr-feedback` (author responds to review).

**PR lifecycle in uwm-classic-sdlc:** `create-pr` → **`review-bitbucket-pr`** → `address-pr-feedback`
</skill_overview>

<rigidity_level>
HIGH FREEDOM — The 5-phase process and finding format are rigid. Aspect selection and agent dispatch adapt to context.

**Rigid (no exceptions):**
- Always parse PR identifier as PROJECT/REPO/NUMBER
- Always create a git worktree for isolated checkout
- Always clean up worktree in Phase 5 (even on failure)
- Always use [SEVERITY] file:LINE format for findings
- Always post summary comment after inline comments

**Flexible (adapt to context):**
- Aspect selection (default all, user can specify subset)
- Skip `types` aspect if no typed language files changed
- Truncate diff for large PRs (agents read files directly)
- Skip `requirements` aspect if no Jira key found in branch name, title, or description
</rigidity_level>

<quick_reference>
| Aspect     | Agent                  | Analyzes                                    |
|------------|------------------------|---------------------------------------------|
| `code`     | code-reviewer          | Project guidelines, bugs, code quality      |
| `tests`    | pr-test-analyzer       | Test coverage, quality, critical gaps        |
| `comments` | comment-analyzer       | Comment accuracy, rot, documentation         |
| `errors`   | silent-failure-hunter  | Silent failures, catch blocks, error logging |
| `types`    | type-design-analyzer   | Type encapsulation, invariants, design       |
| `simplify` | code-simplifier        | Code clarity, readability, standards         |
| `requirements` | requirements-validator | AC compliance, requirement coverage, epic context |
</quick_reference>

<when_to_use>
**Use when:**
- You are reviewing someone else's PR
- User provides a PR identifier and asks for a code review
- User says "review this PR", "check this PR", "analyze PR"

**Do NOT use when:**
- You authored the PR and are responding to feedback (use `address-pr-feedback`)
- You are creating a new PR (use `create-pr`)
</when_to_use>

<the_process>

**Arguments:** "$ARGUMENTS"

## Phase 1: Parse Arguments & Fetch PR Context

1. **Parse the arguments string** "$ARGUMENTS" into components:
   - Split by whitespace. The first token is the PR identifier in format `PROJECT/REPO/NUMBER` (e.g., `EH/allin-ui/123`).
   - Split the PR identifier by `/` to extract: `projectKey`, `repoSlug`, `prNumber`.
   - If the PR identifier does not contain exactly 2 `/` separators, or if the last segment is not a number, stop and show this usage message:
     ```
     Invalid PR identifier. Expected format: PROJECT/REPO/NUMBER
     Examples:
       /uwm-classic-sdlc:review-bitbucket-pr EH/allin-ui/123
       /uwm-classic-sdlc:review-bitbucket-pr EH/allin-ui/123 code tests
       /uwm-classic-sdlc:review-bitbucket-pr EH/allin-ui/123 all parallel
     ```
   - Remaining tokens after the PR identifier are aspect selectors and/or the `parallel` keyword.

2. **Parse aspect selectors** from the remaining tokens:
   - Valid aspects: `code`, `tests`, `errors`, `types`, `comments`, `simplify`, `requirements`, `all`
   - The token `parallel` is a mode keyword, not an aspect — extract it separately.
   - If no aspects specified, default to `all`.
   - If `all` is specified, use all 7 aspects.
   - If an unrecognized token appears (not an aspect and not `parallel`), warn the user and continue with recognized aspects.
   - Parallel mode is the default. The `parallel` keyword is accepted for explicitness but has no behavioral change.

3. **Fetch PR details** using the `mcp__plugin_uwm-enterprise-mcp_bitbucket__get_pull_request_details` tool:
   - Pass `projectKey`, `repositorySlug` (the repoSlug), and `pullRequestId` (the prNumber as integer).
   - If the tool returns an error (PR not found, permissions issue): report the error and stop.
   - Extract from the response:
     - `title` — the PR title
     - `state` — OPEN, MERGED, or DECLINED
     - `fromRef.displayId` — source branch name
     - `toRef.displayId` — target branch name
     - `fromRef.repository.slug` — repository slug (for clone)
     - The list of changed files (paths)
   - If `state` is MERGED or DECLINED: warn the user ("This PR is {state}. Reviewing anyway — code is still accessible.") and continue.

4. **Fetch PR diff** using the `mcp__plugin_uwm-enterprise-mcp_bitbucket__get_pull_request_diff` tool:
   - Pass `projectKey`, `repositorySlug`, and `pullRequestId`.
   - Store the unified diff output.
   - If the diff is larger than 50,000 characters, note that it will be truncated when passed to agents. Agents will read files directly from the worktree instead.
   - If the PR has more than 100 changed files, warn the user: "This PR has {N} changed files. Consider reviewing specific aspects (e.g., `code tests`) for a more focused review."

5. **Discover linked Jira issue** (required for `requirements` aspect):
   - Extract a Jira issue key from the **source branch name** (`fromRef.displayId` from step 3) using the regex `([A-Z]+-\d+)`. Use the **first match** if multiple keys are present (e.g., `feature/EH-1234-merge-PROJ-567` → `EH-1234`).
   - If no match in branch name, try the **PR title** (`title` from step 3) with the same regex.
   - If no match in title, try the **PR description** (`description` field from step 3 response, may be null — skip safely if null) with the same regex.
   - If no match found anywhere:
     - Warn the user: "No Jira key found in branch name, PR title, or description. Skipping requirements validation."
     - Remove `requirements` from the selected aspects list (do NOT fail the review).
     - Set `jiraIssue = null` and skip the rest of this step.
   - If a Jira key is found, fetch the issue using `mcp__plugin_uwm-enterprise-mcp_jira__get_issue`:
     - Pass `issueKey` = the extracted Jira key (e.g., `"EH-1234"`).
     - If the tool returns an error (issue not found, permissions error):
       - Warn the user: "Jira issue {key} could not be fetched: {error}. Skipping requirements validation."
       - Remove `requirements` from selected aspects. Set `jiraIssue = null`.
     - If successful, extract the epic link field `customfield_10014` (needed for epic fetch below). Store the **full issue response** as `jiraIssue` — the requirements-validator agent will receive the complete response and identify acceptance criteria itself.
   - If the issue has an epic link (`customfield_10014` is not null):
     - Fetch the epic using `mcp__plugin_uwm-enterprise-mcp_jira__get_epic`:
       - Pass `epicKey` = the value of `customfield_10014`.
     - If the epic fetch fails: warn "Epic {epicKey} could not be fetched. Proceeding without epic context." and set `epicContext = null`.
     - If successful, extract: epic `summary`, epic `description`, and the list of child issues (each with `key`, `summary`, `status`).
   - Store `jiraIssue` and `epicContext` for use in Phase 3.

6. **Display PR summary** to the user:
   ```
   Reviewing PR #{prNumber}: {title}
   Branch: {sourceBranch} -> {targetBranch}
   State: {state}
   Jira: {jiraKey} - {jiraSummary} (or "No Jira issue linked")
   Changed files: {count}
   Aspects: {selected aspects}
   ```

## Phase 2: Setup Local Environment

1. **Clone the repository** using the `mcp__plugin_uwm-enterprise-mcp_workspace-awareness__ensure_repository_access` tool:
   - Pass `repositoryName` = the repoSlug, `targetFolder` = `"pr-reviews"`.
   - Optionally pass `projectKey` if available.
   - Note the repository clone path from the response. This is the base path for the git worktree.
   - The clone path will typically be at `$DEV_CODE_ROOT/{repoSlug}`.

2. **Determine the clone path** from the ensure_repository_access response. Look for the local filesystem path where the repo was cloned.

3. **Fetch the source branch** so it is available locally:
   ```bash
   git -C <clone-path> fetch origin <source-branch>
   ```
   - If the fetch fails (branch deleted, network error): report "Source branch '{sourceBranch}' could not be fetched. It may have been deleted. Cannot proceed with review." and skip to Phase 5 (cleanup).

4. **Check for stale worktree** from a previous run:
   - The worktree path is: `<clone-path>-worktree-pr-<prNumber>`
   - Check if this path already exists:
     ```bash
     ls <worktree-path> 2>/dev/null && echo "EXISTS" || echo "NOT_EXISTS"
     ```
   - If it exists, remove the stale worktree before creating a new one:
     ```bash
     git -C <clone-path> worktree remove <worktree-path> --force
     ```

5. **Create git worktree** for isolated checkout of the source branch:
   ```bash
   git -C <clone-path> worktree add <worktree-path> origin/<source-branch> --detach
   ```
   - Verify the worktree was created:
     ```bash
     ls <worktree-path>
     ```
   - If worktree creation fails: report the error and skip to Phase 5 (cleanup).

## Phase 3: Dispatch Review Agents

1. **Map aspects to agent types.** Each aspect corresponds to a pr-review-toolkit agent:

   | Aspect     | Agent subagent_type                        |
   |------------|--------------------------------------------|
   | `code`     | `pr-review-toolkit:code-reviewer`          |
   | `tests`    | `pr-review-toolkit:pr-test-analyzer`       |
   | `comments` | `pr-review-toolkit:comment-analyzer`       |
   | `errors`   | `pr-review-toolkit:silent-failure-hunter`  |
   | `types`    | `pr-review-toolkit:type-design-analyzer`   |
   | `simplify`      | `pr-review-toolkit:code-simplifier`        |
   | `requirements`  | `pr-review-toolkit:requirements-validator`  |

   - For `types`: only include this agent if the changed files contain likely type definition files (`.ts`, `.tsx`, `.cs`, `.java`, `.go`, `.rs` extensions). Skip if changes are only config, markdown, or similar.
   - For `requirements`: only include this agent if `jiraIssue` was successfully fetched in Phase 1 step 5. Skip if `jiraIssue` is null.

2. **Construct the agent prompt.** Each agent receives the same base prompt, customized with the PR context. Use this exact prompt template for every agent:

   ```
   You are reviewing Bitbucket PR #{prNumber}: "{title}"
   Branch: {sourceBranch} -> {targetBranch}

   The code is checked out at: {worktree-path}

   Changed files:
   {list each changed file path, one per line}

   Diff summary (may be truncated — read files directly for full content):
   {diff content, truncated to first 50000 chars if larger}

   INSTRUCTIONS:
   - Focus your analysis ONLY on the changed files listed above.
   - Read the actual files from the worktree path for full context.
   - For each finding, output in this EXACT format on its own line:
     [SEVERITY] file/path.ext:LINE_NUMBER - Description of the finding
   - SEVERITY must be one of: CRITICAL, IMPORTANT, SUGGESTION
   - LINE_NUMBER must refer to the line in the current (new) version of the file.
   - If you cannot determine a specific line number, use line 0.
   - At the end of your analysis, list any STRENGTHS you observed in the code, prefixed with [STRENGTH].
   - Example findings:
     [CRITICAL] src/auth/login.ts:42 - SQL injection vulnerability in user input handling
     [IMPORTANT] src/utils/helpers.ts:15 - Missing null check before accessing property
     [SUGGESTION] src/components/Form.tsx:88 - Consider extracting this logic into a custom hook
     [STRENGTH] Good use of TypeScript generics for type-safe API responses
   ```

   **For the `requirements` agent only**, append the following after the base prompt's INSTRUCTIONS section:

   ```
   JIRA STORY CONTEXT (full issue response):
   {jiraIssue — paste the complete JSON response from get_issue}

   {if epicContext is not null:}
   EPIC CONTEXT:
   Epic: {epicKey} - {epicSummary}
   Epic Description: {epicDescription}
   Sibling Subtasks:
   {for each child issue: - {childKey}: {childSummary} ({childStatus})}
   {end if}

   REQUIREMENTS VALIDATION INSTRUCTIONS:
   1. Locate the acceptance criteria from the Jira issue response above. Check these sources in order:
      a. Look for a dedicated "Acceptance Criteria" custom field — many Jira projects store ACs in a custom field (the field ID varies per project, e.g., `customfield_12345`). Scan all fields in the response for one whose content looks like acceptance criteria.
      b. Parse the `description` field for acceptance criteria patterns:
         - Numbered or bulleted lists
         - Checkboxes ([ ] or [x])
         - Lines starting with "AC:", "AC#", "Acceptance Criteria"
         - Given/When/Then (Gherkin) format
         - "As a... I want... So that..." format
      c. If no recognizable ACs found in any field, treat the entire description as the requirement specification and output [SUGGESTION] NONE:0 - No structured acceptance criteria found in Jira issue {jiraKey}. Validating against description as a whole.
   2. For each acceptance criterion found:
      - Read the changed files from the worktree path to determine if the PR diff implements it
      - If NOT implemented: output [CRITICAL] NONE:0 - AC '{criterion text}' has no corresponding implementation in the diff
      - If PARTIALLY implemented: output [IMPORTANT] file/path.ext:LINE_NUMBER - AC '{criterion text}' is partially implemented but missing {what's missing}
      - If FULLY implemented: note for [STRENGTH] reporting
   3. Check for scope creep: code changes that don't map to any stated requirement. Output as [SUGGESTION] file/path.ext:LINE_NUMBER - This change does not map to any stated acceptance criterion — verify it is intentional
   4. If epic context is provided, check if any sibling subtasks appear relevant to this PR's changes (e.g., related functionality being modified). Note as [SUGGESTION] NONE:0 - Sibling subtask {childKey} '{childSummary}' may be relevant to changes in this PR
   5. Report [STRENGTH] when acceptance criteria are well-covered (e.g., [STRENGTH] All N acceptance criteria from {jiraKey} are addressed in the implementation)
   ```

3. **Dispatch all selected agents in parallel** using the Agent tool. Send a single message with multiple Agent tool calls, one per agent:
   - `description`: "PR review: {aspect}" (e.g., "PR review: code")
   - `subagent_type`: the agent type from the mapping table above
   - `prompt`: the constructed prompt from step 2

4. **Collect results.** Wait for all agents to complete.
   - If an agent fails or crashes: note which agent failed and continue with the results from other agents.
   - If ALL agents fail: note all failures and proceed to Phase 4 to post a summary comment about the failures, then skip to Phase 5 for cleanup.

## Phase 4: Post Bitbucket Comments

1. **Parse agent output.** For each agent's result, extract findings by scanning for lines matching the pattern:
   ```
   [SEVERITY] file/path:LINE - description
   ```
   - Regex pattern: `\[(CRITICAL|IMPORTANT|SUGGESTION)\]\s+(\S+?):(\d+)\s+-\s+(.+)`
   - Also extract `[STRENGTH]` lines: `\[STRENGTH\]\s+(.+)`
   - Lines that don't match either pattern: ignore (they are agent reasoning/context).

2. **Post inline comments** for each finding where the line number is greater than 0. Use the `mcp__plugin_uwm-enterprise-mcp_bitbucket__add_pull_request_comment` tool:
   - `projectKey`: the project key from Phase 1
   - `repositorySlug`: the repo slug from Phase 1
   - `pullRequestId`: the PR number from Phase 1
   - `text`: Format as `**[{agent-short-name}] [{SEVERITY}]**: {description}`
     - Agent short names: code-reviewer -> Code, pr-test-analyzer -> Tests, comment-analyzer -> Comments, silent-failure-hunter -> Errors, type-design-analyzer -> Types, code-simplifier -> Simplify, requirements-validator -> Requirements
   - `filePath`: the file path from the finding (relative to repo root)
   - `line`: the line number from the finding
   - `lineType`: `"ADDED"` (default for findings on new/changed code)
   - If a comment posting fails (line no longer exists, permissions error, etc.): log a warning about the failed comment and continue with the next finding. Do NOT stop the workflow.
   - If a finding has line number 0: do not post as inline comment. Include it in the summary comment instead.

3. **Compose the summary comment.** Group all findings by severity and format as markdown:

   ```markdown
   ## PR Review Summary

   **PR**: #{prNumber} - {title}
   **Branch**: {sourceBranch} -> {targetBranch}
   **Reviewed by**: {comma-separated list of agent short names that ran}

   ### Critical Issues ({count})
   {for each CRITICAL finding:}
   - **[{agent-short-name}]** {description} — `{file}:{line}`

   ### Important Issues ({count})
   {for each IMPORTANT finding:}
   - **[{agent-short-name}]** {description} — `{file}:{line}`

   ### Suggestions ({count})
   {for each SUGGESTION finding:}
   - **[{agent-short-name}]** {description} — `{file}:{line}`

   ### Strengths
   {for each STRENGTH:}
   - {description}

   {if any agents failed:}
   ### Agent Errors
   {for each failed agent:}
   - **{agent-short-name}**: {error description}

   {if any inline comments failed to post:}
   ### Findings Not Posted Inline
   {for each failed inline comment:}
   - **[{agent-short-name}] [{SEVERITY}]** {description} — `{file}:{line}` (reason: {error})

   ---
   *Automated review by Claude Code — uwm-classic-sdlc plugin*
   ```

   - If a severity category has 0 findings, still include the heading with "(0)" to show it was checked.
   - If no strengths were found, omit the Strengths section.
   - If no agents failed, omit the Agent Errors section.
   - If all inline comments posted successfully, omit the Findings Not Posted Inline section.

4. **Post the summary comment** as a general PR comment using the `mcp__plugin_uwm-enterprise-mcp_bitbucket__add_pull_request_comment` tool:
   - `projectKey`, `repositorySlug`, `pullRequestId`: same as above
   - `text`: the formatted summary markdown
   - Do NOT pass `filePath`, `line`, or `lineType` — this is a general comment.

## Phase 5: Cleanup

This phase MUST always run, even if previous phases failed or were skipped.

1. **Remove the git worktree:**
   ```bash
   git -C <clone-path> worktree remove <worktree-path> --force 2>&1 || true
   ```
   - If removal fails: warn the user and provide the manual cleanup command:
     ```
     Worktree cleanup failed. To clean up manually, run:
       rm -rf <worktree-path>
       git -C <clone-path> worktree prune
     ```

2. **Report completion** to the user with a summary:
   ```
   PR Review Complete for #{prNumber}: {title}
   - {critical_count} critical issue(s)
   - {important_count} important issue(s)
   - {suggestion_count} suggestion(s)
   - {inline_count} inline comment(s) posted to Bitbucket
   - {failed_count} comment(s) failed to post (included in summary)
   ```

</the_process>

<critical_rules>

## Rules That Have No Exceptions

1. **Always parse PR identifier as PROJECT/REPO/NUMBER** — Never assume project or repo
2. **Always create a git worktree** — Isolated checkout protects the user's working tree
3. **Always clean up worktree in Phase 5** — Even on failure, always attempt cleanup
4. **Always use [SEVERITY] file:LINE format** — Agents must output in this exact format
5. **Always post summary comment** — Even if all inline comments succeed, post the summary
6. **Never stop on a single failed inline comment** — Log warning and continue

## Usage Examples

**Full review (default — all aspects, parallel):**
```
/uwm-classic-sdlc:review-bitbucket-pr EH/allin-ui/123
```

**Specific aspects:**
```
/uwm-classic-sdlc:review-bitbucket-pr EH/allin-ui/123 code tests
/uwm-classic-sdlc:review-bitbucket-pr EH/allin-ui/123 errors types
/uwm-classic-sdlc:review-bitbucket-pr EH/allin-ui/123 simplify
```

**Requirements validation only:**
```
/uwm-classic-sdlc:review-bitbucket-pr EH/allin-ui/123 requirements
```

**Code + requirements validation:**
```
/uwm-classic-sdlc:review-bitbucket-pr EH/allin-ui/123 code requirements
```

</critical_rules>

<integration>

**This skill is called by:**
- Direct user invocation via `/uwm-classic-sdlc:review-bitbucket-pr` or `/review-bitbucket-pr`

**This skill uses these MCP tools (from uwm-enterprise-mcp plugin):**
- `mcp__plugin_uwm-enterprise-mcp_bitbucket__get_pull_request_details` — Get PR metadata
- `mcp__plugin_uwm-enterprise-mcp_bitbucket__get_pull_request_diff` — Get code diff
- `mcp__plugin_uwm-enterprise-mcp_bitbucket__add_pull_request_comment` — Post inline and summary comments
- `mcp__plugin_uwm-enterprise-mcp_bitbucket__get_pull_request_comments` — Check for existing review comments
- `mcp__plugin_uwm-enterprise-mcp_workspace-awareness__ensure_repository_access` — Clone/access repository
- `mcp__plugin_uwm-enterprise-mcp_jira__get_issue` — Fetch linked Jira story details
- `mcp__plugin_uwm-enterprise-mcp_jira__get_epic` — Fetch parent epic for context (sibling subtasks)

**This skill dispatches these agents:**
- `pr-review-toolkit:code-reviewer` — Code quality analysis
- `pr-review-toolkit:pr-test-analyzer` — Test coverage analysis
- `pr-review-toolkit:comment-analyzer` — Comment quality analysis
- `pr-review-toolkit:silent-failure-hunter` — Silent failure detection
- `pr-review-toolkit:type-design-analyzer` — Type design analysis
- `pr-review-toolkit:code-simplifier` — Code simplification analysis
- `pr-review-toolkit:requirements-validator` — Requirements/AC compliance analysis

**Prerequisites:**
- The `uwm-enterprise-mcp` plugin must be installed (provides Bitbucket MCP tools)
- A valid `BITBUCKET_TOKEN` must be configured in `~/.uwm-mcp-shared/config.json`

**Related skills:**
- `uwm-classic-sdlc:create-pr` — Creates the PR (upstream in lifecycle)
- `uwm-classic-sdlc:address-pr-feedback` — Author responds to review comments (downstream in lifecycle)

</integration>
