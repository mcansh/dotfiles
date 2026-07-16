---
name: create-allin-package
description: Use when creating a new package in the allin-ui monorepo - guides through component taxonomy (UFA/IAP/SCL), Turbo scaffolding, dependency configuration, and manifest setup
---

<skill_overview>
Guides the complete process of creating a new package in the allin-ui monorepo, from choosing the correct component type through scaffolding, dependency configuration, and verification. This skill enforces the component taxonomy (UFA, IAP, SCL), ensures correct directory placement, dependency protocols (`catalog:`, `workspace:*`), and architectural boundary compliance.

**Critical context:** allin-ui is a pnpm monorepo using Turborepo and module federation. UFAs live in `ufas/`, shared libraries live in `packages/`. The repo uses `catalogMode: strict` — all shared dependencies must use the `catalog:` protocol with versions managed centrally in `pnpm-workspace.yaml`. Turbo generators (`turbo gen ufa`, `turbo gen lib`) handle scaffolding. Architectural boundaries are enforced via `turbo boundaries` using tag-based rules.
</skill_overview>

<rigidity_level>
LOW FREEDOM - The component taxonomy decision tree is rigid and must follow prescribed criteria. Turbo generators must be used for scaffolding (no manual creation). Dependency protocols and directory placement are non-negotiable. Configuration details (port, route, theme) adapt to the specific package.
</rigidity_level>

<quick_reference>

| Step | Action | Key Details |
|------|--------|-------------|
| **1. Decide Type** | Component taxonomy | UFA (app with routes), SCL (shared components), IAP (advanced cross-UFA product) |
| **2. Scaffold** | `turbo gen ufa` or `turbo gen lib` | Generator prompts for name, publish dest, and type-specific fields |
| **3. Configure Deps** | Add DREAM, GUP, internal packages | Use `catalog:` for shared deps, `workspace:*` for local packages |
| **4. Configure Manifest** | `uwm-manifest.json` (UFAs only) | moduleName, route, port, themeFamily, roleMatrix |
| **5. Create Spec Dir** | `{package}/spec/` | Feature specs for TDD workflow |
| **6. Verify** | `pnpm install && pnpm build` | Also run `turbo boundaries` to check architectural compliance |

**Component Type Decision:**
- Owns routes and layout? → **UFA** (in `ufas/`)
- Shared between 2+ UFAs? → **SCL** (in `packages/`)
- Cross-UFA product with independent SDLC? → **IAP** (in `packages/`, advanced)

</quick_reference>

<when_to_use>
- Creating a brand new User Facing Application (UFA) in allin-ui
- Creating a shared component library (SCL) for use across multiple UFAs
- Creating an In App Product (IAP) for cross-UFA functionality with independent lifecycle
- Need guidance on which component type to create
- Need guidance on allin-ui dependency protocols and configuration

**Do NOT use for:**
- Adding features to an existing package (use `implement-ui-feature`)
- Creating a dedicated SPA (cell-ui-*) — legacy pattern, consider migration to allin-ui instead
- Creating a BFF service (cell-bff-*) — use `create-v3-service` from uwm-business-service-dev
- Contributing components TO the DREAM library itself — see dream-buddy.md
- Modifying app-shell or navigation platform — managed by the app shell team
</when_to_use>

<the_process>

## Step 1: Determine the Component Type

The single most important decision is choosing the correct component type. Getting this wrong causes architectural violations that `turbo boundaries` will reject.

### Component Taxonomy Decision Tree

Use AskUserQuestion to walk through this decision:

**Question 1: Does this component own its own routes and serve as a standalone application?**

| Answer | Result |
|--------|--------|
| **Yes** — It has its own URL path, layout, and page composition | → **UFA** (User Facing Application) |
| **No** — It's a reusable component or service used inside other apps | → Continue to Question 2 |

**Question 2: Will 2+ UFAs use this component?**

| Answer | Result |
|--------|--------|
| **No** — Only one UFA uses it | → Keep it inside that UFA's `src/` directory. Do NOT create a separate package. |
| **Yes** — Multiple UFAs need it | → Continue to Question 3 |

**Question 3: Does a separate team need to control this component's deployment lifecycle independently across multiple UFAs?**

| Answer | Result |
|--------|--------|
| **No** — One team owns the component, consumers just import it | → **SCL** (Shared Component Library) |
| **Yes** — The component has its own release cycle, state management across UFAs, and a dedicated team | → **IAP** (In App Product) — **Use sparingly. Discuss with app shell team first.** |

