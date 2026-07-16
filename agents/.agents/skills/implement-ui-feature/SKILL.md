---
name: implement-ui-feature
description: Use when implementing a UI feature in allin-ui — enforces strict TDD with .feature specs, derives Vitest unit tests, integrates GUP auth patterns, and maintains clean business logic boundaries
---

<skill_overview>
Guides developers through implementing UI features in allin-ui packages using strict TDD (Test-Driven Development). The workflow starts with writing `.feature` specification files, deriving Vitest unit tests from those specs, implementing the minimum code to pass, then verifying with Stryker mutation testing.

**This skill enforces three critical boundaries:**
1. **Spec-first development:** `.feature` files in `{package}/spec/` serve as human-readable specifications (NOT executable BDD tests). Every Vitest test traces back to a `.feature` scenario.
2. **Business logic boundary:** Frontend code handles ONLY user experience — rendering, navigation, form UX, loading states. Business calculations, orchestration, and validation rules belong in backend services.
3. **Mock boundary:** Tests mock ONLY infrastructure (API clients, browser APIs, module federation). Never mock business logic, data transformers, or component rendering.

**Key context:** `.feature` files are a NEW practice being introduced in allin-ui. Zero `.feature` files exist today. This skill establishes the practice. Tests live in `__tests__/` directories alongside source code, use Vitest with jsdom, and follow the custom render wrapper pattern with `MockPassport` for auth testing. Stryker mutation testing exists in some packages (e.g., `configs/platform-api/stryker.config.json`) and should be added to all new packages.
</skill_overview>

<rigidity_level>
LOW FREEDOM - The TDD cycle (spec → RED → GREEN → REFACTOR → mutate) is rigid and must be followed in order. .feature files MUST be written before tests. Tests MUST fail before implementation. Stryker MUST be run after implementation. Business logic boundary and mock boundary rules are non-negotiable. Auth patterns, test utility patterns, and state management choices adapt to the specific feature.
</rigidity_level>

<quick_reference>

| Step | Action | Deliverable |
|------|--------|-------------|
| **1. Write Spec** | Create `.feature` file in `{package}/spec/` | Human-readable Gherkin scenarios |
| **2. Derive Tests (RED)** | Map scenarios → Vitest `it()` blocks | Failing tests in `__tests__/` |
| **3. Implement (GREEN)** | Minimal code to pass tests | Component + hooks + services |
| **4. Refactor** | Improve structure, tests stay green | Clean code, no behavior changes |
| **5. Auth** | Integrate GUP via `lib-node-user-passport-component` | Role checks, MockPassport tests |
| **6. Boundary Check** | Verify no business logic in frontend | UX-only code |
| **7. Mutation Test** | Run `npx stryker run` | Score ≥80 |
| **8. Verify** | Coverage ≥80%, all tests pass | Ready for review |

**TDD Cycle:**
```
.feature spec → Vitest test (RED) → implement (GREEN) → refactor → Stryker (≥80)
```

**Business Logic Boundary:**
```
Frontend (YES): rendering, navigation, form UX, loading states, display formatting
Backend (NO):  calculations, orchestration, business validation, shared state for capabilities
```

</quick_reference>

<when_to_use>
- Implementing a new feature in an existing allin-ui package (UFA, SCL, or IAP)
- Adding components, pages, hooks, or services to an allin-ui package
- Need to write tests for UI components following TDD
- Need to integrate GUP authentication into a feature
- Need guidance on what logic belongs in frontend vs backend

**Do NOT use for:**
- Creating a new allin-ui package (use `create-allin-package`)
- Designing component structure and DREAM compliance (use `design-ui-component`)
- Setting up comprehensive test strategy, Playwright E2E, or pipeline config (use `test-frontend`)
- Implementing backend business services (use `develop-business-service` from uwm-business-service-dev)
- Contributing components TO the DREAM library (see dream-buddy.md)
</when_to_use>

<the_process>

## Step 1: Write the Feature Specification

**This is a NEW practice in allin-ui.** Feature specs create a traceable link between business requirements and test cases. They are human-readable documentation that developers and stakeholders can review together.

### Where .feature Files Live

```
{package}/
  spec/                          ← .feature files go HERE (new directory)
    loan-summary-card.feature
    admin-dashboard.feature
  src/
    components/
      LoanSummaryCard/
        LoanSummaryCard.tsx
        __tests__/               ← Vitest tests go HERE (existing pattern)
          LoanSummaryCard.test.tsx
```

**CRITICAL:** `.feature` files are SPECIFICATIONS, not executable tests. Do NOT install `@cucumber/cucumber`, `cucumber`, `gherkin`, or any BDD test runner. These files are READ by developers and used to DERIVE Vitest tests manually.

### .feature File Template

```gherkin
Feature: Loan Summary Card
  As a loan officer
  I want to see a summary of loan details
  So that I can quickly assess a borrower's application

  Background:
    Given the user is authenticated
    And the loan data API returns valid data

  Scenario: Display borrower name and loan number
    Given a loan with borrower "Jane Smith" and loan number "789012"
    When the component renders
    Then I should see "Jane Smith" displayed
    And I should see loan number "789012" displayed

  Scenario: Show loading state while data is fetching
    Given the loan data API has not responded yet
    When the component renders
    Then I should see a loading spinner
    And I should NOT see any loan details

  Scenario: Show error state when API fails
    Given the loan data API returns an error
    When the component renders
    Then I should see an error message
    And I should see a "Retry" button

  Scenario Outline: Display formatted currency values
    Given a loan with <field> value of <rawValue>
    When the component renders
    Then I should see <field> displayed as <formattedValue>

    Examples:
      | field        | rawValue | formattedValue |
      | Loan Amount  | 350000   | $350,000.00    |
      | Monthly P&I  | 2145.67  | $2,145.67      |
      | Interest Rate| 0.0675   | 6.750%         |
```

### .feature Syntax Rules

| Gherkin Element | Purpose | Example |
|----------------|---------|---------|
| `Feature:` | Component or capability name | `Feature: Loan Summary Card` |
| `As a / I want / So that` | User story context (optional but recommended) | Business justification |
| `Background:` | Shared preconditions for all scenarios | Common setup (auth, data) |
| `Scenario:` | One specific user interaction or state | Maps to one `it()` block |
| `Scenario Outline:` | Parameterized scenario with examples | Maps to `it.each()` |
| `Given` | Initial state / preconditions | Props, mock data, API state |
| `When` | User action or trigger | Click, render, navigate |
| `Then` | Expected outcome | Visible text, state change, API call |
| `And` | Additional Given/When/Then | Continuation of previous step type |
| `Examples:` | Data table for Scenario Outline | Parameterized test values |

---

## Step 2: Derive Vitest Tests from the Spec (RED Phase)

Transform each `.feature` scenario into a Vitest test case. The mapping rules are mechanical:

### Derivation Rules

| .feature Element | Vitest Equivalent |
|-----------------|-------------------|
| `Feature: Loan Summary Card` | `describe('LoanSummaryCard', () => { ... })` |
| `Background:` steps | `beforeEach(() => { ... })` |
| `Scenario: Display borrower name` | `it('displays borrower name and loan number', () => { ... })` |
| `Scenario Outline:` + `Examples:` | `it.each([...])('displays %s as %s', ...)` |
| `Given` steps | Test setup: render with props, configure mocks |
| `When` steps | User action: `fireEvent.click()`, `await waitFor()` |
| `Then` steps | Assertions: `expect(screen.getByText(...)).toBeInTheDocument()` |

