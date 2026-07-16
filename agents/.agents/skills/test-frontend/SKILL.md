---
name: test-frontend
description: Use when setting up comprehensive test strategy for an allin-ui package — covers Vitest configuration, Stryker mutation testing optimization, Playwright E2E/soak/perf tests, coverage reporting, SonarQube integration, and pipeline compliance
---

<skill_overview>
Guides developers through the complete test strategy for an allin-ui package beyond the TDD cycle. While `implement-ui-feature` covers writing unit tests via TDD (spec → RED → GREEN → REFACTOR → Stryker), this skill covers everything else: Stryker configuration optimization, Playwright E2E/soak/perf test authoring, coverage reporting and thresholds, SonarQube integration, pipeline compliance, and time limit enforcement.

**This skill establishes Playwright test patterns from scratch.** Zero Playwright tests exist in allin-ui today. The patterns documented here are derived from the official allin-ui Policies and Standards, CD Pipeline Design, and TestKube standards on Confluence.

**Key context:** Tests in allin-ui run in two places:
1. **Jenkins** (build time): Unit tests + architecture checks — must complete in under 1 minute per package
2. **TestKube** (post-build): E2E, soak, perf, mutation tests — run in Kubernetes containers using Playwright

Mount smoke tests and mutation test orchestration are **managed by the platform** (no package config needed). However, packages CAN add their own Stryker config for local development. The mutation gate (score < 80 blocks merge) is enforced centrally.
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM - Test file locations, naming conventions, coverage thresholds, and pipeline time limits are rigid and non-negotiable. Soak test rules (no behavior assertions) are rigid. Playwright test structure adapts to the specific package's CUJs. Stryker config optimization adapts to the package's mutation results.
</rigidity_level>

<quick_reference>

| Area | Tool | Threshold | File Location | Time Limit |
|------|------|-----------|---------------|------------|
| **Unit tests** | Vitest | >80% coverage | `src/**/__tests__/*.test.ts(x)` | 1 min/package |
| **Mount smoke** | Playwright | N/A | Managed by platform | N/A |
| **Mutation** | Stryker | >80 score (merge gate) | Managed by platform (optional local config) | N/A |
| **E2E** | Playwright | N/A | `{package}/tests/e2e/{testName}.ts` | N/A |
| **Soak** | Playwright | N/A | `{package}/tests/soak/{testName}.ts` | 60min int, 180min stage/prod |
| **Perf** | Playwright | N/A | `{package}/tests/perf/{testName}.ts` | N/A |
| **Build** | Turbo | N/A | N/A | 1 min/package |

**Pipeline stages:**
```
PR:     unit + mount smoke
Merge:  unit + mount smoke + mutation gate
Int:    E2E + soak (60 min)
Stage:  E2E + soak (180 min) + perf
Prod:   E2E + soak (180 min) + UAT
```

**Critical rules:**
- Soak tests detect side effects ONLY — never assert behaviors or outputs
- Perf tests time UI code ONLY — never wrap upstream dependency calls
- All Playwright tests must be TypeScript, browser-agnostic
- Credentials via TAMS/Vault ONLY — never hardcode

</quick_reference>

<when_to_use>
- Setting up vitest.config.ts and setupTests.ts for a new or existing package
- Configuring Stryker mutation testing locally for a package
- Fixing surviving mutants to raise mutation score above 80
- Writing Playwright E2E tests for a package (minimum: one "open the page" smoke)
- Writing Playwright soak tests for Critical User Journeys (CUJs)
- Writing Playwright performance tests for processor-intense UI code
- Setting up SonarQube integration (sonar-project.properties)
- Debugging pipeline failures related to test timeouts, coverage thresholds, or JUnit output
- Understanding which tests run at which pipeline stage

**Do NOT use for:**
- Writing unit tests via TDD cycle (use `implement-ui-feature`)
- Creating test utilities like TestProviders, custom render, createUser factory (use `implement-ui-feature`)
- Writing .feature spec files (use `implement-ui-feature`)
- Running `npx stryker run` as part of the TDD cycle (use `implement-ui-feature`)
- Creating a new allin-ui package (use `create-allin-package`)
- Designing component structure (use `design-ui-component`)
</when_to_use>

<the_process>

## Step 1: Configure Vitest for Your Package

Every allin-ui package needs a `vitest.config.ts` and a `setupTests.ts`. If your package was scaffolded with `turbo gen ufa` or `turbo gen lib`, these may already exist. Verify and configure them correctly.

### vitest.config.ts Template

```typescript
/// <reference types="vitest" />
/// <vitest-environment jsdom>
import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        environment: 'jsdom',
        globals: true,
        setupFiles: './src/setupTests.ts',
        coverage: {
            reporter: ['text', 'lcov'],
            include: [
                'src/components/**',
                'src/pages/**',
                'src/hooks/**',
                'src/services/**',
                'src/utils/**',
            ],
            exclude: [
                'src/testUtils.ts',
                'src/setupTests.ts',
                'src/TestProviders.tsx',
                'src/**/__tests__/**',
            ],
            provider: 'v8',
            reportsDirectory: './coverage',
        },
        exclude: [
            '**/node_modules/**',
            '**/dist/**',
            'src/testUtils.ts',
            'src/setupTests.ts',
        ],
    },
});
```

**Configuration notes:**
- `environment: 'jsdom'` — Required for React component testing. All packages use jsdom.
- `globals: true` — Makes `describe`, `it`, `expect` available without imports. Standard across allin-ui.
- `provider: 'v8'` — Required coverage provider. Do NOT use `istanbul`.
- `reporter: ['text', 'lcov']` — `text` for console output, `lcov` for SonarQube/pipeline integration.
- `coverage.include` — List only directories with production code. Adjust to match your package structure.
- `coverage.exclude` — Always exclude test utilities, setup files, and test directories.

