---
name: develop-frontend
description: Golden path orchestrator for frontend development at UWM — auto-detects context (allin-ui vs SPA, new vs existing, UFA/SCL/IAP), chains through phase skills, and enforces standards at every checkpoint
---

<skill_overview>
Orchestrates the complete frontend development workflow at UWM. This skill auto-detects the development context — are you in the allin-ui monorepo or a legacy SPA? Is this a new package or an existing one? Is it a UFA, SCL, or IAP? — then chains through the appropriate phase skills with standards checkpoints between each phase.

**Phase skills (chained sequentially):**
1. `create-allin-package` — Scaffold a new package (skipped if package exists)
2. `design-ui-component` — Design DREAM-compliant components
3. `implement-ui-feature` — TDD implementation with .feature specs
4. `test-frontend` — Comprehensive test strategy (Stryker, Playwright, coverage)

**This skill enforces UWM frontend standards continuously:**
- Frontends contain ONLY user experience logic — zero business service logic
- DREAM design system mandatory (lib-node-dream-ui)
- GUP auth mandatory (lib-node-user-passport-component, already integrated in allin-ui)
- Component taxonomy enforced (UFA/SCL/IAP with dependency rules)
- Strict TDD with .feature specs as specifications
- Coverage ≥80%, mutation score ≥80, build + tests under 1 minute per package
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM - Context detection checks and phase ordering are rigid. Standards checkpoints are non-negotiable. The specific content within each phase adapts to the detected context and the developer's needs. Phase skills define their own rigidity internally.
</rigidity_level>

<quick_reference>

| Phase | Skill | When Skipped | Checkpoint |
|-------|-------|-------------|------------|
| **0. Detect** | (this skill) | Never | Context identified |
| **1. Scaffold** | `create-allin-package` | Package already exists | Package structure valid |
| **2. Design** | `design-ui-component` | N/A (always runs) | DREAM compliance |
| **3. Implement** | `implement-ui-feature` | N/A (always runs) | TDD + business logic boundary |
| **4. Test** | `test-frontend` | N/A (always runs) | Coverage + pipeline compliance |

**Context detection signals:**
```
pnpm-workspace.yaml exists?      → allin-ui monorepo
ufas/{name}/ directory?           → UFA
packages/{name}/ (flat)?          → SCL
packages/{name}/{sub}/ (nested)?  → IAP
uwm-manifest.json exists?        → UFA confirmed
package.json exists?              → existing package
cell-ui-* naming?                 → legacy SPA (redirect)
```

**Standards enforced continuously:**
- No business logic in frontend
- DREAM components (not raw MUI when DREAM exists)
- GUP auth (not custom auth)
- catalog: protocol for shared deps
- No UFA→UFA dependencies
- No TypeScript `any` types

</quick_reference>

<when_to_use>
- Starting any new frontend work at UWM (default entry point)
- Creating a new UFA, SCL, or IAP in allin-ui
- Adding features to an existing allin-ui package
- Unsure which frontend skill to use (this skill routes you)
- Need to ensure frontend standards compliance throughout development

**Do NOT use for:**
- Migrating a legacy SPA to allin-ui (use `migrate-spa-to-allin`)
- Maintaining a legacy SPA with no plans to migrate (use `maintain-legacy-spa`)
- Contributing components TO the DREAM library itself (see dream-buddy.md)
- Developing backend services (use `develop-business-service` from uwm-business-service-dev)
- Developing BFF services (cell-bff-xxx — different concern)

**Redirects:**
- Legacy SPA detected → Offer `migrate-spa-to-allin` or `maintain-legacy-spa`
- Backend work detected → Redirect to `uwm-business-service-dev:develop-business-service`
</when_to_use>

<the_process>

## Phase 0: Context Detection

Before any development work, detect the context using Glob and Grep checks. Run all checks in parallel where possible.

### Check 1: Is This allin-ui?

```
Glob: pnpm-workspace.yaml
Glob: turbo.json
Grep: "catalogMode" in pnpm-workspace.yaml
```

**If ALL exist:** allin-ui monorepo detected. Proceed to Check 2.

**If NONE exist:** Not in allin-ui. Check for legacy SPA:
- Check directory name: Does it match `cell-ui-*` pattern?
- Check for `webpack.config.js` or `react-scripts` in package.json?