### Derived Test File

From the `.feature` above, derive this test file at `src/components/LoanSummaryCard/__tests__/LoanSummaryCard.test.tsx`:

```tsx
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { screen, waitFor, cleanup } from '@testing-library/react';
import { render } from '../../testUtils/testUtils'; // custom render with providers
import { LoanSummaryCard } from '../LoanSummaryCard';
import * as loanService from '../../services/loanService';

// Mock infrastructure only — the API client
vi.mock('../../services/loanService');

describe('LoanSummaryCard', () => {
    // Background: shared preconditions
    beforeEach(() => {
        // "Given the user is authenticated" → handled by MockPassport in AllProviders
        // "And the loan data API returns valid data" → mock service response
        vi.mocked(loanService.getLoanSummary).mockResolvedValue({
            borrowerName: 'Jane Smith',
            loanNumber: '789012',
            loanAmount: 350000,
            monthlyPI: 2145.67,
            interestRate: 0.0675,
        });
    });

    afterEach(() => {
        vi.restoreAllMocks();
        cleanup();
    });

    // Scenario: Display borrower name and loan number
    it('displays borrower name and loan number', async () => {
        // Given a loan with borrower "Jane Smith" and loan number "789012"
        // (covered by beforeEach mock)

        // When the component renders
        render(<LoanSummaryCard loanId="test-loan-1" />);

        // Then I should see "Jane Smith" displayed
        await waitFor(() => {
            expect(screen.getByText('Jane Smith')).toBeInTheDocument();
        });
        // And I should see loan number "789012" displayed
        expect(screen.getByText('789012')).toBeInTheDocument();
    });

    // Scenario: Show loading state while data is fetching
    it('shows loading spinner while data is fetching', () => {
        // Given the loan data API has not responded yet
        vi.mocked(loanService.getLoanSummary).mockReturnValue(
            new Promise(() => {}) // never resolves
        );

        // When the component renders
        render(<LoanSummaryCard loanId="test-loan-1" />);

        // Then I should see a loading spinner
        expect(screen.getByRole('progressbar')).toBeInTheDocument();
        // And I should NOT see any loan details
        expect(screen.queryByText('Jane Smith')).not.toBeInTheDocument();
    });

    // Scenario: Show error state when API fails
    it('shows error message and retry button when API fails', async () => {
        // Given the loan data API returns an error
        vi.mocked(loanService.getLoanSummary).mockRejectedValue(
            new Error('Network error')
        );

        // When the component renders
        render(<LoanSummaryCard loanId="test-loan-1" />);

        // Then I should see an error message
        await waitFor(() => {
            expect(screen.getByText(/error/i)).toBeInTheDocument();
        });
        // And I should see a "Retry" button
        expect(screen.getByRole('button', { name: /retry/i })).toBeInTheDocument();
    });

    // Scenario Outline: Display formatted currency values
    it.each([
        ['Loan Amount', 350000, '$350,000.00'],
        ['Monthly P&I', 2145.67, '$2,145.67'],
        ['Interest Rate', 0.0675, '6.750%'],
    ])('displays %s formatted as %s', async (field, rawValue, formattedValue) => {
        render(<LoanSummaryCard loanId="test-loan-1" />);

        await waitFor(() => {
            expect(screen.getByText(formattedValue)).toBeInTheDocument();
        });
    });
});
```

### RED Phase Verification

After writing tests, run them to confirm they FAIL:

```bash
cd {package}
npx vitest run --reporter=verbose
```

All tests should fail with errors like "Component not found" or "Cannot find module". This confirms the tests are testing real behavior, not passing vacuously.

---

## Step 3: Implement Minimum Code (GREEN Phase)

Write the minimum code necessary to make all tests pass. Follow DREAM component standards from the `design-ui-component` skill.

### Implementation Checklist

1. **Create the component file:** `src/components/LoanSummaryCard/LoanSummaryCard.tsx`
2. **Create the service file (if needed):** `src/services/loanService.ts` — pure functions for API calls
3. **Create custom hooks (if needed):** `src/hooks/useLoanSummary.ts` — React Query wrapper
4. **Follow DREAM standards:** Use DREAM components, `useDreamTheme()`, `sx` prop with theme variables
5. **Follow business logic boundary:** Component renders data, hook fetches data, service calls API

### GREEN Phase Verification

```bash
cd {package}
npx vitest run --reporter=verbose
```

All tests should now pass. If any fail, fix the implementation (not the tests).

---

## Step 4: Refactor (While GREEN)

Improve code quality while keeping all tests passing:

- Extract reusable hooks from components
- Apply DREAM theme variables to replace any hardcoded values
- Simplify conditional rendering logic
- Extract formatting functions into utilities
- Ensure consistent import patterns

**Rule:** Run tests after EVERY refactoring change. If tests fail, the refactoring changed behavior — revert and try a smaller change.

---

## Step 5: GUP Auth Integration

### Package: `lib-node-user-passport-component`

This is the correct package name for all GUP auth imports. The package provides:

### Core Auth Components and Hooks

#### PassportAuth (App-Level Wrapper)

Already provided by the app-shell `GlobalLayout.tsx`. **Do NOT add PassportAuth again** in your UFA or SCL. Your components are already wrapped.

```tsx
// DO NOT DO THIS — app-shell already wraps with PassportAuth
// ❌ <PassportAuth backendUrl={url}><YourComponent /></PassportAuth>

// Your component just uses the hooks — auth is already set up
// ✅
import { usePassport } from 'lib-node-user-passport-component';

export function YourComponent() {
    const { user, isLoggedIn } = usePassport();
    // ... use user data
}
```

**Exception:** Standalone UFA development (running outside app-shell) wraps with PassportAuth in run-level-one providers:

```tsx
// Only for local development outside app-shell
import { PassportAuth } from 'lib-node-user-passport-component';

export const RunLevelOneProviders = ({ children }: { children: ReactNode }) => (
    <DreamThemeProvider family="external" mode="light">
        <PassportAuth backendUrl={`http://localhost:${port}`}>
            {children}
        </PassportAuth>
    </DreamThemeProvider>
);
```

#### usePassport() — Get User Context

Returns the current authenticated user and auth state.

```tsx
import { usePassport } from 'lib-node-user-passport-component';

export function UserGreeting() {
    const { user, isLoggedIn, logout, error, isLoading } = usePassport();

    if (isLoading) return <Loading />;
    if (error) return <SectionMessage appearance="error">{error.message}</SectionMessage>;
    if (!isLoggedIn || !user) return <Typography>Please log in</Typography>;

    return (
        <Box>
            <Typography>Welcome, {user.firstName} {user.lastName}</Typography>
            <Typography variant="body2">{user.email}</Typography>
            <Button onClick={logout}>Logout</Button>
        </Box>
    );
}
```

**User object shape:**

```tsx
interface User {
    userIdentifier: string;
    firstName: string;
    lastName: string;
    displayName: string;
    email: string;
    organizations: Array<{
        type: string;
        value: string;
        roles: string[];
        isCorrespondent: boolean;
        isSuperCorrespondent: boolean;
        contactId: string;
    }>;
    roles: string[];
    actualIdentity: User | null; // non-null during impersonation
}
```

#### useSinglePageAuth() — Standalone UFA Init

Call at the top level of a UFA's `App.tsx` when the UFA runs standalone (outside app-shell):

```tsx
import { usePassport, useSinglePageAuth } from 'lib-node-user-passport-component';