### Advanced Configuration: Thread Pooling

For packages with many tests that approach the 1-minute time limit, enable thread pooling:

```typescript
export default defineConfig({
    test: {
        // ...base config above...
        pool: 'threads',
        poolOptions: {
            threads: {
                maxThreads: 9,
                minThreads: 3,
            },
        },
    },
});
```

This is used in `packages/shared-components/vitest.config.ts` and helps keep large test suites under the 1-minute limit.

### setupTests.ts Template

```typescript
import '@testing-library/jest-dom';
import { vi } from 'vitest';

// Mock window.matchMedia — required for DREAM components that use responsive design
Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: vi.fn().mockImplementation((query) => ({
        matches: false,
        media: query,
        onchange: null,
        addListener: vi.fn(),
        removeListener: vi.fn(),
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
        dispatchEvent: vi.fn(),
    })),
});
```

**Optional: Accessibility testing** — Add vitest-axe for accessibility assertions:

```typescript
import '@testing-library/jest-dom';
import 'vitest-axe/extend-expect';
import { vi, expect } from 'vitest';
import * as matchers from 'vitest-axe/matchers';

expect.extend(matchers);

// ...matchMedia mock...
```

**Optional: MUI X License** — If your package uses MUI X components (DataGrid, DatePicker Pro):

```typescript
import { LicenseInfo } from '@mui/x-license';
LicenseInfo.setLicenseKey(import.meta.env.VITE_REACT_APP_MUI_X_KEY);

// ...rest of setup...
```

### Register in vitest.workspace.ts

When you create a new package, add it to the monorepo workspace test configuration at `vitest.workspace.ts`:

```typescript
// In vitest.workspace.ts at the repo root, add your package:
{
    test: {
        name: 'your-package-name',
        root: './ufas/your-package-name',  // or ./packages/your-package-name
    },
},
```

This enables the package to participate in monorepo-wide test runs.

---

## Step 2: Configure Coverage and Thresholds

### Coverage Threshold: 80% Lines (Enforced in CI)

The pipeline enforces 80% line coverage via the CLI flag:

```bash
vitest run --coverage --coverage.thresholds.lines=80
```

Add this as a `test:ci` script in your package.json:

```json
{
    "scripts": {
        "test": "vitest run",
        "test:coverage": "vitest run --coverage",
        "test:ci": "vitest run --coverage --coverage.thresholds.lines=80"
    }
}
```

**How the pipeline runs tests:**

The `scripts/build/tasks/testPackage.js` script runs:

```bash
npx vitest run --test-timeout=60000 --hook-timeout=60000 --reporter junit --outputFile junit-vitest-output.xml --coverage --coverage.reporter lcov
```

This produces:
- `junit-vitest-output.xml` — JUnit test report for Jenkins
- `coverage/lcov.info` — Coverage report for SonarQube

You do NOT need to configure JUnit output yourself — `testPackage.js` handles it. But your `vitest.config.ts` must produce valid lcov output via the `v8` provider.

### SonarQube Integration

Create `sonar-project.properties` in your package root:

```properties
# SonarQube Configuration for {PackageName}

# Exclude test files and utilities from coverage
sonar.coverage.exclusions=**/scripts/**,**/__tests__/**,**/testUtils/**,**/*.test.ts,**/*.test.tsx

# Exclude generated files from analysis
sonar.exclusions=**/__generated__/**

# Exclude test files from duplication analysis
sonar.cpd.exclusions=**/__tests__/**,**/*.test.ts,**/*.test.tsx
```

SonarQube picks up coverage from `coverage/lcov.info` and ESLint issues from `eslint-report.json` automatically via `scripts/build/tasks/sonarScan.js`. The project key is derived from your `package.json` `name` field.

### Turbo Task Integration

Your package's tests are orchestrated by turbo.json tasks:

| Turbo Task | Dependencies | Outputs | When Used |
|------------|-------------|---------|-----------|
| `allin-test` | `^build`, `platform-api#build`, `shared-components#build` | `junit-vitest-output.xml` | PR and merge builds |
| `test` | None | `coverage/**` | Local development |
| `test:ci` | `^build`, `^test:ci` | `coverage/**`, `junit-vitest-output.xml` | CI pipeline |
| `allin-sonar-scan` | `allin-test` | N/A | Post-test SonarQube scan |

---

## Step 3: Configure Stryker Mutation Testing

### How Mutation Testing Works in allin-ui

