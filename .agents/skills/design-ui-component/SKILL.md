---
name: design-ui-component
description: Use when designing or implementing UI components in allin-ui — enforces DREAM design system standards, props conventions, TypeScript strictness, theming, and accessibility
---

<skill_overview>
Guides developers through designing and implementing UI components that comply with DREAM design system standards when building in the allin-ui monorepo. This skill ensures components use DREAM components first, follow strict TypeScript and styling conventions, and maintain accessibility standards.

**This skill covers two distinct workflows:**
1. **Primary (80%):** USING DREAM components in your allin-ui package — importing from `lib-node-dream-ui` / `lib-node-dream-ui-latest`, styling with `useDreamTheme()`, following props and TypeScript conventions.
2. **Secondary (20%):** CONTRIBUTING new components TO the DREAM library — the contribute-commit model with Storybook, index.ts barrel exports, and PR checklist.

**Key context:** DREAM is UWM's enterprise UI component library built on React + MUI (Material-UI). It provides themed, accessible components via `lib-node-dream-ui`. In allin-ui, DREAM components coexist with direct MUI imports — MUI is used for capabilities DREAM doesn't provide (Grid, useMediaQuery, CssBaseline, etc.). There are no ESLint rules enforcing DREAM-over-MUI; the standard is cultural and enforced via code review.
</skill_overview>

<rigidity_level>
MEDIUM FREEDOM - Props standards (nullable id, required name for inputs), TypeScript standards (no any), and style standards (theme variables, no shorthand, no magic numbers) are rigid and must be followed exactly. Component structure and DREAM-vs-MUI decisions adapt to what's available in the DREAM library.
</rigidity_level>

<quick_reference>

| Step | Action | Key Rule |
|------|--------|----------|
| **1. Check DREAM** | Search dream.uwm.com Storybook | If DREAM has it → use DREAM. Never duplicate. |
| **2. File Structure** | `Component.tsx` + `Component.test.tsx` | allin-ui uses flat structure. No index.ts per component. |
| **3. Props** | `id?: string \| number`, `name: string` (inputs) | JSDoc all props. No `any`. No prop spreading. |
| **4. TypeScript** | Strict types everywhere | No `any` ever. No `@ts-ignore`. No `console.*`. |
| **5. Styles** | `useDreamTheme()` + `sx` prop | No magic numbers. No shorthand. No inline `style`. |
| **6. DREAM Priority** | DREAM → MUI → custom | MUI OK for: Grid, useMediaQuery, CssBaseline, SxProps, Popover, styled |
| **7. Version** | v2 or v3, never mix | `lib-node-dream-ui` (v2) or `lib-node-dream-ui-latest` (v3) |
| **8. Accessibility** | DREAM inherits MUI a11y | Custom components: add ARIA, keyboard nav, WCAG AA yourself |

**Import Priority Decision:**
```
Does DREAM have this component?
  YES → import from lib-node-dream-ui / lib-node-dream-ui-latest
  NO  → Is this a layout/utility (Grid, useMediaQuery, styled)?
    YES → import from @mui/material (legitimate)
    NO  → Create custom component following DREAM style standards
```

</quick_reference>

<when_to_use>
- Creating a new React component in an allin-ui package (UFA, SCL, or IAP)
- Reviewing or auditing existing components for DREAM compliance
- Deciding whether to use DREAM, MUI, or create a custom component
- Styling components with theme variables and the sx prop
- Contributing a new component to the DREAM library (contribute-commit model)

**Do NOT use for:**
- Creating a new allin-ui package (use `create-allin-package`)
- Writing tests for components (use `test-frontend`)
- Implementing business logic (this belongs in services, NOT frontend)
- Modifying the DREAM library's build system or infrastructure
</when_to_use>

<the_process>

## Step 1: Check DREAM Storybook First

Before creating ANY component, check if DREAM already provides it.

**Search:** https://dream.uwm.com (DREAM Storybook — live component documentation)

| DREAM Has It? | Action |
|---------------|--------|
| **Yes, exact match** | Import from `lib-node-dream-ui` or `lib-node-dream-ui-latest`. DO NOT create a custom version. |
| **Yes, but missing variant** | Use the DREAM component with `sx` prop + `useDreamTheme()` to customize. Do NOT create a custom wrapper. If the variant is genuinely reusable, consider contributing it to DREAM. |
| **No, but MUI has it** | Check if the MUI component is a layout/utility (Grid, useMediaQuery, Popover, etc.). If yes, import from `@mui/material` directly — this is legitimate. If it's a UI component (Button, TextField, etc.), extend MUI with DREAM theming. |
| **Neither has it** | Create a custom component following ALL DREAM style standards below. |

**Common DREAM components** (check Storybook for full list):
- Layout: `Box`, `Stack`, `Card`, `CardText`
- Typography: `Typography`, `Link`
- Navigation: `Breadcrumb`, `Tabs`
- Input: `Button`, `TextField`, `Select`, `Checkbox`
- Feedback: `SectionMessage`, `Icon`
- Data: `Stepper`, `Badge`
- Theme: `DreamThemeProvider`, `useDreamTheme`

