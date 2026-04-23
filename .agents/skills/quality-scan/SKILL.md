---
name: quality-scan
description: Run the full pre-push quality gate — SonarQube analysis + Snyk security scan on the current branch. Use when the user says "quality scan", "quality gate", "run sonar", "pre-push check", or before pushing code.
---

<skill_overview>
Orchestrates SonarQube code quality analysis and Snyk security scanning against the current branch. Checks quality gate status, surfaces issues, and provides actionable fix guidance. This is the automated version of the manual pre-push quality gate.
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM — The scan sequence and reporting format are rigid. How you present findings and suggest fixes is flexible.
</rigidity_level>

<when_to_use>
- User says "quality scan", "quality gate", "run quality check", "pre-push check"
- User is about to push code and wants to verify quality
- User wants to check SonarQube or Snyk status for their branch
- Before pushing to remote (if quality gate is part of the workflow)
</when_to_use>

<the_process>

## 1. Determine Context

Gather the current branch, project, and changed files:

```bash
# Get current branch
git rev-parse --abbrev-ref HEAD

# Get changed files vs base branch (develop or main)
git diff --name-only develop...HEAD 2>/dev/null || git diff --name-only main...HEAD
```

Identify the SonarQube project key. Known mappings:

| Repo directory | SonarQube Key |
|---|---|
| brand360-gateway | `cell-biz-marketing-gateway` |
| brand360-contact-validate | `cell-biz-contact-info-validate` |
| lead-ingestion | `cell-biz-lead-profile` |
| loa-text-messaging | `cell-text-messaging` |

If the project key is not in this table, check `sonar-project.properties` or ask the user.

## 2. Run SonarQube Analysis

Use the SonarQube MCP tools in this order:

1. **Quality Gate Status** — `mcp__sonarqube__quality_gate_status` with project_key and branch
2. **Metrics** — `mcp__sonarqube__measures_component` with key metrics:
   - `bugs`, `vulnerabilities`, `code_smells`, `coverage`, `duplicated_lines_density`
   - `new_bugs`, `new_vulnerabilities`, `new_code_smells`, `new_coverage`, `new_duplicated_lines_density`
3. **Open Issues** — `mcp__sonarqube__issues` filtered to `OPEN`, `CONFIRMED`, `REOPENED` statuses

Run steps 1-3 in parallel where the MCP tools support it.

## 3. Run Snyk Security Scan

1. **Code Scan (SAST)** — use `mcp__Snyk__snyk_code_scan` via MCP (fast, reliable)
2. **Dependency Scan (SCA)** — use Bash CLI (the MCP tool times out on large .NET dependency trees):
   ```bash
   npx snyk test <absolute-path-to-project> --all-projects
   ```
   If the folder hasn't been trusted: `npx snyk config set trusted-folders=<path>`

## 4. Report Results

Present a consolidated quality gate report:

```
## Quality Gate: [PASSED/FAILED]

### SonarQube
| Metric | Overall | New Code | Status |
|--------|---------|----------|--------|
| ...    | ...     | ...      | OK/FAIL|

### Issues (N open)
- [severity] rule: message (file:line)

### Snyk Security
- [severity] vulnerability description
- ...

### Verdict
[Pass/fail summary with specific items to fix before pushing]
```

## 5. Fix Guidance

If the quality gate FAILS:
- For SonarQube issues: read the flagged file, understand the issue, and offer a fix
- For Snyk vulnerabilities: suggest dependency updates or code changes
- After fixes, offer to re-scan

</the_process>

<critical_rules>
- ALWAYS check both SonarQube AND Snyk — a partial scan is not a quality gate
- NEVER report "passed" if either tool reports blocking issues
- Present the SonarQube project key used so the user can verify it
- If MCP tools are unavailable (missing config), tell the user and suggest running `/setup-quality-tools`
</critical_rules>