Mutation testing is **managed at the repo level** by the platform team:
- Runs **daily** on the `develop` branch in TestKube
- Can be **manually triggered** in Port (https://app.us.port.io)
- Merge gate: **mutation score < 80 blocks the merge**
- Teams monitor their mutation score on their package page in Dynatrace

**You do NOT need a Stryker config in your package** for the pipeline to run mutation tests. However, adding a local config lets you run `npx stryker run` during development to fix surviving mutants before they block your merge.

### Add Local Stryker Config (Recommended)

The `implement-ui-feature` skill covers basic Stryker setup. If you've already added a config during TDD, you have what you need. If not, add it now:

**1. Install dependencies:**

```bash
cd {package}
pnpm add -D @stryker-mutator/core @stryker-mutator/vitest-runner @stryker-mutator/typescript-checker
```

**2. Create `stryker.config.json`** (based on `configs/platform-api/stryker.config.json`):

```json
{
    "$schema": "./node_modules/@stryker-mutator/core/schema/stryker-schema.json",
    "mutate": ["src/**/*.tsx", "src/**/*.ts", "!src/**/*.test.*", "!src/**/*.config.*"],
    "testRunner": "vitest",
    "checkers": ["typescript"],
    "tsconfigFile": "tsconfig.json",
    "vitest": {
        "configFile": "vitest.config.ts"
    },
    "thresholds": {
        "high": 90,
        "low": 80,
        "break": 79.999999999
    },
    "plugins": [
        "@stryker-mutator/vitest-runner",
        "@stryker-mutator/typescript-checker"
    ]
}
```

**3. Add npm script:**

```json
{
    "scripts": {
        "test:mutation": "npx stryker run"
    }
}
```

### Optimizing Mutation Score

When `npx stryker run` reports surviving mutants, fix them:

**Step 1: Read the Stryker report.** Stryker outputs which mutations survived and where:

```
Mutant #42: ConditionalExpression
  src/utils/formatCurrency.ts:15
  Changed: amount > 0 → amount >= 0
  Status: Survived
```

**Step 2: Understand what the surviving mutant means.** The mutation changed `>` to `>=` and no test failed. This means no test verifies the boundary condition at exactly 0.

**Step 3: Add a test that kills the mutant:**

```typescript
it('returns empty string when amount is exactly zero', () => {
    expect(formatCurrency(0)).toBe('');
});
```

**Step 4: Re-run Stryker to verify the mutant is now killed.**

### Common Surviving Mutant Patterns

| Mutation Type | Example | Fix |
|---|---|---|
| **Boundary** | `>` → `>=` | Add boundary value test (exact threshold) |
| **Negation** | `!isValid` → `isValid` | Add test for both valid and invalid states |
| **String** | `"Error"` → `""` | Assert exact error message, not just presence |
| **Arithmetic** | `a + b` → `a - b` | Test with values where +/- produce different results |
| **Conditional removal** | `if (x)` → `if (true)` | Test the false branch explicitly |
| **Return value** | `return result` → `return ""` | Assert specific return value, not truthiness |

### Stryker Performance Tips

If Stryker is slow (common with large packages):

1. **Limit mutated files:** Narrow the `mutate` glob to only changed files during development:
   ```bash
   npx stryker run --mutate "src/components/NewFeature/**/*.ts"
   ```

2. **Use `incremental` mode:** Stryker caches results between runs:
   ```json
   {
       "incremental": true,
       "incrementalFile": ".stryker-tmp/incremental.json"
   }
   ```

3. **Exclude stable code:** If utility files haven't changed, exclude them from mutation:
   ```json
   {
       "mutate": ["src/**/*.ts", "!src/utils/stable/**"]
   }
   ```

---

## Step 4: Write Playwright E2E Tests

### Overview

E2E tests verify Critical User Journeys (CUJs) in a real browser. They run in TestKube containers post-build, not during the Jenkins build.

**Minimum requirement:** At least one "open the page" E2E test per package. This is a smoke test that verifies the package loads correctly in the app shell.

**Zero Playwright tests exist today.** You are establishing the patterns.

### File Location and Structure

```
{package}/
  tests/
    e2e/
      smoke.ts              ← Required: basic load test
      loan-application.ts   ← CUJ-specific test
      admin-dashboard.ts    ← CUJ-specific test
    soak/
      ...
    perf/
      ...
  src/
    ...
```

**All test files must be TypeScript** (`.ts`, not `.js`). This is a TestKube standard.

### E2E Smoke Test Template (Required)

Every package MUST have at least this basic smoke test:

```typescript
import { test, expect } from '@playwright/test';

test.describe('{PackageName} Smoke', () => {
    test('loads the package in the app shell', async ({ page }) => {
        // Navigate to the package's route in the app shell
        await page.goto('/{package-route}');

        // Verify the page loaded without errors
        await expect(page).toHaveTitle(/.+/);

        // Verify a key element from your package rendered
        await expect(page.getByRole('heading', { name: /expected heading/i })).toBeVisible();

        // Verify no console errors during load
        const errors: string[] = [];
        page.on('console', (msg) => {
            if (msg.type() === 'error') {
                errors.push(msg.text());
            }
        });

        // Allow time for async rendering
        await page.waitForLoadState('networkidle');

        expect(errors).toHaveLength(0);
    });
});
```

### CUJ E2E Test Template

For tests beyond the smoke test, write tests that verify complete user journeys:

```typescript
import { test, expect } from '@playwright/test';

test.describe('{PackageName} - Loan Application CUJ', () => {
    test.beforeEach(async ({ page }) => {
        // Navigate to the package
        await page.goto('/{package-route}');
        await page.waitForLoadState('networkidle');
    });

    test('user completes a loan application form', async ({ page }) => {
        // Step 1: Fill in borrower information
        await page.getByLabel('First Name').fill('Jane');
        await page.getByLabel('Last Name').fill('Smith');
        await page.getByLabel('Email').fill('jane.smith@example.com');

        // Step 2: Select loan type
        await page.getByRole('combobox', { name: 'Loan Type' }).click();
        await page.getByRole('option', { name: 'Conventional' }).click();

        // Step 3: Submit
        await page.getByRole('button', { name: 'Submit' }).click();

        // Step 4: Verify success
        await expect(page.getByText('Application submitted successfully')).toBeVisible();
    });

    test('user sees validation errors for missing required fields', async ({ page }) => {
        // Submit without filling required fields
        await page.getByRole('button', { name: 'Submit' }).click();

        // Verify validation errors appear
        await expect(page.getByText('First Name is required')).toBeVisible();
        await expect(page.getByText('Last Name is required')).toBeVisible();
    });
});
```

### E2E Test Rules

1. **Only test interactions you cannot test with high-fidelity doubles in a unit test.** If the behavior can be verified with Vitest + jsdom + MockPassport, it belongs in unit tests.

2. **Browser agnostic.** Tests must pass in all supported browsers. Do not use browser-specific APIs.

3. **No hardcoded credentials.** Use TAMS/Vault for test user accounts (see Step 7).

4. **No direct MUI selectors.** Use accessible roles and labels (`getByRole`, `getByLabel`, `getByText`) not CSS classes or data attributes tied to MUI internals.

---

## Step 5: Write Playwright Soak Tests

### Overview

Soak tests simulate typical user activity over an extended period to detect **side effects** — memory leaks, lost references, browser-level errors. They do NOT test behaviors or outcomes.

**CRITICAL: Soak tests detect side effects ONLY.** Do NOT assert on behavior, output, or state. Use unit and E2E tests for that.

### Soak Durations

| Environment | Duration |
|---|---|
| Integration (int) | 60 minutes |
| Staging (stage) | 180 minutes |
| Production (prod) | 180 minutes |

### File Location

```
{package}/
  tests/
    soak/
      typical-usage.ts    ← Primary soak test
```

### Soak Test Template

```typescript
import { test, expect } from '@playwright/test';

// Soak test durations (overridden by TestKube in pipeline)
const SOAK_DURATION_MS = 60 * 60 * 1000; // 60 minutes default
const CYCLE_PAUSE_MS = 5000; // 5 seconds between cycles

test.describe('{PackageName} Soak Test', () => {
    test('sustained typical usage produces no browser errors', async ({ page }) => {
        // Collect browser errors throughout the soak period
        const browserErrors: string[] = [];
        page.on('console', (msg) => {
            if (msg.type() === 'error') {
                browserErrors.push(`[${new Date().toISOString()}] ${msg.text()}`);
            }
        });

        page.on('pageerror', (error) => {
            browserErrors.push(`[${new Date().toISOString()}] PAGE ERROR: ${error.message}`);
        });

        // Navigate to the package
        await page.goto('/{package-route}');
        await page.waitForLoadState('networkidle');

        const startTime = Date.now();

        // Loop CUJ actions for the soak duration
        while (Date.now() - startTime < SOAK_DURATION_MS) {
            // --- CUJ Cycle: Define typical user actions ---

            // Example: Navigate to a page
            await page.getByRole('link', { name: /dashboard/i }).click();
            await page.waitForLoadState('networkidle');

            // Example: Open and close a details panel
            await page.getByRole('button', { name: /view details/i }).first().click();
            await page.waitForTimeout(1000);
            await page.getByRole('button', { name: /close/i }).click();

            // Example: Navigate back
            await page.getByRole('link', { name: /home/i }).click();
            await page.waitForLoadState('networkidle');

            // --- End CUJ Cycle ---

            // Pause between cycles
            await page.waitForTimeout(CYCLE_PAUSE_MS);
        }

        // After soak period: check for browser errors
        // Filter out known benign errors if needed
        const unexpectedErrors = browserErrors.filter(
            (error) => !error.includes('ResizeObserver loop') // Known benign
        );

        expect(unexpectedErrors).toHaveLength(0);
    });
});
```

### Soak Test Rules

1. **DO NOT assert on behaviors or outputs.** Soak tests are NOT E2E tests. They simulate activity and detect side effects.

2. **DO NOT check specific outcomes from user behavior.** The soak loop performs actions but only checks for browser errors at the end.

3. **Define tests for each CUJ.** Each Critical User Journey gets its own soak loop cycle. Multiple CUJs can be in one test or separate tests.

4. **Filter known benign errors.** Some browser errors (e.g., `ResizeObserver loop completed with undelivered notifications`) are benign. Filter these out to avoid false failures.

5. **The pipeline fallback is very basic.** If your package has no soak tests, the fallback just loads the package and leaves it open for 5 minutes. This catches nothing useful. Write real soak tests.

---

## Step 6: Write Playwright Performance Tests (Optional)

### Overview

Performance tests measure the speed of processor-intense UI code. They are optional — only add them if your package has computationally expensive UI operations like in-browser filtering of large datasets, complex rendering, or heavy transformations.

**CRITICAL: Test UI code ONLY.** Wrap your diagnostic timer around UI operations, NOT upstream dependency calls (API responses, service worker processing). If the performance bottleneck is upstream, that's a backend concern.

### File Location

```
{package}/
  tests/
    perf/
      data-filter.ts    ← Performance test for specific operation
```

### Performance Test Template

```typescript
import { test, expect } from '@playwright/test';

test.describe('{PackageName} Performance', () => {
    test('filters 1000 records in under 500ms', async ({ page }) => {
        // Navigate to the page with the large dataset
        await page.goto('/{package-route}/data-view');
        await page.waitForLoadState('networkidle');

        // Wait for data to load (upstream dependency — do NOT time this)
        await expect(page.getByRole('table')).toBeVisible();

        // Start timing ONLY the UI filter operation
        const startTime = await page.evaluate(() => performance.now());

        // Trigger the UI filter (this is what we're measuring)
        await page.getByPlaceholder('Search...').fill('specific-term');

        // Wait for filtered results to render
        await page.waitForFunction(() => {
            const rows = document.querySelectorAll('table tbody tr');
            return rows.length < 1000; // Filtered result count is less than full set
        });

        const endTime = await page.evaluate(() => performance.now());
        const duration = endTime - startTime;

        // Assert UI operation completed within threshold
        expect(duration).toBeLessThan(500);
    });
});
```

### Performance Test Rules

1. **Test processor-intense UI code ONLY.** Filter, sort, render, transform — operations that run in the browser.

2. **DO NOT time upstream dependencies.** API response time, data fetching, service worker processing are NOT frontend performance. If you wrap a `fetch()` call in your timer, you're testing network latency, not UI code.

3. **DO NOT use performance tests to validate behavioral correctness.** Use unit tests and E2E tests for that.

4. **Consider if your package actually needs performance tests.** Most packages don't. Simple form-based UIs don't need them. Only add performance tests for:
   - In-browser filtering of large datasets (100+ rows)
   - Complex chart/visualization rendering
   - Heavy form validation with many fields
   - Real-time data processing (SignalR streams)

---

## Step 7: Manage Test Credentials (TAMS/Vault)

### Overview

Playwright tests that run in TestKube need test user credentials to authenticate through GUP. Credentials are managed through TAMS (Test Account Management System) and Vault.

**NEVER hardcode credentials** in test files, config files, environment files, or anywhere in the repository.

### Process

1. **Claim a test account in TAMS:**
   - Navigate to TAMS
   - Input the test user ID
   - Click "Claim Account" and select duration
   - Copy the generated password

2. **Store in Vault:**
   - Open Vault-Wrapper
   - Navigate to the test automation secret path for your package
   - Store credentials at: `Development > KV > Credentials > PortalUsers > {userId} > Password`
   - Repeat for each environment (int, stage, prod)

3. **Access in Playwright tests:**

```typescript
import { test } from '@playwright/test';

test.describe('Authenticated tests', () => {
    test.beforeEach(async ({ page }) => {
        // Credentials are injected by TestKube from Vault
        const username = process.env.TEST_USER_ID;
        const password = process.env.TEST_USER_PASSWORD;

        // Authenticate via GUP login flow
        await page.goto('/login');
        await page.getByLabel('Username').fill(username!);
        await page.getByLabel('Password').fill(password!);
        await page.getByRole('button', { name: 'Sign In' }).click();
        await page.waitForLoadState('networkidle');
    });
});
```

**Reference:** Confluence page "Instructions for Test User Account Claiming and Password Update in TAMS and Vault-Wrapper" (page ID: 1332938089).

---

## Step 8: Enforce Time Limits

### Build and Test Time Limits

| Operation | Time Limit |
|---|---|
| Build | 1 minute per package |
| Unit tests | 1 minute per package |

Time is measured per package overall, not per individual test. You can parallelize tests within the package.

### Strategies to Stay Under 1 Minute

**1. Enable thread pooling** in vitest.config.ts (see Step 1).

**2. Reduce test setup overhead:**
```typescript
// BAD: Heavy setup in each test
it('renders loan card', () => {
    const queryClient = new QueryClient();
    render(<QueryClientProvider client={queryClient}><LoanCard /></QueryClientProvider>);
});

// GOOD: Shared setup via TestProviders
it('renders loan card', () => {
    render(<LoanCard />, { wrapper: AllProviders });
});
```

**3. Avoid unnecessary re-renders:**
```typescript
// BAD: Rendering full page when testing one component
render(<FullDashboardPage />);

// GOOD: Render only the component under test
render(<LoanSummaryCard loan={mockLoan} />);
```

**4. Split large packages:** If a UFA has too many tests, consider extracting shared components into an SCL package. Each package gets its own 1-minute window.

**5. Avoid real timers:**
```typescript
// BAD: Waiting for real time to pass
await new Promise(resolve => setTimeout(resolve, 3000));

// GOOD: Use fake timers
vi.useFakeTimers();
vi.advanceTimersByTime(3000);
vi.useRealTimers();
```

**6. Monitor test duration locally:**
```bash
npx vitest run --reporter verbose
```
Review the output for slow tests. Any single test taking >5 seconds is a candidate for optimization.

### Pipeline Timeout Behavior

If tests exceed 1 minute, the pipeline fails with a timeout. The `testPackage.js` script uses:
- `--test-timeout=60000` (60 seconds per individual test)
- `--hook-timeout=60000` (60 seconds per hook execution)

Note: These are per-test timeouts, but the overall pipeline stage also has a timeout. Keep total suite execution under 1 minute.

---

## Step 9: Understand the Pipeline

### Pipeline Stages and Test Execution

| Stage | Tests Run | Runner | What It Catches |
|---|---|---|---|
| **Local dev** | Unit (vitest watch) | Local terminal | Immediate feedback during development |
| **PR** | Unit + mount smoke | Jenkins | Regressions from your changes |
| **Merge to develop** | Unit + mount smoke + mutation gate | Jenkins + TestKube | Weak tests (mutation score < 80) |
| **Int deploy (CD)** | E2E + soak (60 min) | TestKube | Integration issues, memory leaks in int |
| **Stage deploy (CD)** | E2E + soak (180 min) + perf | TestKube | Long-duration side effects, performance |
| **Prod deploy (CD)** | E2E + soak (180 min) + UAT | TestKube + Manual | Production readiness, user acceptance |

### Incremental Testing

The pipeline uses **incremental testing** — tests only run on packages that have changed since the last successful build on `develop`.

**Warning:** Implicit dependencies are NOT detected. If your package depends on another package via runtime module federation (not a workspace dependency), changes in that dependency won't trigger your tests. Watch for this when shared components change.

### Fallback Tests

If your package does not define E2E, soak, or perf tests, the pipeline uses a fallback:
- **E2E fallback:** Basic load test (verifies the package loads in the app shell)
- **Soak fallback:** Loads the package and leaves it open for 5 minutes

**Do NOT rely on fallbacks.** They catch almost nothing. Write real tests.

### Responsibility Division

| Activity | Package Team | Platform Team |
|---|---|---|
| Unit tests | Write and maintain | Run in Jenkins, enforce 1-min timeout |
| Mutation | Monitor score in Dynatrace, fix surviving mutants | Run Stryker in TestKube, enforce merge gate (< 80 blocks) |
| Mount smoke | N/A | Create and maintain mount smoke test |
| E2E | Write browser-agnostic Playwright tests | Run in TestKube for all browsers |
| Soak | Write CUJ soak tests | Run in TestKube, manage durations |
| Perf | Write UI perf tests (optional) | Run in TestKube |

</the_process>

<examples>

## Example 1: Setting Up Tests for a New UFA

**Scenario:** You've just created a new UFA called `loan-tracker` using `turbo gen ufa` and need to set up the full test infrastructure.

**Correct approach:**

```
{package}/
  vitest.config.ts         ← Vitest configuration
  stryker.config.json      ← Local Stryker config (optional but recommended)
  sonar-project.properties ← SonarQube exclusions
  src/
    setupTests.ts          ← Test setup (jest-dom, matchMedia mock)
    testUtils.ts           ← Custom render, createUser factory
    TestProviders.tsx       ← Provider wrappers (MockPassport + DREAM + Router)
    components/
      LoanCard/
        LoanCard.tsx
        __tests__/
          LoanCard.test.tsx
  tests/
    e2e/
      smoke.ts             ← REQUIRED: basic load test
      loan-tracking.ts     ← CUJ: track a loan
    soak/
      typical-usage.ts     ← CUJ loop for soak
  spec/
    loan-card.feature      ← Feature spec (from implement-ui-feature)
  package.json
```

**package.json scripts:**

```json
{
    "scripts": {
        "test": "vitest run",
        "test:watch": "vitest watch",
        "test:coverage": "vitest run --coverage",
        "test:ci": "vitest run --coverage --coverage.thresholds.lines=80",
        "test:mutation": "npx stryker run"
    }
}
```

---

## Example 2: Soak Test — Correct vs Incorrect

**Incorrect (testing behavior in a soak test):**

```typescript
// BAD: This is an E2E test disguised as a soak test
test('soak: user can create loans repeatedly', async ({ page }) => {
    for (let i = 0; i < 100; i++) {
        await page.goto('/loan-tracker/new');
        await page.getByLabel('Borrower Name').fill('Test User');
        await page.getByRole('button', { name: 'Create' }).click();

        // BAD: Asserting on behavior outcome
        await expect(page.getByText('Loan created successfully')).toBeVisible();

        // BAD: Verifying specific state after each action
        const loanCount = await page.getByTestId('loan-count').textContent();
        expect(Number(loanCount)).toBe(i + 1);
    }
});
```

**Correct (detecting side effects only):**

```typescript
// GOOD: Simulates activity, detects side effects
test('sustained loan creation produces no browser errors', async ({ page }) => {
    const browserErrors: string[] = [];
    page.on('console', (msg) => {
        if (msg.type() === 'error') {
            browserErrors.push(`[${new Date().toISOString()}] ${msg.text()}`);
        }
    });
    page.on('pageerror', (error) => {
        browserErrors.push(`[${new Date().toISOString()}] PAGE ERROR: ${error.message}`);
    });

    await page.goto('/loan-tracker');
    await page.waitForLoadState('networkidle');

    const startTime = Date.now();

    while (Date.now() - startTime < SOAK_DURATION_MS) {
        // Perform typical actions without asserting on outcomes
        await page.getByRole('link', { name: /new loan/i }).click();
        await page.waitForLoadState('networkidle');

        await page.getByLabel('Borrower Name').fill('Test User');
        await page.getByRole('button', { name: 'Create' }).click();
        await page.waitForLoadState('networkidle');

        // Navigate back (no assertion on success)
        await page.getByRole('link', { name: /dashboard/i }).click();
        await page.waitForLoadState('networkidle');

        await page.waitForTimeout(CYCLE_PAUSE_MS);
    }

    // Only check for browser-level errors after the soak period
    const unexpectedErrors = browserErrors.filter(
        (error) => !error.includes('ResizeObserver loop')
    );
    expect(unexpectedErrors).toHaveLength(0);
});
```

---

## Example 3: Performance Test — Correct vs Incorrect

**Incorrect (timing upstream dependencies):**

```typescript
// BAD: Timing includes API call — testing network, not UI
test('loads loan data in under 1 second', async ({ page }) => {
    const startTime = await page.evaluate(() => performance.now());

    // BAD: This includes API fetch time
    await page.goto('/loan-tracker/dashboard');
    await page.waitForLoadState('networkidle');
    await expect(page.getByRole('table')).toBeVisible();

    const endTime = await page.evaluate(() => performance.now());
    expect(endTime - startTime).toBeLessThan(1000);
});
```

**Correct (timing UI code only):**

```typescript
// GOOD: Times only the UI filter operation, not data loading
test('filters 500 loans in under 300ms', async ({ page }) => {
    await page.goto('/loan-tracker/dashboard');
    await page.waitForLoadState('networkidle');

    // Wait for data to load (DO NOT time this — it's upstream)
    await expect(page.getByRole('table')).toBeVisible();
    await page.waitForFunction(
        () => document.querySelectorAll('table tbody tr').length >= 500
    );

    // NOW start timing the UI filter
    const startTime = await page.evaluate(() => performance.now());

    await page.getByPlaceholder('Filter loans...').fill('conventional');

    await page.waitForFunction(
        () => document.querySelectorAll('table tbody tr').length < 500
    );

    const endTime = await page.evaluate(() => performance.now());
    const filterDuration = endTime - startTime;

    expect(filterDuration).toBeLessThan(300);
});
```

---

## Example 4: Fixing Surviving Mutants

**Scenario:** Stryker reports 3 surviving mutants in `src/utils/loanFormatter.ts`.

**Stryker output:**

```
Mutant #1: StringLiteral
  src/utils/loanFormatter.ts:8
  Changed: "Conventional" → ""
  Status: Survived

Mutant #2: ConditionalExpression
  src/utils/loanFormatter.ts:15
  Changed: amount > 0 → amount >= 0
  Status: Survived

Mutant #3: ArrowFunction
  src/utils/loanFormatter.ts:22
  Changed: () => formattedDate → () => ""
  Status: Survived
```

**Before (tests that let mutants survive):**

```typescript
it('formats loan type', () => {
    const result = formatLoanType('CONV');
    expect(result).toBeTruthy(); // BAD: "" is falsy but so is undefined
});

it('formats positive amounts', () => {
    expect(formatAmount(100)).toBe('$100.00');
    // Missing: no test for amount = 0
});

it('formats date', () => {
    const result = formatDate('2024-01-15');
    expect(result).toBeDefined(); // BAD: "" is defined
});
```

**After (tests that kill the mutants):**

```typescript
it('formats loan type to display name', () => {
    expect(formatLoanType('CONV')).toBe('Conventional'); // Kills mutant #1: asserts exact string
});

it('formats positive amounts with currency symbol', () => {
    expect(formatAmount(100)).toBe('$100.00');
});

it('returns empty string when amount is exactly zero', () => {
    expect(formatAmount(0)).toBe(''); // Kills mutant #2: tests boundary at 0
});

it('formats date to readable string', () => {
    expect(formatDate('2024-01-15')).toBe('January 15, 2024'); // Kills mutant #3: asserts exact value
});
```

</examples>

<critical_rules>

## Rules That Have No Exceptions

1. **Soak tests NEVER assert on behaviors or outputs.** They simulate activity and detect browser errors. If you're checking that a button click produced the correct result, that's an E2E test.

2. **Performance tests time UI code ONLY.** Never wrap an API call, data fetch, or any upstream dependency in your diagnostic timer. If the bottleneck is upstream, that's a backend concern.

3. **All Playwright tests must be TypeScript.** No `.js` files in `tests/`. TestKube standard.

4. **Never hardcode credentials.** Use TAMS/Vault for test user accounts. Credentials are injected as environment variables by TestKube.

5. **Coverage threshold is 80% lines.** The CI flag `--coverage.thresholds.lines=80` enforces this. Do not lower it.

6. **Mutation merge gate is score < 80.** If your mutation score drops below 80, your merge is blocked. Fix surviving mutants by adding meaningful tests, not by excluding files from mutation.

7. **Unit tests + build must complete in under 1 minute per package.** Pipeline timeout is non-negotiable. Optimize or split.

8. **Every package needs at least one E2E smoke test.** The "open the page" test in `tests/e2e/smoke.ts` is the minimum.

9. **Cleanup in afterEach is mandatory.** Use `@testing-library/react` cleanup to avoid state corruption between tests. The implement-ui-feature skill covers this in detail.

10. **Browser-agnostic tests only.** A test failing in any supported browser stops the CD pipeline for that package. Do not use browser-specific APIs.

## Common Excuses

All of these mean: **STOP. Follow the rules.**

- "Soak tests should verify the actions worked" (No. Soak tests detect side effects. Use E2E for behavioral verification.)
- "I'll add the smoke test later" (Every package needs at least one E2E smoke test. Add it now.)
- "Mutation score is close enough at 78" (78 < 80 = merge blocked. Fix surviving mutants.)
- "I need to time the full page load for performance" (Page load includes API calls. Time UI operations only.)
- "Tests are at 1:15, close enough to 1 minute" (Pipeline will timeout and fail. Optimize now.)
- "I'll hardcode credentials for now and fix later" (Credentials in code = security incident. Use TAMS/Vault.)
- "The fallback tests are good enough" (Fallbacks catch nothing. Write real tests.)
- "I can skip SonarQube for this package" (SonarQube integration is automatic. Just create sonar-project.properties.)

</critical_rules>

<edge_cases>

## No Tests Defined — Fallback Behavior

If your package has no E2E, soak, or perf tests, the pipeline uses fallbacks:
- **E2E fallback:** Loads the package in the app shell and verifies it doesn't crash
- **Soak fallback:** Loads the package and leaves it open for 5 minutes

These are extremely basic and catch almost nothing. Always write real tests.

## Implicit Dependencies Not Detected

The incremental testing system only detects explicit dependencies (workspace references). If your UFA depends on a shared component via module federation (runtime), changes to that component won't trigger your tests.

**Mitigation:** If you know a shared component changed, manually trigger your package's tests:
```bash
cd {package}
pnpm test
```

## Stryker Config: Platform vs Local

Mutation testing is managed centrally — the platform runs Stryker on all packages daily. Some packages also have local Stryker configs for development convenience.

- **If platform-managed config and your local config have different thresholds:** The merge gate uses the platform's threshold (80). Your local config's `break` threshold is for your development workflow only.
- **If you don't have a local config:** You can still run mutation testing locally by installing Stryker dependencies and creating a config. The platform will run mutations regardless.

## Coverage Exclusions

Be careful with `sonar.coverage.exclusions` in `sonar-project.properties`. Over-excluding files inflates your coverage percentage artificially. Only exclude:
- Test files and utilities (`**/__tests__/**`, `**/*.test.*`, `**/testUtils.*`)
- Generated files (`**/__generated__/**`)
- Build scripts (`**/scripts/**`)

Do NOT exclude production code to boost coverage numbers.

## Thread Pool Configuration

If you enable thread pooling for performance, be aware:
- CI environments may have different CPU counts than your local machine
- `maxThreads: 9` works well locally but may cause contention in CI
- Start with `minThreads: 2, maxThreads: 4` for CI compatibility and increase if needed

## Soak Test Duration in Local Development

Soak tests are designed for 60-180 minute durations in the pipeline. When running locally for development:
- Override the duration: `SOAK_DURATION_MS = 5 * 60 * 1000` (5 minutes)
- Or use Playwright's `--timeout` flag
- Never commit a shortened duration — use environment variables

## MUI X License in Tests

Some DREAM components use MUI X (DataGrid, DatePicker Pro). If your tests render these components and you see license warnings:
- Add `LicenseInfo.setLicenseKey(import.meta.env.VITE_REACT_APP_MUI_X_KEY)` to `setupTests.ts`
- The key comes from the `.env` file (do NOT hardcode the actual key)

</edge_cases>

<verification_checklist>

Before considering test setup complete:

**Vitest Configuration:**
- [ ] `vitest.config.ts` exists with jsdom environment, globals: true, v8 coverage provider
- [ ] `setupTests.ts` exists with @testing-library/jest-dom and matchMedia mock
- [ ] Coverage reporters include `text` and `lcov`
- [ ] Coverage includes only production code directories
- [ ] Package added to `vitest.workspace.ts` at repo root

**Coverage:**
- [ ] Unit test coverage ≥80% lines
- [ ] `test:ci` script uses `--coverage.thresholds.lines=80`

**Stryker (if local config added):**
- [ ] `stryker.config.json` matches platform-api pattern
- [ ] Thresholds: high=90, low=80, break=79.999999999
- [ ] `test:mutation` script in package.json
- [ ] Mutation score ≥80 locally

**Playwright E2E:**
- [ ] At least one smoke test at `tests/e2e/smoke.ts`
- [ ] Smoke test verifies package loads in app shell
- [ ] All tests are TypeScript
- [ ] No hardcoded credentials

**Playwright Soak (if applicable):**
- [ ] Soak tests at `tests/soak/{testName}.ts`
- [ ] NO behavior assertions — only browser error detection
- [ ] CUJ cycles defined for typical user activity
- [ ] Benign errors filtered (e.g., ResizeObserver loop)

**Playwright Perf (if applicable):**
- [ ] Perf tests at `tests/perf/{testName}.ts`
- [ ] Diagnostic timer wraps UI code ONLY, not upstream dependencies
- [ ] Clear threshold defined for what "fast enough" means

**SonarQube:**
- [ ] `sonar-project.properties` exists with correct exclusions
- [ ] Coverage report generated at `coverage/lcov.info`

**Pipeline Compliance:**
- [ ] Unit tests + build complete in under 1 minute
- [ ] JUnit output compatible (testPackage.js handles this)

</verification_checklist>

<integration>

**This skill is called by:**
- `develop-frontend` (orchestrator) — Phase 4 in the golden path
- Directly when setting up or improving test infrastructure for an existing package

**This skill builds on:**
- `implement-ui-feature` — TDD cycle, unit test writing, basic Stryker setup, test utilities (TestProviders, createUser, custom render)

**Skill chain for new features:**
```
create-allin-package → design-ui-component → implement-ui-feature → test-frontend
```

**Scope boundary with implement-ui-feature:**
- `implement-ui-feature` covers: .feature specs, TDD cycle (RED → GREEN → REFACTOR), running Stryker as verification, test utilities setup, GUP auth patterns in tests, business logic boundary
- `test-frontend` covers: Vitest config optimization, Stryker config optimization and mutant fixing, Playwright E2E/soak/perf tests, coverage reporting and SonarQube, pipeline integration, TestKube, time limit enforcement

**Dependencies:**
- Package must exist (created by `create-allin-package`)
- Unit tests should be written first via TDD (guided by `implement-ui-feature`)
- Component design decisions made (guided by `design-ui-component`)

</integration>

<resources>

**Reference files in allin-ui:**
- `configs/platform-api/stryker.config.json` — Reference Stryker configuration
- `configs/platform-api/vitest.config.ts` — Minimal vitest config example
- `ufas/action-iq/vitest.config.ts` — UFA vitest config with coverage
- `packages/shared-components/vitest.config.ts` — Advanced vitest config with thread pooling
- `scripts/build/tasks/testPackage.js` — Pipeline test runner (vitest + JUnit + lcov)
- `scripts/build/tasks/sonarScan.js` — SonarQube scanner script
- `turbo.json` — Turbo task definitions (allin-test, test, test:ci, allin-sonar-scan)
- `vitest.workspace.ts` — Monorepo workspace test orchestration
- `turbo/generators/templates/lib/setupTests.ts` — Generator template for setupTests

**Confluence pages:**
- Policies and Standards (page ID: 1479759939) — Testing policy table, thresholds, file locations, time limits
- CD Pipeline Design (page ID: 1467250722) — Pipeline stages, test execution, responsibility division
- Test Coverage Overview (page ID: 1484946496) — SonarQube coverage, 80% minimum
- Stryker Mutator (page ID: 1490228218) — How mutation testing works
- UWM Software Testing Guidance (page ID: 1465101912) — Organization-wide testing tool standards
- TestKube/Playwright Standards — TypeScript required, browser agnostic, credentials via TAMS/Vault
- TAMS/Vault Instructions (page ID: 1332938089) — Test credential management process
- Performance Testing NFR (page ID: 1492161254) — Infrastructure specs, response time expectations

**Bitbucket:**
- `EH/allin-ui` — Monorepo MFE with all test infrastructure

**Tools:**
- Vitest — Unit testing framework (jsdom environment)
- Playwright — E2E, soak, performance testing
- Stryker — Mutation testing (@stryker-mutator/vitest-runner)
- SonarQube — Code quality and coverage reporting
- TestKube — Kubernetes-based test execution for post-build tests
- Port (https://app.us.port.io) — Manual trigger for mutation tests, deployment management

</resources>