function App() {
    const { user } = usePassport();
    useSinglePageAuth(); // initializes auth flow — call with no arguments

    return (
        <DreamThemeProvider>
            <BrowserRouter basename="/your-ufa">
                <Router user={user!} />
            </BrowserRouter>
        </DreamThemeProvider>
    );
}
```

#### useAuthExclusion() — Skip Auth for a Page

Call in components that should render without requiring authentication:

```tsx
import { useAuthExclusion } from 'lib-node-user-passport-component';

export function PublicLandingPage() {
    useAuthExclusion(); // this page does NOT require login

    return <Typography>Welcome to our public page</Typography>;
}
```

#### MockPassport — Test Wrapper

Replaces `PassportAuth` in tests. Provides a mock user context:

```tsx
import { MockPassport, type User } from 'lib-node-user-passport-component';

const mockUser: User = {
    userIdentifier: '123-456-abc',
    firstName: 'John',
    lastName: 'Doe',
    displayName: 'John Doe',
    email: 'jdoe@uwm.com',
    organizations: [{
        type: 'Broker',
        value: '1234567',
        roles: [],
        isCorrespondent: true,
        isSuperCorrespondent: false,
        contactId: '7654321',
    }],
    roles: ['IT Department'],
    actualIdentity: null,
};

// In AllProviders for tests:
<MockPassport mockUser={mockUser}>
    {children}
</MockPassport>
```

### Platform API Auth Wrappers (`@uwm/platform-api`)

These hooks build on top of `lib-node-user-passport-component` for app-shell integration:

#### useAppShellRoleMatrix — Register Roles

Maps logical role names to AD group names, scoped by module:

```tsx
import { useAppShellRoleMatrix } from '@uwm/platform-api';

export function MyUfaRoot() {
    // Register role matrix for this UFA
    useAppShellRoleMatrix(
        {
            admin: ['IT Department', 'UFA Admin Group'],
            viewer: ['All Employees'],
            approver: ['Loan Approvers'],
        },
        'my-ufa', // module name for scoping
    );

    return <MyUfaRoutes />;
}
```

**RoleMatrix type:** `Record<string, string[]>` — key is logical role name, value is array of AD groups that satisfy it.

#### RequiredRoles.ts — Per-UFA Pattern

Each UFA defines its role mappings in a dedicated file:

```tsx
// src/RequiredRoles.ts
import type { RoleMatrix } from 'lib-node-user-passport-component';

export const roleMatrix: RoleMatrix = {
    admin: ['IT Department'],
    approver: ['CES-Exemption-Approvers'],
    requester: ['CES-Exemption-Requesters'],
    creator: ['CES-Policy-Creators'],
};
```

#### useAppShellRoles — Check Authorization

Check if the current user has required roles (scoped by module name):

```tsx
import { useAppShellRoles } from '@uwm/platform-api';

export function AdminPanel() {
    const isAuthorized = useAppShellRoles(
        { requiredRoles: ['admin'], requireAll: false },
        'my-ufa',
    );

    if (!isAuthorized) {
        return <SectionMessage appearance="warning">Access denied</SectionMessage>;
    }

    return <AdminContent />;
}
```

#### usePolicy — Complex Authorization

Evaluate authorization policies that combine email, organization, group, and role matrix conditions:

```tsx
import { usePolicy } from '@uwm/platform-api';

export function ChatWidget() {
    const canAccessChat = usePolicy('chatUwm');

    if (canAccessChat === undefined) return <Loading />; // still evaluating
    if (!canAccessChat) return null; // not authorized

    return <ChatInterface />;
}
```

---

## Step 6: Enforce Business Logic Boundaries

### What Belongs Where

| Logic Type | Frontend (YES) | Backend (NO) |
|-----------|---------------|-------------|
| **Rendering** | Display data, conditional visibility, layout | - |
| **Navigation** | Route changes, breadcrumbs, menu highlighting | - |
| **Form UX** | Field masking, character limits, focus management | - |
| **Loading states** | Spinners, skeletons, progress indicators | - |
| **Display formatting** | Currency formatting, date formatting, truncation | - |
| **UI validation** | Required field, email format, max length | - |
| **Business calculations** | - | LTV ratios, pricing, eligibility scoring |
| **Business validation** | - | Minimum amounts, rate limits, policy rules |
| **Orchestration** | - | Multi-service coordination, saga patterns |
| **Shared capability state** | - | Cross-UFA business data |

### Architecture Layers

Implement features using this layer separation:

```
┌─────────────────────────────────────────┐
│  Components (render UI, handle UX)      │ ← DREAM components, sx, theme
│  src/components/Foo/Foo.tsx             │
├─────────────────────────────────────────┤
│  Context Providers (orchestrate hooks)   │ ← Compose hooks, provide to children
│  src/context/FooProvider.tsx             │
├─────────────────────────────────────────┤
│  Custom Hooks (React Query wrappers)     │ ← useQuery, useMutation, caching
│  src/hooks/useFoo.ts                     │
├─────────────────────────────────────────┤
│  Service Functions (pure, no React)      │ ← API calls via createGateway()
│  src/services/fooService.ts              │
├─────────────────────────────────────────┤
│  Mappers (data transformation)           │ ← API DTO → UI model
│  src/utils/fooMapper.ts                  │
└─────────────────────────────────────────┘
```

### Service Layer Pattern

Service functions are pure — no React dependencies, no hooks, no state:

```tsx
// src/services/loanService.ts
import { createGateway } from '@uwm/platform-api';

const loanApi = createGateway('loan-service/api', 'v1');

export async function getLoanSummary(loanId: string): Promise<LoanSummary> {
    const { data } = await loanApi.get<LoanSummaryResponse>(`/loans/${loanId}/summary`);
    return data;
}

export async function updateLoanStatus(
    loanId: string,
    status: LoanStatus,
): Promise<void> {
    await loanApi.put(`/loans/${loanId}/status`, { status });
}
```

### React Query Hook Pattern

Hooks wrap services for caching and React state management:

```tsx
// src/hooks/useLoanSummary.ts
import { useQuery } from '@tanstack/react-query';
import { getLoanSummary } from '../services/loanService';

export function useLoanSummary(loanId: string) {
    return useQuery({
        queryKey: ['loanSummary', loanId],
        queryFn: () => getLoanSummary(loanId),
        enabled: Boolean(loanId),
    });
}
```

### Mapper Pattern

Mappers transform API data to UI display models:

```tsx
// src/utils/loanMapper.ts
export function formatCurrency(value: number): string {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
    }).format(value);
}

export function formatRate(value: number): string {
    return `${(value * 100).toFixed(3)}%`;
}

