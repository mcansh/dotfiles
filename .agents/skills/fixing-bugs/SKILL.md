---
name: fixing-bugs
description: Use when encountering a bug - reproduce it, track it in task docs, fix it with a regression test, and verify the result
---

<skill_overview>
Bug work is still planned work. Capture the reproduction, find the root cause, write the failing test, then fix and verify.
</skill_overview>

<rigidity_level>
LOW FREEDOM - Follow the workflow exactly: reproduce, document, debug, write the failing test, implement the smallest fix, verify, then update the task docs.
</rigidity_level>

<quick_reference>
| Step | Action |
|------|--------|
| 1 | Create or resume a task directory for the bug |
| 2 | Record reproduction in `plan.md` or `context.md` |
| 3 | Use debugging tools to find the root cause |
| 4 | Write a failing regression test |
| 5 | Implement the smallest fix |
| 6 | Verify and update `tasks.md` / `context.md` |
</quick_reference>

<when_to_use>
- A bug was reported
- A regression was found
- Production behavior is wrong and needs a tracked fix
</when_to_use>

<the_process>
## 1. Track the bug in task docs

Use a dedicated task directory or a clearly scoped bug slice in the current active directory.

Capture:
- reproduction steps
- expected behavior
- actual behavior
- suspected impact

## 2. Debug before fixing

Use `debugging-with-tools` and `root-cause-tracing` as needed.
Do not patch symptoms first.

## 3. Write the failing test

Reproduce the bug in an automated test before the fix.

## 4. Implement the smallest real fix

Fix the root cause, not the visible symptom.

## 5. Verify and document

Run the regression test and any broader checks.
Update:
- `context.md` with root cause and fix notes
- `tasks.md` with the completed bug slice
</the_process>
