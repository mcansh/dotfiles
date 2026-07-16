---
name: brainstorming
description: Use when shaping a feature before implementation - turns rough ideas into an approved markdown spec and local task directory
---

<skill_overview>
Shape first, then execute. Lock intent in `plan.md`; keep execution flexible in `tasks.md`.
</skill_overview>

<rigidity_level>
HIGH FREEDOM - Ask enough questions to stabilize intent, but always end with an approved `plan.md` and a task directory stub.
</rigidity_level>

<quick_reference>
| Step | Action | Deliverable |
|------|--------|-------------|
| 1 | Ask questions | Goals, anti-goals, constraints |
| 2 | Research | Existing patterns plus 3+ internet sources |
| 3 | Compare approaches | Chosen approach and rejected alternatives |
| 4 | Write spec | local `plans/active/<slug>/plan.md` |
| 5 | Seed docs | `context.md` and `tasks.md` skeleton |

**Contract:** `plan.md` holds intent. `tasks.md` must not replace the spec. Delete the finished local task directory when the work is complete.
</quick_reference>

<when_to_use>
- New feature work
- Large process changes
- Architecture decisions
- Any task where the problem or constraints are still fuzzy
</when_to_use>

<the_process>
## 1. Clarify the problem

Ask focused questions until you can state:
- problem
- goals
- anti-goals
- constraints
- audience
- success conditions

## 2. Research before proposing

- Inspect repo patterns
- Use subagents for codebase or internet research when useful
- Collect at least 3 current internet sources about best practices for the specific feature or task
- Use a real web-search tool call or the `internet-researcher` agent
- Do not summarize “best practices” from memory
- Bring back a short list of real options

## 3. Recommend an approach

Present 2-3 approaches with trade-offs.
Lead with the recommended option and explain why it fits the repo.

## 4. Write the approved spec

Create a local `plans/active/<slug>/plan.md` with:
- problem
- goals
- anti-goals
- constraints
- research notes with at least 3 sources
- chosen approach
- rejected alternatives
- acceptance checks

## 5. Create the task directory shell

Add:
- `context.md` with known files and decisions
- `tasks.md` with headings for `Now`, `Next`, `Later`, `Blocked`, and `Done`

Only seed 1-2 `Now` items.
</the_process>

<examples>
<example>
<scenario>Developer writes a task list before clarifying anti-goals</scenario>

<why_it_fails>
- The backlog optimizes for motion instead of intent
- Rejected shortcuts come back during implementation
</why_it_fails>

<correction>
Write anti-goals and rejected alternatives into `plan.md` before drafting execution tasks.
</correction>
</example>

<example>
<scenario>Developer turns the plan into a giant upfront backlog</scenario>

<why_it_fails>
- The backlog becomes stale immediately
- Agents optimize for checking boxes, not adapting to reality
</why_it_fails>

<correction>
Keep the spec detailed, but keep `tasks.md` short and rolling.
</correction>
</example>
</examples>

<integration>
Calls:
- `writing-plans`
- `sre-task-refinement`
- `review-implementation`
</integration>