export function mapLoanToDisplayModel(loan: LoanSummary): LoanDisplayModel {
    return {
        borrowerName: loan.borrowerName,
        loanNumber: loan.loanNumber,
        formattedAmount: formatCurrency(loan.loanAmount),
        formattedRate: formatRate(loan.interestRate),
        formattedMonthlyPayment: formatCurrency(loan.monthlyPI),
    };
}
```

---

## Step 7: Set Up Test Infrastructure

### Test Utility Files

Every package needs a test utilities setup. Follow the established patterns:

#### testUtils.ts — Custom Render Wrapper

```tsx
// src/testUtils/testUtils.ts
import {
    type RenderOptions,
    type RenderResult,
    render,
} from '@testing-library/react';
import React from 'react';

import { AllProviders } from './TestProviders';

type CustomRender = (
    component: React.ReactElement,
    options?: RenderOptions,
) => RenderResult;

const customRender: CustomRender = (component, options) =>
    render(component, { wrapper: AllProviders, ...options });

// re-export everything from testing-library
export * from '@testing-library/react';

// override render method with custom wrapper
export { customRender as render };
```

#### TestProviders.tsx — Provider Wrapper

Compose all required providers for tests. The exact providers depend on your package:

**For packages using MockPassport (PREFERRED):**

```tsx
// src/testUtils/TestProviders.tsx
import { DreamThemeProvider } from 'lib-node-dream-ui-latest';
import { MockPassport, type User } from 'lib-node-user-passport-component';
import { type ReactNode } from 'react';
import { BrowserRouter } from 'react-router';

const mockUser: User = {
    userIdentifier: '123-456-abc',
    firstName: 'John',
    lastName: 'Doe',
    displayName: 'John Doe',
    email: 'jdoe@uwm.com',
    organizations: [],
    roles: ['IT Department'],
    actualIdentity: null,
};

export const AllProviders = ({ children }: { children: ReactNode }) => (
    <BrowserRouter>
        <DreamThemeProvider family="external" mode="light">
            <MockPassport mockUser={mockUser}>
                {children}
            </MockPassport>
        </DreamThemeProvider>
    </BrowserRouter>
);
```

**For packages using React Query:**

```tsx
// src/testUtils/TestProviders.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { DreamThemeProvider } from 'lib-node-dream-ui-latest';
import { MockPassport, type User } from 'lib-node-user-passport-component';
import { type ReactNode } from 'react';
import { BrowserRouter } from 'react-router';

const queryClient = new QueryClient({
    defaultOptions: {
        queries: { retry: false },
    },
});

const mockUser: User = {
    userIdentifier: '123-456-abc',
    firstName: 'John',
    lastName: 'Doe',
    displayName: 'John Doe',
    email: 'jdoe@uwm.com',
    organizations: [],
    roles: ['IT Department'],
    actualIdentity: null,
};

export const AllProviders = ({ children }: { children: ReactNode }) => (
    <BrowserRouter>
        <QueryClientProvider client={queryClient}>
            <DreamThemeProvider family="external" mode="light">
                <MockPassport mockUser={mockUser}>
                    {children}
                </MockPassport>
            </DreamThemeProvider>
        </QueryClientProvider>
    </BrowserRouter>
);
```

#### createUser() Factory — Mock User Objects

For tests that need different user configurations:

```tsx
// src/testUtils/userFactory.ts
import type { User } from 'lib-node-user-passport-component';

export function createUser(overrides?: Partial<User>): User {
    return {
        userIdentifier: '',
        firstName: 'Test',
        lastName: 'User',
        displayName: 'Test User',
        email: 'test@uwm.com',
        organizations: [{
            type: 'test',
            value: 'test',
            roles: [],
            isCorrespondent: false,
            isSuperCorrespondent: false,
            contactId: '',
        }],
        roles: [],
        actualIdentity: null,
        ...overrides,
    };
}

export const adminUser = createUser({
    roles: ['IT Department', 'Admin'],
    firstName: 'Admin',
    lastName: 'User',
    displayName: 'Admin User',
});

export const brokerUser = createUser({
    roles: ['External Broker Admin'],
    firstName: 'Broker',
    lastName: 'User',
    displayName: 'Broker User',
    organizations: [{
        type: 'Broker',
        value: '1234567',
        roles: [],
        isCorrespondent: true,
        isSuperCorrespondent: false,
        contactId: '7654321',
    }],
});
```

#### setupTests.ts — Test Environment

```tsx
// src/testUtils/setupTests.ts
import '@testing-library/jest-dom/vitest';
import { vi } from 'vitest';

// Mock browser APIs not available in jsdom
Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: vi.fn().mockImplementation((query) => ({
        matches: false,
        media: query,
        onchange: null,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
        dispatchEvent: vi.fn(),
    })),
});
```

### Mock Boundaries

**Mock ONLY infrastructure — never business logic:**

| Category | What to Mock | How |
|----------|-------------|-----|
| **API clients** | Service functions that call APIs | `vi.mock('../../services/loanService')` |
| **Auth (most tests)** | User context | `MockPassport` with `mockUser` prop in AllProviders |
| **Auth (conditional)** | isLoggedIn toggle between renders | `vi.mock('lib-node-user-passport-component')` with `usePassport: vi.fn()` |
| **Module federation** | Remote loading | `vi.mock('virtual:__federation__', ...)` |
| **Browser APIs** | matchMedia, fetch, dtrum | `vi.stubGlobal(...)` or `Object.defineProperty(window, ...)` |
| **Platform API** | Gateway, feature flags | `vi.mock('@uwm/platform-api', ...)` |

**NEVER mock these:**

| Category | Why Not |
|----------|---------|
| Data mappers/transformers | They contain display logic — test them with real inputs |
| Component rendering | You're testing the component — mocking it defeats the purpose |
| React hooks (internal) | Mock the service they call, not the hook itself |
| Business logic functions | If you find business logic in frontend, move it to backend |

### Auth Testing with MockPassport vs vi.mock

**Use MockPassport (preferred) for most tests:**

```tsx
// Testing that a component renders user info
// MockPassport in AllProviders provides the user

it('displays user name', () => {
    render(<UserGreeting />);
    expect(screen.getByText('John Doe')).toBeInTheDocument();
});
```

**Use vi.mock ONLY for testing auth-conditional rendering:**

```tsx
// Testing logged-in vs logged-out rendering within same test file
import { usePassport } from 'lib-node-user-passport-component';

vi.mock('lib-node-user-passport-component', async () => {
    const actual = await vi.importActual('lib-node-user-passport-component');
    return {
        ...actual,
        usePassport: vi.fn(() => ({
            user: null,
            isLoggedIn: false,
            isLoading: false,
            error: null,
            logout: vi.fn(),
        })),
        useSinglePageAuth: vi.fn(),
    };
});

it('shows login prompt when not authenticated', () => {
    render(<ProtectedPage />);
    expect(screen.getByText('Please log in')).toBeInTheDocument();
});

