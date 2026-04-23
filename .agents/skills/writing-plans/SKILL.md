---
name: writing-plans
description: Use after a spec is approved - distills plan.md into context.md and a rolling markdown backlog
---

<skill_overview>
The approved spec says what must be true. `context.md` and `tasks.md` say what to do next and what was learned.
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM - Verify the codebase against the spec, then write concrete task docs with no placeholders or fake certainty.
</rigidity_level>

<quick_reference>
| Step | Action | Rule |
|------|--------|------|
| 1 | Read `plan.md` | Do not restate it vaguely |
| 2 | Verify codebase reality | Prefer investigator evidence over assumptions |
| 3 | Research the task | Collect 3+ best-practice sources for the specific slice |
| 4 | Write `context.md` | Capture files, decisions, discoveries, resume notes |
| 5 | Write `tasks.md` | Use `Now`, `Next`, `Later`, `Blocked`, `Done` |
| 6 | Keep backlog lean | Only 1-2 active items in `Now` |

**Forbidden:** placeholders like `[details omitted]` or giant speculative task trees.
</quick_reference>

<when_to_use>
- Spec approved, implementation not started
- Existing task docs are vague or stale
- Need a better handoff/resume surface for a large task
</when_to_use>

<the_process>
## 1. Identify the task directory

Work in a local `plans/active/<slug>/`.
Read `plan.md` first.

## 2. Verify the codebase

Use repo inspection or `codebase-investigator` to confirm:
- real file paths
- existing modules and constraints
- likely implementation seams

Write down mismatches instead of ignoring them.

## 3. Research the specific task or feature

Before finalizing the next task slices, collect at least 3 current internet sources about:
- implementation best practices
- library or framework guidance
- common pitfalls for the specific task

Use a real web-search tool call or the `internet-researcher` agent.
Do not fill this section from memory.

Record the useful sources in `context.md`.

## 4. Populate `context.md`

Capture:
- key files
- important decisions
- discoveries from verification
- open questions
- explicit resume notes

## 5. Distill the rolling backlog

Write `tasks.md` so each item is small and concrete.

Use:
- `Now` for immediate work only
- `Next` for near-term follow-ups
- `Later` for deferred work
- `Blocked` with a reason
- `Done` for completed items

## 6. Show the real docs

Present the actual doc contents, not a summary that says “see above.”
</the_process>

<examples>
<example>
<scenario>Developer copies the spec into tasks.md verbatim</scenario>

<why_it_fails>
- No execution guidance is added
- The backlog becomes a second, worse spec
</why_it_fails>

<correction>
Keep the spec in `plan.md`; write only actionable slices in `tasks.md`.
</correction>
</example>

<example>
<scenario>Developer writes tasks against guessed file paths</scenario>

<why_it_fails>
- The first implementation step is already wrong
- The task docs lose credibility immediately
</why_it_fails>

<correction>
Verify the codebase first, then write definitive file references into `context.md`.
</correction>
</example>
</examples>

<integration>
Calls:
- `brainstorming`
- `executing-plans`
- `managing-task-docs`
</integration>
