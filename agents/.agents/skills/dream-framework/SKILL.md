---
name: dream-framework
description: Use when creating a new web project, scaffolding a React app, or needing Dream Design System component guidance - covers setup, component selection, theming, and layout patterns
---

# Dream Framework Skill

## Overview

This skill provides guidance for building web applications with UWM's Dream Design System (`lib-node-dream-ui`). It covers project scaffolding, component selection, theming, and layout patterns.

## When to Use

- Creating a new web project from scratch
- Adding Dream components to an existing project
- Choosing the right component for a UI pattern
- Setting up theming (light/dark, external/internal)
- Building common layouts (dashboards, forms, navigation)

## Project Scaffolding

When creating a new React + TypeScript + Vite project with Dream:

### Step 1: Create Vite project

```bash
npm create vite@latest project-name -- --template react-ts
cd project-name
```

### Step 2: Configure npm registry

```bash
echo "registry=https://artifacts.uwm.com/artifactory/api/npm/npm" >> .npmrc
```

### Step 3: Install Dream and core dependencies

```bash
npm i lib-node-dream-ui
npm install @mui/material@^7.2.0 @mui/system@^7.2.0 @emotion/react@^11.14.0 @emotion/styled@^11.14.1 @fontsource-variable/open-sans@^5.2.7 @fontsource-variable/roboto@^5.2.9 @fontsource-variable/roboto-mono@^5.2.8 @fortawesome/fontawesome-svg-core@^6.7.1 @fortawesome/free-solid-svg-icons@^6.7.1 @fortawesome/pro-duotone-svg-icons@^6.7.1 @fortawesome/pro-light-svg-icons@^6.7.1 @fortawesome/pro-regular-svg-icons@^6.7.1 @fortawesome/pro-solid-svg-icons@^6.7.1 @fortawesome/react-fontawesome@^0.2.2 @mui/icons-material@^7.2.0 @mui/x-charts@^7.29.1 @tanstack/react-query@^5.69.0
```

### Step 4: Install common dev dependencies

```bash
npm install -D @testing-library/react @testing-library/jest-dom @testing-library/user-event vitest jsdom @types/react @types/react-dom
```

### Step 5: Set up main.tsx

```tsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { DreamThemeProvider } from 'lib-node-dream-ui'
import '@fontsource-variable/roboto'
import '@fontsource-variable/open-sans'
import 'lib-node-dream-ui/external.css'
import 'lib-node-dream-ui/index.css'
import './index.css'
import App from './App.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <DreamThemeProvider family="external" mode="light">
        <App />
      </DreamThemeProvider>
    </BrowserRouter>
  </StrictMode>,
)
```

Use `family="internal"` and import `lib-node-dream-ui/internal.css` instead for employee-facing apps.

## Component Import Pattern

Always use deep imports for tree-shaking:

```tsx
// Correct
import Button from 'lib-node-dream-ui/Button'
import Card from 'lib-node-dream-ui/Card'
import Typography from 'lib-node-dream-ui/Typography'

// Wrong - do NOT use barrel imports
import { Button, Card } from 'lib-node-dream-ui'
```

## Component Selection Guide

### "I need a..." Decision Tree

**Page layout:**
- App shell with header → `TopNavigation` + `SideNavigation`
- Content sections → `Box` + `Stack`
- Card grid → `Card` with CSS Grid or MUI Grid
- Tabbed content → `Tabs` + `Tab`
- Collapsible sections → `Accordion`
- Step-by-step flow → `Stepper` or `SteppedModal`

**User input:**
- Short text → `InputField`
- Long text → `TextArea`
- Select from list → `SelectField` (single) or `MultiSelectField` (multi)
- Searchable select → `Autocomplete`
- Yes/no toggle → `Toggle` or `Checkbox`
- Choose one from few → `RadioButtonGroup`
- Date → `DatePicker`
- Time → `TimePicker`
- File → `FileUploader`
- Rich text → `RichTextEditor`
- Formatted number → `MaskedInput`

**Actions:**
- Primary action → `Button`
- Icon-only action → `IconButton`
- Dropdown actions → `Menu` + `MenuItem` or `PopoverMenu`
- Bulk actions on selected items → `BulkActionToolbar`
- Navigation link → `Link`