### Component Type Reference

| Type | Definition | Directory | Build Tool | Generator | Examples |
|------|-----------|-----------|------------|-----------|---------|
| **UFA** | Self-contained application with dedicated UX. Owns routes, layout, orchestration. | `ufas/{name}/` | Vite | `turbo gen ufa` | income-calculator, loan-import, scenario-center |
| **SCL** | Reusable components shared between 2+ UFAs/IAPs. Config-driven with clear contracts. | `packages/{name}/` | tsup | `turbo gen lib` | shared-components, 1003-application |
| **IAP** | Product component running alongside UFAs with independent SDLC. Multi-directory structure. | `packages/{name}/` | tsup | Manual (no generator) | actioniq, chat-assist, onav |

### Module Dependency Rules

These rules are enforced by `turbo boundaries` via tags in `turbo.json`:

| Dependency | Allowed? | Reason |
|-----------|----------|--------|
| UFA → SCL (public packages) | YES | UFAs consume shared components |
| IAP → SCL (public packages) | YES | IAPs consume shared components |
| SCL → SCL (public packages) | YES | Libraries can compose other libraries |
| UFA → UFA | **FORBIDDEN** | Violates module federation isolation |
| UFA → IAP | **FORBIDDEN** | UFAs cannot directly depend on IAPs |
| IAP → IAP | **FORBIDDEN** | Creates circular dependency risk |
| UFA → app-shell / internal | **FORBIDDEN** | App shell is not a consumable dependency |
| Any → private packages | **FORBIDDEN** | Private packages are isolated |

**Boundary tag mapping:**
- UFAs get the `ufas` tag — can only depend on `public` packages
- SCLs get the `public` tag — can be depended on by UFAs, IAPs, other SCLs
- IAPs use granular tags (`core-*`, `lib-*`, `shell-*`) — fine-grained dependency control
- App shell and internal packages are restricted from UFA consumption

Run `pnpm lint:architecture` (alias for `turbo boundaries`) to verify compliance.

---

## Step 2: Scaffold Using Turbo Generators

### Creating a UFA

```bash
pnpm create-ufa
# OR equivalently:
turbo gen ufa
```

The generator prompts for:

| Field | Description | Guidance |
|-------|-------------|----------|
| **packageName** | Package name (lowercase, hyphens only) | e.g., `loan-center`, `broker-dashboard`. Becomes `@uwm/{name}` in package.json and `ufas/{name}/` directory. |
| **publishToArtifactory** | Publish destination | Choose "Artifactory" if other projects outside allin-ui consume this. Choose "Local" for allin-ui-only. |
| **title** | Human-readable application title | Displayed in navigation. e.g., "Loan Center", "Broker Dashboard". |
| **route** | Base URL path | e.g., `/loan-center`. Must be unique across all UFAs. |
| **themeFamily** | DREAM theme | `external` for broker-facing apps, `internal` for internal tools. |
| **port** | Dev server port | Press Enter for auto-generated unused port. Generator checks all existing `uwm-manifest.json` files to avoid conflicts. Avoids reserved ports: 3000, 5000, 5001, 9000. |
| **maintainers** | Package maintainers | Team members responsible for this UFA. |

**Generated structure:**
```
ufas/{name}/
  package.json          # @uwm/{name}, private, vite scripts
  vite.config.ts        # Dev server, module federation plugin
  vitest.config.ts      # Test configuration
  tsconfig.json         # TypeScript config
  uwm-manifest.json     # Module federation manifest
  src/
    App.tsx             # Root component
    ...
```

### Creating a Library / SCL

```bash
pnpm create-lib
# OR equivalently:
turbo gen lib
```

The generator prompts for:

| Field | Description | Guidance |
|-------|-------------|----------|
| **packageName** | Package name (lowercase, hyphens only) | e.g., `shared-widgets`, `loan-components`. Becomes `@uwm/{name}`. |
| **publishToArtifactory** | Publish destination | "Artifactory" if consumed outside allin-ui, "Local" for internal only. |

**Generated structure:**
```
packages/{name}/
  package.json          # @uwm/{name}, tsup build, dual CJS/ESM exports
  tsup.config.ts        # Build configuration
  vitest.config.ts      # Test configuration
  tsconfig.json         # TypeScript config
  src/
    index.ts            # Public API barrel export
    ...
```

### Creating an IAP (Advanced — Manual Setup)

There is **no Turbo generator for IAPs**. IAPs require manual setup following the multi-directory pattern. This is intentional — IAPs are complex and should be rare.

