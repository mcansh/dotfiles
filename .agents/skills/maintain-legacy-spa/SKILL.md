---
name: maintain-legacy-spa
description: Lightweight reference for maintaining legacy cell-ui-xxx SPAs — covers which UWM standards still apply, what differs from allin-ui, and when to consider migration
---

<skill_overview>
Provides lightweight guidance for teams maintaining legacy dedicated SPAs (cell-ui-xxx pattern) that have not yet migrated to allin-ui. This is NOT the recommended path — all new frontend development should happen in allin-ui. This skill exists for teams with approved exceptions or pending migrations.

**This skill does NOT provide a full development workflow.** It documents which UWM standards still apply to legacy SPAs, what differs from the allin-ui patterns, and when migration should be triggered.
</skill_overview>

<rigidity_level>
HIGH FREEDOM - This is a reference document, not a workflow. Teams adapt these guidelines to their legacy SPA's specific technology stack. The standards that still apply are non-negotiable; everything else adapts to context.
</rigidity_level>

<quick_reference>

| Standard | Still Applies? | Notes |
|----------|---------------|-------|
| React | Yes | UWM standard — all frontends must be React |
| DREAM design system | Yes (where available) | Use lib-node-dream-ui for new components |
| GUP auth | Yes | Must use lib-node-user-passport-component |
| TDD | Yes | Write tests first, use .feature specs |
| Coverage ≥80% | Yes | Measured per project |
| Mutation testing ≥80 | Yes | Stryker with vitest-runner or jest-runner |
| No business logic | Yes | Frontends = UX only |
| No TypeScript `any` | Yes | Ever |
| catalog: protocol | No | Legacy SPAs use npm/yarn with direct versions |
| turbo boundaries | No | Not applicable to standalone repos |
| uwm-manifest.json | No | No app shell integration |
| Module federation | No | Legacy SPAs are standalone |
| Playwright E2E/soak/perf | Recommended | Follow allin-ui patterns if adding new tests |

</quick_reference>

<when_to_use>
- Maintaining a cell-ui-xxx SPA with no immediate migration plan
- Adding features to a legacy SPA approved to remain standalone
- Need to understand which UWM standards apply to legacy frontends
- Evaluating whether a legacy SPA should be migrated

**Do NOT use for:**
- New frontend development (use `develop-frontend` — targets allin-ui)
- Migrating a legacy SPA to allin-ui (use `migrate-spa-to-allin`)
- Backend or BFF development (use `uwm-business-service-dev`)
</when_to_use>

<the_process>

## Standards That Apply

These UWM-wide frontend standards apply regardless of whether you're in allin-ui or a legacy SPA.

### React (Mandatory)

All frontend code at UWM must be React. If a legacy SPA uses a different framework, it should be migrated.

### DREAM Design System (Mandatory for New Components)

- New components should use `lib-node-dream-ui` where available
- Existing MUI components don't need to be replaced immediately (that's a migration concern)
- Theme variables should be used for new styles (theme.palette.*, theme.spacing(), theme.typography.*)
- Check https://dream.uwm.com for available components

### GUP Authentication (Mandatory)

- Use `lib-node-user-passport-component` for auth
- If the legacy SPA has custom auth, plan migration to GUP
- GUP provides: PassportAuth, usePassport, useSinglePageAuth, useAuthExclusion, MockPassport

### Business Logic Boundary (Mandatory)

- Frontend handles ONLY user experience logic
- No calculations, orchestration, or business validation in the UI
- Business logic belongs in the BFF or backend service
- This applies to ALL frontends, legacy or modern

### TDD and Testing (Mandatory)

- Write tests first using .feature specs as documentation
- Use the test framework available in your project (Jest or Vitest)
- Coverage must be ≥80%
- Mutation testing should target ≥80 score
- For Vitest: use `@stryker-mutator/vitest-runner`
- For Jest: use `@stryker-mutator/jest-runner`

### Code Quality (Mandatory)

- No TypeScript `any` types
- Cleanup in afterEach for tests
- ESLint and Prettier configured
- No inline styles (use sx prop or styled components)

---

## Standards That Differ

These allin-ui-specific patterns do NOT apply to legacy SPAs.

### No catalog: Protocol

Legacy SPAs use npm or yarn with direct version numbers. The catalog: protocol is an allin-ui monorepo feature.

```json
// Legacy SPA (acceptable):
"react": "^18.3.1"

// allin-ui (required there, not here):
"react": "catalog:"
```

### No Turbo Boundaries

Architecture boundary enforcement via `turbo boundaries` is an allin-ui feature. Legacy SPAs don't have this protection — be extra careful about dependency management.

### No uwm-manifest.json