**Legitimate MUI-only imports** (DREAM doesn't provide these):

| MUI Import | Purpose | Why Not DREAM |
|------------|---------|---------------|
| `Grid` | Responsive layout grid system | DREAM uses Box/Stack, not Grid |
| `useMediaQuery` | Responsive breakpoint hook | Utility, not a component |
| `CssBaseline` | CSS reset / normalization | App-level concern |
| `SxProps` | TypeScript type for sx prop | Type only, not a component |
| `Popover` | Overlay positioning | DREAM may not have equivalent |
| `styled` | CSS-in-JS for complex dynamic styles | Utility, not a component |
| `useTheme` | MUI theme hook (fallback) | Use `useDreamTheme()` when possible |

---

## Step 2: Component File Structure

### allin-ui Pattern (Primary — for your package components)

allin-ui uses a **flat** component structure. This is different from the DREAM library's internal structure.

```
src/components/<ComponentName>/
├── <ComponentName>.tsx         # Component source, props interface, implementation
├── <ComponentName>.test.tsx    # Vitest unit tests
└── (optional) <Related>.tsx    # Related sub-components if needed
```

For complex components with multiple tests or sub-components:
```
src/components/<ComponentName>/
├── <ComponentName>.tsx         # Main component
├── <ComponentName>.test.tsx    # Primary test file
├── __tests__/                  # Additional test files
│   ├── edge-cases.test.tsx
│   └── accessibility.test.tsx
├── components/                 # Internal sub-components (not exported)
│   └── SubPart.tsx
└── common/                     # Shared utilities for this component
    └── helpers.ts
```

**Key differences from dream-buddy.md's structure:**
- **No `index.ts` per component** — allin-ui does not use per-component barrel exports
- **No `.stories.tsx`** — allin-ui packages do not use Storybook (Storybook is only in the DREAM library)
- **Barrel exports** for SCL packages go in `src/index.ts` at the package root:
  ```typescript
  // packages/{scl-name}/src/index.ts
  export { LoanSummaryCard } from './components/LoanSummaryCard/LoanSummaryCard';
  export type { LoanSummaryCardProps } from './components/LoanSummaryCard/LoanSummaryCard';
  ```

### DREAM Library Pattern (Secondary — only for contributions to lib-node-dream-ui)

When contributing a component TO the DREAM library (not to allin-ui), use this structure:
```
src/components/<ComponentName>/
├── index.ts                        # Export component and types
├── <ComponentName>.tsx             # Component source and props
├── <ComponentName>.stories.tsx     # Storybook stories (required)
└── <ComponentName>.test.tsx        # Tests
```

See Step 10 for the full contribute-commit workflow.

---

## Step 3: Props Standards

These standards apply to ALL components — whether using DREAM, extending MUI, or creating custom.

### Required Props

**Every component MUST have a nullable `id` prop:**
```typescript
export interface MyComponentProps {
  /** Unique identifier for testing and accessibility. */
  id?: string | number;
  // ... other props
}
```

**Input components MUST have a required `name` prop:**
```typescript
export interface InputFieldProps {
  /** Unique identifier for the input field. */
  id?: string | number;
  /** Name attribute for form submission. Required for all inputs. */
  name: string;
  // ... other props
}
```

### Props Documentation

All props MUST have JSDoc comments:
```typescript
export interface StatusBadgeProps {
  /** Unique identifier for testing and accessibility. */
  id?: string | number;
  /** The current status to display. */
  status: 'pending' | 'approved' | 'rejected';
  /** Optional label override. Defaults to status name. */
  label?: string;
  /** Controls the visual size of the badge. */
  size?: 'small' | 'medium' | 'large';
  /** Callback fired when the badge is clicked. */
  onClick?: (status: string) => void;
}
```

### Props Rules

| Rule | Correct | Wrong |
|------|---------|-------|
| No implicit prop spreading | `<Button label={label} size={size} />` | `<Button {...props} />` without type definition |
| Discriminated unions for variants | `type: 'primary' \| 'secondary'` with different prop shapes | Boolean flags: `isPrimary`, `isSecondary` |
| No `any` in props | `onClick?: (event: React.MouseEvent<HTMLButtonElement>) => void` | `onClick?: (event: any) => void` |
| Default values in destructuring | `({ size = 'medium' }: Props)` | `props.size \|\| 'medium'` |

---

## Step 4: TypeScript Standards

### Strict Requirements (No Exceptions)

**1. NO `any` types — ever:**
```typescript
// WRONG
const handleClick = (event: any) => { ... }
const data: any = fetchData();

// CORRECT
const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => { ... }
const data: LoanData = fetchData();
```

**2. Proper event handler types:**

| Event | Type |
|-------|------|
| Click (button) | `React.MouseEvent<HTMLButtonElement>` |
| Click (div) | `React.MouseEvent<HTMLDivElement>` |
| Change (input) | `React.ChangeEvent<HTMLInputElement>` |
| Change (select) | `React.ChangeEvent<HTMLSelectElement>` |
| Submit (form) | `React.FormEvent<HTMLFormElement>` |
| Key press | `React.KeyboardEvent<HTMLElement>` |
| Focus | `React.FocusEvent<HTMLElement>` |

**3. No `@ts-ignore` without justification:**
```typescript
// WRONG
// @ts-ignore
const result = someUntypedThing();

// ACCEPTABLE (only with explanation)
// @ts-ignore - MUI internal API, typed in our declaration file at types/mui-overrides.d.ts
const internalProp = theme.__internal;
```

**4. No linting errors or warnings** — fix all ESLint and TypeScript compiler warnings before committing.

**5. No console statements in committed code:**
```typescript
// WRONG
console.log('debug:', data);
console.warn('deprecated usage');
console.error('something failed');

// CORRECT — remove before committing, or use proper error boundaries
```

---

## Step 5: Style Standards

### Theme Variables — Always

Access the theme via `useDreamTheme()` hook:

```typescript
import { useDreamTheme } from 'lib-node-dream-ui-latest';

export const MyComponent = ({ id }: MyComponentProps) => {
  const theme = useDreamTheme();

  return (
    <Box
      id={id?.toString()}
      sx={{
        color: theme.palette.text.primary,
        backgroundColor: theme.palette.background.paper,
        padding: theme.spacing(2),
        fontSize: theme.typography.body1.fontSize,
        borderRadius: theme.shape.borderRadius,
      }}
    >
      {/* content */}
    </Box>
  );
};
```

### No Magic Numbers

```typescript
// WRONG — hardcoded values
sx={{
  color: '#1976d2',
  padding: '16px',
  fontSize: '14px',
  borderRadius: '4px',
}}

// CORRECT — theme variables
sx={{
  color: theme.palette.primary.main,
  padding: theme.spacing(2),        // 16px via theme
  fontSize: theme.typography.body2.fontSize,
  borderRadius: theme.shape.borderRadius,
}}
```

### No CSS Shorthand

Use full property names for searchability and clarity:

```typescript
// WRONG — shorthand
sx={{
  px: 2,
  py: 1,
  m: 1,
  bg: 'primary',
  mt: 2,
}}

// CORRECT — full names
sx={{
  paddingX: 2,
  paddingY: 1,
  margin: 1,
  backgroundColor: 'primary',
  marginTop: 2,
}}
```

### CSS Unit Guidelines

| CSS Unit | When to Use | Example |
|----------|-------------|---------|
| Unitless number | `lineHeight` only | `lineHeight: 1.5` |
| `rem` | `fontSize`, vertical margins for text | `fontSize: '1rem'` |
| `px` | `margin`, `padding`, `minWidth`, `maxWidth` | `padding: '16px'` |
| Theme spacing | padding, margin via theme | `padding: theme.spacing(2)` |

```typescript
sx={{
  fontSize: '1rem',              // rem for font-size
  lineHeight: 1.5,               // unitless for line-height
  padding: theme.spacing(2),     // theme spacing for padding
  marginTop: '1rem',             // rem for text spacing
  minWidth: '200px',             // px for size constraints
}}
```

### Styling Rules

| Rule | Correct | Wrong |
|------|---------|-------|
| Use `sx` prop | `<Box sx={{ padding: 2 }}>` | `<Box style={{ padding: 16 }}>` |
| Theme variables | `color: theme.palette.error.main` | `color: '#f44336'` |
| Responsive | Container queries (MUI pattern) | Media queries for component-level |
| No inline `style` | `sx={{ ... }}` | `style={{ ... }}` |

**Container Queries** — for responsive components, use MUI's container query pattern:
- Reference: https://mui.com/material-ui/customization/container-queries/
- Prefer container queries over media queries for component-level responsiveness

---

## Step 6: DREAM Component Priority Rule

When writing a component, follow this import priority:

### Priority 1: DREAM Components
```typescript
// CORRECT — DREAM has Button, Typography, Box, Stack, etc.
import { Button, Typography, Box, Stack, useDreamTheme } from 'lib-node-dream-ui-latest';
```

### Priority 2: MUI for Components DREAM Doesn't Provide
```typescript
// CORRECT — Grid and useMediaQuery are not in DREAM
import { Grid, useMediaQuery } from '@mui/material';
import { Button, Box, useDreamTheme } from 'lib-node-dream-ui-latest';
```

### Priority 3: Custom Components Following DREAM Standards
```typescript
// CORRECT — when neither DREAM nor MUI has what you need
// Follow ALL standards: id prop, JSDoc, theme variables, no any, no shorthand
import { useDreamTheme } from 'lib-node-dream-ui-latest';

export interface LoanProgressProps {
  /** Unique identifier for testing and accessibility. */
  id?: string | number;
  /** Current progress percentage (0-100). */
  progress: number;
  /** Label to display below the progress indicator. */
  label: string;
}

export const LoanProgress = ({ id, progress, label }: LoanProgressProps) => {
  const theme = useDreamTheme();
  // ... implementation using theme variables
};
```

### What NOT to Do
```typescript
// WRONG — MUI Button when DREAM Button exists
import { Button } from '@mui/material';

// WRONG — custom Button when DREAM Button exists
const CustomButton = styled('button')({ ... });

// WRONG — importing from DREAM internals
import { Button } from 'lib-node-dream-ui/dist/components/Button';
```

---

## Step 7: DREAM Version Selection

Two DREAM versions are in active use in allin-ui:

| Package | Version | Catalog Entry | Status |
|---------|---------|---------------|--------|
| `lib-node-dream-ui` | v2 | `^2.9.1` | Stable, used by older UFAs |
| `lib-node-dream-ui-latest` | v3 | `npm:lib-node-dream-ui@^3.1.2` | Newer, used by recent UFAs |

### Selection Rules

1. **Existing package:** Use whichever version the package already imports. Check existing import statements.
2. **New package:** Prefer `lib-node-dream-ui-latest` (v3) unless your team has a specific reason for v2.
3. **NEVER mix versions in the same package** — causes duplicate DREAM instances and theme conflicts.

### How to Check

```bash
# Check which version a package uses
grep -r "lib-node-dream-ui" ufas/{your-ufa}/src/ | head -5
```

**Examples of v2 vs v3 imports:**
```typescript
// v2 (lib-node-dream-ui)
import { Button, useDreamTheme } from 'lib-node-dream-ui';
import { DreamThemeProvider } from 'lib-node-dream-ui/DreamThemeProvider';

// v3 (lib-node-dream-ui-latest)
import { Button, useDreamTheme } from 'lib-node-dream-ui-latest';
import { DreamThemeProvider } from 'lib-node-dream-ui-latest';
```

**Component APIs may differ between versions.** Always check the Storybook at dream.uwm.com for the correct API for your version.

---

## Step 8: Accessibility Requirements

### DREAM/MUI Components — Accessibility Inherited

When using DREAM or MUI components, you inherit extensive accessibility from MUI's built-in support:
- ARIA attributes on interactive elements
- Keyboard navigation (Tab, Enter, Space, Escape)
- Focus management and visible focus indicators
- Screen reader compatibility
- Role attributes

**You still must:**
- Provide meaningful labels: `<Button aria-label="Submit loan application">Submit</Button>`
- Ensure custom content inside DREAM components is accessible
- Test keyboard navigation in your composed views

### Custom Components — Full Accessibility Required

When creating components that do NOT extend DREAM or MUI, YOU must implement:

| Requirement | Implementation |
|-------------|---------------|
| ARIA roles | `role="button"`, `role="dialog"`, etc. |
| ARIA labels | `aria-label`, `aria-labelledby`, `aria-describedby` |
| Keyboard navigation | `onKeyDown` handlers for Enter, Space, Escape, Arrow keys |
| Focus management | `tabIndex`, `autoFocus`, focus trapping for modals |
| Focus indicators | Visible outline on `:focus-visible` via theme |
| Color contrast | WCAG AA minimum (4.5:1 for text, 3:1 for large text) |
| Screen reader | Meaningful text content, `aria-live` for dynamic updates |

```typescript
// Custom accessible component example
export const CustomToggle = ({ id, label, checked, onChange }: ToggleProps) => {
  const theme = useDreamTheme();

  return (
    <div
      id={id?.toString()}
      role="switch"
      aria-checked={checked}
      aria-label={label}
      tabIndex={0}
      onClick={() => onChange(!checked)}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          onChange(!checked);
        }
      }}
      sx={{
        cursor: 'pointer',
        outline: 'none',
        '&:focus-visible': {
          boxShadow: `0 0 0 2px ${theme.palette.primary.main}`,
        },
      }}
    >
      {/* toggle visual */}
    </div>
  );
};
```

---

## Step 9: Audit Mode — Evaluating Existing UI

Use this checklist to audit existing allin-ui components for DREAM compliance.

### Audit Checklist

**1. Component Selection**
- [ ] Uses DREAM components from `lib-node-dream-ui` / `lib-node-dream-ui-latest`
- [ ] Direct MUI imports only for components DREAM doesn't provide (Grid, useMediaQuery, etc.)
- [ ] No custom components that duplicate DREAM functionality

**2. Import Patterns**
```typescript
// CORRECT
import { Button, TextField, useDreamTheme } from 'lib-node-dream-ui-latest';

// ACCEPTABLE — MUI for what DREAM doesn't have
import { Grid, useMediaQuery } from '@mui/material';

// REVIEW — should these be DREAM components?
import { Button } from '@mui/material';

// WRONG — importing from DREAM internals
import { Button } from 'lib-node-dream-ui/dist/components/Button';
```

**3. Props Compliance**
- [ ] `id` prop available (nullable) on all components
- [ ] `name` prop required on all form inputs
- [ ] All props have JSDoc comments
- [ ] No `any` types in props
- [ ] No implicit prop spreading without type definition

**4. Style Patterns**
```typescript
// CORRECT — theme variables via useDreamTheme()
const theme = useDreamTheme();
<Box sx={{ color: theme.palette.text.primary, padding: theme.spacing(2) }}>

// REVIEW — style override on DREAM component (is there a variant?)
<Button sx={{ color: 'red' }}>

// WRONG — inline styles bypass theme
<Button style={{ color: 'red' }}>

// WRONG — magic numbers
<Box sx={{ color: '#1976d2', padding: '16px' }}>

// WRONG — CSS shorthand
<Box sx={{ px: 2, mt: 1, bg: 'primary' }}>
```

**5. Accessibility**
- [ ] Interactive elements have ARIA labels
- [ ] Keyboard navigation works (Tab, Enter, Space, Escape)
- [ ] Focus indicators visible
- [ ] Color contrast meets WCAG AA (4.5:1 text, 3:1 large text)
- [ ] Images have alt text
- [ ] Buttons have accessible names

**6. TypeScript Usage**
- [ ] No `any` types anywhere
- [ ] Event handlers properly typed
- [ ] No `@ts-ignore` without justification
- [ ] No console.log/warn/error in committed code

### Audit Report Template

```markdown
## DREAM Compliance Audit: [Component/File Name]

**File**: path/to/file.tsx
**Lines**: XX-YY
**DREAM Version**: lib-node-dream-ui / lib-node-dream-ui-latest

### Compliance Score: X/10

### Compliant
- [What's done correctly]

### Needs Review
- Line XX: Direct MUI import — should this be a DREAM component?
- Line YY: Style override — is there a DREAM variant?

### Non-Compliant
- Line XX: Missing id prop (required on all components)
- Line YY: Using `any` type for event handler
- Line ZZ: Inline `style` prop — use `sx` with theme variables
- Line AA: Magic number `#1976d2` — use `theme.palette.primary.main`
- Line BB: CSS shorthand `px` — use `paddingX`

### Recommendations

1. **High Priority**
   - Replace inline styles with sx + theme variables
   - Add proper TypeScript types (remove `any`)

2. **Medium Priority**
   - Replace MUI Button with DREAM Button (exists in Storybook)
   - Add id prop for testing and accessibility

3. **Low Priority**
   - Add JSDoc comments to props interface
   - Consider contributing style variant to DREAM
```

---

## Step 10: DREAM Library Contribution (Secondary Workflow)

This section applies ONLY when contributing a new component TO the DREAM library itself (UCP/lib-node-dream-ui). This is NOT the typical allin-ui development workflow.

### Pre-Development Checklist

1. **Verify Figma design exists** — component must be designed and approved in Figma before development
   - Figma: https://www.figma.com/design/zRsKww4xBqzzRVbTM7wAye/Dream-Component-Guidelines
2. **Check for duplicate work** — search DREAM Storybook (dream.uwm.com) and Jira board
   - Jira: https://work.uwm.com/secure/RapidBoard.jspa?rapidView=1361
3. **Create Jira story** — format: "DREAM-### [Component Name] - Implement"
4. **Contact DREAM team** (if first contribution) — dreamdesignsystem@uwm.com

### DREAM Library File Structure

```
src/components/<ComponentName>/
├── index.ts                        # Export component and types
├── <ComponentName>.tsx             # Component source and props
├── <ComponentName>.stories.tsx     # Storybook stories (REQUIRED)
└── <ComponentName>.test.tsx        # Vitest tests
```

**index.ts:**
```typescript
export { MyComponent, type MyComponentProps } from './MyComponent';
```

### Storybook Requirements

```typescript
import type { Meta, StoryObj } from '@storybook/react';
import { MyComponent } from './MyComponent';

const meta: Meta<typeof MyComponent> = {
  title: 'Components/MyComponent',
  component: MyComponent,
  tags: ['autodocs'],          // REQUIRED — generates documentation
  argTypes: {
    size: {
      control: 'select',
      options: ['small', 'medium', 'large'],
      description: 'Controls the size of the component',
    },
    variant: {
      control: 'select',
      options: ['primary', 'secondary'],
      description: 'Visual style variant',
    },
  },
};

export default meta;
type Story = StoryObj<typeof MyComponent>;

// REQUIRED: Story for each meaningful prop variation
export const Default: Story = {
  args: { label: 'Default', size: 'medium' },
};

export const Small: Story = {
  args: { label: 'Small', size: 'small' },
};

export const Large: Story = {
  args: { label: 'Large', size: 'large' },
};
```

**Storybook rules:**
- `tags: ['autodocs']` is required — generates props table from JSDoc
- Create a story for each meaningful prop variation
- No stories needed for common props (id, name)
- Control table must have correct names, required props marked with `*`, descriptions
- Use `argTypes` for select controls on enum/union props

### DREAM PR Checklist (14 Items)

Before raising a PR to the DREAM library:

1. Branch runs locally without errors
2. No errors in terminal or browser console when Storybook runs
3. Component exported in `~/src/index.ts`
4. Design matches Figma exactly
5. All states implemented (default, hover, focus, active, disabled, loading, success, error, empty)
6. All variants implemented (sizes, primary/secondary/tertiary, filled/outlined/text)
7. Props follow standards (`id` nullable, `name` required for inputs)
8. No TypeScript `any` types
9. No linting errors
10. Theme variables used (no magic numbers)
11. No CSS shorthand (paddingX not px, backgroundColor not bg)
12. Proper CSS units (rem for font-size, unitless for line-height, px for spacing)
13. Storybook documentation complete (autodocs, stories, controls)
14. Tests written and passing

**PR title format:** `feature/DREAM-XXX: [Component Name] implementation`

### Repository Setup

```bash
git clone https://code.uwm.com/scm/ucp/lib-node-dream-ui.git
cd lib-node-dream-ui
git checkout develop
git pull
git checkout -b feature/DREAM-XXX-component-name
npm install
npm run storybook    # Primary development environment
npm run test         # Run tests
npm run test:mutate  # Run mutation tests (Stryker)
```

</the_process>

<examples>

<example>
<scenario>Creating a component in allin-ui using DREAM with proper standards</scenario>

<code>
// ufas/loan-center/src/components/LoanStatusCard/LoanStatusCard.tsx

import { Box, Typography, Icon, Stack, useDreamTheme } from 'lib-node-dream-ui-latest';

export interface LoanStatusCardProps {
  /** Unique identifier for testing and accessibility. */
  id?: string | number;
  /** The loan number to display. */
  loanNumber: string;
  /** Current status of the loan. */
  status: 'pending' | 'approved' | 'rejected' | 'in-review';
  /** Borrower's full name. */
  borrowerName: string;
  /** Callback fired when the card is clicked. */
  onClick?: (loanNumber: string) => void;
}

const STATUS_ICONS: Record<LoanStatusCardProps['status'], string> = {
  pending: 'clock',
  approved: 'check-circle',
  rejected: 'x-circle',
  'in-review': 'eye',
};

export const LoanStatusCard = ({
  id,
  loanNumber,
  status,
  borrowerName,
  onClick,
}: LoanStatusCardProps) => {
  const theme = useDreamTheme();

  const statusColor = {
    pending: theme.palette.warning.main,
    approved: theme.palette.success.main,
    rejected: theme.palette.error.main,
    'in-review': theme.palette.info.main,
  }[status];

  return (
    <Box
      id={id?.toString()}
      role="button"
      tabIndex={0}
      aria-label={`Loan ${loanNumber} for ${borrowerName}, status: ${status}`}
      onClick={() => onClick?.(loanNumber)}
      onKeyDown={(e: React.KeyboardEvent<HTMLDivElement>) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          onClick?.(loanNumber);
        }
      }}
      sx={{
        padding: theme.spacing(2),
        borderRadius: theme.shape.borderRadius,
        backgroundColor: theme.palette.background.paper,
        border: `1px solid ${theme.palette.divider}`,
        cursor: onClick ? 'pointer' : 'default',
        '&:hover': onClick ? {
          backgroundColor: theme.palette.action.hover,
        } : undefined,
        '&:focus-visible': {
          boxShadow: `0 0 0 2px ${theme.palette.primary.main}`,
          outline: 'none',
        },
      }}
    >
      <Stack direction="row" spacing={theme.spacing(1)} alignItems="center">
        <Icon name={STATUS_ICONS[status]} sx={{ color: statusColor }} />
        <Stack>
          <Typography variant="subtitle1">{loanNumber}</Typography>
          <Typography variant="body2" sx={{ color: theme.palette.text.secondary }}>
            {borrowerName}
          </Typography>
        </Stack>
      </Stack>
    </Box>
  );
};
</code>

<why_it_works>
- Uses DREAM components (Box, Typography, Icon, Stack) not MUI
- useDreamTheme() for all style values — zero magic numbers
- Nullable id prop present
- All props have JSDoc comments
- Proper TypeScript types (React.KeyboardEvent, no any)
- Full property names (paddingX not px, backgroundColor not bg)
- sx prop for styling, no inline style
- Accessibility: role="button", tabIndex, aria-label, keyboard handler, focus-visible
- Status mapped to theme palette colors, not hardcoded hex
</why_it_works>
</example>

<example>
<scenario>Legitimate MUI import alongside DREAM components</scenario>

<code>
// ufas/loan-center/src/components/LoanGrid/LoanGrid.tsx

// CORRECT: Grid and useMediaQuery are legitimate MUI imports
import { Grid, useMediaQuery } from '@mui/material';
import { Box, Typography, useDreamTheme } from 'lib-node-dream-ui-latest';

export interface LoanGridProps {
  /** Unique identifier for the grid container. */
  id?: string | number;
  /** Array of loan data to display in the grid. */
  loans: LoanSummary[];
}

export const LoanGrid = ({ id, loans }: LoanGridProps) => {
  const theme = useDreamTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

  return (
    <Box id={id?.toString()} sx={{ padding: theme.spacing(2) }}>
      <Grid container spacing={isMobile ? 1 : 2}>
        {loans.map((loan) => (
          <Grid item xs={12} sm={6} md={4} key={loan.id}>
            <LoanStatusCard
              loanNumber={loan.number}
              status={loan.status}
              borrowerName={loan.borrowerName}
            />
          </Grid>
        ))}
      </Grid>
    </Box>
  );
};
</code>

<why_it_works>
- Grid imported from @mui/material — DREAM doesn't provide a grid system
- useMediaQuery imported from @mui/material — DREAM doesn't provide this utility
- DREAM components (Box, Typography) used for everything else
- useDreamTheme() for spacing and breakpoints
- Both DREAM and MUI coexist correctly
</why_it_works>
</example>

<example>
<scenario>Developer imports MUI Button when DREAM Button exists</scenario>

<code>
// WRONG
import { Button } from '@mui/material';
import { Box } from 'lib-node-dream-ui-latest';

export const SubmitSection = () => {
  return (
    <Box>
      <Button variant="contained" color="primary">
        Submit
      </Button>
    </Box>
  );
};
</code>

<why_it_fails>
- DREAM has a Button component — check dream.uwm.com
- Importing MUI Button bypasses DREAM theming and styling
- The DREAM Button may have UWM-specific variants, accessibility, and styling
- This will look inconsistent with other components using DREAM Button
</why_it_fails>

<correction>
import { Button, Box } from 'lib-node-dream-ui-latest';

export const SubmitSection = () => {
  return (
    <Box>
      <Button variant="contained" color="primary">
        Submit
      </Button>
    </Box>
  );
};
</correction>
</example>

<example>
<scenario>Developer uses magic numbers, CSS shorthand, any types, and inline styles</scenario>

<code>
// WRONG — multiple violations
import { Box } from 'lib-node-dream-ui-latest';

export const StatusBar = (props: any) => {
  return (
    <Box
      style={{ backgroundColor: '#1976d2', padding: '16px' }}
      sx={{ px: 2, mt: 1 }}
    >
      <span style={{ color: '#fff', fontSize: '14px' }}>
        {props.message}
      </span>
    </Box>
  );
};
</code>

<why_it_fails>
- `any` type for props — NO any ever
- `style` prop — NEVER use inline style, use sx
- Magic numbers: '#1976d2', '16px', '#fff', '14px'
- CSS shorthand: px, mt
- No id prop, no JSDoc, no proper TypeScript interface
- Missing accessibility (no semantic HTML or ARIA)
</why_it_fails>

<correction>
import { Box, Typography, useDreamTheme } from 'lib-node-dream-ui-latest';

export interface StatusBarProps {
  /** Unique identifier for testing. */
  id?: string | number;
  /** The status message to display. */
  message: string;
}

export const StatusBar = ({ id, message }: StatusBarProps) => {
  const theme = useDreamTheme();

  return (
    <Box
      id={id?.toString()}
      role="status"
      aria-live="polite"
      sx={{
        backgroundColor: theme.palette.primary.main,
        padding: theme.spacing(2),
        marginTop: theme.spacing(1),
      }}
    >
      <Typography
        variant="body2"
        sx={{
          color: theme.palette.primary.contrastText,
        }}
      >
        {message}
      </Typography>
    </Box>
  );
};
</correction>
</example>

<example>
<scenario>Developer mixes DREAM v2 and v3 in the same package</scenario>

<code>
// WRONG — mixing versions
// File: ufas/my-ufa/src/components/Header/Header.tsx
import { Button } from 'lib-node-dream-ui';           // v2

// File: ufas/my-ufa/src/components/Footer/Footer.tsx
import { Typography } from 'lib-node-dream-ui-latest'; // v3
</code>

<why_it_fails>
- Two DREAM instances loaded at runtime — theme conflicts
- Component APIs may differ between v2 and v3
- Duplicate bundle size
- Theme provider may apply to one version but not the other
- Will cause unpredictable visual and behavioral inconsistencies
</why_it_fails>

<correction>
// Pick ONE version for the entire package
// For new packages, prefer v3 (lib-node-dream-ui-latest)

// File: ufas/my-ufa/src/components/Header/Header.tsx
import { Button } from 'lib-node-dream-ui-latest';

// File: ufas/my-ufa/src/components/Footer/Footer.tsx
import { Typography } from 'lib-node-dream-ui-latest';
</correction>
</example>

<example>
<scenario>Audit of a non-compliant component</scenario>

<code>
// File: ufas/example-ufa/src/components/UserCard/UserCard.tsx
import { Card } from '@mui/material';

const UserCard = (props: any) => {
  return (
    <Card style={{ padding: 16, margin: 8, backgroundColor: '#f5f5f5' }}>
      <h3 style={{ color: '#333', fontSize: 18 }}>{props.name}</h3>
      <p>{props.email}</p>
      <button onClick={props.onClick}>View Profile</button>
    </Card>
  );
};

export default UserCard;
</code>

<audit_result>
## DREAM Compliance Audit: UserCard

**File**: ufas/example-ufa/src/components/UserCard/UserCard.tsx
**DREAM Version**: None detected

### Compliance Score: 1/10

### Non-Compliant

1. **Line 2:** `import { Card } from '@mui/material'` — DREAM has Card component. Use `import { Card } from 'lib-node-dream-ui-latest'`.
2. **Line 4:** `props: any` — NO any types ever. Create `UserCardProps` interface with JSDoc.
3. **Line 4:** Missing `id` prop — every component must have `id?: string | number`.
4. **Line 6:** `style={{ padding: 16 }}` — NEVER use inline `style`. Use `sx` with theme variables.
5. **Line 6:** Magic numbers `16`, `8`, `'#f5f5f5'` — use `theme.spacing(2)`, `theme.spacing(1)`, `theme.palette.background.default`.
6. **Line 7:** Raw `<h3>` — use DREAM `Typography` component with `variant="h6"`.
7. **Line 7:** Magic color `'#333'` — use `theme.palette.text.primary`.
8. **Line 7:** Magic size `18` — use `theme.typography.h6.fontSize`.
9. **Line 8:** Raw `<p>` — use DREAM `Typography` with `variant="body2"`.
10. **Line 9:** Raw `<button>` — use DREAM `Button` component.
11. **Line 9:** Missing keyboard accessibility on custom button.
12. **Line 12:** `export default` — prefer named export with type.

### Recommendations

1. **High Priority**: Replace all inline styles with sx + useDreamTheme(). Remove `any` type.
2. **Medium Priority**: Replace raw HTML (h3, p, button) with DREAM components (Typography, Button).
3. **Low Priority**: Add JSDoc to props, add id prop.
</audit_result>
</example>

</examples>

<critical_rules>

## Rules That Have No Exceptions

1. **NO `any` types — ever.** Use proper TypeScript types for all props, event handlers, state, and function parameters. There are no exceptions. If you can't figure out the type, ask — don't use `any`.

2. **DREAM components first.** Before importing from `@mui/material`, check dream.uwm.com Storybook. If DREAM has the component, use it. The only acceptable MUI imports are for capabilities DREAM doesn't provide (Grid, useMediaQuery, CssBaseline, SxProps, Popover, styled).

3. **Theme variables always.** Never use hardcoded colors, pixel values, or font sizes. Access the theme via `useDreamTheme()` and use `theme.palette.*`, `theme.spacing()`, `theme.typography.*`, `theme.shape.*`.

4. **No CSS shorthand.** Use `paddingX` not `px`, `backgroundColor` not `bg`, `marginTop` not `mt`. Full property names are searchable and explicit.

5. **No inline `style` prop.** Use `sx` prop with theme variables. The `style` prop bypasses the theme system and is not responsive.

6. **No magic numbers.** `'#1976d2'` is not a color — `theme.palette.primary.main` is. `'16px'` is not a spacing — `theme.spacing(2)` is. `'14px'` is not a font size — `theme.typography.body2.fontSize` is.

7. **Every component has `id?: string | number`.** No exceptions. This enables testing and accessibility.

8. **Input components have required `name: string`.** All form inputs (TextField, Select, Checkbox, etc.) must have a required `name` prop for form submission.

9. **Never mix DREAM versions.** A package uses EITHER `lib-node-dream-ui` (v2) OR `lib-node-dream-ui-latest` (v3). Never both.

10. **Custom components must implement accessibility.** DREAM/MUI components inherit accessibility. Custom components do NOT — you must add ARIA roles, keyboard navigation, focus management, and WCAG AA contrast yourself.

## Common Mistakes

- "I'll just use MUI directly for speed" → Check DREAM first. It takes 10 seconds to search dream.uwm.com.
- "This color is close enough" → Use the theme variable. Hardcoded colors break in different themes (internal vs external).
- "The shorthand is more readable" → It's less searchable. A grep for `paddingX` finds styling; a grep for `px` finds everything.
- "I'll add types later" → No. TypeScript strictness prevents bugs. Type it correctly now.
- "Storybook isn't needed in allin-ui" → Correct! Storybook is only for the DREAM library. Don't create .stories.tsx files in allin-ui packages.
- "I need to create an index.ts for each component" → Not in allin-ui. Barrel exports go in `src/index.ts` at the package root for SCLs.

</critical_rules>

<edge_cases>

### DREAM Component Missing a Variant

When DREAM has a Button but not the specific variant you need:

**DO:** Extend with `sx` prop and `useDreamTheme()`:
```typescript
import { Button, useDreamTheme } from 'lib-node-dream-ui-latest';

const DestructiveAction = () => {
  const theme = useDreamTheme();
  return (
    <Button sx={{ color: theme.palette.error.main, borderColor: theme.palette.error.main }}>
      Delete
    </Button>
  );
};
```

**DON'T:** Create a custom DestructiveButton component.

If the variant is genuinely reusable across multiple teams, consider contributing it to DREAM via the contribute-commit model (Step 10).

### Product Theming (Internal vs External)

DREAM supports different theme families set via `themeFamily` in `uwm-manifest.json`:
- `"external"` — broker-facing apps (lighter theme)
- `"internal"` — internal tools (darker/corporate theme)

**Impact:** Components using `theme.palette.primary.main` will get different colors depending on the theme family. This is correct behavior — it means your component works across both themes.

**Risk:** Hardcoding `color: '#1976d2'` will look correct in external theme but wrong in internal theme. Always use theme variables.

### MUI Components That Look Like They Should Be DREAM

Some MUI components exist in DREAM under different names or APIs. Always check Storybook before assuming DREAM doesn't have it:
- MUI `Alert` → DREAM may have `SectionMessage`
- MUI `Snackbar` → Check DREAM for notification components
- MUI `Stepper` → DREAM has `Stepper` with potentially different API

### Accessibility for Composed Views

When composing multiple DREAM components into a view (e.g., a form with multiple fields):
- DREAM handles individual component accessibility
- YOU handle the composition-level accessibility:
  - Form-level aria attributes: `aria-labelledby`, `aria-describedby`
  - Error message association: `aria-errormessage` linking to error display
  - Required field indicators: `aria-required="true"`
  - Focus order: Ensure Tab order is logical
  - Live regions: `aria-live="polite"` for dynamic status updates

### Components with External Data

When a component fetches or receives business data:
- The component should NOT fetch data directly (that's business logic — belongs in a hook or service)
- The component receives data via props (props-driven, stateless)
- Loading states should use DREAM components (Skeleton, CircularProgress if available)
- Error states should use DREAM SectionMessage or similar
- This follows the 3-layer decomposition pattern from create-allin-package

### No Automated DREAM Enforcement

There are NO ESLint rules in allin-ui that enforce DREAM-over-MUI imports. The standard is:
- Cultural — enforced by team conventions and code review
- Documented in this skill — developers must self-enforce
- Consider recommending custom ESLint rules for teams that want automation:
  ```javascript
  // Example custom rule concept (not implemented in allin-ui)
  'no-restricted-imports': ['error', {
    patterns: [{
      group: ['@mui/material/Button', '@mui/material/TextField'],
      message: 'Use DREAM component from lib-node-dream-ui-latest instead.',
    }],
  }]
  ```

</edge_cases>

<verification_checklist>

Before moving to the next phase (implement-ui-feature), verify ALL of the following:

### Component Structure
- [ ] Component files follow allin-ui flat pattern: `Component.tsx` + `Component.test.tsx`
- [ ] No `index.ts` per component directory (barrel exports at package root for SCLs)
- [ ] No `.stories.tsx` files (Storybook is DREAM library only)

### Props
- [ ] Every component has `id?: string | number` prop
- [ ] All form input components have `name: string` (required) prop
- [ ] All props have JSDoc comments
- [ ] No implicit prop spreading without type definition
- [ ] No `any` types in any prop interface

### TypeScript
- [ ] Zero `any` types in the entire component
- [ ] All event handlers properly typed (`React.MouseEvent<HTMLButtonElement>`, etc.)
- [ ] No `@ts-ignore` without written justification
- [ ] No linting errors or warnings
- [ ] No console.log/warn/error

### Styles
- [ ] All colors from `theme.palette.*` (no hex codes, no named colors)
- [ ] All spacing from `theme.spacing()` (no hardcoded pixel values)
- [ ] All font sizes from `theme.typography.*` (no hardcoded font sizes)
- [ ] Using `sx` prop, not inline `style` prop
- [ ] No CSS shorthand (`paddingX` not `px`, `backgroundColor` not `bg`)
- [ ] CSS units correct: `rem` for font-size, unitless for line-height, `px` for spacing

### DREAM Usage
- [ ] DREAM components used for all available UI elements (checked dream.uwm.com)
- [ ] Direct MUI imports only for Grid, useMediaQuery, CssBaseline, SxProps, Popover, styled
- [ ] Using correct DREAM version (same as rest of package, never mixed)
- [ ] Theme accessed via `useDreamTheme()` hook

### Accessibility
- [ ] DREAM/MUI components: meaningful labels provided
- [ ] Custom components: ARIA roles, keyboard nav, focus management, WCAG AA contrast
- [ ] Interactive elements have accessible names
- [ ] Keyboard navigation works (Tab, Enter, Space, Escape as appropriate)

</verification_checklist>

<integration>

**This skill is called by:**
- `develop-frontend` orchestrator (Phase 2)
- Developers directly when designing new components

**After this skill, proceed to:**
- `implement-ui-feature` (Phase 3) — TDD implementation with .feature specs → Vitest tests
- `test-frontend` (Phase 4) — Testing strategy (Stryker mutation, Playwright E2E)

**Before this skill, complete:**
- `create-allin-package` (Phase 1) — Package must exist before designing components

**Related skills:**
- `create-allin-package` — For the 3-layer decomposition pattern and SCL architecture
- `test-frontend` — For testing the components designed with this skill
- `implement-ui-feature` — For TDD implementation using .feature specs

**Related documents:**
- `dream-buddy.md` — Full DREAM standards reference (for DREAM library contributions)
- Component taxonomy (Confluence page 1514786638) — UFA/IAP/SCL component architecture

</integration>

<resources>

**DREAM Design System:**
- Storybook: https://dream.uwm.com (live component documentation — check here first)
- Repository: https://code.uwm.com/projects/UCP/repos/lib-node-dream-ui
- Figma Guidelines: https://www.figma.com/design/zRsKww4xBqzzRVbTM7wAye/Dream-Component-Guidelines
- Jira Board: https://work.uwm.com/secure/RapidBoard.jspa?rapidView=1361
- Confluence: https://kb.uwm.com/display/DREAMREP/Dream+Design+System
- Team Contact: dreamdesignsystem@uwm.com
- Feedback Form: https://airtable.com/appXMaBIvjbE6Aw09/pag3T8vNQADLW4PMc/form

**UWM Standards:**
- Enterprise UX/UI Strategy: https://kb.uwm.com/pages/viewpage.action?pageId=1479753831
- UXPC Charter: https://kb.uwm.com/pages/viewpage.action?pageId=1453025032
- Component Taxonomy: https://kb.uwm.com/pages/viewpage.action?pageId=1514786638

**MUI Reference:**
- Container Queries: https://mui.com/material-ui/customization/container-queries/
- Theming: https://mui.com/material-ui/customization/theming/

**Reference Components in allin-ui:**
- DREAM v3 patterns: `ufas/income-calculator/src/components/` — modern usage with `lib-node-dream-ui-latest`
- SCL patterns: `packages/shared-components/src/components/` — shared components with barrel exports
- DREAM v2 patterns: `ufas/data-dashboard/src/components/` — older `lib-node-dream-ui` usage
- Test utilities: `packages/shared-components/src/testUtils/TestProviders.tsx` — DreamThemeProvider in test setup
- Theme for tests: `ufas/income-calculator/src/testUtils.tsx` — ExternalThemeLight import pattern

**When stuck:**
- "Does DREAM have X?" → Search dream.uwm.com Storybook
- "Which DREAM version?" → Check existing imports in your package
- "Can I use MUI directly?" → Only for Grid, useMediaQuery, CssBaseline, SxProps, Popover, styled
- "What theme variable for this color?" → Check `theme.palette.*` in Storybook theme panel
- "Component needs to work in both themes" → Use theme variables exclusively, test with both themeFamily values
- "Need a new DREAM component" → Contact dreamdesignsystem@uwm.com, follow contribute-commit model

</resources>
