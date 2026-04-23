---
name: review-implementation
description: Use after executing a task directory - verifies implementation against plan.md, acceptance checks, and anti-goals
---

<skill_overview>
Review the implementation against the approved spec, not just against what happened to get coded.
</skill_overview>

<rigidity_level>
LOW FREEDOM - Review with evidence. Do not approve based on intuition or diff-skimming.
</rigidity_level>

<quick_reference>
| Step | Action |
|------|--------|
| 1 | Read `plan.md`, `context.md`, and `tasks.md` |
| 2 | Verify acceptance checks with evidence |
| 3 | Search for anti-goal violations and unfinished work |
| 4 | Report findings or approve with evidence |

**Evidence:** file references, command output, or explicit test results.
</quick_reference>

<when_to_use>
- Before claiming feature completion
- Before deleting a finished local task directory
- After a meaningful execution slice if risk is high
</when_to_use>

<the_process>
## 1. Load the docs

Read the active task directory completely.

## 2. Check the acceptance contract

For each acceptance check in `plan.md`:
- find direct implementation evidence
- run the relevant verification command if needed
- mark gaps explicitly

## 3. Check anti-goals

Search for:
- forbidden shortcuts
- TODO or placeholder remnants
- behavior that contradicts the spec

## 4. Report clearly

If there are gaps, lead with findings.
If approved, cite the evidence that supports approval.
</the_process>

<integration>
Calls:
- `verification-before-completion`
- `finishing-a-development-branch`
</integration>