**Only create an IAP after discussing with the app shell team.**

IAPs follow a multi-directory structure within `packages/`:

```
packages/{name}/
  core/                 # Business logic, shared types, state management
    package.json        # @uwm/core-{name}
    src/
  lib-node-{name}/      # npm-publishable library (consumer API)
    package.json        # @uwm/lib-{name}
    src/
  shell-{name}/         # App-shell integration (lifecycle, mounting)
    package.json        # @uwm/shell-{name}
    src/
```

**Reference implementations:** Study `packages/actioniq/`, `packages/chat-assist/`, or `packages/onav/` for the pattern.

Each sub-package needs its own boundary tag in `turbo.json`. Work with the app shell team to add the appropriate tag rules.

---

## Step 3: Configure Package Dependencies

After scaffolding, add the dependencies your package needs. allin-ui uses three dependency protocols:

### Dependency Protocol System

| Protocol | Syntax | Meaning | When to Use |
|----------|--------|---------|-------------|
| **catalog:** | `"react": "catalog:"` | Version resolved from the `catalog` section in `pnpm-workspace.yaml` | Shared external packages managed centrally. **Required for all packages listed in the catalog.** |
| **workspace:*** | `"@uwm/shared-components": "workspace:*"` | Local monorepo package, always uses latest local version | Cross-package references within allin-ui |
| **semver** | `"axios": "^1.9.0"` | Standard npm version range | Package-specific deps NOT in the catalog |

**CRITICAL: `catalogMode: strict`** — If a package exists in the catalog section of `pnpm-workspace.yaml`, you MUST use `"catalog:"` as the version. Using a direct semver version for a catalog package will cause `pnpm install` to fail. If your package needs a different version of a catalog entry, escalate to the app shell team — do not work around it.

### Adding DREAM Design System

The Turbo generator does NOT add DREAM to UFA dependencies by default. You must add it manually.

For **UFAs** — add to `peerDependencies` (provided by module federation at runtime):
```json
{
  "peerDependencies": {
    "lib-node-dream-ui": "catalog:"
  }
}
```

For **SCLs** — already included in the lib template's `peerDependencies`:
```json
{
  "peerDependencies": {
    "lib-node-dream-ui": "catalog:"
  }
}
```

**DREAM version note:**
- `lib-node-dream-ui` — DREAM v2 (current stable, `^2.9.1` in catalog)
- `lib-node-dream-ui-latest` — npm alias for DREAM v3 (`npm:lib-node-dream-ui@^3.1.2` in catalog)
- Check which version your team should use. New projects may prefer v3 (`lib-node-dream-ui-latest`).

### Adding GUP Auth

GUP auth is already integrated into the allin-ui app shell. You do NOT need to set up GUP yourself.

To use GUP features in your package, add `lib-node-user-passport-component` as a peer dependency:

```json
{
  "peerDependencies": {
    "lib-node-user-passport-component": "catalog:"
  }
}
```

This gives you access to:
- `PassportAuth` — wrapper component for auth-protected routes
- `usePassport()` — hook to access user info, roles, tokens
- `useSinglePageAuth()` — hook for SPA-style auth flow
- `useAuthExclusion()` — hook for excluding routes from auth
- `MockPassport` — test double for unit testing auth-dependent components
- `roleMatrix` — role-based access control configuration (in `uwm-manifest.json`)

### Adding Internal Packages

For dependencies on other allin-ui packages:
```json
{
  "peerDependencies": {
    "@uwm/shared-components": "workspace:*",
    "@uwm/platform-api": "workspace:*"
  }
}
```

### Module Federation Shared Libraries

These are provided by the app shell at runtime via module federation. They MUST be `peerDependencies`, NOT direct `dependencies`:

| Package | Protocol | Purpose |
|---------|----------|---------|
| `react` | `catalog:` | React core |
| `react-dom` | `catalog:` | React DOM |
| `lib-node-dream-ui` | `catalog:` | DREAM design system |
| `lib-node-user-passport-component` | `catalog:` | GUP auth |
| `@uwm/platform-api` | `workspace:*` | App shell platform API |
| `@uwm/shared-components` | `workspace:*` | Shared component library |

**Why peerDependencies?** Module federation shares a single instance of these libraries across all UFAs at runtime. Bundling them as direct dependencies would create duplicate instances, causing React context errors, DREAM theme mismatches, and auth session splits.

---

## Step 4: Configure UFA-Specific Files

### uwm-manifest.json

