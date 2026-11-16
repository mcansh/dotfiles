---
name: conventional-commit-message
description: Draft Conventional Commit messages. Use when the user asks for help writing a commit message, provides a change summary, asks how to describe current changes, or wants a git commit subject/body.
---

# Conventional Commit Message

## Goal

Turn a change summary or git diff into a concise Conventional Commit message that is accurate, reviewable, and ready to paste into `git commit`.

## Workflow

1. Identify the source of truth.
   - If the user provided a summary, use it directly.
   - If the user asks about current repo changes, inspect `git status --short` and the relevant diff.
   - Prefer staged changes with `git diff --staged` when the user says "commit message" and staged changes exist.
   - Use `git diff` for unstaged changes only when nothing is staged or the user explicitly asks for all current changes.

2. Determine whether the changes are one commit or several.
   - If the work mixes unrelated concerns, propose separate commit messages.
   - Keep one message only when the changes form one logical unit.

3. Choose the Conventional Commit type.
   - `feat`: user-facing feature or capability
   - `fix`: bug fix
   - `docs`: documentation only
   - `style`: formatting only, no behavior change
   - `refactor`: restructuring without feature or bug fix
   - `perf`: performance improvement
   - `test`: tests only or test coverage changes
   - `build`: build system, dependencies, packaging
   - `ci`: CI configuration or pipeline changes
   - `chore`: maintenance that does not fit another type
   - `revert`: revert a previous commit

4. Write the message.
   - Format: `<type>[optional scope][!]: <description>`
   - Use imperative mood: "add", "fix", "remove", "rename".
   - Keep the subject concise, normally 72 characters or fewer.
   - Use lowercase for the description unless a proper noun requires capitalization.
   - Do not end the subject with a period.
   - Add a body for any non-trivial change where the subject alone would not explain the intent, scope, risk, verification, or review context.
   - Make commit bodies substantive: summarize what changed and why in one or two short paragraphs, and include concrete verification or coverage impact when known.
   - For test or coverage commits, include the major scenarios covered and any measured coverage change if available.
   - For breaking changes, add `!` after the type or scope and include a `BREAKING CHANGE:` footer.
   - Include issue footers only when the user or repo context provides an issue key.

5. Present the result.
   - Put the recommended message in a fenced `text` code block.
   - If confidence is low, state the assumption in one short sentence before committing and ask the user to confirm.
   - If changes should be split, list each proposed commit separately.
   - Sign the commit with `git commit --signoff`.

## Output Patterns

Single commit:

```text
fix(auth): reject expired magic links

Prevents stale login links from creating new sessions after their expiry window.
```

Split commits:

```text
feat(settings): add notification preferences
```

```text
test(settings): cover notification preference updates
```

Breaking change:

```text
feat(api)!: require explicit pagination limits

BREAKING CHANGE: list endpoints now reject requests without a limit parameter.
```
