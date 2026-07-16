---
name: using-hyper
description: Use when starting any conversation - establishes skill selection and the local task-doc workflow
---

<skill_overview>
Skills are mandatory when they apply, and substantial work must stay grounded in local task docs.
</skill_overview>

<rigidity_level>
HIGH FREEDOM - The meta-process is rigid: check for skills, read them from disk, announce usage, and keep work anchored in `plans/active/`.
</rigidity_level>

<quick_reference>
1. Check if any skill applies.
2. Read the relevant `SKILL.md` from disk.
3. Announce which skill you are using.
4. For substantial work, create or resume a local `plans/active/<slug>/`.
5. Keep `plan.md`, `context.md`, and `tasks.md` current.
</quick_reference>

<when_to_use>
- At the start of every conversation
- Before starting any non-trivial task
- Before editing skills, hooks, docs, or code
</when_to_use>

<the_process>
## 1. Check for skills first

- If a skill matches, use it.
- Never rely on memory; read the file from disk.
- Announce the skill before acting.

## 2. Ground large work in task docs

For features, rewrites, and multi-step tasks:
- `brainstorming` shapes the work
- `writing-plans` distills it into task docs
- `executing-plans` implements the current `Now` slice

Use:
- `plans/active/<slug>/plan.md`
- `plans/active/<slug>/context.md`
- `plans/active/<slug>/tasks.md`

These task directories are local working state. Delete the finished directory instead of archiving it.

## 3. Treat the docs as distinct tools

- `plan.md` is the approved intent and acceptance contract
- `context.md` is the living discovery log
- `tasks.md` is the rolling execution backlog

## 4. Verify before claiming completion

Use `verification-before-completion` before any completion claim.
</the_process>

<examples>
<example>
<scenario>Developer jumps into implementation with no task directory</scenario>

<why_it_fails>
- The plan drifts out of memory
- Implementation learns things that never get written down
- Resumption after compaction becomes guesswork
</why_it_fails>

<correction>
Create or resume a local `plans/active/<slug>/` first, then keep `context.md` and `tasks.md` updated as reality changes.
</correction>
</example>

<example>
<scenario>Developer finds a matching skill but works from memory</scenario>

<why_it_fails>
- Skills evolve
- Important steps get skipped
- The user cannot tell whether the workflow was actually followed
</why_it_fails>

<correction>
Read the current `SKILL.md`, announce it, then follow it.
</correction>
</example>
</examples>

<integration>
Common path:
- `brainstorming`
- `writing-plans`
- `executing-plans`
- `review-implementation`
- `verification-before-completion`
</integration>
