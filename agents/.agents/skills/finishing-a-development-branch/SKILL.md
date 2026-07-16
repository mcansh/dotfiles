---
name: finishing-a-development-branch
description: Use when implementation is complete and verified - delete finished local task docs, present integration options, and clean up safely
---

<skill_overview>
Finish work intentionally: verify the spec, decide how to integrate it, then delete the finished local task directory.
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM - Verify first, then present integration choices and execute the chosen one without leaving stale local task docs behind.
</rigidity_level>

<quick_reference>
1. Re-read `plan.md`, `context.md`, and `tasks.md`
2. Confirm acceptance checks and verification evidence
3. Present integration options: merge/PR, keep branch, discard branch
4. Delete the local task directory under `plans/active/`
</quick_reference>

<when_to_use>
- Work is implemented and verified
- The task directory is ready to close
- The user needs a clean finish to the branch
</when_to_use>

<the_process>
## 1. Confirm the work is actually complete

- `tasks.md` should have no active `Now` items
- acceptance checks in `plan.md` should have evidence
- verification should be fresh

## 2. Present the integration choice

Offer the user clear options:
- merge or open PR
- keep the branch for more work
- discard the branch if the work should not land

## 3. Delete the local docs

Delete the completed local task directory from `plans/active/`.
</the_process>
