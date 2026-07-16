---
name: generate-demo
description: Use when completed work needs to be demonstrated — identifies spec changes from a branch, generates realistic demo data, creates a docker-compose environment running the real application with seeded data, and writes a step-by-step DEMO-GUIDE.md for presenting to stakeholders. Use after implementation is complete and you want to show what was built.
---

<skill_overview>
This skill creates a post-implementation demo environment for completed work. It compares the current branch to main/master to identify what changed in spec/, reads those spec changes to understand new functionality (without looking at implementation code), generates realistic demo data as JSON files, creates a docker-compose.yml that runs the real production application with seeded data, and writes a DEMO-GUIDE.md with step-by-step scenarios for presenting to stakeholders. The demo is not a throwaway artifact — it is committed to git as documentation of what was demonstrated.
</skill_overview>

<rigidity_level>
MEDIUM — The 5-phase sequence (scope → spec review → data generation → docker-compose → guide) is fixed and cannot be reordered. The demo output structure (`./demo/{YYYY-MM-DD}-{slug}/`) is fixed. The content of demo data, docker-compose services, and guide scenarios adapts to the specific project and spec changes.
</rigidity_level>

<quick_reference>
| Phase | Action | Output |
|-------|--------|--------|
| 1. Identify Scope | `git diff main...HEAD -- spec/` | List of changed capabilities |
| 2. Review Spec | Read changed spec files | Change manifest with ubiquitous language |
| 3. Generate Data | Create realistic JSON data | `demo/{date}-{slug}/data/*.json` |
| 4. Docker-Compose | Layered codebase discovery | `demo/{date}-{slug}/docker-compose.yml` |
| 5. Write Guide | Scenario-based walkthrough | `demo/{date}-{slug}/DEMO-GUIDE.md` |

**Key:** Spec is the source of truth for WHAT was built. Codebase analysis is only for HOW to run the app.
</quick_reference>

<when_to_use>
Use when:
- A feature branch has been implemented and needs to be demonstrated
- Stakeholders need to see new functionality running in a real environment
- You want to create a repeatable demo with realistic data
- A sprint review or demo session is coming up
- You need to document what was built and how to show it

Do NOT use when:
- No spec exists yet (use spec-develop first to write the spec)
- Implementation is not yet complete (demo runs the real app — it must work)
- You want a pre-implementation visual mockup (use spec-mockup instead)
- The project does not use spec-driven-development (no spec/ directory)
- You want to run automated tests (use spec-implement + integration tests)
</when_to_use>

<the_process>

## Announce

```
"I'm using generate-demo to create a demo environment for the completed work on this branch."
```

---

## Phase 1: Identify Scope

Determine which spec changes exist on the current branch compared to the base branch.

**Step 1a: Detect base branch**

```bash
git rev-parse --verify main 2>/dev/null && echo "main" || (git rev-parse --verify master 2>/dev/null && echo "master" || echo "NONE")
```

- If `main` exists, use `main` as base branch
- If only `master` exists, use `master`
- If neither exists, ask the user: "No main or master branch found. Which branch should I compare against?"

**Step 1b: Find spec changes**

```bash
git diff main...HEAD -- spec/ --name-only
```

**Step 1c: Verify spec/ directory exists**

If `git diff` returns nothing, check whether spec/ exists at all:

```bash
ls spec/ 2>/dev/null
```

- If `spec/` does not exist: STOP. Tell the user: "No spec/ directory found. This skill requires spec-driven-development. Use spec-develop or spec-capture to create a spec first."
- If `spec/` exists but no changes on branch: Ask the user: "No spec/ changes found between this branch and [base]. Should I compare against a different branch or commit range?"

**Step 1d: Categorize changes**

Parse the diff output to identify changed capabilities. The spec directory supports two structures:
- `spec/{domain}/{capability}/features/*.feature`
- `spec/capabilities/{capability}/features/*.feature`

Use `git diff main...HEAD -- spec/ --stat` to count changed lines per capability.

Categorize each capability:
- **NEW** — Capability directory only exists on the current branch
- **MODIFIED** — Capability exists on both branches but has changes
- **REMOVED** — Capability was deleted (exists on base, not on HEAD)

**Step 1e: Handle removals**

If changes are only deletions (capabilities removed, no additions):
- Note which capabilities were removed
- Tell the user: "Only removals detected — [capability names] were removed. The demo will document what was removed but cannot demonstrate deleted functionality. Proceeding with any remaining modified capabilities."
- If ALL changes are removals and nothing remains to demo, ask the user if they still want a demo documenting the removals.

