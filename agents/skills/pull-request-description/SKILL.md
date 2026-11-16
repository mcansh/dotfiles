---
name: pull-request-description
description: Draft or revise a pull request description from its changes and validation evidence, with summary, changes, test coverage, impact, and risk/rollback sections. Use when the user asks for a PR body or description.
---

# Pull request description

Turn the final PR diff and available validation evidence into a concise, copy-ready description for a reviewer who has not seen the conversation.

## Workflow

1. Establish scope. Use the supplied PR, branch/base, or diff. For a repository, read its instructions and PR template, inspect the full diff against the target branch, and distinguish uncommitted changes from changes included in the PR. Ask one focused question only when the PR scope cannot be established.
2. Gather evidence. Read changed implementation and test files, relevant validation results, and available CI details. Account for every material behavior change. Treat an existing description, agent report, or Computer History observation as reported evidence until corroborated by results. Drafting a description does not require rerunning tests; mark missing results explicitly.
3. Write the five sections below. Explain the problem and resulting behavior first. Group changes by behavior, name files only when they help review, and keep detail proportional to the diff. Use the user's terminology and preserve exact configuration names and version numbers when relevant.
4. Check every claim against the diff or evidence. Separate tests added/changed from tests executed. Keep local checks, CI, quality gates, scans, deployment, and live behavior distinct. Conflicting counts or statuses remain unresolved unless a result identifies the same revision, scope, and environment. A passing check does not establish merge readiness when blockers remain.
5. Return the finished Markdown body without a surrounding code fence. In Codex, use a document writing block for a chat-delivered body. When the user authorizes updating an existing PR, save the description there and read it back to verify headings, formatting, and content. Keep drafting separate from opening, pushing, merging, or deploying.

## Default body

Use these headings unless the user explicitly requests another format. Honor a required repository template while retaining all five categories; for a Summary/Evidence/Merge Danger template, place Changes and Impact under Summary, Test Coverage under Evidence, and Risk and Rollback under Merge Danger.

```markdown
## Summary

<State the concrete problem, the final change, and its purpose in one or two sentences.>

## Changes

- <Describe each material change and the resulting behavior.>

## Test Coverage

- **Added or changed:** <Cases covered by modified tests, or “No tests added or modified.”>
- **Validation:** <Check or command, result, and relevant revision/environment; include counts only when supported.>
- **Gaps:** <Checks not run, skipped, failed, pending, or unverified; distinguish mock validation from deployed behavior.>

## Impact

<Describe affected users, runtime paths, deployment/configuration, compatibility, or operational behavior. Explain intended behavior separately from verified behavior.>

## Risk and Rollback

- **Risk:** <Specific failure modes and affected scope, with evidence-backed mitigations and remaining blockers.>
- **Rollback:** <Concrete recovery action and any migration, state, or configuration limitations.>
```

Replace all placeholders. Retain every section; use a short explicit statement when evidence is unavailable. State risk from the changed paths, rather than assigning an unsupported “low risk” label. Claim unchanged user behavior, smaller images, improved security, or migration-free rollback only when the diff and evidence support it.

For packaging or startup changes, describe runtime dependencies, configuration precedence, asset availability, and secret-loading behavior when affected. Separate automated test coverage from image build, startup, healthcheck, asset delivery, image scanning, and deployed smoke checks.

For UI changes, include available matched before/after evidence with links usable by PR reviewers. Keep secrets, machine-local paths, and private history excerpts out of the PR body.

## Completion check

The body describes the final scope, includes all five categories, attributes reported evidence, states validation gaps, and gives a concrete rollback path or explains why it is unverified. Every claimed pass is backed by a result; no historical count or project-specific claim is copied into another PR.
