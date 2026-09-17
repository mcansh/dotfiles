---
name: create-pr
description: Generate a pull request title and detailed PR description from all changes in the current branch. Use when the user asks for a PR title, PR description, pull request summary, or help preparing a PR body.
---

# Create a Pull Request

## Goal

Create an accurate, review-ready pull request title and detailed description that covers all changes in the branch.

## Workflow

1. Establish the source of truth.
   - If the user provides a change summary, use it as context but verify against the branch when a repository is available.
   - Run `git status --short --branch` to identify the current branch, upstream, and dirty working tree.
   - Identify the PR target branch from user input, local upstream, or common base branches in this order: `main`, `master`, `develop`.
   - Use the merge-base diff for committed branch changes: `git diff --stat <base>...HEAD` and `git diff <base>...HEAD`.
   - Include uncommitted changes only when the user explicitly asks, when there are no committed branch changes, or when the user says the current working tree should be included.

2. Inspect the branch change set.
   - Review changed files, key diffs, and any added or updated tests.
   - Check recent commit messages with `git log --oneline <base>..HEAD` when commits exist.
   - Prefer concrete behavior and user-visible effects over implementation trivia.
   - Group related changes by feature area, API, UI, data model, infrastructure, tests, or documentation.
   - Map each code change to runtime behavior change.
   - Identify blast radius and rollback strategy.

3. Write the PR title.
   - Use a concise imperative phrase, normally 12 words or fewer.
   - Describe the main outcome of the branch, not every file touched.
   - Avoid issue IDs unless the repo convention or user input requires them.
   - Avoid vague titles like "updates", "fixes", "changes", or "misc cleanup".

4. Write the PR description with these sections in this order.
   - `## Summary`
     - One short paragraph explaining the purpose and net effect of the PR.
   - `## What Changed`
     - Bullets covering the meaningful implementation or behavior changes.
     - Mention important files, modules, endpoints, components, or workflows when useful for review.
   - `## Test Coverage Updates`
     - List tests added, updated, removed, or run.
     - If no tests changed or tests were not run, state that plainly.
     - Include command results when known.
   - `## Impact`
     - Explain user-facing, API, data, operational, deployment, documentation, or developer-experience impact.
     - State "No expected user-facing impact" only when the diff supports that claim.
   - `## Risk And Rollback`
     - Call out the main risks, edge cases, migrations, feature flags, compatibility concerns, and monitoring needs.
     - Include a practical rollback path, such as reverting the PR, disabling a flag, restoring config, or redeploying the previous version.

5. Calibrate detail.
   - Be specific enough for reviewers to understand scope without rereading the entire diff.
   - Do not overstate certainty; use "appears", "likely", or "not verified" when evidence is incomplete.
   - Preserve unknowns as explicit notes instead of inventing test results or product impact.
   - Keep bullets parallel and actionable.

## Output Format

Return the title first, followed by the PR body in a fenced `markdown` block.

```text
PR Title:
feat: add lender eligibility matching controls
```

```markdown
PR Body:

## Summary

Adds controls for lender eligibility matching and wires them into the mortgage matchup flow so reviewers can evaluate borrower scenarios more precisely.

## What Changed

- Added eligibility matching inputs to the matchup workflow.
- Updated the matching service to account for lender-specific constraints.
- Refined validation messages for incomplete borrower data.

## Test Coverage Updates

- Added unit coverage for eligibility constraint matching.
- Ran `dotnet test`.

## Impact

Loan officers can compare lender fit with more complete eligibility data. Existing matchup requests continue to use the same API shape.

## Risk And Rollback

Risk is concentrated in matching logic changes for edge-case borrower profiles. Roll back by reverting this PR and redeploying the previous service version.
```

Larger API/content branch:

```text
Title: feat(chatuwm): add CMS markdown and webhook data endpoints
```

```markdown
## Summary

Adds ChatUWM-facing API support for retrieving CMS page data and rendering CMS entries as plain Markdown. This includes a reusable JSON-to-Markdown renderer, a Markdown API route, and webhook payload validation for resolving page content by UID.

## What Changed

- Added `/api/chatuwm-data` POST endpoint for Contentstack update/create/delete webhook events.
- Added `/api/md/[[...slug]]` route that returns sanitized `text/plain` Markdown for pages, dashboard content, and trending entries.
- Added `utilities/json-to-markdown.ts` for rendering CMS JSON, rich text, tables, media, timelines, dashboard sections, broker rankings,
tabs, and trending cards.
- Moved `createEntryUrl` into shared utilities.
- Converted Vitest setup/config files to TypeScript.
- Corrected cookie header formatting expectations.

## Test Coverage Updates

- Added webhook API tests for validation, lookup failures, invalid entry data, and successful responses.
- Added Markdown API route tests for slug safety, dashboard/trending paths, response headers, 404/500 handling, and sanitized output.
- Added broad renderer coverage for rich text, tables, media, timelines, dashboard content, broker rankings, unsafe HTML, and malformed HTML.
- Updated page/helper tests for the shared `createEntryUrl` helper.

## Impact

- Enables ChatUWM consumers to retrieve CMS page data and Markdown-rendered CMS content through API routes.
- Improves safety by rejecting unsafe slugs and stripping unsafe scripts, styles, links, images, and raw dangerous markup.

## Risk and Rollback

- Risk is moderate because the renderer supports many CMS component shapes and introduces new API behavior.
- Roll back by reverting the new API routes, renderer utility, shared helper extraction, and associated tests/config changes.
```