it('shows content when authenticated', () => {
    vi.mocked(usePassport).mockReturnValue({
        user: createUser({ roles: ['IT Department'] }),
        isLoggedIn: true,
        isLoading: false,
        error: null,
        logout: vi.fn(),
    });

    render(<ProtectedPage />);
    expect(screen.getByText('Welcome')).toBeInTheDocument();
});
```

---

## Step 8: Run Mutation Tests (Verification)

Stryker mutation testing verifies that your tests actually catch bugs, not just inflate coverage.

### Add Stryker to Your Package

If your package doesn't have a Stryker config yet, add one. Reference the existing config at `configs/platform-api/stryker.config.json`:

**1. Add dev dependencies:**

```bash
cd {package}
pnpm add -D @stryker-mutator/core @stryker-mutator/vitest-runner @stryker-mutator/typescript-checker
```

**2. Create `stryker.config.json`:**

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

**3. Add npm script to `package.json`:**

```json
{
    "scripts": {
        "test:mutation": "npx stryker run"
    }
}
```

### Run Mutation Tests

```bash
cd {package}
npx stryker run
```

### Interpret Results

- **Mutation score ≥80:** Pass. Your tests catch real bugs.
- **Mutation score <80:** Fail. Review surviving mutants and add tests for gaps.
- **Surviving mutant:** A code change that didn't cause any test to fail — your tests missed a bug.

### Fix Surviving Mutants

For each surviving mutant, add a test that specifically catches that mutation:

```
Mutant: Changed `>` to `>=` in line 15
File: src/utils/loanMapper.ts
Status: Survived

→ Add test: 'rejects value at exact boundary' that verifies the > vs >= distinction
```

---

## Platform API Capabilities for Feature Implementation

Beyond auth, `@uwm/platform-api` provides these capabilities you'll commonly use:

### createGateway — API Calls

Primary pattern for calling backend services:

```tsx
import { createGateway } from '@uwm/platform-api';

const api = createGateway('my-service/api', 'v1');

// GET request
const { data } = await api.get<ResponseType>('/endpoint');

// POST request
const { data } = await api.post<ResponseType>('/endpoint', payload);
```

### Feature Flags

Conditionally enable features:

```tsx
import { useFeatureFlag } from '@uwm/platform-api';

export function NewFeature() {
    const isEnabled = useFeatureFlag('my-feature-flag');
    if (!isEnabled) return null;

    return <NewFeatureContent />;
}
```

### SignalR — Real-Time Updates

For features requiring live data:

```tsx
import { useSignalRConnection, useSignalRListener } from '@uwm/platform-api';

export function LiveUpdates() {
    const connection = useSignalRConnection('notification-hub');

    useSignalRListener(connection, 'NewNotification', (data) => {
        // handle real-time notification
    });

    return <NotificationList />;
}
```

### Observability — Dynatrace Integration

Track user actions for monitoring:

```tsx
import { observabilityUtils } from '@uwm/platform-api';

export function handleSubmit() {
    const actionId = observabilityUtils.enterAction('submit-loan-application');
    try {
        await submitApplication(data);
        observabilityUtils.leaveAction(actionId);
    } catch (error) {
        observabilityUtils.leaveAction(actionId);
        throw error;
    }
}
```

### State Management Decision Guide

| State Type | Tool | When to Use |
|-----------|------|-------------|
| **Server state** (API data) | React Query (`useQuery`, `useMutation`) | Fetching, caching, syncing backend data |
| **App-wide state** (cross-component) | Zustand stores (from `@uwm/platform-api`) | UFA info, navigation, manifest, policies |
| **Feature state** (local to feature) | React Context + `useReducer` | Complex state within a feature boundary |
| **Form state** | `react-hook-form` (`useForm`, `useFormContext`) | Form inputs, validation, submission |
| **Redux** (legacy) | `react-redux` + Redux Toolkit | **Only in existing packages that already use Redux.** Do not introduce Redux in new packages. |

</the_process>

<examples>

## Example 1: Complete TDD Cycle (Correct)

**Scenario:** Implement a BorrowerInfoCard component that displays borrower name and loan number.

### Step 1: .feature spec (`spec/borrower-info-card.feature`)

```gherkin
Feature: Borrower Info Card
  As a loan officer
  I want to see borrower information at a glance
  So that I can identify the loan I'm working on

  Background:
    Given the user is authenticated

  Scenario: Display borrower name and loan number
    Given a borrower named "Alice Johnson" with loan number "456789"
    When the card renders
    Then I should see "Alice Johnson"
    And I should see "456789"

  Scenario: Show placeholder when no borrower data provided
    Given no borrower data is available
    When the card renders
    Then I should see "No borrower information available"
```

### Step 2: Derived test (`src/components/BorrowerInfoCard/__tests__/BorrowerInfoCard.test.tsx`)

```tsx
import { describe, it, expect, afterEach, vi } from 'vitest';
import { screen, cleanup } from '@testing-library/react';
import { render } from '../../../testUtils/testUtils';
import { BorrowerInfoCard } from '../BorrowerInfoCard';

describe('BorrowerInfoCard', () => {
    afterEach(() => {
        vi.restoreAllMocks();
        cleanup();
    });

    // Scenario: Display borrower name and loan number
    it('displays borrower name and loan number', () => {
        render(
            <BorrowerInfoCard
                borrowerName="Alice Johnson"
                loanNumber="456789"
            />
        );

        expect(screen.getByText('Alice Johnson')).toBeInTheDocument();
        expect(screen.getByText('456789')).toBeInTheDocument();
    });

    // Scenario: Show placeholder when no borrower data provided
    it('shows placeholder when no borrower data provided', () => {
        render(<BorrowerInfoCard />);

        expect(
            screen.getByText('No borrower information available')
        ).toBeInTheDocument();
    });
});
```

### Step 3: Run tests (RED) — both fail

```
FAIL  src/components/BorrowerInfoCard/__tests__/BorrowerInfoCard.test.tsx
  ✕ displays borrower name and loan number
  ✕ shows placeholder when no borrower data provided
```

### Step 4: Implement (`src/components/BorrowerInfoCard/BorrowerInfoCard.tsx`)

```tsx
import { Card, Typography } from 'lib-node-dream-ui-latest';
import { useDreamTheme } from 'lib-node-dream-ui-latest';

interface BorrowerInfoCardProps {
    /** Borrower's full name */
    borrowerName?: string;
    /** Loan identification number */
    loanNumber?: string;
}

export function BorrowerInfoCard({ borrowerName, loanNumber }: BorrowerInfoCardProps) {
    const theme = useDreamTheme();

    if (!borrowerName || !loanNumber) {
        return (
            <Card sx={{ padding: theme.spacing(2) }}>
                <Typography variant="body1" color="text.secondary">
                    No borrower information available
                </Typography>
            </Card>
        );
    }

    return (
        <Card sx={{ padding: theme.spacing(2) }}>
            <Typography variant="h6">{borrowerName}</Typography>
            <Typography variant="body2" color="text.secondary">
                Loan #{loanNumber}
            </Typography>
        </Card>
    );
}
```

### Step 5: Run tests (GREEN) — both pass

```
PASS  src/components/BorrowerInfoCard/__tests__/BorrowerInfoCard.test.tsx
  ✓ displays borrower name and loan number
  ✓ shows placeholder when no borrower data provided
