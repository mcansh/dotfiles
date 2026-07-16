---
name: verification-before-completion
description: Use before claiming work complete, fixed, or passing - requires fresh evidence before any completion claim
---

<skill_overview>
Completion claims without fresh verification are not acceptable. Evidence first.
</skill_overview>

<rigidity_level>
LOW FREEDOM - No exceptions. Run the command, read the output, then make the claim.
</rigidity_level>

<quick_reference>
| Claim | Required evidence |
|------|-------------------|
| Tests pass | Fresh test output with no failures |
| Build succeeds | Fresh build output with exit 0 |
| Task slice complete | Updated `tasks.md` plus verification evidence |
| Feature complete | Acceptance checks in `plan.md` satisfied with evidence |

**Not sufficient:** “should work”, “looks done”, or stale output.
</quick_reference>

<when_to_use>
- Before any completion claim
- Before moving work to `Done`
- Before deleting a finished local task directory
- Before committing or opening a PR
</when_to_use>

<the_process>
## 1. Identify the claim

What exact statement are you about to make?

## 2. Run the proof

Run the specific command or check that proves that claim.

## 3. Read the result

Confirm the output actually supports the claim.

## 4. Update the docs

If the work is complete:
- move the task to `Done`
- note the verification in `context.md` if it matters

## 5. Only then state completion
</the_process>

<examples>
<example>
<scenario>Developer says the slice is done because the code looks right</scenario>

<why_it_fails>
- No proof the behavior works
- No proof the spec was met
</why_it_fails>

<correction>
Run the relevant verification, update `tasks.md`, then claim completion with evidence.
</correction>
</example>
</examples>