**Display data:**
- Text content → `Typography` (use Dream variants: `titleL`, `bodyM`, `dataL`, etc.)
- Data table → `DataGrid` (interactive) or `Table` (simple)
- Charts → `BarChart`, `PieChart`, `Gauge`
- Status indicator → `Badge` or `Chip`
- Tags/labels → `Chip` / `ChipGroup`
- User identity → `Avatar`
- Loading state → `Skeleton` (content placeholder) or `Spinner` (action in progress)
- Empty content → `EmptyState`
- PDF document → `PdfViewer`

**Feedback:**
- Inline message → `Alert`
- Temporary notification → `Snackbar`
- Confirmation needed → `Dialog`
- Detailed content overlay → `Modal`
- Hover info → `Tooltip`
- Floating content → `Popover` or `Flyout`
- Guided tour → `useTour` hook

**Navigation:**
- App header → `TopNavigation`
- Sidebar → `SideNavigation`
- Page breadcrumbs → `Breadcrumb`
- Tab sections → `Tabs`
- Anchor links → `Anchors`

## Common Layout Patterns

### Dashboard with Card Grid

```tsx
import Box from 'lib-node-dream-ui/Box'
import Card from 'lib-node-dream-ui/Card'
import CardText from 'lib-node-dream-ui/CardText'
import Typography from 'lib-node-dream-ui/Typography'
import TopNavigation from 'lib-node-dream-ui/TopNavigation'
import 'lib-node-dream-ui/TopNavigation.css'

function Dashboard() {
  return (
    <>
      <TopNavigation title="My App" />
      <Box sx={{ p: 3 }}>
        <Typography variant="titleL">Welcome</Typography>
        <Box sx={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
          gap: 2,
          mt: 2
        }}>
          {cards.map(card => (
            <Card key={card.id}>
              <CardText
                title={card.title}
                description={card.description}
              />
            </Card>
          ))}
        </Box>
      </Box>
    </>
  )
}
```

### Form Page

```tsx
import Box from 'lib-node-dream-ui/Box'
import Stack from 'lib-node-dream-ui/Stack'
import InputField from 'lib-node-dream-ui/InputField'
import SelectField from 'lib-node-dream-ui/SelectField'
import Button from 'lib-node-dream-ui/Button'
import Typography from 'lib-node-dream-ui/Typography'

function FormPage() {
  return (
    <Box sx={{ maxWidth: 600, mx: 'auto', p: 3 }}>
      <Typography variant="titleL">Create Item</Typography>
      <Stack spacing={3} sx={{ mt: 2 }}>
        <InputField label="Name" required />
        <InputField label="Description" multiline rows={3} />
        <SelectField
          label="Category"
          options={[
            { label: 'Option A', value: 'a' },
            { label: 'Option B', value: 'b' },
          ]}
        />
        <Button variant="contained">Submit</Button>
      </Stack>
    </Box>
  )
}
```

## Theme Usage

### Accessing theme tokens in styles

```tsx
import { useTheme } from '@mui/material/styles'

function MyComponent() {
  const theme = useTheme()
  return (
    <Box sx={{
      backgroundColor: theme.fill.background.high,
      color: theme.text.neutral.default,
      boxShadow: theme.shadows[200],
      borderRadius: theme.radius?.md,
    }}>
      Content
    </Box>
  )
}
```

### Theme-aware sx prop

```tsx
<Box sx={(theme) => ({
  backgroundColor: theme.fill.background.default,
  color: theme.text.neutral.default,
})}>
  Themed content
</Box>
```

### Toggling dark mode

```tsx
import { useDreamTheme } from 'lib-node-dream-ui'

function ThemeToggle() {
  const { mode, setMode } = useDreamTheme()
  return (
    <Button onClick={() => setMode(mode === 'light' ? 'dark' : 'light')}>
      Switch to {mode === 'light' ? 'Dark' : 'Light'} Mode
    </Button>
  )
}
```

## Anti-Patterns

- **Do NOT use barrel imports**  - Always deep import (`lib-node-dream-ui/Button`)
- **Do NOT use raw MUI components** when Dream equivalent exists
- **Do NOT hardcode colors**  - Use theme tokens for light/dark mode support
- **Do NOT use `@fontsource/roboto`**  - Use `@fontsource-variable/roboto`
- **Do NOT use deprecated `ONavProvider`**  - Use `TopNavigation` + `SideNavigation`
- **Do NOT create custom MUI themes**  - Use `DreamThemeProvider`

## Reference

Full documentation: https://dream.uwm.com