```

### Step 6: Run Stryker — mutation score ≥80

```bash
npx stryker run
# Mutation score: 100% (all mutants killed)
```

**Why this is correct:** Every test traces to a `.feature` scenario. Tests verify real user-facing behavior (text rendering). No infrastructure was mocked because the component is pure UI. The implementation was minimal — just enough to pass tests.

---

## Example 2: Auth-Conditional Component with MockPassport (Correct)

**Scenario:** Implement an ActionsMenu that shows "Create Policy" only for users with the creator role.

### .feature spec (`spec/actions-menu.feature`)

```gherkin
Feature: Actions Menu
  As an admin
  I want to see available actions based on my role
  So that I only attempt actions I'm authorized for

  Scenario: Show create option for policy creators
    Given the user has the "CES-Policy-Creators" role
    When the actions menu renders
    Then I should see a "Create Policy" menu item

  Scenario: Hide create option for non-creators
    Given the user does NOT have the "CES-Policy-Creators" role
    When the actions menu renders
    Then I should NOT see a "Create Policy" menu item
    And I should see "No available actions"
```

### Test (`src/components/ActionsMenu/__tests__/ActionsMenu.test.tsx`)

```tsx
import { describe, it, expect, afterEach, vi } from 'vitest';
import { screen, cleanup, render } from '@testing-library/react';
import { DreamThemeProvider } from 'lib-node-dream-ui-latest';
import { MockPassport } from 'lib-node-user-passport-component';
import { BrowserRouter } from 'react-router';
import { ActionsMenu } from '../ActionsMenu';
import { createUser } from '../../../testUtils/userFactory';

// Custom renders for different user roles (NOT using shared AllProviders
// because we need different mockUser per test)
function renderWithUser(user: ReturnType<typeof createUser>) {
    return render(
        <BrowserRouter>
            <DreamThemeProvider family="external" mode="light">
                <MockPassport mockUser={user}>
                    <ActionsMenu />
                </MockPassport>
            </DreamThemeProvider>
        </BrowserRouter>
    );
}

describe('ActionsMenu', () => {
    afterEach(() => {
        vi.restoreAllMocks();
        cleanup();
    });

    // Scenario: Show create option for policy creators
    it('shows Create Policy for users with CES-Policy-Creators role', () => {
        const creator = createUser({ roles: ['CES-Policy-Creators'] });
        renderWithUser(creator);

        expect(screen.getByText('Create Policy')).toBeInTheDocument();
    });

    // Scenario: Hide create option for non-creators
    it('hides Create Policy for users without creator role', () => {
        const viewer = createUser({ roles: ['IT Department'] });
        renderWithUser(viewer);

        expect(screen.queryByText('Create Policy')).not.toBeInTheDocument();
        expect(screen.getByText('No available actions')).toBeInTheDocument();
    });
});
```

### Implementation (`src/components/ActionsMenu/ActionsMenu.tsx`)

```tsx
import { Box, Typography, Button } from 'lib-node-dream-ui-latest';
import { usePassport } from 'lib-node-user-passport-component';
import { useDreamTheme } from 'lib-node-dream-ui-latest';

export function ActionsMenu() {
    const { user } = usePassport();
    const theme = useDreamTheme();
    const canCreate = user?.roles.includes('CES-Policy-Creators') ?? false;

    if (!canCreate) {
        return (
            <Box sx={{ padding: theme.spacing(2) }}>
                <Typography color="text.secondary">No available actions</Typography>
            </Box>
        );
    }

    return (
        <Box sx={{ padding: theme.spacing(2) }}>
            <Button variant="contained" onClick={() => { /* navigate to create */ }}>
                Create Policy
            </Button>
        </Box>
    );
}
```

**Why this is correct:** Uses `MockPassport` with different `mockUser` objects per test instead of `vi.mock`. Tests verify real role-checking behavior. The `createUser()` factory makes user construction concise. Each test traces to a `.feature` scenario.

---

## Example 3: Business Logic Boundary Violation (Anti-Pattern)

### WRONG: Business calculation in frontend

```tsx
// ❌ WRONG — business logic (LTV calculation) in frontend
// src/utils/fieldTypeUtils.ts

export function calculateLoanToValue(
    loanAmount: number,
    salesPrice: number,
    appraisedValue: number,
    propertyState: string,
): number {
    // This is a BUSINESS RULE — it varies by state
    const isNewYork = propertyState === 'NY' || propertyState === 'New York';

    let calculationPrice: number;
    if (isNewYork && appraisedValue > 0) {
        // New York: always use appraised value only
        calculationPrice = appraisedValue;
    } else if (salesPrice === 0 && appraisedValue > 0) {
        calculationPrice = appraisedValue;
    } else {
        // Lesser of sales price or appraised value
        calculationPrice = Math.min(salesPrice, appraisedValue);
    }

    return loanAmount / calculationPrice;
}
```

**Why this is wrong:**
- State-specific LTV rules are business logic that belongs in the backend service
- If the rule changes (e.g., new state exception), both frontend and backend need updating
- The frontend should call the backend API for the calculated LTV value
- Frontend tests would need to replicate all business rule edge cases

### RIGHT: Frontend calls backend, displays result

```tsx
// ✅ RIGHT — service calls backend for LTV
// src/services/loanService.ts
import { createGateway } from '@uwm/platform-api';

const loanApi = createGateway('loan-calculation-service/api', 'v1');

export async function getLoanToValue(loanId: string): Promise<LtvResult> {
    const { data } = await loanApi.get<LtvResult>(`/loans/${loanId}/ltv`);
    return data;
}

// ✅ RIGHT — component only displays the result
// src/components/LtvDisplay/LtvDisplay.tsx
import { Typography } from 'lib-node-dream-ui-latest';
import { useLoanToValue } from '../../hooks/useLoanToValue';

export function LtvDisplay({ loanId }: { loanId: string }) {
    const { data: ltv, isLoading, error } = useLoanToValue(loanId);

    if (isLoading) return <Typography>Calculating...</Typography>;
    if (error) return <Typography color="error">Failed to calculate LTV</Typography>;

    return <Typography>{(ltv.ratio * 100).toFixed(2)}% LTV</Typography>;
}
```

**Why this is correct:**
- Business rule lives in one place (backend)
- Frontend only formats and displays
- Rule changes require only backend updates
- Frontend tests mock the service, not the business logic

---

## Example 4: Mock Boundary Violation (Anti-Pattern)

### WRONG: Mocking the data mapper

```tsx
// ❌ WRONG — mocking a mapper function means you're testing the mock, not production code
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '../testUtils/testUtils';
import { LoanCard } from '../LoanCard';
import * as loanMapper from '../../utils/loanMapper';

// ❌ Don't mock mappers — they contain display logic you need to test
vi.mock('../../utils/loanMapper', () => ({
    formatCurrency: vi.fn(() => '$100,000.00'),
    mapLoanToDisplayModel: vi.fn(() => ({
        borrowerName: 'Test User',
        formattedAmount: '$100,000.00',
    })),
}));

