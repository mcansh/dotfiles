---
name: jira-sync
description: Use when a bd hook fires indicating a bd item was viewed, completed, or updated — synchronizes bd epics and tasks with corresponding Jira epics and stories using JIT (just-in-time) creation and status management.
---

<skill_overview>
Synchronize bd (beads) items with Jira. When you start work on a bd epic or task, this skill ensures a corresponding Jira epic or story exists. When work completes, it transitions the Jira item toward Done. All synchronization is JIT — Jira items are created when work begins, not when bd items are created. The skill reads the Jira project key from CLAUDE.md and uses dynamic transition discovery (no hardcoded status names).
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM — The JIT check pattern and CLAUDE.md config reading are rigid. The exact Jira field values and story formatting adapt to the project context.

**Rigid (no exceptions):**
- Read CLAUDE.md for Jira project key before any Jira operations
- If no Jira config in CLAUDE.md → silently skip (do not prompt, do not error)
- Use dynamic transition discovery via get_transitions (never hardcode status names)
- Include `[bd: ITEM-ID]` reference in Jira issue descriptions for mapping
- Search for existing Jira items before creating duplicates

**Flexible (adapt to context):**
- Story description formatting (adapt "As a / I want / So that" to the task context)
- Which transition to use (pick the best match from available transitions)
- Additional Jira fields (labels, components, priority) based on project conventions
</rigidity_level>

<when_to_use>
**Activated by hook:** This skill is called when the jira-sync-hook.sh fires after a bd command. The hook outputs a `[bd-event]` message that prompts you to consider using this skill.

**Use when ALL of these are true:**
1. A `[bd-event]` hook message appeared in the conversation
2. The project's CLAUDE.md contains a `## Jira` section with a `Project:` key
3. The bd item is an epic or a task (feature/bug) — not a generic note

**Do NOT use when:**
- No `## Jira` section exists in CLAUDE.md (silently skip)
- The bd operation is read-only (bd list, bd ready, bd dep)
- The bd item is not part of an SDLC workflow (e.g., one-off research notes)
</when_to_use>

<the_process>

## Step 1: Read Jira Configuration

Read the project's CLAUDE.md and look for a `## Jira` section:

```markdown
## Jira
Project: EH
```

**If no `## Jira` section exists:** Stop immediately. Do not prompt the user, do not create Jira items. Jira sync is not configured for this project.

**If found:** Extract the project key (e.g., `EH`) and proceed.

---

## Step 2: Determine the Sync Action

Based on the `[bd-event]` hook message that triggered this skill:

### Case A: Starting work on a bd epic (`bd show` on an epic)

1. Read the bd epic details to get:
   - Epic ID (e.g., `ucep-7o9`)
   - Epic title
   - Epic description/design summary

2. Search Jira for an existing epic with this bd reference:
   ```
   Use mcp__plugin_uwm-enterprise-mcp_jira__search_issues
   JQL: project = {PROJECT_KEY} AND issuetype = Epic AND description ~ "bd: {BD_EPIC_ID}"
   ```

3. **If Jira epic exists:**
   - Check its status. If it's in a "To Do" equivalent state and you're starting work, transition it toward "In Progress":
     ```
     Use mcp__plugin_uwm-enterprise-mcp_jira__get_transitions for the issue
     Find a transition whose target status suggests active work (e.g., contains "Progress", "Active", "Developing")
     Use mcp__plugin_uwm-enterprise-mcp_jira__transition_issue with that transition name
     ```
   - Report: "Jira epic {KEY} already exists and is now In Progress."

4. **If no Jira epic found:**
   - Create one:
     ```
     Use mcp__plugin_uwm-enterprise-mcp_jira__create_issue
     projectKey: {PROJECT_KEY}
     issueType: "Epic"
     summary: {BD_EPIC_TITLE}
     description: "{SHORT_DESCRIPTION}\n\n[bd: {BD_EPIC_ID}]"
     fields: {"customfield_10103": "{SHORT_EPIC_NAME}"}
     ```
     The `customfield_10103` field (Epic Name) is required when creating Epics. Derive the short epic name from the summary — keep it under 30 characters if possible.
   - Then transition it to In Progress (same transition discovery as above).
   - Report: "Created Jira epic {KEY} and transitioned to In Progress."

### Case B: Starting work on a bd task (`bd show` on a task/feature/bug)

1. Read the bd task details to get:
   - Task ID (e.g., `ucep-a05`)
   - Task title
   - Task description/design goal
   - Parent epic ID (from bd dependencies)

2. Find the parent Jira epic:
   - Search using the parent bd epic ID: `description ~ "bd: {BD_PARENT_EPIC_ID}"`
   - If no parent Jira epic found, create it first (follow Case A)

3. Search Jira for an existing story with this bd reference:
   ```
   Use mcp__plugin_uwm-enterprise-mcp_jira__search_issues
   JQL: project = {PROJECT_KEY} AND description ~ "bd: {BD_TASK_ID}"
   ```

4. **If Jira story exists:**
   - Transition toward In Progress if not already.
   - Report: "Jira story {KEY} already exists and is now In Progress."