**If legacy SPA detected:**

Present to user:
```
This appears to be a legacy SPA (cell-ui-* pattern). The current standard is allin-ui monorepo.

Options:
1. Migrate to allin-ui → I'll use the migrate-spa-to-allin skill
2. Maintain as legacy → I'll use the maintain-legacy-spa skill
3. Start fresh in allin-ui → I'll guide you through creating a new UFA
```

Use AskUserQuestion to let the user choose, then load the appropriate skill.

**If neither allin-ui nor legacy SPA:** This skill doesn't apply. Inform the user and ask for clarification.

### Check 2: Where in allin-ui?

Determine the working context within the monorepo:

```
Glob: ufas/*/package.json      → List existing UFAs
Glob: packages/*/package.json  → List existing SCLs/IAPs
```

**If user specified a package name:** Check if it exists:
```
Glob: ufas/{name}/package.json
Glob: packages/{name}/package.json
```

**If package exists:** Proceed to Check 3 (determine type).
**If package does NOT exist:** New package needed. Proceed to Phase 1 (create-allin-package).

### Check 3: What Component Type?

For existing packages, determine the type:

```
Glob: {package-path}/uwm-manifest.json                    → UFA indicator
Grep: "@uwm/vite-plugin-appshell" in {package-path}/vite.config.ts  → UFA confirmed
Glob: {package-path}/*/package.json                        → IAP indicator (nested packages)
```

| Signal | Component Type |
|--------|---------------|
| `uwm-manifest.json` exists | **UFA** |
| `@uwm/vite-plugin-appshell` in vite.config.ts | **UFA** (confirmed) |
| Nested directories with package.json (core/, lib-*, shell-*) | **IAP** |
| None of the above (flat package in `packages/`) | **SCL** |

### Check 4: Current Development State

Determine which phases have been completed:

```
Glob: {package-path}/src/**/*.tsx                    → Source files exist?
Glob: {package-path}/spec/*.feature                  → .feature specs exist?
Glob: {package-path}/src/**/__tests__/*.test.tsx      → Unit tests exist?
Glob: {package-path}/vitest.config.ts                → Vitest configured?
Glob: {package-path}/stryker.config.json             → Stryker configured?
Glob: {package-path}/tests/e2e/*.ts                  → E2E tests exist?
Glob: {package-path}/sonar-project.properties        → SonarQube configured?
```

Use these signals to determine which phase to start from:

| Signals Present | Start From |
|----------------|------------|
| No package.json | Phase 1 (create) |
| Package exists, no src/ files | Phase 2 (design) |
| Source exists, no spec/ or __tests__/ | Phase 3 (implement with TDD) |
| Tests exist, no vitest.config.ts or E2E | Phase 4 (test setup) |
| Everything present | Standards review only |

### Present Context Summary

After detection, present the findings to the user:

```
Context detected:
- Environment: allin-ui monorepo
- Package: {name} ({UFA/SCL/IAP})
- Status: {new/existing}
- Starting from: Phase {N} ({phase-name})
- Component type: {UFA in ufas/ | SCL in packages/ | IAP in packages/{name}/}

I'll chain through the following phases:
{list remaining phases with brief descriptions}

Shall I proceed?
```

---

## Phase 1: Scaffold Package

**Skip if:** Package already exists (package.json found).

**Announce:** "Phase 1: Scaffold Package — Loading create-allin-package skill."

Load the `create-allin-package` sub-skill:

```
Skill: uwm-frontend-dev:create-allin-package
```

This skill will:
- Walk through the component taxonomy decision tree (UFA/SCL/IAP)
- Run `turbo gen ufa` or `turbo gen lib` to scaffold
- Configure dependencies with catalog: protocol
- Set up uwm-manifest.json (UFAs only)
- Create spec/ directory for .feature files

### Checkpoint 1: Package Structure Valid

After Phase 1 completes, verify:

```
CHECK 1.1: Package directory exists at correct location
  - UFA: ufas/{name}/
  - SCL: packages/{name}/
  - IAP: packages/{name}/{sub}/

CHECK 1.2: package.json exists with @uwm/ scope

CHECK 1.3: Dependencies use catalog: protocol for shared deps
  Grep: "catalog:" in package.json

CHECK 1.4: (UFA only) uwm-manifest.json exists with required fields
  - moduleName, route, port, rootComponent, themeFamily

CHECK 1.5: spec/ directory exists for .feature files

CHECK 1.6: No UFA→UFA dependencies
  Grep in package.json for dependencies on other UFA packages
```

**If any check fails:** Stop and fix before proceeding. Do NOT continue to Phase 2 with invalid package structure.

---

## Phase 2: Design Components

**Announce:** "Phase 2: Design Components — Loading design-ui-component skill."

Load the `design-ui-component` sub-skill:

```
Skill: uwm-frontend-dev:design-ui-component
```

This skill will:
- Guide DREAM component selection (DREAM → MUI fallback → custom)
- Enforce DREAM styling standards (theme variables, sx prop, no magic numbers)
- Set up component structure following allin-ui patterns
- Handle DREAM + MUI coexistence for components DREAM doesn't cover

### Checkpoint 2: DREAM Compliance

After Phase 2 completes, verify:

```
CHECK 2.1: Components import from lib-node-dream-ui where available
  Grep: "from 'lib-node-dream-ui'" or "from \"lib-node-dream-ui\"" in src/

CHECK 2.2: No direct MUI imports when DREAM equivalent exists
  Grep: "from '@mui/material'" in src/ → verify each is for a component DREAM doesn't provide

CHECK 2.3: No magic numbers in styles
  Grep for raw pixel values in sx props (e.g., padding: 8, margin: 16)
  → Should use theme.spacing(), theme.palette.*, theme.typography.*

CHECK 2.4: No inline styles (style={{...}})
  Grep: "style={{" or "style={" in src/**/*.tsx

CHECK 2.5: No CSS shorthand in sx props
  Grep: " px:" or " py:" or " mx:" or " my:" or " bg:" in sx props
  → Should use paddingX, paddingY, marginX, marginY, backgroundColor
```

**If any check fails:** Stop and fix before proceeding. DREAM compliance must be established before implementation.

---

## Phase 3: TDD Implementation

**Announce:** "Phase 3: TDD Implementation — Loading implement-ui-feature skill."

Load the `implement-ui-feature` sub-skill:

```
Skill: uwm-frontend-dev:implement-ui-feature
```

This skill will:
- Write .feature specifications in {package}/spec/
- Derive Vitest unit tests from specs (RED → GREEN → REFACTOR)
- Integrate GUP auth patterns (MockPassport, usePassport, role-based rendering)
- Enforce business logic boundaries (UX-only in frontend)
- Run Stryker mutation testing for verification

### Checkpoint 3: TDD and Boundaries

After Phase 3 completes, verify:

```
CHECK 3.1: .feature spec files exist in spec/
  Glob: {package-path}/spec/*.feature

CHECK 3.2: Unit tests exist in __tests__/ directories
  Glob: {package-path}/src/**/__tests__/*.test.tsx

CHECK 3.3: Unit test coverage ≥80%
  Run: cd {package} && npx vitest run --coverage
  Verify: Lines coverage ≥80%

CHECK 3.4: Stryker mutation score ≥80
  Run: cd {package} && npx stryker run (if stryker.config.json exists)
  Verify: Score ≥80

CHECK 3.5: No business logic in frontend
  Review src/ for:
  - Mathematical calculations (should be in service)
  - Business validation rules (should be in service)
  - Orchestration logic (should be in service)
  - Shared state for business capabilities (should be in service)

CHECK 3.6: .feature files are NOT being executed directly
  Verify: No @cucumber/cucumber, cucumber, or gherkin in package.json dependencies

CHECK 3.7: Mock boundary correct
  Review test files: Only infrastructure is mocked (API clients, browser APIs)
  NOT mocked: Business logic, data transformers, component rendering

CHECK 3.8: afterEach cleanup present in all test files
  Grep: "afterEach" in test files → verify cleanup() called
```

**If any check fails:** Stop and fix before proceeding. TDD discipline and boundary enforcement are non-negotiable.

---

## Phase 4: Comprehensive Testing

**Announce:** "Phase 4: Comprehensive Testing — Loading test-frontend skill."