Legacy SPAs don't integrate with the app shell. They manage their own routing, navigation, and auth flow. The uwm-manifest.json format is allin-ui-specific.

### No Module Federation

Legacy SPAs are standalone applications. They don't share runtime dependencies via module federation.

### Build Tools May Vary

Legacy SPAs may use webpack, Create React App, Next.js, or Vite. allin-ui requires Vite with @uwm/vite-plugin-appshell, but legacy SPAs can keep their existing build tool.

---

## When to Trigger Migration

Consider migrating to allin-ui when any of these conditions apply:

1. **Major refactoring planned:** If you're already rewriting significant portions, migrate instead
2. **New features require app shell integration:** Navigation, cross-UFA communication, shared auth
3. **Team capacity available:** Migration takes effort — plan for it
4. **Maintenance burden increasing:** Legacy tools becoming harder to maintain
5. **Security or compliance requirements:** allin-ui provides standardized security patterns

**How to start migration:** Use the `migrate-spa-to-allin` skill.

**Success criteria for migration** (from Confluence page 1443991649):
- Dev team can do local development after setup
- Deployed UFA works as specified
- Kill criteria: Local dev setup takes >2 weeks or deploy lead time >1 week

</the_process>

<examples>

## Example: Adding a Feature to cell-ui-lending

**Context:** Team needs to add a new page to cell-ui-lending. No migration planned.

**Approach:**
1. Write .feature spec for the new page behavior
2. Create DREAM components (not raw MUI) for new UI elements
3. Use existing auth patterns (GUP if integrated, or plan GUP adoption)
4. Write Vitest (or Jest, if that's what the project uses) tests achieving ≥80% coverage
5. Run Stryker to verify mutation score ≥80
6. Keep business logic in the BFF — frontend handles only UX

**What NOT to do:**
- Don't add new MUI components when DREAM has equivalents
- Don't put calculations in the frontend
- Don't skip testing
- Don't add TypeScript `any` types

</examples>

<critical_rules>

1. **All new components use DREAM.** Existing MUI is fine, but new work uses lib-node-dream-ui.
2. **GUP auth is mandatory.** If the legacy SPA doesn't have it, adopt it with the next feature.
3. **No business logic in frontend.** This rule has no exceptions regardless of SPA type.
4. **Coverage ≥80%.** Maintained across all frontends.
5. **Consider migration.** Every feature request is an opportunity to evaluate whether migration makes more sense.

</critical_rules>

<edge_cases>

## Legacy SPA Without GUP

If the legacy SPA uses custom authentication:
1. Adopt GUP as the first step before adding new features
2. Install lib-node-user-passport-component
3. Replace custom auth with PassportAuth + usePassport
4. This is a prerequisite — custom auth is not acceptable

## Legacy SPA With Enzyme Tests

If the legacy SPA uses Enzyme:
1. Do NOT add new Enzyme tests
2. New tests must use @testing-library/react
3. Migrate existing Enzyme tests to RTL when touching those files
4. Enzyme is deprecated and not supported

## Very Old React Version

If the legacy SPA uses React <18:
1. Upgrade to React 18 before adding new features
2. React 18 is the UWM standard minimum version
3. DREAM components require React 18+

</edge_cases>

<verification_checklist>

**For any work on a legacy SPA:**
- [ ] New components use DREAM (not raw MUI)
- [ ] GUP auth used (or adoption planned as first step)
- [ ] No business logic added to frontend
- [ ] Tests written first (.feature spec → unit tests)
- [ ] Coverage ≥80%
- [ ] Mutation score ≥80
- [ ] No TypeScript `any` types
- [ ] Migration evaluation documented (why staying legacy)

</verification_checklist>

<integration>

**This skill is called by:**
- `develop-frontend` (orchestrator) — when legacy SPA detected and user chooses to maintain

**When ready to migrate, use:**
- `migrate-spa-to-allin` — formalized migration process

**Related skills:**
- `develop-frontend` — for allin-ui development (recommended path)
- `uwm-business-service-dev` — for BFF or service changes

</integration>

<resources>

**Confluence:**
- V3 Architectural Baselines (page ID: 944046789) — Legacy naming: cell-ui-{context}
- Trade-offs Analysis (page ID: 1455929059) — Advantages of joining allin-ui
- UFA Onboarding Experiment (page ID: 1443991649) — Migration success criteria

**Design System:**
- https://dream.uwm.com — DREAM Storybook documentation
- `UCP/lib-node-dream-ui` on Bitbucket — DREAM source

**Auth:**
- `lib-node-user-passport-component` — GUP auth library
- GUP UI Onboarding Guide on Confluence — Integration walkthrough

</resources>
