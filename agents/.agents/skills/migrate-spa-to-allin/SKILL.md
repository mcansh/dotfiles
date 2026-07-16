---
name: migrate-spa-to-allin
description: Use when migrating a legacy cell-ui-xxx dedicated SPA to the allin-ui monorepo — covers pre-migration assessment, package scaffolding, dependency migration, build tool conversion, auth migration to GUP, DREAM adoption, and testing migration
---

<skill_overview>
Guides the migration of a legacy dedicated SPA (cell-ui-xxx pattern) into the allin-ui monorepo as a UFA. This is a formalized process that covers pre-migration assessment, scaffolding the new UFA, migrating dependencies from npm/yarn to pnpm with catalog: protocol, converting build tools (webpack/CRA/Next.js to Vite), adopting GUP auth and DREAM design system, migrating tests to Vitest, and integrating with the app shell.

**Migration is not a rewrite.** The goal is to move existing functionality into the allin-ui structure with minimal changes to business behavior. Refactoring for improved patterns happens after migration is complete and the UFA is stable.

**BFF consideration:** Many legacy SPAs have a dedicated Backend For Frontend (cell-bff-xxx). The BFF itself is NOT migrated into allin-ui — it remains a separate service. The UFA in allin-ui calls the BFF via `createGateway` from `@uwm/platform-api`. If the BFF should be consolidated into a v3 business service, that's a separate effort using `uwm-business-service-dev`.
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM - The migration sequence (assess → scaffold → migrate deps → migrate build → migrate auth → migrate UI → migrate tests → integrate) is rigid. The specific migration steps within each phase adapt to what the legacy SPA uses (webpack vs CRA vs Next.js, Jest vs Mocha, custom auth vs partial GUP).
</rigidity_level>

<quick_reference>

| Phase | Action | Key Change |
|-------|--------|-----------|
| **1. Assess** | Inventory the legacy SPA | Document: deps, build tool, auth, tests, BFF |
| **2. Scaffold** | `turbo gen ufa` in allin-ui | New UFA directory in ufas/ |
| **3. Dependencies** | Migrate to pnpm + catalog: | Remove package-lock/yarn.lock, add catalog refs |
| **4. Build Tool** | Webpack/CRA/Next.js → Vite | Replace build config with vite.config.ts + @uwm/vite-plugin-appshell |
| **5. Auth** | Custom/partial → GUP | Remove auth code, use PassportAuth + usePassport from shell |
| **6. UI Components** | Custom/MUI → DREAM | Replace MUI imports with lib-node-dream-ui equivalents |
| **7. Tests** | Jest/other → Vitest | Replace test runner, update mocking patterns |
| **8. Integrate** | Connect to app shell | uwm-manifest.json, routing, navigation |

**BFF:** Stays separate. UFA calls BFF via `createGateway`.

</quick_reference>

<when_to_use>
- Migrating a cell-ui-xxx SPA to allin-ui
- Team has been approved to move their frontend into the monorepo
- Legacy SPA needs to integrate with app shell navigation and auth
- Consolidating a standalone frontend into the allin-ui ecosystem

**Do NOT use for:**
- Building a new UFA from scratch (use `develop-frontend`)
- Maintaining a legacy SPA without migration (use `maintain-legacy-spa`)
- Migrating the BFF (use `uwm-business-service-dev` for service-level work)
- Migrating a Next.js app using the vertical MFE on-ramp (see Confluence page 1518153972 for the Next.js on-ramp decision)
</when_to_use>

<the_process>

## Phase 1: Pre-Migration Assessment

Before any code changes, inventory the legacy SPA to understand what needs to migrate.

### Assessment Checklist

Use Glob and Grep to build this inventory automatically:

```
1. REPOSITORY
   - Repo name (cell-ui-{context})
   - Repo location on Bitbucket
   - Associated BFF (cell-bff-{context}) if any
   - Associated business services

2. DEPENDENCIES
   - Package manager: npm or yarn?
   - React version: 16.x, 17.x, or 18.x?
   - UI library: MUI, DREAM, custom, or mix?
   - State management: Redux, Redux Toolkit, Context, other?
   - Routing: React Router version?
   - HTTP client: Axios, fetch, other?
   - Auth library: What auth mechanism is in use?

3. BUILD TOOL
   - Webpack, Create React App, Vite, or Next.js?
   - Custom webpack config complexity
   - Environment variable patterns (REACT_APP_*, NEXT_PUBLIC_*, VITE_*)

4. TESTING
   - Test runner: Jest, Mocha, Vitest, other?
   - Test library: RTL, Enzyme, other?
   - Coverage tool and current coverage %
   - Number of test files

5. AUTH
   - GUP already integrated? (lib-node-user-passport-component)
   - Custom auth implementation?
   - Role-based access patterns?
   - Session management approach?

6. SIZE & COMPLEXITY
   - Number of source files
   - Number of pages/routes
   - Approximate lines of code
   - External service integrations
```

### Risk Assessment

| Risk | Signal | Mitigation |
|------|--------|------------|
| React version mismatch | React <18 | Upgrade to 18 before migration |
| Heavy Redux state | Redux store with 10+ slices | Migrate to React Query for server state, keep Redux for complex client state |
| Custom webpack config | Extensive webpack plugins/loaders | Map each to Vite equivalent or remove |
| Enzyme tests | `import { shallow } from 'enzyme'` | Rewrite to RTL (no Enzyme in allin-ui) |
| Custom auth | No GUP integration | Full auth replacement needed |
| Business logic in frontend | Calculations, orchestration in UI | Extract to service before or during migration |

### Create Migration Plan

After assessment, present the migration plan to the user with phases, estimated complexity, and risk areas. Use AskUserQuestion for decisions:

- Should business logic be extracted first or during migration?
- Keep Redux or migrate state management?
- Migrate all pages at once or incrementally?

---

## Phase 2: Scaffold UFA in allin-ui

Create the new UFA in the allin-ui monorepo:

```bash
cd /path/to/allin-ui
turbo gen ufa
```

Follow prompts:
- **Name:** Use the same context name (e.g., `cell-ui-lending` → UFA name `lending`)
- **Port:** Select from available range (8080-8099)
- **Theme:** Match the legacy SPA's theme (internal/external)

After scaffolding:
1. Create `spec/` directory for .feature files
2. Configure uwm-manifest.json with routes matching legacy SPA
3. Set up roleMatrix matching existing access patterns

---

## Phase 3: Migrate Dependencies

### Replace Package Manager

```bash
# In the new UFA directory
# Remove legacy lock files (they're in the old repo)
# allin-ui uses pnpm with catalog: protocol
```

### Migrate Dependencies to catalog:

For every dependency in the legacy package.json:

| Legacy Dependency | allin-ui Equivalent |
|---|---|
| `"react": "^18.x.x"` | `"react": "catalog:"` |
| `"@mui/material": "^5.x.x"` | `"@mui/material": "catalog:"` |
| `"lib-node-dream-ui": "^x.x.x"` | `"lib-node-dream-ui": "catalog:"` |
| `"vitest": "^x.x.x"` | `"vitest": "catalog:"` |
| `"react-router-dom": "^x.x.x"` | `"react-router-dom": "catalog:"` |

**Check `pnpm-workspace.yaml` catalog section** to see which dependencies are available. If a dependency isn't in the catalog, add it to package.json with a direct version (and consider requesting it be added to the catalog).

### Migrate Internal Dependencies

If the legacy SPA imports shared packages that exist in allin-ui:

```json
{
    "dependencies": {
        "@uwm/shared-components": "workspace:*",
        "@uwm/platform-api": "workspace:*"
    }
}
```

---

## Phase 4: Migrate Build Tool

### From Webpack or CRA to Vite

1. **Remove old build config:** Delete `webpack.config.js`, `config/`, or CRA-related files.

2. **Create `vite.config.ts`:**

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { appShellPlugin } from '@uwm/vite-plugin-appshell';