Load the `test-frontend` sub-skill:

```
Skill: uwm-frontend-dev:test-frontend
```

This skill will:
- Configure vitest.config.ts with correct coverage settings
- Set up Stryker mutation testing config (if not already done)
- Write Playwright E2E smoke test (minimum requirement)
- Write Playwright soak tests for CUJs (if applicable)
- Configure SonarQube integration (sonar-project.properties)
- Verify pipeline compliance (time limits, JUnit output)

### Checkpoint 4: Test Infrastructure Complete

After Phase 4 completes, verify:

```
CHECK 4.1: vitest.config.ts exists with jsdom, globals, v8 coverage
  Glob: {package-path}/vitest.config.ts

CHECK 4.2: setupTests.ts exists with @testing-library/jest-dom and matchMedia mock
  Glob: {package-path}/src/setupTests.ts or {package-path}/src/testUtils/setupTests.ts

CHECK 4.3: E2E smoke test exists
  Glob: {package-path}/tests/e2e/smoke.ts

CHECK 4.4: sonar-project.properties exists
  Glob: {package-path}/sonar-project.properties

CHECK 4.5: Coverage ≥80% lines
  Run: cd {package} && npx vitest run --coverage --coverage.thresholds.lines=80

CHECK 4.6: Build + tests complete in under 1 minute
  Run: cd {package} && time npx vitest run

CHECK 4.7: Package registered in vitest.workspace.ts
  Grep: "{package-name}" in vitest.workspace.ts
```

**If any check fails:** Fix before considering the work complete.

---

## Continuous Standards Enforcement

These standards apply at ALL phases, not just specific checkpoints. Verify continuously during development.

### Business Logic Boundary

**Frontend code handles ONLY:**
- Rendering and display formatting
- Navigation and routing
- Form UX (field state, validation display, submission UX)
- Loading states, error display, empty states
- User interaction feedback

**Frontend code NEVER handles:**
- Business calculations (LTV ratios, payment amounts, interest rates)
- Business validation rules (eligibility checks, compliance rules)
- Orchestration (coordinating multiple services)
- Shared state for business capabilities (cross-UFA data sharing)
- Queue management or workflow orchestration

**If business logic is needed:** It belongs in a backend service. Use `createGateway` from `@uwm/platform-api` to call it. If the service doesn't exist yet, use `uwm-business-service-dev:develop-business-service` to create it.

### Authentication

- GUP via `lib-node-user-passport-component` — already integrated in allin-ui for free
- Use `usePassport()` for user info and auth state
- Use `useAppShellRoles()` from `@uwm/platform-api` for role-based access
- Use `MockPassport` in tests — NEVER mock auth manually
- NEVER implement custom authentication

### DREAM Design System

- Import from `lib-node-dream-ui` first — check if DREAM has the component
- Use MUI (`@mui/material`) ONLY for components DREAM doesn't provide (Grid, useMediaQuery, utility components)
- ALWAYS use theme variables: `theme.palette.*`, `theme.spacing()`, `theme.typography.*`
- NEVER use magic numbers in styles
- NEVER use inline `style={{}}` — use `sx` prop
- NEVER use CSS shorthand in sx props (use `paddingX` not `px`)

### Dependencies

- Use `catalog:` protocol for shared dependencies (React, DREAM, Vitest, etc.)
- Use `workspace:*` for local workspace packages
- NEVER add React, DREAM, or other core libraries with direct version numbers
- NEVER create UFA→UFA dependencies (violates MFE architecture boundary)

### Code Quality

- No TypeScript `any` types — ever
- Cleanup in `afterEach` for every test (prevents state corruption)
- .feature files are specifications ONLY — never install BDD test runners
- Unit tests + build under 1 minute per package

</the_process>

<examples>

## Example 1: New UFA from Scratch

**User:** "I need to build a new loan status dashboard"

**Context Detection:**
```
CHECK 1: pnpm-workspace.yaml → YES (allin-ui monorepo)
CHECK 2: ufas/loan-status/ → does NOT exist
RESULT: New package needed in allin-ui
```

