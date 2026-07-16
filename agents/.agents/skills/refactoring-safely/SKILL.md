---
name: refactoring-safely
description: Use when refactoring code - tracks the refactor in task docs and preserves behavior through small verified changes
---

<skill_overview>
Refactor in small truth-preserving steps. Keep the refactor tracked in task docs and stop if behavior starts drifting.
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM - Keep the change→test→document loop strict, but adapt the exact refactor pattern to the codebase.
</rigidity_level>

<quick_reference>
1. Create or resume a refactor task directory
2. Capture invariants and risks in `plan.md`
3. Make one small change at a time
4. Run tests between steps
5. Update `context.md` and `tasks.md`
</quick_reference>

<when_to_use>
- Behavior should stay the same
- The current design is painful to change
- You need a deliberate, reversible refactor path
</when_to_use>

<the_process>
## 1. Track the refactor

Use task docs to capture:
- invariants that must not change
- risks
- target design

## 2. Refactor in tiny steps

Each step should be small enough to explain and verify on its own.

## 3. Verify every step

Run the smallest relevant tests after each change.

## 4. Keep docs current

Update discoveries, remaining risks, and next slices as the refactor unfolds.
</the_process>
