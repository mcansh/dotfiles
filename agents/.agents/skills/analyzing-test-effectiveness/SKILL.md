---
name: analyzing-test-effectiveness
description: Use to audit test quality with SRE scrutiny - identifies weak tests, missing cases, and creates task docs for improvements
---

<skill_overview>
High coverage is not the goal. Tests must catch real failures and justify their maintenance cost.
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM - Follow the audit flow strictly, but adapt the exact categories and examples to the codebase.
</rigidity_level>

<quick_reference>
1. Inventory the tests
2. Classify them as strong, weak, or misleading
3. Identify missing edge cases
4. Create or update a task directory for test-quality improvements
</quick_reference>

<when_to_use>
- Coverage looks good but bugs still escape
- A test suite feels noisy or low-signal
- You want a quality-improvement backlog for tests
</when_to_use>

<the_process>
## 1. Audit the suite

Look for:
- tautological tests
- mock-heavy tests that prove little
- weak assertions
- missing edge cases

## 2. Explain each finding

For every weak area, say what real bug it would or would not catch.

## 3. Turn findings into tracked work

Create or update a task directory that captures:
- which tests to remove
- which tests to strengthen
- which missing scenarios to add

## 4. Refine before execution

Use `sre-task-refinement` to harden the improvement plan before implementation.
</the_process>
