---
name: setup-quality-tools
description: Guided first-time setup for SonarQube and Snyk quality gate tools. Use when a developer needs to configure tokens, authenticate, or troubleshoot quality gate connectivity.
---

<skill_overview>
Walks a developer through configuring SonarQube and Snyk for the quality gate plugin. Checks current config state, identifies what's missing, and provides step-by-step setup instructions.
</skill_overview>

<rigidity_level>
LOW FREEDOM — Follow the diagnostic steps exactly, then adapt guidance to what's missing.
</rigidity_level>

<when_to_use>
- User says "setup quality tools", "configure sonarqube", "configure snyk"
- SessionStart hook reported missing configuration
- Quality scan failed due to authentication errors
- New team member onboarding
</when_to_use>

<the_process>

## 1. Diagnose Current State

Check each component:

```bash
# Node.js / npx available?
which npx && npx --version

# SonarQube token configured?
echo "${SONARQUBE_TOKEN:+SET}" || echo "NOT SET"

# Snyk auth — check both env var and config file
echo "${SNYK_TOKEN:+SET}" || echo "NOT SET"
cat ~/.config/configstore/snyk.json 2>/dev/null | jq -r '.api // "NOT SET"' || echo "NOT SET"

# Snyk org configured?
echo "${SNYK_CFG_ORG:+SET}" || echo "NOT SET"

# Config file exists?
ls -la ~/.config/uwm-mcp/config.env 2>/dev/null || echo "NOT FOUND"
```

## 2. Report Status

```
## Quality Gate Setup Status

| Component | Status | Action Needed |
|-----------|--------|---------------|
| Node.js/npx | OK/MISSING | [install instructions] |
| SonarQube Token | OK/MISSING | [create token link] |
| Snyk Auth | OK/MISSING | [auth instructions] |
| Snyk Org | OK/MISSING | [org ID instructions] |
| Config File | OK/MISSING | [create instructions] |
```

## 3. Guide Setup for Missing Components

### Node.js (if missing)
```bash
# Install Node.js 18+ via nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
nvm install 18
```

### SonarQube Token (if missing)
1. Go to https://sonarqube.uwm.com/account/security
2. Click "Generate Token"
3. Select type "User Token", give it a name
4. Copy the token value
5. Add to config:
```bash
mkdir -p ~/.config/uwm-mcp
echo 'export SONARQUBE_TOKEN="squ_your_token_here"' >> ~/.config/uwm-mcp/config.env
```

### Snyk Authentication (if missing)
Option A — Browser login (recommended):
```bash
npx snyk auth
```

Option B — Manual token:
1. Go to https://app.snyk.io/account
2. Copy your API token
3. Add to config:
```bash
echo 'export SNYK_TOKEN="your_token_here"' >> ~/.config/uwm-mcp/config.env
```

### Snyk Org ID (if missing)
1. Go to https://app.snyk.io/org → Settings → General
2. Copy the Organization ID (UUID format)
3. Add to config:
```bash
echo 'export SNYK_CFG_ORG="your-org-uuid-here"' >> ~/.config/uwm-mcp/config.env
```

### Source the config file
Add to `~/.bashrc` or `~/.zshrc`:
```bash
[ -f ~/.config/uwm-mcp/config.env ] && source ~/.config/uwm-mcp/config.env
```

## 4. Verify Setup

After configuration, verify connectivity:

```bash
# Source the new config
source ~/.config/uwm-mcp/config.env

# Test SonarQube connectivity
curl -s -u "${SONARQUBE_TOKEN}:" "https://sonarqube.uwm.com/api/system/status" | jq .status

# Test Snyk connectivity
npx snyk whoami
```

Tell the user to restart their Claude Code session for the MCP servers to pick up the new environment variables.

</the_process>

<critical_rules>
- NEVER display or echo actual token values — only check if they are SET or NOT SET
- Always create the config directory before writing to it
- Always remind the user to source config.env in their shell profile
- Always remind the user to restart Claude Code after configuration changes
</critical_rules>