5. **If no Jira story found:**
   - Auto-format the description into user story format:
     ```
     As a developer,
     I want to {BD_TASK_GOAL_REFORMULATED},
     so that {BENEFIT_DERIVED_FROM_EPIC_CONTEXT}.

     ## Implementation Details
     {BD_TASK_DESIGN_SUMMARY}

     [bd: {BD_TASK_ID}]
     ```
   - Include the parent epic reference in the description (add `Parent epic: {PARENT_EPIC_KEY}` before the `[bd: ...]` marker):
     ```
     ...
     Parent epic: {PARENT_EPIC_KEY}
     [bd: {BD_TASK_ID}]
     ```
   - Create the story:
     ```
     Use mcp__plugin_uwm-enterprise-mcp_jira__create_issue
     projectKey: {PROJECT_KEY}
     issueType: "Story"
     summary: {BD_TASK_TITLE}
     description: {FORMATTED_DESCRIPTION}
     ```
     Note: The Epic Link custom field (`customfield_10014`) is often unavailable or not on the create screen. Instead, the parent epic is referenced in the description. Manual epic linking in the Jira UI may be needed if the project requires a formal epic link.
   - Transition to In Progress.
   - Report: "Created Jira story {KEY} linked to epic {EPIC_KEY} and transitioned to In Progress."

### Case C: Completing a bd item (`bd done` or `bd close`)

1. Read the bd item details to get the item ID.

2. Search Jira for the corresponding item:
   ```
   Use mcp__plugin_uwm-enterprise-mcp_jira__search_issues
   JQL: project = {PROJECT_KEY} AND description ~ "bd: {BD_ITEM_ID}"
   ```

3. **If Jira item found:**
   - Get available transitions:
     ```
     Use mcp__plugin_uwm-enterprise-mcp_jira__get_transitions
     ```
   - Find a transition whose target status suggests completion (e.g., contains "Done", "Closed", "Resolved", "Complete").
   - Execute the transition:
     ```
     Use mcp__plugin_uwm-enterprise-mcp_jira__transition_issue
     ```
   - Report: "Transitioned Jira {KEY} to {NEW_STATUS}."

4. **If no Jira item found:**
   - This is normal if Jira sync wasn't active when the item was created.
   - Report nothing (silent skip).

### Case D: Updating a bd item (`bd update`)

1. Read the bd item details.

2. Search Jira for the corresponding item using `description ~ "bd: {BD_ITEM_ID}"`.

3. **If Jira item found and update is significant:**
   - If the bd summary changed → update Jira summary:
     ```
     Use mcp__plugin_uwm-enterprise-mcp_jira__update_issue
     fields: {"summary": "{NEW_SUMMARY}"}
     ```
   - If the bd status changed → transition Jira accordingly.
   - Report: "Updated Jira {KEY} to reflect bd changes."

4. **If update is minor** (e.g., adding a dependency, editing design details):
   - Skip Jira update (too noisy).
   - Report nothing.

---

## Step 3: Report Summary

After completing the sync action, provide a brief one-line summary of what happened:

- "Jira epic EH-1234 created and transitioned to In Progress."
- "Jira story EH-1235 already exists, transitioned to In Progress."
- "Jira story EH-1235 transitioned to Done."
- (silent if no action needed)

Then continue with your current work — the sync should be minimally disruptive.

</the_process>

<critical_rules>

## Rules That Have No Exceptions

1. **Always read CLAUDE.md first** — No Jira section = no sync, silently skip
2. **Never hardcode status names** — Always use get_transitions for dynamic discovery
3. **Always include `[bd: ID]` reference** — This is how existing items are found later
4. **Search before creating** — Never create duplicates; search by `[bd: ID]` in description
5. **Informative, not disruptive** — Keep reports brief, don't interrupt the workflow
6. **Auto-format stories** — bd task descriptions become "As a / I want / So that" format

## Transition Name Matching

When looking for transitions, match by intent, not exact name. Different projects use different workflow names:

**Starting work:** Look for transitions containing: "Progress", "Start", "Active", "Developing", "Begin"
**Completing work:** Look for transitions containing: "Done", "Close", "Resolve", "Complete", "Finish"

Use case-insensitive matching. If multiple transitions match, prefer the one that most closely matches the intent.

## Epic Name Field (Epics)

When creating Epics, the `customfield_10103` (Epic Name) field is required. Derive it from the summary, keeping it under 30 characters.

## Epic Link Field (Stories)

The Epic Link custom field (`customfield_10014`) is often unavailable on the create screen. Instead, include `Parent epic: {EPIC_KEY}` in the story description. The `[bd: ID]` reference in the description provides the primary mapping regardless.

## JQL Text Search

When searching for `[bd: ID]` markers in descriptions, omit the square brackets in JQL: `description ~ "bd: {ID}"`. Jira text search tokenizes on brackets, so the ID is still matched. Square brackets are special characters in JQL and cause query parse errors.

</critical_rules>

<integration>

**This skill is called by:**
- The jira-sync-hook.sh hook (fires on PostToolUse for Bash commands containing bd operations)
- The hook outputs a `[bd-event]` message that prompts the model to use this skill

**This skill uses these MCP tools (from uwm-enterprise-mcp plugin):**
- `mcp__plugin_uwm-enterprise-mcp_jira__search_issues` — Find existing Jira items by bd reference
- `mcp__plugin_uwm-enterprise-mcp_jira__create_issue` — Create new Jira epics and stories
- `mcp__plugin_uwm-enterprise-mcp_jira__update_issue` — Update Jira item fields
- `mcp__plugin_uwm-enterprise-mcp_jira__get_transitions` — Discover available status transitions
- `mcp__plugin_uwm-enterprise-mcp_jira__transition_issue` — Move items to new statuses

**Prerequisites:**
- The `uwm-enterprise-mcp` plugin must be installed (provides Jira MCP tools)
- A valid `JIRA_TOKEN` must be configured in `~/.uwm-mcp-shared/config.json`
- The project's CLAUDE.md must contain a `## Jira` section with `Project: KEY`

**Example CLAUDE.md configuration:**
```markdown
## Jira
Project: EH
```

</integration>