export default defineConfig({
    plugins: [
        react(),
        appShellPlugin(),
    ],
});
```

3. **Migrate environment variables:**

| Legacy Pattern | Vite Pattern |
|---|---|
| `process.env.REACT_APP_*` | `import.meta.env.VITE_*` |
| `process.env.NEXT_PUBLIC_*` | `import.meta.env.VITE_*` |
| `process.env.NODE_ENV` | `import.meta.env.MODE` |

4. **Update scripts in package.json:**

```json
{
    "scripts": {
        "dev": "vite",
        "build": "vite build",
        "preview": "vite preview"
    }
}
```

### From Next.js

Next.js SPAs require special consideration:
- **If pure SPA (no SSR):** Convert to Vite as above
- **If using SSR/SSG:** Consider the vertical MFE on-ramp (Confluence page 1518153972) instead of this migration path
- **If using Next.js API routes as BFF:** Extract API routes to a separate cell-bff-xxx or v3 business service first

---

## Phase 5: Migrate Auth to GUP

### Remove Legacy Auth

1. **Identify existing auth code:**
```
Grep: "login" or "authenticate" or "getToken" or "sessionStorage" in src/
```

2. **Remove custom auth components and hooks.** In allin-ui, the app shell handles authentication via GUP. Your UFA receives the authenticated user automatically.

3. **Remove auth-related routes** (login page, logout page, callback page). The app shell handles these.

### Adopt GUP Patterns

Replace custom auth with GUP hooks from `lib-node-user-passport-component` and `@uwm/platform-api`:

```typescript
// Legacy pattern (REMOVE):
const { user, isAuthenticated } = useCustomAuth();
if (!isAuthenticated) redirect('/login');

// allin-ui pattern (ADOPT):
import { usePassport } from 'lib-node-user-passport-component';
const { user, isLoggedIn, isLoading } = usePassport();
if (isLoading) return <LoadingSpinner />;
// Auth is handled by the shell — user is always authenticated when your UFA loads
```

### Migrate Role-Based Access

```typescript
// Legacy pattern (REMOVE):
const hasAccess = user.roles.includes('Admin');

// allin-ui pattern (ADOPT):
import { useAppShellRoles } from '@uwm/platform-api';
const roles = useAppShellRoles();
const hasAccess = roles.includes('admin');
```

Define roles in uwm-manifest.json `roleMatrix`.

---

## Phase 6: Migrate UI to DREAM

### Audit Component Usage

Run a DREAM compatibility audit:

```
Grep: "from '@mui/material'" in src/ → List all MUI components used
Grep: "from 'lib-node-dream-ui'" in src/ → List DREAM components already used
```

For each MUI component, check if DREAM provides an equivalent:
- Check https://dream.uwm.com (DREAM Storybook)
- If DREAM has it → replace the import
- If DREAM doesn't have it → keep the MUI import (this is acceptable)

### Replace MUI with DREAM Where Available

```typescript
// Legacy:
import { Button, TextField, Card } from '@mui/material';

// Migrated:
import { DreamButton, DreamTextField, DreamCard } from 'lib-node-dream-ui';
```

### Adopt Theme Variables

Replace hardcoded styles with theme references:

```typescript
// Legacy:
<Box sx={{ padding: '16px', backgroundColor: '#f5f5f5', fontSize: '14px' }}>

// Migrated:
<Box sx={{ padding: theme.spacing(2), backgroundColor: theme.palette.background.default, ...theme.typography.body2 }}>
```

---

## Phase 7: Migrate Tests to Vitest

### Replace Test Runner

1. **Remove Jest or other test runner:**
```bash
# Remove legacy test dependencies
pnpm remove jest @types/jest ts-jest babel-jest
# or: pnpm remove mocha chai
```

2. **Add Vitest (via catalog):**
```json
{
    "devDependencies": {
        "vitest": "catalog:",
        "@testing-library/react": "catalog:",
        "@testing-library/jest-dom": "catalog:"
    }
}
```

3. **Create vitest.config.ts** (see test-frontend skill for template).

4. **Create setupTests.ts** (see test-frontend skill for template).

### Update Test Syntax

Most test syntax is compatible between Jest and Vitest. Key differences:

```typescript
// Jest:
jest.fn()
jest.mock('./module')
jest.spyOn(obj, 'method')

// Vitest:
vi.fn()
vi.mock('./module')
vi.spyOn(obj, 'method')
```

### Replace Enzyme with RTL

If the legacy SPA uses Enzyme (deprecated):

```typescript
// Enzyme (REMOVE):
import { shallow, mount } from 'enzyme';
const wrapper = shallow(<Component />);
expect(wrapper.find('.class-name')).toHaveLength(1);

