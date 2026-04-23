---
name: executing-plans
description: Use to execute an approved local markdown task directory iteratively - work the current Now slice, update docs, then stop
---

<skill_overview>
Execute in short reviewed slices. `plan.md` keeps intent stable; `tasks.md` keeps execution adaptive.
</skill_overview>

<rigidity_level>
LOW FREEDOM - Load the task docs, work only 1-2 `Now` items, update the docs immediately, then stop for review.
</rigidity_level>

<quick_reference>
| Step | Action | Output |
|------|--------|--------|
| 1 | Load `plan.md`, `context.md`, `tasks.md` | Current truth |
| 2 | Work 1-2 `Now` items | Implementation slice |
| 3 | Research the next slice | 3+ sources before promoting new work |
| 4 | Update docs | New discoveries and task status |
| 5 | Verify changed behavior | Evidence |
| 6 | Stop | Review checkpoint |

**Critical:** Do not silently continue through the whole backlog in one pass.
</quick_reference>

<when_to_use>
- A task directory already exists
- The next work slice is understood
- You want an implementation loop that survives compaction and review checkpoints
</when_to_use>

<the_process>
## 0. Resume correctly

If resuming:
- find the active local directory in `plans/active/`
- read all three docs
- continue from `Now` or the `Resume Here` section

## 1. Load the contract

Read:
- `plan.md` for goals, anti-goals, and acceptance checks
- `context.md` for discoveries and resume notes
- `tasks.md` for the active slice

## 2. Execute the current slice

- Work only 1-2 unchecked `Now` items
- Track substeps explicitly
- Use TDD and verification as appropriate

## 3. Update docs before moving on

After each slice:
- move completed items to `Done`
- move blocked items to `Blocked` with a reason
- promote the next smallest sensible items into `Now`
- update `context.md` with discoveries and resume notes

Before promoting new items into active work, collect at least 3 current internet sources about best practices for that specific slice and record them in `context.md`.
Use a real web-search tool call or the `internet-researcher` agent. Do not rely on memory for best-practice guidance.

## 4. Stop at a checkpoint

Summarize:
- what changed
- what was learned
- what remains in `Now`
- what verification was run
</the_process>

<examples>
<example>
<scenario>Developer keeps coding after the current slice is done</scenario>

<why_it_fails>
- Context gets noisy
- Review opportunities vanish
- The docs stop matching reality
</why_it_fails>

<correction>
Update `context.md` and `tasks.md`, then stop after the current slice.
</correction>
</example>

<example>
<scenario>Developer hits a blocker and improvises around the spec</scenario>

<why_it_fails>
- Rejected approaches come back through the side door
- Anti-goals stop protecting the design
</why_it_fails>

<correction>
Re-read `plan.md`, record the blocker in `context.md`, and only revise the backlog in a way that still honors the spec.
</correction>
</example>
</examples>

<integration>
Calls:
- `test-driven-development`
- `review-implementation`
- `verification-before-completion`
- `managing-task-docs`
</integration>