Every UFA requires a `uwm-manifest.json` in its root directory. The Turbo generator creates this automatically, but you should review and customize it.

```json
{
  "moduleName": "{kebab-case-name}",
  "title": "{Human Readable Title}",
  "route": "/{kebab-case-name}",
  "rootComponent": "./src/App.tsx",
  "port": {unique-port},
  "excludeFromSideNav": false,
  "themeFamily": "external",
  "policies": [],
  "roleMatrix": {},
  "subRoutes": [
    { "id": "home", "path": "" }
  ],
  "menus": []
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `moduleName` | Yes | Must match the directory name in `ufas/`. Used for module federation registration. |
| `title` | Yes | Human-readable name shown in navigation sidebar. |
| `route` | Yes | URL path this UFA owns. Must be unique across all UFAs. |
| `rootComponent` | Yes | Entry point component, typically `./src/App.tsx`. |
| `port` | Yes | Dev server port. Auto-generated by Turbo to avoid conflicts. |
| `excludeFromSideNav` | No | Set `true` to hide from navigation (e.g., utility UFAs). Default: `false`. |
| `themeFamily` | Yes | DREAM theme to apply: `"external"` (broker-facing) or `"internal"` (internal tools). |
| `policies` | No | GUP policy conditions for access control. Empty `[]` = unrestricted. |
| `roleMatrix` | No | GUP role groups for RBAC. Empty `{}` = no role restrictions. |
| `subRoutes` | Yes | Array of routes this UFA handles. Minimum: `[{ "id": "home", "path": "" }]`. |
| `menus` | No | Navigation menu items to display for this UFA. |

### Role-Based Access Control Example

For UFAs that need restricted access:

```json
{
  "roleMatrix": {
    "admins": ["IT Brand 360 Admin", "Dev Servers Admin"],
    "developers": ["Web Developers", "Snyk-AppDev"]
  },
  "policies": {
    "admin": {
      "requireAll": true,
      "conditions": [
        { "type": "policy", "policies": ["uwm"] },
        { "type": "roleMatrix", "roleMatrixName": "{moduleName}", "roles": ["admins"] }
      ]
    }
  }
}
```

The `roleMatrixName` must match the `moduleName` of the UFA. Roles reference groups defined in GUP. The `"uwm"` base policy ensures the user is an authenticated UWM user.

---

## Step 5: Create Spec Directory

Specs drive TDD implementation. Create the spec directory inside your package:

```
{package}/
  spec/
    capabilities/
      {capability-name}/
        README.md           # Capability overview
        features/
          {feature-name}.feature  # Feature spec (Gherkin syntax, NOT executable)
```

**The `.feature` files are specifications, NOT executable BDD tests.** They describe expected behavior in Gherkin syntax and are used to derive Vitest unit tests. Do NOT attempt to execute them with Cucumber or similar tools.

Example spec structure for a UFA:
```
ufas/loan-center/
  spec/
    capabilities/
      loan-overview/
        README.md
        features/
          display-loan-summary.feature
          filter-loans-by-status.feature
      condition-tracking/
        README.md
        features/
          view-conditions.feature
          update-condition-status.feature
```

---

## Step 6: Dual-Mode Component Pattern (3-Layer Decomposition)

When a component needs to work both as a standalone UFA AND as an embedded component inside another UFA, use the 3-layer decomposition pattern. This avoids the anti-pattern of creating sub-UFAs or embedded-mode routing hacks.

```
Layer 3: UFA Pages (thin composition layer)
  Location: ufas/{consuming-ufa}/src/pages/
  Purpose: Thin page components that compose Layer 2 components
  Example: <LoanPage> fetches loan data, passes to <IncomePanel loanData={data} />

    |
    | imports (via workspace:*)
    v

Layer 2: Higher Level Component (data adapter)
  Location: packages/{scl}/src/components/{Name}/
  Purpose: Maps external data (e.g., loan object) → core component props
  Props: { loanId, loanData } — accepts data from consuming context
  Example: <IncomePanel loanData={data} /> extracts income fields → passes to <IncomeDisplay>

    |
    | imports (same package)
    v

Layer 1: Core Component (stateless, props-driven)
  Location: packages/{scl}/src/components/{Name}/
  Purpose: Pure UI + calculation logic. Stable contract.
  Props: { employmentIncome, assetIncome, otherIncome, ... }
  Example: <IncomeDisplay employmentIncome={1200} assetIncome={300} />