it('displays formatted loan amount', () => {
    render(<LoanCard loan={rawLoan} />);
    // ❌ This always passes because the mock returns '$100,000.00'
    // ❌ If formatCurrency has a bug, this test won't catch it
    expect(screen.getByText('$100,000.00')).toBeInTheDocument();
});
```

### RIGHT: Use real mapper, mock only the API client

```tsx
// ✅ RIGHT — mock infrastructure (API), let mapper run with real logic
import { describe, it, expect, vi, afterEach } from 'vitest';
import { render, screen, waitFor, cleanup } from '../testUtils/testUtils';
import { LoanCard } from '../LoanCard';
import * as loanService from '../../services/loanService';

// ✅ Mock only the infrastructure layer (API call)
vi.mock('../../services/loanService');

describe('LoanCard', () => {
    afterEach(() => {
        vi.restoreAllMocks();
        cleanup();
    });

    it('displays formatted loan amount from API data', async () => {
        // ✅ Mock the API response with raw data
        vi.mocked(loanService.getLoanDetails).mockResolvedValue({
            borrowerName: 'Test User',
            loanAmount: 100000,  // raw number from API
        });

        render(<LoanCard loanId="test-1" />);

        // ✅ Assert the FORMATTED output — this tests the real mapper
        await waitFor(() => {
            expect(screen.getByText('$100,000.00')).toBeInTheDocument();
        });
    });

    it('handles zero loan amount correctly', async () => {
        vi.mocked(loanService.getLoanDetails).mockResolvedValue({
            borrowerName: 'Test User',
            loanAmount: 0,
        });

        render(<LoanCard loanId="test-2" />);

        await waitFor(() => {
            expect(screen.getByText('$0.00')).toBeInTheDocument();
        });
    });
});
```

### WRONG: vi.mock for auth in every test file

```tsx
// ❌ WRONG — unnecessarily mocking the auth library in every file
vi.mock('lib-node-user-passport-component', () => ({
    usePassport: vi.fn(() => ({
        user: { firstName: 'Test', roles: [] },
        isLoggedIn: true,
    })),
    useSinglePageAuth: vi.fn(),
    MockPassport: ({ children }) => children,
}));

it('renders component', () => {
    render(<MyComponent />);
    // ❌ MockPassport in AllProviders already handles auth
    // ❌ vi.mock adds complexity and can mask auth integration bugs
});
```

### RIGHT: Use MockPassport from AllProviders

```tsx
// ✅ RIGHT — AllProviders includes MockPassport with a default mockUser
// No vi.mock needed for auth — just render
import { render, screen } from '../testUtils/testUtils'; // custom render

it('renders component with authenticated user', () => {
    // ✅ MockPassport in AllProviders provides a default authenticated user
    render(<MyComponent />);
    expect(screen.getByText('Welcome')).toBeInTheDocument();
});
```

**Why this is correct:** Using `MockPassport` in `AllProviders` is the official testing pattern from `lib-node-user-passport-component`. It provides a real mock context that behaves like the production `PassportAuth`. Using `vi.mock` creates a shallow mock that can mask integration issues. Reserve `vi.mock` for tests that specifically need to toggle `isLoggedIn` between test cases.

</examples>

<critical_rules>

## Rules That Have No Exceptions

1. **Write .feature spec BEFORE tests** - Every Vitest test must trace back to a .feature scenario. No "I'll add the spec later."
2. **Tests MUST fail first (RED)** - If tests pass before implementation exists, they're testing nothing. Run tests immediately after writing them and verify failure.
3. **.feature files are NOT executable** - Do NOT install cucumber, gherkin, or any BDD runner. .feature files are specifications read by developers, NOT executed by tools.
4. **.feature files go in `{package}/spec/`** - NOT in `__tests__/`, NOT in `src/`, NOT in the repo root.
5. **Vitest tests go in `__tests__/` alongside source** - `src/components/Foo/__tests__/Foo.test.tsx` — NOT in `spec/`, NOT at the package root.
6. **Frontend = UX logic ONLY** - No business calculations, no orchestration, no business validation rules. If you're writing `if (state === 'NY')` logic about loan amounts, it belongs in the backend.
7. **Mock only infrastructure** - API clients, module federation, browser APIs, platform-api. Never mock data mappers, component rendering, or business logic functions.
8. **Use MockPassport for auth testing** - Not `vi.mock('lib-node-user-passport-component')` unless you specifically need to toggle `isLoggedIn` between renders.
9. **Always import from vitest explicitly** - `import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'` — even though `globals: true` makes imports optional, explicit imports provide clarity and IDE support.
10. **Always cleanup in afterEach** - `vi.restoreAllMocks()` + `cleanup()` from `@testing-library/react`. Omitting this causes state corruption between tests.
11. **GUP package is `lib-node-user-passport-component`** - NOT `@uwm/passport-ui`. All imports use this package name.
12. **Stryker mutation score ≥80** - Run `npx stryker run` after implementation. Review and fix surviving mutants. This is the FINAL verification step.
13. **Unit tests + build must complete in under 1 minute per package** - allin-ui pipeline policy. If tests are slow, optimize or split the package.

## Common Rationalizations

All of these mean: **STOP. Follow the process.**

