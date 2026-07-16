---
name: managing-task-docs
description: Use for advanced markdown task-doc operations - split work, reprioritize slices, delete finished local task dirs, and keep docs clean
---

<skill_overview>
Task docs are the active workflow surface. Keep them accurate, small, and easy to resume.
</skill_overview>

<rigidity_level>
HIGH FREEDOM - Adapt the operations to the task, but keep the docs truthful and lean.
</rigidity_level>

<quick_reference>
| Operation | Action |
|-----------|--------|
| Split work | Break a large item into smaller `Now`/`Next` items |
| Reprioritize | Move items between `Now`, `Next`, `Later`, and `Blocked` |
| Refresh context | Update discoveries and resume notes |
| Close | Delete completed local dirs from `plans/active/` |
| Resume | Re-read docs and tighten `Now` back to 1-2 items |

**Rule:** `tasks.md` is a rolling backlog, not a frozen project plan.
</quick_reference>

<when_to_use>
- Current tasks are too large
- Priorities changed
- A task became blocked
- Work is complete and ready to close
- A session is about to compact or end
</when_to_use>

<the_process>
## 1. Read the full task directory

Before editing `tasks.md`, re-read:
- `plan.md`
- `context.md`
- `tasks.md`

## 2. Make the smallest truthful change

Examples:
- split one large item into three smaller items
- move an item from `Now` to `Blocked` with a reason
- promote the next best item from `Next` to `Now`

## 3. Update `context.md`

Record:
- why the backlog changed
- what was learned
- what should happen next

## 4. Close cleanly

When the work is complete:
- verify acceptance checks
- make sure `Now` is empty
- delete the local directory from `plans/active/`
</the_process>
