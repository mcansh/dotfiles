---
name: sre-task-refinement
description: Use when hardening a spec or task docs - stress-tests edge cases, failure modes, and acceptance checks before implementation
---

<skill_overview>
Refinement is where vague plans become safe to execute. Tighten the spec and the next work slices before coding.
</skill_overview>

<rigidity_level>
HIGH FREEDOM - Apply deep scrutiny to the current spec and task docs, but keep the output concrete and immediately actionable.
</rigidity_level>

<quick_reference>
1. Read `plan.md`, `context.md`, and `tasks.md`
2. Identify ambiguity, missing edge cases, and weak acceptance checks
3. Strengthen the spec and the next slices
4. Verify no placeholders remain
</quick_reference>

<when_to_use>
- A plan looks underspecified
- The next slice has hidden edge cases
- Acceptance checks are weak or unverifiable
</when_to_use>

<the_process>
## 1. Review the current docs line by line

Look for:
- vague goals
- implicit assumptions
- missing failure modes
- untestable acceptance checks

## 2. Strengthen the docs

Update the relevant task docs with:
- concrete edge cases
- clearer acceptance checks
- smaller, safer slices
- explicit blocked conditions

## 3. Verify the docs are execution-ready

No placeholders, no “figure it out later,” no giant tasks hiding multiple risks.
</the_process>