**Step 1f: Confirm scope**

```
Demo scope:
  Branch: [current] → [base]
  NEW capabilities:      [list or "none"]
  MODIFIED capabilities: [list or "none"]
  REMOVED capabilities:  [list or "none"]
  Demo slug: {YYYY-MM-DD}-{slug}
```

Generate a short slug from the most significant capability change (e.g., `2026-02-24-checkout-flow`).

---

## Phase 2: Review Spec Changes (Spec-Only)

Read the changed spec files to understand what new functionality was implemented.

**CRITICAL: Spec is the source of truth for WHAT was built.**

During this phase, you MUST NOT read implementation code (controllers, services, business logic, tests) to understand features. The spec tells you what was built in business terms. Implementation code is analyzed only in Phase 4 for infrastructure/tech-stack detection — a completely different concern.

**Step 2a: Read changed spec files**

For each changed capability, read:
1. `spec/{path}/README.md` — value statement, ubiquitous language, invariants, domain events
2. All `spec/{path}/features/*.feature` — scenarios with Given/When/Then steps
3. `spec/{path}/personas.md` — if it exists, persona definitions
4. `spec/{path}/subdomains.md` — if it exists, subdomain boundaries

**Step 2b: Extract ubiquitous language**

From the README and feature files, extract:
- Domain entity names (these MUST be used in demo data, not generic names)
- Persona names and roles
- Business process names
- State names and transitions
- Event names

**Step 2c: Build change manifest**

Document what is new or modified:

```
## Change Manifest

### NEW: [Capability Name]
- Purpose: [from README value statement]
- Personas involved: [list]
- Key scenarios: [list of scenario titles]
- Domain entities: [list]

### MODIFIED: [Capability Name]
- What changed: [summary from diff]
- New scenarios: [list]
- Modified scenarios: [list]
- Affected personas: [list]
```

This manifest drives Phase 3 (data generation) and Phase 5 (guide writing).

---

## Phase 3: Generate Demo Data

Create realistic JSON data files that bring the spec scenarios to life.

**Step 3a: Create demo folder**

```bash
mkdir -p ./demo/{YYYY-MM-DD}-{slug}/data
```

**Step 3b: Design data relationships**

Before writing any JSON, plan the data:
- Which personas need user accounts?
- What entities do the scenarios reference?
- How do entities relate to each other?
- What state should entities be in at demo start?

The data must tell a coherent story — the same user referenced in scenario 1 should appear consistently in scenario 3.

**Step 3c: Write JSON data files**

Create one JSON file per entity type in `./demo/{YYYY-MM-DD}-{slug}/data/`:

```json
{
  "_description": "Demo loan officers for the qualification workflow scenarios",
  "loanOfficers": [
    {
      "id": "lo-001",
      "name": "Sarah Chen",
      "email": "sarah.chen@example.com",
      "branch": "Downtown Detroit",
      "role": "Senior Loan Officer",
      "_usedInScenario": "Scenario: Loan officer reviews qualification request"
    }
  ]
}
```

**Data quality rules:**
- Use realistic names, not "User1" or "John Doe"
- Use the exact ubiquitous language from the spec (e.g., "qualificationRequest" not "application")
- Include plausible domain-appropriate values (realistic dollar amounts, dates, addresses)
- Each entity should have a `_usedInScenario` field noting which scenario references it
- Include enough data for each scenario but not more — keep it focused

---

## Phase 4: Generate Docker-Compose (Layered Discovery)

Create a docker-compose.yml that runs the real production application with demo data.

**IMPORTANT:** This phase analyzes the codebase for infrastructure requirements (HOW to run the app). This is distinct from Phase 2's restriction on reading implementation code for feature understanding (WHAT it does).

**Step 4a: Check for existing docker-compose**

```bash
ls docker-compose.yml docker-compose.yaml compose.yml compose.yaml 2>/dev/null
```

If found: Use the existing compose file as the base. Copy it into the demo folder and extend it with a seed container. Skip to Step 4d.

**Step 4b: Analyze tech stack (if no existing compose)**

Examine the codebase for infrastructure requirements:

| File/Pattern | What it reveals |
|-------------|-----------------|
| `Dockerfile` | App runtime (node, dotnet, python, java, go) |
| `appsettings.json`, `appsettings.*.json` | .NET connection strings, service URLs |
| `.env`, `.env.example` | Environment variables, service endpoints |
| `package.json` | Node dependencies (pg, mysql2, redis, amqplib) |
| `*.csproj` | .NET packages (Npgsql, StackExchange.Redis) |
| `requirements.txt`, `Pipfile` | Python packages (psycopg2, pymongo) |
| `go.mod` | Go modules (pgx, mongo-driver) |
| `application.yml`, `application.properties` | Spring Boot config |