**Orchestrator output:**
```
Context detected:
- Environment: allin-ui monorepo
- Package: loan-status (new)
- Status: needs creation
- Starting from: Phase 1 (scaffold)
- Component type: TBD (will determine in Phase 1)

I'll chain through all 4 phases:
1. create-allin-package → scaffold the UFA
2. design-ui-component → design DREAM components
3. implement-ui-feature → TDD implementation
4. test-frontend → comprehensive test setup
```

**Phase execution:**
1. Phase 1: `create-allin-package` → runs `turbo gen ufa`, creates uwm-manifest.json, sets up catalog deps
2. Checkpoint 1: Verify ufas/loan-status/ exists, uwm-manifest.json valid, catalog deps
3. Phase 2: `design-ui-component` → identify DREAM components, create component tree
4. Checkpoint 2: Verify DREAM imports, no magic numbers, no inline styles
5. Phase 3: `implement-ui-feature` → write .feature specs, TDD cycle, GUP auth
6. Checkpoint 3: Verify .feature files, tests pass, coverage ≥80%, mutation ≥80, no business logic
7. Phase 4: `test-frontend` → vitest config, E2E smoke test, SonarQube
8. Checkpoint 4: Verify E2E exists, coverage enforced, time limits met

---

## Example 2: Adding Feature to Existing UFA

**User:** "Add a filter feature to the action-iq UFA"

**Context Detection:**
```
CHECK 1: pnpm-workspace.yaml → YES (allin-ui monorepo)
CHECK 2: ufas/action-iq/package.json → EXISTS
CHECK 3: uwm-manifest.json → EXISTS → UFA
CHECK 4: src/**/*.tsx → EXISTS, spec/ → EMPTY, __tests__/ → EXISTS
RESULT: Existing UFA, has source and tests, no .feature specs yet
```

**Orchestrator output:**
```
Context detected:
- Environment: allin-ui monorepo
- Package: action-iq (existing UFA)
- Status: existing with source and tests
- Starting from: Phase 2 (design) — package exists, skipping scaffold
- Note: No .feature specs found — Phase 3 will establish the practice

Skipping Phase 1 (package already exists).
I'll chain through phases 2-4:
2. design-ui-component → design filter component with DREAM
3. implement-ui-feature → write .feature spec for filter, TDD cycle
4. test-frontend → verify test infrastructure
```

---

## Example 3: Creating a Shared Component Library

**User:** "Create a reusable loan card component that BrokerDrive and action-iq both need"

**Context Detection:**
```
CHECK 1: pnpm-workspace.yaml → YES (allin-ui monorepo)
CHECK 2: packages/loan-card/ → does NOT exist
RESULT: New package needed, shared between 2+ UFAs → SCL
```

**Orchestrator output:**
```
Context detected:
- Environment: allin-ui monorepo
- Package: loan-card (new)
- Status: needs creation
- Starting from: Phase 1 (scaffold)
- Component type: SCL (shared between BrokerDrive and action-iq)

I'll chain through all 4 phases:
1. create-allin-package → scaffold SCL in packages/
2. design-ui-component → design DREAM-compliant loan card
3. implement-ui-feature → TDD implementation
4. test-frontend → test infrastructure
```

---

## Example 4: Legacy SPA Detected

**User:** "I need to add a feature to cell-ui-lending"

**Context Detection:**
```
CHECK 1: pnpm-workspace.yaml → NO
CHECK: directory name matches cell-ui-* → YES → Legacy SPA
```

**Orchestrator output:**
```
This appears to be a legacy SPA (cell-ui-lending). The current UWM standard
is the allin-ui monorepo.

Options:
1. Migrate to allin-ui → I'll use the migrate-spa-to-allin skill
2. Maintain as legacy → I'll use the maintain-legacy-spa skill
3. Start fresh in allin-ui → I'll guide you through creating a new UFA

Which would you like to do?
```

</examples>

<critical_rules>

## Rules That Have No Exceptions

1. **Run ALL context detection checks before starting any phase.** Never assume the context — detect it with Glob/Grep.

2. **Run standards checkpoints between every phase.** Never skip a checkpoint even if "everything looks fine." Check with actual Glob/Grep commands.

3. **Phase ordering is rigid.** Scaffold → Design → Implement → Test. You can skip phases (if context detection confirms completion) but never reorder them.