// RTL (ADOPT):
import { render, screen } from '@testing-library/react';
render(<Component />);
expect(screen.getByRole('button', { name: /submit/i })).toBeInTheDocument();
```

### Set Up Test Infrastructure

Follow the `test-frontend` skill for:
- vitest.config.ts with coverage
- setupTests.ts with jest-dom and matchMedia
- TestProviders with MockPassport and DreamThemeProvider
- sonar-project.properties
- E2E smoke test in tests/e2e/smoke.ts

---

## Phase 8: Integrate with App Shell

### Configure uwm-manifest.json

```json
{
    "moduleName": "{ufa-name}",
    "title": "{Display Name}",
    "route": "/{ufa-route}",
    "rootComponent": "./src/App.tsx",
    "port": {assigned-port},
    "themeFamily": "{internal|external}",
    "subRoutes": [
        { "id": "home", "path": "" },
        { "id": "details", "path": "details/:id" }
    ],
    "roleMatrix": {
        "admin": ["{AD-group-1}", "{AD-group-2}"],
        "viewer": ["{AD-group-3}"]
    },
    "menus": [
        {
            "id": "sideNav",
            "items": [
                {
                    "label": "{Menu Item}",
                    "icon": "{icon-name}",
                    "subRouteId": "home"
                }
            ]
        }
    ]
}
```

### Migrate Routing

Replace standalone React Router setup with app-shell-integrated routing:

```typescript
// Legacy (standalone router — REMOVE):
<BrowserRouter>
    <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/details/:id" element={<Details />} />
    </Routes>
</BrowserRouter>

// allin-ui (shell-managed routing — ADOPT):
// Routes are defined in uwm-manifest.json subRoutes
// App.tsx receives routing from the shell
import { Routes, Route } from 'react-router-dom';

function App() {
    return (
        <Routes>
            <Route path="" element={<Home />} />
            <Route path="details/:id" element={<Details />} />
        </Routes>
    );
}
```

### Connect to BFF

If the legacy SPA had a dedicated BFF (cell-bff-xxx):

```typescript
// Legacy (direct API calls — REMOVE):
const response = await axios.get(`${process.env.REACT_APP_BFF_URL}/api/loans`);