**Database detection by driver/package:**
- `npgsql`, `pg`, `psycopg2`, `pgx` → PostgreSQL
- `mysql2`, `MySql.Data`, `pymysql` → MySQL
- `mongodb`, `mongoose`, `mongo-driver` → MongoDB
- `Microsoft.Data.SqlClient`, `mssql` → SQL Server
- `StackExchange.Redis`, `redis`, `ioredis` → Redis
- `RabbitMQ.Client`, `amqplib`, `amqp` → RabbitMQ

**Step 4c: Generate docker-compose.yml**

Write to `./demo/{YYYY-MM-DD}-{slug}/docker-compose.yml`:

```yaml
services:
  app:
    build:
      context: ../..    # Points to project root
      dockerfile: Dockerfile
    ports:
      - "8080:8080"     # Adjust based on app config
    environment:
      - DATABASE_URL=postgres://demo:demo@db:5432/demo
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: demo
      POSTGRES_PASSWORD: demo
      POSTGRES_DB: demo
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U demo"]
      interval: 5s
      timeout: 5s
      retries: 5

  seed:
    image: postgres:16-alpine
    volumes:
      - ./data:/data
      - ./seed:/seed
    depends_on:
      db:
        condition: service_healthy
    entrypoint: ["/seed/seed.sh"]
    restart: "no"
```

Adapt the template based on discovered tech stack. Include health checks for all infrastructure services.

**Step 4d: Create seed container**

Create `./demo/{YYYY-MM-DD}-{slug}/seed/` with appropriate seeding mechanism:

**PostgreSQL:**
Create `seed/seed.sh`:
```bash
#!/bin/bash
set -e
# Generate and execute SQL from JSON data files
for f in /data/*.json; do
  echo "Seeding from $f..."
  # Parse JSON and generate INSERT statements
done
```

**MongoDB:**
Create `seed/seed.sh`:
```bash
#!/bin/bash
set -e
for f in /data/*.json; do
  collection=$(basename "$f" .json)
  mongoimport --host db --db demo --collection "$collection" --file "$f" --jsonArray
done
```

**SQL Server:**
Create `seed/seed.sh`:
```bash
#!/bin/bash
set -e
/opt/mssql-tools/bin/sqlcmd -S db -U sa -P "$SA_PASSWORD" -d demo -i /seed/seed.sql
```

**Generic (Node/Python script):**
If the database type is unclear, create a small script that reads JSON files and uses the appropriate driver.

**If no Dockerfile exists:**
Ask the user: "No Dockerfile found. How should the application be run? Options: (A) Provide a Docker image name, (B) Provide run instructions, (C) Skip docker-compose and create a manual setup guide."

---

## Phase 5: Write Demo Guide

Create `./demo/{YYYY-MM-DD}-{slug}/DEMO-GUIDE.md`.

**Required sections:**

```markdown
# Demo: [What Was Built] — {YYYY-MM-DD}

## What's New

[Summary of spec changes being demonstrated, derived from Phase 2 change manifest.
List new capabilities and modified features in business terms.]

## Prerequisites

- Docker and Docker Compose installed
- Ports [list] available
- [Any required environment variables or API keys]

## Setup

1. Navigate to this demo folder:
   ```bash
   cd demo/{YYYY-MM-DD}-{slug}
   ```

2. Start the environment:
   ```bash
   docker compose up -d
   ```

3. Wait for services to be healthy:
   ```bash
   docker compose ps
   ```
   All services should show "healthy" or "running".

4. Verify seed data loaded:
   ```bash
   docker compose logs seed
   ```
   Look for "Seeding complete" message.

5. Open the application:
   - Web UI: http://localhost:8080
   - API: http://localhost:8080/api

## Scenarios

### Scenario 1: [Persona Name] — [Goal]

**Persona:** [Name], [Role] (e.g., Sarah Chen, Senior Loan Officer)
**Goal:** [What they are trying to accomplish]
**Context:** [1-2 sentences of business context explaining why this matters]

**Steps:**
1. [Specific action — reference UI elements or API endpoints]
2. [Next action — be specific about what to click, enter, or observe]
3. [Continue until scenario complete]
4. [Note what the expected outcome is]

**What to observe:** [Key thing to point out to stakeholders]

### Scenario 2: [Next Persona] — [Next Goal]
[Same format as above]

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Port [X] already in use | Stop conflicting service or change port in docker-compose.yml |
| Database connection refused | Wait for health check: `docker compose ps` — db should be "healthy" |
| Seed data not loaded | Check logs: `docker compose logs seed` — look for errors |
| Application won't start | Check logs: `docker compose logs app` — look for missing env vars |
| Docker not running | Start Docker Desktop or `systemctl start docker` |

## Additional Tools

- **Database client:** Connect to [db-type] at localhost:[port] with user `demo` / password `demo`
- **API testing:** Use curl or a REST client to test endpoints directly
- **Logs:** `docker compose logs -f [service]` to follow logs in real-time
- **Restart:** `docker compose restart [service]` to restart a single service
- **Clean up:** `docker compose down -v` to stop all services and remove data
```