```

**Both Layer 1 and Layer 2 live in the same SCL package** (e.g., `packages/shared-components/`). Layer 3 lives in each consuming UFA.

**When to use this pattern:**
- Income Calculator exists as standalone UFA, but income display also needed inside Loan Center
- Credit component exists as standalone UFA, but credit summary needed inside AUS

**When NOT to use this pattern:**
- Component only used in one UFA — keep it in that UFA's `src/`
- Component shared but always used the same way — simple SCL export is sufficient

---

## Step 7: Verify Setup

After scaffolding and configuring, verify everything works:

```bash
# Install dependencies (validates catalog: protocol compliance)
pnpm install

# Build the new package
pnpm build --filter=@uwm/{name}

# Run tests (should pass with generated boilerplate)
pnpm test --filter=@uwm/{name}

# Verify architectural boundary compliance
pnpm lint:architecture
# OR equivalently:
turbo boundaries

# Verify catalog entries are correct
pnpm check:catalog

# Full validation suite
pnpm validate
```

**If `pnpm install` fails with a catalog error:** You used a direct semver version for a package that exists in the catalog. Replace it with `"catalog:"`.

**If `turbo boundaries` fails:** Your package depends on something it shouldn't. Check the module dependency rules in Step 1 and fix the offending import.

</the_process>

<examples>

<example>
<scenario>Creating a new UFA for a Loan Center application</scenario>

<code>
# Step 1: Determine type
# - Owns routes (/loan-center)? YES → UFA
# - Has its own layout and pages? YES → UFA confirmed

# Step 2: Scaffold
turbo gen ufa
# Prompts:
#   packageName: loan-center
#   publishToArtifactory: Local (Scoped inside repo)
#   title: Loan Center
#   route: /loan-center
#   themeFamily: external (broker-facing)
#   port: [Enter for auto-generated]
#   maintainers: [team members]

# Step 3: Add DREAM and GUP to peerDependencies
# Edit ufas/loan-center/package.json:
{
  "peerDependencies": {
    "react": "catalog:",
    "react-dom": "catalog:",
    "lib-node-dream-ui": "catalog:",
    "lib-node-user-passport-component": "catalog:",
    "@uwm/platform-api": "workspace:*",
    "@uwm/shared-components": "workspace:*"
  }
}

# Step 4: Review uwm-manifest.json (auto-generated)
# Customize roleMatrix if access restrictions needed

# Step 5: Create spec directory
mkdir -p ufas/loan-center/spec/capabilities/loan-overview/features

# Step 6: Verify
pnpm install
pnpm build --filter=@uwm/loan-center
pnpm test --filter=@uwm/loan-center
pnpm lint:architecture
</code>
</example>

<example>
<scenario>Creating a shared component library for loan-related UI components</scenario>

<code>
# Step 1: Determine type
# - Owns routes? NO
# - Used by 2+ UFAs (Loan Center + AUS)? YES
# - Needs independent SDLC? NO → SCL (not IAP)

# Step 2: Scaffold
turbo gen lib
# Prompts:
#   packageName: loan-components
#   publishToArtifactory: Local (Scoped inside repo)

# Step 3: Verify dependencies
# The lib template already includes lib-node-dream-ui in peerDependencies.
# Add any additional internal packages needed:
# Edit packages/loan-components/package.json:
{
  "peerDependencies": {
    "lib-node-dream-ui": "catalog:",
    "@emotion/react": "catalog:",
    "@emotion/styled": "catalog:",
    "react": "catalog:",
    "react-dom": "catalog:"
  }
}

# Step 4: No uwm-manifest.json needed (SCLs don't have manifests)

# Step 5: Create spec directory
mkdir -p packages/loan-components/spec/capabilities/loan-display/features

# Step 6: Set up barrel export
# Edit packages/loan-components/src/index.ts:
export { LoanSummaryCard } from './components/LoanSummaryCard';
export { ConditionBadge } from './components/ConditionBadge';

# Step 7: Verify
pnpm install
pnpm build --filter=@uwm/loan-components
pnpm test --filter=@uwm/loan-components
pnpm lint:architecture
</code>
</example>

<example>
<scenario>Developer tries to import from one UFA into another UFA</scenario>

<code>
# WRONG: UFA importing from another UFA
// In ufas/loan-center/src/pages/OverviewPage.tsx
import { IncomeDisplay } from '@uwm/income-calculator';  // FORBIDDEN
</code>

<why_it_fails>
- UFA → UFA dependency violates module federation architecture
- `turbo boundaries` will reject this with a tag violation error
- Each UFA is independently deployed — importing creates a build-time coupling
  that breaks when the other UFA is deployed independently
- Solution: Extract shared components into an SCL in packages/
</why_it_fails>

<correction>
# CORRECT: Extract shared component to SCL
# 1. Move IncomeDisplay to packages/shared-components/src/components/
# 2. Export from packages/shared-components/src/index.ts
# 3. Import via SCL in both UFAs:

// In ufas/loan-center/src/pages/OverviewPage.tsx
import { IncomeDisplay } from '@uwm/shared-components';  // SCL import — allowed

// In ufas/income-calculator/src/pages/CalculatorPage.tsx
import { IncomeDisplay } from '@uwm/shared-components';  // Same SCL — allowed
</correction>
</example>

<example>
<scenario>Developer uses direct version instead of catalog protocol</scenario>

<code>
# WRONG: Direct version for a catalog-managed package
{
  "dependencies": {
    "react": "^18.3.1",
    "@mui/material": "^7.2.0"
  }
}
</code>

<why_it_fails>
- pnpm-workspace.yaml has `catalogMode: strict`
- react and @mui/material are both in the catalog
- `pnpm install` will fail with a catalog violation error
- Even if the version matches the catalog entry, the protocol must be "catalog:"
</why_it_fails>

<correction>
# CORRECT: Use catalog protocol
{
  "peerDependencies": {
    "react": "catalog:"
  },
  "dependencies": {
    "@mui/material": "catalog:"
  }
}
# Version resolved automatically from pnpm-workspace.yaml catalog section
</correction>
</example>

<example>
<scenario>Developer creates a UFA in packages/ instead of ufas/</scenario>

<code>
# WRONG: UFA in the wrong directory
turbo gen lib  # Using lib generator for a UFA
# Creates packages/loan-center/ with tsup build

# Or manually creating:
mkdir -p packages/loan-center
</code>

<why_it_fails>
- packages/ is for libraries (SCLs/IAPs) built with tsup
- UFAs need Vite for dev server, module federation, and HMR
- The turbo boundary tags are assigned based on directory location:
  - ufas/* → tagged as "ufas"
  - packages/* → tagged as "public" or specific IAP tags
- Wrong directory = wrong build pipeline, wrong boundary tags, wrong behavior
- The UFA won't be discovered by the app shell's module federation system
</why_it_fails>

<correction>
# CORRECT: Use the right generator for the right directory
turbo gen ufa   # Creates in ufas/{name}/ with Vite
turbo gen lib   # Creates in packages/{name}/ with tsup
</correction>
</example>

<example>
<scenario>Developer tries to create an IAP without consulting app shell team</scenario>

<code>
# WRONG: Creating IAP like a regular package
turbo gen lib
# packageName: my-cross-ufa-widget

# Then trying to mount it in multiple UFAs with shared state,
# custom lifecycle management, independent releases...
</code>

<why_it_fails>
- IAPs require multi-directory structure (core/, lib-node-*, shell-*)
- IAPs need custom boundary tags added to turbo.json
- IAPs have complex lifecycle management (mounting, unmounting, state isolation)
- The app shell team needs to integrate the IAP's shell component
- Without proper setup, the IAP won't participate in module federation correctly
</why_it_fails>

<correction>
# CORRECT: IAP creation workflow
# 1. Confirm IAP is truly needed (not just an SCL)
# 2. Discuss with app shell team
# 3. Study reference IAPs: packages/actioniq/, packages/onav/, packages/chat-assist/
# 4. Create multi-directory structure manually:
mkdir -p packages/my-widget/{core,lib-node-my-widget,shell-my-widget}/src
# 5. Work with app shell team to add boundary tags to turbo.json
# 6. Follow the pattern from reference IAPs for package.json, tsconfig, etc.
</correction>
</example>

</examples>

<critical_rules>

## Rules That Have No Exceptions

1. **ALWAYS use Turbo generators for scaffolding** — `turbo gen ufa` for UFAs, `turbo gen lib` for SCLs. Never manually create package directories and configs. The generators set up the correct build tooling, scripts, exports, and initial configuration.

2. **NEVER place UFAs in `packages/` or libraries in `ufas/`** — Directory determines the build pipeline (Vite vs tsup), boundary tags, and module federation registration. Wrong directory = broken build.

3. **ALWAYS use `"catalog:"` for catalog-managed packages** — `catalogMode: strict` means direct versions will cause `pnpm install` to fail. If you need a different version, escalate to the app shell team.

4. **NEVER create UFA → UFA dependencies** — Module federation requires UFAs to be independently deployable. Extract shared components to an SCL in `packages/`.

5. **ALWAYS put module federation shared libs in peerDependencies** — React, DREAM, GUP, and platform-api are shared at runtime. Direct dependencies create duplicate instances, causing React context errors and theme mismatches.

6. **NEVER create sub-UFAs or embedded mode routing hacks** — If a component needs to work standalone AND embedded, use the 3-layer decomposition pattern (Core → Higher Level → UFA Pages) with an SCL.

7. **ALWAYS verify with `turbo boundaries` after adding dependencies** — Architectural boundary violations must be caught before committing. Run `pnpm lint:architecture`.

8. **NEVER create an IAP without consulting the app shell team** — IAPs are architecturally complex. They require custom boundary tags, multi-directory setup, and app shell integration. Simple shared components should be SCLs.

9. **ALWAYS use `@uwm/` scope prefix** — All allin-ui packages are scoped under `@uwm/`. The Turbo generators handle this automatically.

10. **NEVER import from `@mui/material` when a DREAM component exists** — DREAM wraps MUI with UWM theming and standards. Import from `lib-node-dream-ui` instead. Check dream.uwm.com (Storybook) for available components.

## Common Mistakes

- "I'll just create the directory manually" → Use generators. They configure 10+ files correctly.
- "This needs to be an IAP" → It probably doesn't. SCLs handle 95% of sharing needs. IAPs are for products with their own team and release cycle.
- "I'll put my version number directly" → Check if it's in the catalog. If yes, use `"catalog:"`.
- "I need to set up GUP auth" → GUP is already integrated in allin-ui. Just add `lib-node-user-passport-component` as a peer dependency and use the hooks.
- "I'll use MUI directly for this custom component" → Check DREAM first. If a DREAM component exists, you must use it.

</critical_rules>

<edge_cases>

### DREAM Version Transition (v2 → v3)

- `lib-node-dream-ui` in the catalog points to v2 (`^2.9.1`)
- `lib-node-dream-ui-latest` is an npm alias pointing to v3 (`npm:lib-node-dream-ui@^3.1.2`)
- Some existing packages use v2, some use v3
- Check with your team which version to use for new packages
- Both are in the catalog — use `"catalog:"` for either

### Port Conflicts

The Turbo UFA generator auto-generates unique ports by scanning all existing `uwm-manifest.json` files. However, if you're working on a branch where another UFA was just added, the port scan may not see the other branch's port. To check manually:

```bash
grep -r '"port"' ufas/*/uwm-manifest.json
```

Reserved ports (never use): 3000, 5000, 5001, 9000.

### Catalog Strictness Edge Cases

If your package genuinely needs a different version of a catalog entry (rare), you cannot work around `catalogMode: strict` locally. Options:
1. Request an update to the catalog version in `pnpm-workspace.yaml` (preferred)
2. Request a named catalog override for your package (advanced, discuss with app shell team)
3. Use an alternative package that isn't in the catalog

### IAP vs SCL Gray Area

Sometimes it's unclear whether a component should be an IAP or SCL. Key differentiator:

| Characteristic | SCL | IAP |
|---------------|-----|-----|
| Has its own team? | No — owned by consumers | Yes — dedicated team |
| Independent release cycle? | No — released with allin-ui | Yes — can release independently |
| Manages cross-UFA state? | No — stateless/props-driven | Yes — owns state across UFAs |
| Needs lifecycle management? | No — just import and use | Yes — mount/unmount/suspend |

**When in doubt, start with SCL.** You can always promote to IAP later if the complexity is justified.

### Testing Setup for New Packages

Both UFA and lib templates include a `vitest.config.ts`. For test utilities:
- Use `@testing-library/react` and `@testing-library/jest-dom` (both in catalog)
- Use `MockPassport` from `lib-node-user-passport-component` for auth-dependent tests
- Use test doubles from `@uwm/platform-api` for platform API mocking
- Add your package to `vitest.workspace.ts` at the repo root if it should participate in workspace-level test runs

### Package with Both Publishable and Local Concerns

If your SCL needs to be published to Artifactory (consumed outside allin-ui) AND used locally:
- Choose "Artifactory" during `turbo gen lib`
- The generator adds `allin-publish` and `allin-release-candidate` scripts
- Local consumers use `workspace:*`, external consumers use the published version
- Keep the `"files"` field in package.json to control what gets published

</edge_cases>

<verification_checklist>

Before moving to the next phase (design-ui-component), verify ALL of the following:

### Package Structure
- [ ] Package created via Turbo generator (`turbo gen ufa` or `turbo gen lib`)
- [ ] Package is in the correct directory: UFAs in `ufas/`, libraries in `packages/`
- [ ] `package.json` has `@uwm/` scope prefix
- [ ] `package.json` uses `"catalog:"` for all catalog-managed dependencies
- [ ] `package.json` uses `"workspace:*"` for internal allin-ui packages
- [ ] Module federation shared libs (react, DREAM, GUP) are in `peerDependencies`
- [ ] No direct MUI dependency when using DREAM (import from `lib-node-dream-ui`)

### UFA-Specific (skip for SCLs)
- [ ] `uwm-manifest.json` exists with all required fields
- [ ] `moduleName` matches directory name
- [ ] `route` is unique across all UFAs
- [ ] `port` doesn't conflict with existing UFAs
- [ ] `themeFamily` matches app audience (`external` or `internal`)
- [ ] `roleMatrix` and `policies` configured if access restrictions needed

### Spec Directory
- [ ] `spec/capabilities/` directory created inside the package
- [ ] At least one capability directory with `README.md` and `features/` subdirectory
- [ ] `.feature` files are specs (Gherkin syntax), NOT executable tests

### Verification Commands
- [ ] `pnpm install` succeeds (no catalog violations)
- [ ] `pnpm build --filter=@uwm/{name}` succeeds
- [ ] `pnpm test --filter=@uwm/{name}` succeeds (boilerplate tests pass)
- [ ] `pnpm lint:architecture` passes (no boundary violations)
- [ ] `pnpm check:catalog` passes

</verification_checklist>

<integration>

**This skill is called by:**
- `develop-frontend` orchestrator (Phase 1)
- Developers directly when creating a new allin-ui package

**After this skill, proceed to:**
- `design-ui-component` (Phase 2) — Design components using DREAM design system
- `implement-ui-feature` (Phase 3) — TDD implementation of features

**Prerequisites:**
- Access to the allin-ui repository (EH/allin-ui on Bitbucket)
- Node.js and pnpm installed (pnpm@10.0.0 — see `packageManager` in root `package.json`)
- For IAPs: approval from app shell team

**Related skills:**
- `implement-ui-feature` — For adding features to an existing package
- `test-frontend` — For testing strategy (Vitest, Stryker, Playwright)
- `migrate-spa-to-allin` — For moving legacy cell-ui-* into allin-ui

</integration>

<resources>

**Repositories:**
- allin-ui: `https://code.uwm.com/projects/EH/repos/allin-ui/browse`
- DREAM library: `https://code.uwm.com/projects/UCP/repos/lib-node-dream-ui/browse`

**Confluence Documentation:**
- Component Taxonomy (UFA/IAP/SCL): `https://kb.uwm.com/pages/viewpage.action?pageId=1514786638`
- allin-ui Operational Runbook: `https://kb.uwm.com/pages/viewpage.action?pageId=1424495810`
- allin-ui Policies and Standards: `https://kb.uwm.com/pages/viewpage.action?pageId=1479759939`
- allin-ui Implementation View: `https://kb.uwm.com/pages/viewpage.action?pageId=1424495816`
- GUP UI Onboarding: Search kb for "Global User Passport System Design"

**Storybook:**
- DREAM Storybook: `https://dream.uwm.com/`

**Reference Packages in allin-ui:**
- UFA example: `ufas/income-calculator/` — clean UFA with standard deps
- UFA with RBAC: `ufas/example/` — comprehensive roleMatrix and policies
- SCL example: `packages/shared-components/` — shared component library with 80% coverage enforcement
- IAP example: `packages/actioniq/` — multi-directory IAP pattern
- IAP example: `packages/onav/` — another IAP with core/lib/shell structure

**Turbo Generators:**
- UFA generator: `turbo/generators/generator/ufa.ts`
- Lib generator: `turbo/generators/generator/lib.ts`
- UFA template: `turbo/generators/templates/ufa/`
- Lib template: `turbo/generators/templates/lib/`

**When stuck:**
- `pnpm install` fails → Check for catalog violations (direct versions instead of `catalog:`)
- `turbo boundaries` fails → Check import paths, verify you're not importing across forbidden boundaries
- IAP questions → Contact app shell team
- DREAM component questions → Check Storybook at dream.uwm.com
- GUP auth questions → Search kb for "Global User Passport" documentation

</resources>