// allin-ui (via platform-api gateway — ADOPT):
import { createGateway } from '@uwm/platform-api';
const api = createGateway('cell-bff-{context}/api', 'v1');
const { data } = await api.get<LoanResponse[]>('/loans');
```

### Verify Integration

1. Run local dev: `pnpm dev` in the UFA directory
2. Verify the UFA loads in the app shell at the configured route
3. Verify navigation items appear in the side nav
4. Verify auth works (user info available via usePassport)
5. Verify BFF connectivity via createGateway

</the_process>

<examples>

## Example: Migrating cell-ui-lending

**Assessment:**
```
Repository: cell-ui-lending (Bitbucket EH project)
BFF: cell-bff-lending (separate repo)
React: 18.2.0
UI: MUI 5 + partial DREAM
State: Redux Toolkit
Build: CRA (react-scripts)
Tests: Jest + RTL (72% coverage)
Auth: Partial GUP + custom session handling
Routes: 8 pages
Size: 147 source files
```

**Migration plan:**
1. Scaffold `lending` UFA in allin-ui (turbo gen ufa)
2. Copy src/ files to new UFA
3. Replace react-scripts with Vite + appShellPlugin
4. Replace npm deps with catalog: refs
5. Remove custom session handling, use shell-provided auth
6. Replace MUI Button/TextField with DREAM equivalents (DreamButton, DreamTextField)
7. Keep MUI DataGrid (DREAM doesn't have a grid component)
8. Replace Jest with Vitest (vi.fn → vi.fn, jest.mock → vi.mock)
9. Configure uwm-manifest.json with 8 routes and roleMatrix
10. Connect to cell-bff-lending via createGateway
11. Add E2E smoke test
12. Verify coverage ≥80% (was 72% — need to add tests)

</examples>

<critical_rules>

## Rules That Have No Exceptions

1. **Migration is not a rewrite.** Move existing functionality first. Refactor after stable.
2. **BFF stays separate.** Do not try to merge the BFF into allin-ui. Connect via createGateway.
3. **GUP auth replaces all custom auth.** No custom session handling, login pages, or token management.
4. **DREAM where available.** Replace MUI imports with DREAM equivalents. Keep MUI only for components DREAM doesn't provide.
5. **catalog: protocol for shared deps.** No direct version numbers for core libraries.
6. **Coverage must reach ≥80%.** If legacy coverage is lower, add tests during migration.
7. **No Enzyme.** Replace with @testing-library/react. Enzyme is not supported in allin-ui.

## Common Excuses

- "We'll keep our custom auth for now" (No. GUP is mandatory. The shell handles auth.)
- "Can we bring our webpack config?" (No. Vite with appShellPlugin is required.)
- "We'll fix the tests later" (Coverage must be ≥80% at migration. Add tests now.)
- "The BFF should be part of the UFA" (No. BFF is a separate service. Use createGateway.)

</critical_rules>

<edge_cases>

## Next.js SPAs

Next.js applications using SSR or SSG cannot follow the standard Vite migration path. Options:
1. **Pure SPA (client-side only):** Migrate normally, replace Next.js with Vite
2. **SSR/SSG required:** Use the vertical MFE on-ramp (Confluence page 1518153972)
3. **API routes as BFF:** Extract to separate service before migrating UI

## Very Low Coverage (<50%)

If the legacy SPA has very low test coverage:
1. Write .feature specs for existing behavior first
2. Add tests during migration targeting ≥80%
3. Focus on CUJs (Critical User Journeys) for highest-value tests

## Redux-Heavy Applications

If the legacy SPA has extensive Redux state:
1. Migrate Redux as-is initially (allin-ui supports Redux for legacy)
2. After stable migration, incrementally replace with React Query (server state) and Zustand (client state)
3. Do NOT attempt a full state management rewrite during migration

## Multiple BFFs

Some SPAs call multiple BFFs or services:
1. Register each BFF with createGateway using different base paths
2. Do NOT consolidate BFFs during UI migration — that's a separate effort

</edge_cases>

<verification_checklist>

**After migration is complete:**
- [ ] UFA loads in allin-ui app shell at configured route
- [ ] All routes work as in legacy SPA
- [ ] Auth via GUP (no custom auth code remaining)
- [ ] DREAM components used where available
- [ ] Dependencies use catalog: protocol
- [ ] Build uses Vite with @uwm/vite-plugin-appshell
- [ ] Tests use Vitest (no Jest, no Enzyme)
- [ ] Coverage ≥80%
- [ ] E2E smoke test exists in tests/e2e/smoke.ts
- [ ] uwm-manifest.json configured with routes, roleMatrix, menus
- [ ] BFF connected via createGateway (if applicable)
- [ ] No business logic migrated into frontend (extract to service)
- [ ] Build + tests under 1 minute

</verification_checklist>

<integration>

**This skill is called by:**
- `develop-frontend` (orchestrator) — when legacy SPA detected and user chooses migration

**After migration, use:**
- `develop-frontend` — for continued development in allin-ui
- `implement-ui-feature` — for adding features with TDD
- `test-frontend` — for comprehensive test setup

**Related skills:**
- `maintain-legacy-spa` — if user chooses NOT to migrate
- `uwm-business-service-dev` — for BFF or service-level migrations

</integration>

<resources>

**Confluence:**
- Operational Runbook (page ID: 1424495810) — allin-ui architecture overview
- UFA Onboarding Experiment (page ID: 1443991649) — Onboarding success/kill criteria
- Next.js Vertical MFE On-Ramp (page ID: 1518153972) — Alternative path for Next.js apps
- V3 Architectural Baselines (page ID: 944046789) — Legacy naming: cell-ui-{context}, cell-bff-{context}
- BFF Pattern (page ID: 1367081328) — Backend For Frontend architecture
- Trade-offs Analysis (page ID: 1455929059) — Advantages/disadvantages of joining allin-ui

**Bitbucket:**
- `EH/allin-ui` — Target monorepo
- Legacy SPAs follow `cell-ui-{context}` naming in various Bitbucket projects

**Tools:**
- `turbo gen ufa` — Scaffold new UFA in allin-ui
- `pnpm` — Package manager with catalog: protocol
- Vite + @uwm/vite-plugin-appshell — Build tool
- `createGateway` from @uwm/platform-api — BFF connectivity

</resources>