**Tone:** Written for someone presenting to stakeholders — specific enough to follow without improvising, but not overly technical.

---

## Finalize

After writing all files:

1. Verify the demo folder structure:
```
./demo/{YYYY-MM-DD}-{slug}/
├── docker-compose.yml
├── DEMO-GUIDE.md
├── data/
│   ├── [entity1].json
│   ├── [entity2].json
│   └── ...
└── seed/
    ├── seed.sh (or seed script)
    └── Dockerfile (if needed)
```

2. Confirm deliverables:
```
Created demo at: ./demo/{YYYY-MM-DD}-{slug}/

Files:
  DEMO-GUIDE.md          — Step-by-step presentation guide
  docker-compose.yml     — Environment with [N] services
  data/                  — [N] JSON files with realistic demo data
  seed/                  — Database seeding scripts

To run the demo:
  cd demo/{YYYY-MM-DD}-{slug}
  docker compose up -d

Scenarios: [N] scenarios covering [capabilities]
```

</the_process>

<anti_patterns>
- ❌ NO reading implementation code (controllers, services, business logic) during Phase 2 to understand WHAT was built — the spec is the source of truth for business functionality; implementation code is only analyzed in Phase 4 for infrastructure detection (HOW to run the app)
- ❌ NO gitignoring or treating demo artifacts as throwaway — demos are committed to git as documentation of what was demonstrated; they have lasting value for onboarding and regression reference
- ❌ NO hardcoding tech stack assumptions in docker-compose generation — always use layered discovery (check existing compose → analyze codebase → generate); never assume "this project uses postgres" without evidence
- ❌ NO generic or lorem-ipsum demo data — use realistic names, amounts, dates with the exact ubiquitous language from the spec; "User1" and "test123" are never acceptable
- ❌ NO confusing "demo" with "mockup" — a demo is a post-implementation live walkthrough using the real application with seeded data; a mockup is a pre-implementation HTML visualization created by the spec-mockup skill
- ❌ NO writing scenarios without persona context — every scenario must include a specific persona (from spec), their goal, and business context; generic "the user clicks X" is not sufficient
- ❌ NO skipping the seed container — demo data must be automatically loaded when `docker compose up` runs; requiring manual data setup defeats the purpose of a repeatable demo
- ❌ NO inventing features not in the spec — the demo shows ONLY what the spec describes; if functionality exists in code but not in spec, it is not part of this demo
</anti_patterns>

<critical_rules>
1. Spec is the source of truth — Phase 2 reads spec to understand features, never implementation code; Phase 4 analyzes codebase only for infrastructure
2. Demo output goes in `./demo/{YYYY-MM-DD}-{slug}/` — this path format is fixed and must be followed exactly
3. Demo artifacts are committed to git — they are documentation, not throwaway files
4. All demo data MUST use ubiquitous language from the spec — entity names, state names, role names must match spec exactly
5. Docker-compose generation uses layered discovery — check existing compose first, then analyze tech stack, then generate
6. Every scenario in DEMO-GUIDE.md must have persona, goal, context, and step-by-step actions
7. Seed container must load data automatically — `docker compose up` should produce a ready-to-demo environment with no manual steps
8. If spec/ directory does not exist: STOP and tell the user to create a spec first
9. If no spec changes found on branch: ask the user before proceeding, do not generate a demo from unchanged spec
10. Never reference the word "mockup" in demo artifacts — demos and mockups are separate concepts with separate skills
</critical_rules>

<verification_checklist>

