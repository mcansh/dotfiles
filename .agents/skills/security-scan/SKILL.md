---
name: security-scan
description: Run a Snyk security scan on the current project — code analysis (SAST) and dependency scanning (SCA). Use when the user says "security scan", "snyk scan", "check vulnerabilities", or "dependency audit".
---

<skill_overview>
Runs Snyk static analysis (SAST) and software composition analysis (SCA) against the current project. Reports vulnerabilities with severity, fix guidance, and remediation steps.
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM — The scan types and reporting are rigid. Fix suggestions are flexible.
</rigidity_level>

<when_to_use>
- User says "security scan", "snyk scan", "check for vulnerabilities"
- User wants to audit dependencies for known CVEs
- User has added new dependencies and wants to verify safety
- As part of the pre-push quality gate (called by `quality-scan` skill)
</when_to_use>

<the_process>

## 1. Run Code Scan (SAST) — via MCP

Use `mcp__Snyk__snyk_code_scan` to analyze first-party code for security issues:
- SQL injection, XSS, command injection, path traversal
- Hardcoded secrets, insecure crypto, weak randomness
- OWASP Top 10 patterns

The SAST scan works reliably through the Snyk MCP and typically completes in seconds.

## 2. Run Dependency Scan (SCA) — via Bash

Run the SCA scan using the Snyk CLI directly through Bash:

```bash
npx snyk test <absolute-path-to-project> --all-projects
```

**Why Bash instead of MCP?** The `mcp__Snyk__snyk_sca_scan` MCP tool times out on .NET projects with large dependency trees (hundreds of transitive dependencies). The CLI via Bash produces identical results reliably.

The SCA scan checks:
- Known CVEs in direct and transitive dependencies
- License compliance issues
- Available upgrade paths

**Trust requirement:** If the folder hasn't been trusted yet, run first:
```bash
npx snyk config set trusted-folders=<absolute-path-to-project>
```

## 3. Report Results

```
## Snyk Security Report

### Code Analysis (SAST)
| Severity | Issue | File | Line |
|----------|-------|------|------|
| ...      | ...   | ...  | ...  |

### Dependency Analysis (SCA)
| Severity | Package | Version | Fixed In | Issue |
|----------|---------|---------|----------|-------|
| ...      | ...     | ...     | ...      | ...   |

Distinguish between:
- **Direct upgrades** — the vulnerable package is a direct dependency and can be upgraded
- **Transitive (no direct fix)** — the vulnerability is in a dependency of a dependency; fixing requires upgrading the intermediate package

### Summary
- Critical: N | High: N | Medium: N | Low: N
- [Action items if any issues found]
```

## 4. Fix Guidance

For code issues:
- Read the flagged file and understand the vulnerability
- Offer a secure alternative (parameterized queries, output encoding, etc.)
- After fixing, re-scan to confirm resolution

For dependency issues:
- Suggest specific version upgrades
- If no fix available, suggest alternative packages or mitigations

</the_process>

<critical_rules>
- ALWAYS run both SAST and SCA — code vulnerabilities and dependency vulnerabilities are different threat vectors
- NEVER dismiss HIGH or CRITICAL severity findings — they must be addressed or explicitly acknowledged
- After fixing issues, ALWAYS re-scan to verify the fix and check for newly introduced issues
- If Snyk auth is not configured, tell the user to run `npx snyk auth` or use `/setup-quality-tools`
</critical_rules>