4. **Business logic boundary is non-negotiable.** If you detect calculations, business validation, or orchestration in frontend code, stop and redirect to backend service development.

5. **DREAM compliance is non-negotiable.** If a DREAM component exists for the need, use it. MUI is only for components DREAM doesn't provide.

6. **GUP auth is the only auth.** Never implement custom authentication. `lib-node-user-passport-component` and `@uwm/platform-api` provide everything needed.

7. **No UFA→UFA dependencies.** If two UFAs need the same component, create an SCL. Violating this breaks the MFE architecture.

8. **Legacy SPA → redirect.** This skill is for allin-ui. Legacy SPAs get redirected to `migrate-spa-to-allin` or `maintain-legacy-spa`.

9. **catalog: protocol mandatory.** All shared dependencies (React, DREAM, Vitest, etc.) must use the catalog: protocol. Direct version numbers are forbidden for core libraries.

10. **Load sub-skills via Skill tool.** Do not inline sub-skill content. Load the actual skill files so they stay current.

## Common Excuses

All of these mean: **STOP. Follow the process.**

- "I know the context, don't need detection" (Detection prevents wrong assumptions. Always run checks.)
- "This phase is trivial, skip the checkpoint" (Checkpoints catch subtle violations. Always verify.)
- "The calculation is simple, keep it in frontend" (Business logic belongs in services. Always.)
- "MUI is easier for this component" (Check DREAM first. MUI only if DREAM doesn't have it.)
- "Just one UFA import, it's fine" (UFA→UFA dependencies break MFE architecture. Create an SCL.)
- "I'll use the skill from memory" (Skills evolve. Use the Skill tool to load current version.)

</critical_rules>

<edge_cases>

## Mid-Project Entry

When context detection finds a partially-completed package:

1. **Has package, no source:** Start at Phase 2 (design). The package was scaffolded but not yet developed.
2. **Has source, no tests:** Start at Phase 3 (implement with TDD). Emphasize that .feature specs should be written for existing code too.
3. **Has tests, no E2E or coverage config:** Start at Phase 4 (test infrastructure). The implementation exists but test strategy is incomplete.
4. **Everything present:** Run standards checkpoints only. Verify compliance without re-running phases.

## Package Type Ambiguity

If context detection can't determine UFA vs SCL vs IAP:

Use AskUserQuestion:
```
I found a package at {path} but can't determine the component type.

Does this package:
A. Own its own routes and serve as a standalone application? → UFA
B. Provide shared components used by multiple UFAs? → SCL
C. Provide a cross-UFA product with its own deployment lifecycle? → IAP
```

## Not in allin-ui Root

If the developer is working inside a specific package directory (e.g., `ufas/action-iq/`) rather than the repo root:

Navigate up to find the monorepo root:
```
Glob: ../../pnpm-workspace.yaml
Glob: ../../../pnpm-workspace.yaml
```

Use the monorepo root for context detection while working in the package directory.

## Multiple Features Requested

If the user requests multiple features spanning different packages:

1. Handle one package at a time
2. Complete all phases for the first package before moving to the next
3. If features share components, identify the SCL opportunity first

## Non-React Framework Detected

If context detection finds Angular, Vue, or other frameworks:

```
This codebase uses {framework}. UWM frontend standard requires React.
All new frontend development must use React in the allin-ui monorepo.

Options:
1. Start a new React UFA in allin-ui for this feature
2. This is a legacy system — use maintain-legacy-spa for guidance
```

## Existing Code Without Tests

When adding features to packages that have source code but no tests:

- Do NOT skip testing. Phase 3 (implement-ui-feature) requires TDD.
- Write .feature specs for the existing behavior FIRST, then derive tests.
- New features follow full TDD cycle.
- Existing code without tests should get at least smoke-level coverage.

</edge_cases>

<verification_checklist>

Before considering development complete, verify all standards:

**Package Structure:**
- [ ] Package in correct directory (ufas/ for UFA, packages/ for SCL/IAP)
- [ ] package.json uses @uwm/ scope
- [ ] Dependencies use catalog: protocol for shared libs
- [ ] No UFA→UFA dependencies in package.json
- [ ] (UFA) uwm-manifest.json exists with moduleName, route, port, themeFamily

**DREAM Compliance:**
- [ ] Components import from lib-node-dream-ui where available
- [ ] MUI imports only for components DREAM doesn't provide
- [ ] No magic numbers in styles (theme.spacing, theme.palette, theme.typography)
- [ ] No inline style={{}} — uses sx prop
- [ ] No CSS shorthand in sx props

**TDD and Business Logic:**
- [ ] .feature specs exist in {package}/spec/
- [ ] Unit tests exist in __tests__/ directories
- [ ] Coverage ≥80% lines
- [ ] Stryker mutation score ≥80
- [ ] No business logic in frontend (calculations, validation rules, orchestration)
- [ ] .feature files are NOT executed directly (no BDD runner installed)
- [ ] Mock boundary: only infrastructure mocked in tests

**Auth:**
- [ ] GUP via lib-node-user-passport-component (not custom auth)
- [ ] MockPassport used in tests (not manual auth mocking)

**Test Infrastructure:**
- [ ] vitest.config.ts with jsdom, globals: true, v8 coverage
- [ ] setupTests.ts with @testing-library/jest-dom and matchMedia mock
- [ ] E2E smoke test at tests/e2e/smoke.ts
- [ ] sonar-project.properties for SonarQube
- [ ] Package in vitest.workspace.ts
- [ ] Build + tests under 1 minute

**Code Quality:**
- [ ] No TypeScript `any` types
- [ ] afterEach cleanup in all test files
- [ ] No TODO without issue reference

</verification_checklist>

<integration>

**This skill chains through:**
1. `create-allin-package` — Phase 1: scaffold new package
2. `design-ui-component` — Phase 2: DREAM component design
3. `implement-ui-feature` — Phase 3: TDD implementation
4. `test-frontend` — Phase 4: comprehensive test strategy

**This skill redirects to:**
- `migrate-spa-to-allin` — when legacy SPA (cell-ui-*) detected and user wants to migrate
- `maintain-legacy-spa` — when legacy SPA detected and user wants to maintain as-is
- `uwm-business-service-dev:develop-business-service` — when backend service work detected

**This skill is the default entry point for:**
- Any frontend development request at UWM
- Any request involving allin-ui, DREAM, or GUP auth in a frontend context

**Phase skill chain:**
```
develop-frontend (orchestrator)
  ├── Phase 1: create-allin-package (skip if exists)
  │     └── Checkpoint 1: package structure
  ├── Phase 2: design-ui-component
  │     └── Checkpoint 2: DREAM compliance
  ├── Phase 3: implement-ui-feature
  │     └── Checkpoint 3: TDD + boundaries
  └── Phase 4: test-frontend
        └── Checkpoint 4: test infrastructure
```

</integration>

<resources>

**allin-ui codebase:**
- `EH/allin-ui` on Bitbucket — monorepo MFE
- `turbo.json` — task definitions, boundary tags
- `pnpm-workspace.yaml` — workspace config with `catalogMode: strict` and catalog versions
- `vitest.workspace.ts` — monorepo test orchestration
- `ufas/example/` — reference UFA with uwm-manifest.json
- `packages/shared-components/` — reference SCL
- `packages/actioniq/` — reference IAP (multi-package)

**Design system:**
- `UCP/lib-node-dream-ui` on Bitbucket — DREAM component library
- https://dream.uwm.com — DREAM Storybook documentation

**Auth:**
- `lib-node-user-passport-component` — GUP auth (PassportAuth, usePassport, MockPassport)
- `@uwm/platform-api` — App-shell integration (useAppShellRoles, usePolicy, createGateway)
- `SOLAR/cell-user-passport` on Bitbucket — GUP backend ecosystem

**Confluence:**
- Component Taxonomy (page ID: 1514786638) — UFA/IAP/SCL definitions and decision tree
- Policies and Standards (page ID: 1479759939) — Testing policy, thresholds, time limits
- CD Pipeline Design (page ID: 1467250722) — Pipeline stages and test execution
- GUP UI Onboarding Guide — Auth integration walkthrough
- DREAM Design System docs — Figma workflow, design tokens, product theming

**Other plugins:**
- `uwm-business-service-dev:develop-business-service` — Backend service orchestrator (reference pattern)
- `spec-driven-development` — Spec-driven development skills

</resources>