**Before declaring done:**
- [ ] Phase 1: Spec changes identified from branch comparison (not guessed)
- [ ] Phase 1: Scope confirmed with user before proceeding
- [ ] Phase 2: All changed spec files read; ubiquitous language extracted
- [ ] Phase 2: Change manifest documents all NEW/MODIFIED/REMOVED capabilities
- [ ] Phase 2: No implementation code was read to understand features
- [ ] Phase 3: JSON data files created in `demo/{date}-{slug}/data/`
- [ ] Phase 3: Data uses ubiquitous language from spec (not generic names)
- [ ] Phase 3: Data tells a coherent story across scenarios (consistent references)
- [ ] Phase 4: docker-compose.yml created via layered discovery
- [ ] Phase 4: Seed container included and loads data automatically
- [ ] Phase 4: Health checks configured for infrastructure services
- [ ] Phase 5: DEMO-GUIDE.md created with all required sections
- [ ] Phase 5: Every scenario has persona, goal, context, and steps
- [ ] Phase 5: Troubleshooting section covers common issues
- [ ] Demo folder structure matches expected layout
- [ ] Demo artifacts are ready to commit (not gitignored)

</verification_checklist>

<integration>
Called by: using-hyper (when user asks to create a demo for completed work, demonstrate new functionality, or prepare for a sprint review).
Precondition: Implementation must be complete on the current branch. Spec must exist in spec/ with changes relative to main/master.
Reads: spec/ directory (for business understanding), Dockerfile and config files (for infrastructure detection), existing docker-compose.yml (if present).
Writes: ./demo/{YYYY-MM-DD}-{slug}/ directory with docker-compose.yml, DEMO-GUIDE.md, data/*.json, seed/ scripts.
Never writes to: spec/ (spec is immutable), application source code.
Related skills: spec-mockup (creates pre-implementation HTML visualizations — different purpose), spec-detect-drift (validates spec against code), spec-implement (implements from spec).
</integration>

<edge_cases>

## Edge Case: No spec/ directory exists
- Signal: `ls spec/` fails or spec/ directory not found at project root
- Action: STOP. Tell the user: "No spec/ directory found. This skill requires spec-driven-development. Use spec-develop to create a spec or spec-capture to reverse-engineer one from existing code."

## Edge Case: No spec changes on branch
- Signal: `git diff main...HEAD -- spec/ --name-only` returns empty, but spec/ exists
- Action: Ask the user: "No spec/ changes found between this branch and [base]. Options: (A) Compare against a different branch, (B) Demo the full current spec (not just changes), (C) Cancel."

## Edge Case: No main or master branch
- Signal: Both `git rev-parse --verify main` and `git rev-parse --verify master` fail
- Action: Ask the user: "No main or master branch found. Which branch should I compare against for spec changes?"

## Edge Case: Multiple capabilities changed
- Signal: git diff output contains files from 2+ capability directories
- Action: Include all changed capabilities in the demo. Generate data and scenarios for each. Organize DEMO-GUIDE.md with one scenario section per capability. If there are too many (5+), ask the user which capabilities to prioritize.

## Edge Case: Spec changes are only deletions
- Signal: All changed spec files are deletions (capabilities removed, none added or modified)
- Action: Note which capabilities were removed. Tell the user: "Only removals detected — [capabilities] were removed. The demo will document what was removed but cannot demonstrate deleted functionality." If some capabilities were modified alongside removals, focus the demo on the modifications.

## Edge Case: No Dockerfile in project
- Signal: No Dockerfile, Dockerfile.*, or *.dockerfile found at project root
- Action: Check for existing docker-compose.yml (may reference pre-built images). If no compose either, ask the user: "No Dockerfile or docker-compose found. Options: (A) Provide a Docker image name, (B) Provide manual run instructions for a setup-only guide, (C) Cancel."

## Edge Case: Existing docker-compose uses v1 syntax
- Signal: Existing docker-compose.yml has `version: "2"` or `version: "3"` key
- Action: Copy the existing compose file into the demo folder. The seed container addition will use modern compose syntax. Note in DEMO-GUIDE.md if compose version differences may cause issues.

## Edge Case: Project uses multiple databases
- Signal: Codebase analysis reveals dependencies on 2+ database types (e.g., PostgreSQL for data, Redis for cache, MongoDB for documents)
- Action: Include all discovered databases in docker-compose.yml with appropriate health checks. Create separate seed strategies per database type. Note in DEMO-GUIDE.md which data goes where.

## Edge Case: Spec has no scenarios (empty feature files)
- Signal: `grep -c "Scenario:" spec/{path}/features/*.feature` returns 0 for changed capabilities
- Action: STOP. Tell the user: "Changed spec files for [capability] have 0 scenarios. There is nothing to demonstrate. Are the feature files still being written?"

</edge_cases>