- "I'll add the .feature spec after I write the tests" (Spec comes FIRST. Tests derive from spec.)
- "This component is too simple for TDD" (Simple components still need specs and tests.)
- "I'll mock the mapper to make tests faster" (Speed doesn't matter if tests don't catch bugs.)
- "This calculation is just formatting, not business logic" (If the calculation rule could change based on business requirements, it's business logic.)
- "The vi.mock pattern is easier" (MockPassport is the official testing utility. Use it.)
- "I don't need Stryker for this small change" (Mutation testing catches gaps unit tests miss.)
- "I'll install cucumber to validate my .feature files" (.feature files are specs, NOT executable tests.)
- "This business rule needs to be in the frontend for real-time feedback" (Call the backend API. Cache the result. Display instantly on subsequent loads.)

</critical_rules>

<edge_cases>

## .feature Files as New Practice

Zero `.feature` files exist in allin-ui today. When introducing this practice:

1. Create the `spec/` directory in your package
2. Write `.feature` files for ALL scenarios before writing tests
3. During code review, verify that every `it()` block traces to a `.feature` scenario
4. The `.feature` file is the source of truth — if a test exists without a corresponding scenario, either add the scenario or remove the test

**Risk:** Developers may try to install `@cucumber/cucumber` to "execute" the `.feature` files. This is WRONG. The `.feature` files use Gherkin syntax for human readability, not for machine execution. If asked, explain that the derivation from `.feature` → Vitest is a manual, human-driven process.

## GUP Package Name Discrepancy

The epic requirements reference `@uwm/passport-ui` — this name is **incorrect**. The actual package used throughout the allin-ui codebase is `lib-node-user-passport-component`. Always use the correct name in imports:

```tsx
// ✅ Correct
import { usePassport, MockPassport } from 'lib-node-user-passport-component';

// ❌ Wrong — this package name does not exist
import { usePassport } from '@uwm/passport-ui';
```

Platform API auth wrappers come from a separate package:
```tsx
import { useAppShellRoleMatrix, useAppShellRoles, usePolicy } from '@uwm/platform-api';
```

## Stryker Config in Some Packages But Not All

Stryker mutation testing is configured in `configs/platform-api/stryker.config.json` but most UFAs and packages don't have it yet. When implementing a feature:

1. Check if `stryker.config.json` exists in your package
2. If not, add one (see Step 8 for template)
3. Required dev dependencies: `@stryker-mutator/core`, `@stryker-mutator/vitest-runner`, `@stryker-mutator/typescript-checker`
4. Required npm script: `"test:mutation": "npx stryker run"`
5. Thresholds: `high: 90, low: 80, break: 79.999999999`

## Redux in Legacy UFAs

Some existing UFAs use Redux (react-redux, Redux Toolkit):
- `ufas/BrokerDrive` — ReduxProvider in TestProviders
- `ufas/currencyenforcement` — Redux store with slices
- `ufas/exluded-ufas/referralroyalties` — Redux store

**For existing packages with Redux:** Continue using Redux. Don't rewrite the state management mid-feature.

**For new packages:** Use React Query (server state) + Zustand (app-wide state) + Context (feature state) + react-hook-form (form state). Do NOT introduce Redux in new packages.

## Two Test Provider Patterns

The codebase has two competing patterns for auth in tests:

**Pattern A — MockPassport (preferred):**
```tsx
// BrokerDrive, currencyenforcement style
<MockPassport mockUser={mockUser}>{children}</MockPassport>
```

**Pattern B — vi.mock (legacy):**
```tsx
// action-iq, example style
vi.mock('lib-node-user-passport-component', async () => ({
    ...actual,
    usePassport: vi.fn(() => testPassportContext),
}));
```

**Guidance:** Use Pattern A (MockPassport) for all new code. MockPassport is the official testing utility from `lib-node-user-passport-component`. Pattern B is a workaround — only use it when you need to toggle `isLoggedIn` between individual test cases within the same describe block.

## DREAM Version in TestProviders

TestProviders may use either DREAM v2 or v3:
- `lib-node-dream-ui` (v2): `import { theme as dreamTheme } from 'lib-node-dream-ui'` + `ThemeProvider`
- `lib-node-dream-ui-latest` (v3): `import { DreamThemeProvider } from 'lib-node-dream-ui-latest'`

Match the version your package uses. Never mix versions within a package. Check `package.json` to determine which version is in use.

## Form State with react-hook-form

For form-heavy features, use `react-hook-form` with the provider pattern:

```tsx
import { FormProvider, useForm } from 'react-hook-form';

// In parent:
const methods = useForm<FormData>({ defaultValues });
<FormProvider {...methods}><FormContent /></FormProvider>

// In child:
const { watch, setValue, control } = useFormContext<FormData>();
```

In tests, wrap with `FormProvider`:
```tsx
const methods = useForm({ defaultValues: testData });
render(
    <FormProvider {...methods}>
        <FormContent />
    </FormProvider>
);
```

</edge_cases>

<verification_checklist>

Before considering a feature implementation complete:

**Spec Coverage:**
- [ ] `.feature` file exists in `{package}/spec/` for every component/feature
- [ ] Every `it()` block in tests traces back to a `.feature` scenario
- [ ] No "orphan" tests without corresponding `.feature` scenarios

**TDD Cycle:**
- [ ] Tests were written BEFORE implementation (RED phase verified)
- [ ] Tests failed before implementation was written
- [ ] Implementation is minimal — only enough code to pass tests
- [ ] All tests pass (GREEN phase verified)
- [ ] Code was refactored with tests staying green

**Test Quality:**
- [ ] afterEach includes `vi.restoreAllMocks()` + `cleanup()`
- [ ] Explicit vitest imports: `import { describe, it, expect, vi } from 'vitest'`
- [ ] Only infrastructure is mocked (API clients, browser APIs, module federation)
- [ ] No data mappers, transformers, or business logic mocked
- [ ] MockPassport used for auth (not vi.mock except for auth-conditional tests)
- [ ] createUser() factory used for different user configurations

**Business Logic Boundary:**
- [ ] No business calculations in frontend code
- [ ] No business validation rules in frontend code
- [ ] No orchestration logic in frontend code
- [ ] Service functions are pure (no React dependencies)
- [ ] Mappers handle only display formatting (currency, dates, truncation)

**Auth Integration:**
- [ ] Using `lib-node-user-passport-component` (correct package name)
- [ ] NOT adding PassportAuth (already in app-shell)
- [ ] Role checks use `usePassport().user.roles` or `useAppShellRoles()`
- [ ] roleMatrix defined in `RequiredRoles.ts` for UFA

**Coverage:**
- [ ] Unit test coverage ≥80%
- [ ] Stryker mutation score ≥80
- [ ] Unit tests + build complete in under 1 minute

</verification_checklist>

<integration>

**This skill is called by:**
- `develop-frontend` (orchestrator) — Phase 3 in the golden path
- Directly when adding features to an existing allin-ui package

**This skill calls:**
- `design-ui-component` — for DREAM component standards during implementation
- `test-frontend` — for comprehensive test strategy beyond unit tests (Playwright E2E, soak, perf)

**Skill chain for new features:**
```
create-allin-package → design-ui-component → implement-ui-feature → test-frontend
```

**Scope boundary with test-frontend:**
- `implement-ui-feature` covers: TDD cycle with Vitest, running Stryker as verification
- `test-frontend` covers: Stryker config optimization, Playwright E2E/soak/perf tests, coverage reports, pipeline integration, TestKube configuration

**Dependencies:**
- Package must exist (created by `create-allin-package` or already existing)
- Component design decisions made (guided by `design-ui-component`)
- Backend service APIs available (or documented for mocking)

</integration>

<resources>

**Packages:**
- `lib-node-user-passport-component` — GUP auth: PassportAuth, usePassport, MockPassport, RoleMatrix, useRoles
- `@uwm/platform-api` — App-shell integration: createGateway, useAppShellRoles, usePolicy, featureFlag, signalR, observability, Zustand stores
- `lib-node-dream-ui` / `lib-node-dream-ui-latest` — DREAM design system components
- `@tanstack/react-query` — Server state management (useQuery, useMutation)
- `@stryker-mutator/core` + `@stryker-mutator/vitest-runner` — Mutation testing

**Reference implementations in allin-ui:**
- `ufas/BrokerDrive/testUtils/testUtils.tsx` — MockPassport + custom render + multiple user fixtures
- `ufas/action-iq/src/testUtils.ts` — createUser() factory + symulateLogin/symulateLogout
- `ufas/currencyenforcement/src/TestProviders.tsx` — FunctionalProviders + AllProviders + UnauthProviders
- `packages/shared-components/src/testUtils/testUtils.ts` — Clean re-export pattern
- `configs/platform-api/hooks/passportHooks.ts` — useAppShellRoleMatrix, useAppShellRoles, usePolicy
- `configs/platform-api/stryker.config.json` — Reference Stryker configuration

**Confluence:**
- allin-ui Policies and Standards — Testing policy, time limits, coverage thresholds
- GUP UI Onboarding Guide — Auth integration walkthrough
- Component Taxonomy (page 1514786638) — UFA/IAP/SCL definitions

**Bitbucket:**
- `EH/allin-ui` — Monorepo MFE
- `UCP/lib-node-dream-ui` — DREAM component library source + Storybook
- `SOLAR/cell-user-passport` — GUP backend service ecosystem

**Storybook:**
- https://dream.uwm.com — DREAM component documentation and live examples

</resources>
