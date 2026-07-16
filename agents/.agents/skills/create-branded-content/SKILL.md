---
name: create-branded-content
description: Use when creating UWM branded content — presentations, pitch decks, documents, memos, agendas, marketing materials, one-pagers, or any content that needs UWM Brand Standards 2025 compliance. Produces self-contained HTML files with proper branding.
---

<skill_overview>
Create UWM-branded content as self-contained HTML files. Read brand-reference.md for specs, pick the closest template, customize with real content, and output HTML that follows UWM Brand Standards 2025.
</skill_overview>

<rigidity_level>
HIGH FREEDOM — Templates are starting points, not constraints. Claude can create entirely new layouts as long as all brand rules from brand-reference.md are followed: CSS variables for colors, correct font stacks, heading hierarchy, and no hardcoded values.
</rigidity_level>

<quick_reference>
| Content Type | Template | Key Layout |
|-------------|----------|------------|
| Presentation / pitch deck | template-presentation.html | 16:9 slides with scroll-snap (title, content, sidebar, three-card, split, closing) |
| Memo | template-document.html | .uwm-doc--memo with TO/FROM/DATE/RE table |
| Agenda | template-document.html | .uwm-doc--agenda with time/topic/presenter table |
| Letterhead | template-document.html | .uwm-doc--letterhead with address and signature |
| Training / Job Aid | template-document.html | .uwm-doc--jobaid with color-coded heading hierarchy |
| Marketing one-pager | template-one-pager.html | Hero, stats bar, two-column content, CTA |
| Spreadsheet / data report | template-spreadsheet.html | Header with logo, branded data table, summary row |
| Custom / other | Start from brand-system.css | Use CSS variables and brand-reference.md rules |
</quick_reference>

<when_to_use>
Use when:
- User asks for a presentation, slide deck, or pitch deck
- User needs a memo, agenda, letterhead, or training document
- User wants marketing content, one-pager, or external-facing material
- User asks for a spreadsheet, data report, or table-heavy document
- User asks for any UWM-branded output
- User says "make it look like UWM" or references brand guidelines

Do NOT use when:
- Building web application UI (use uwm-frontend-dev / DREAM framework instead)
- Writing code documentation or READMEs
- Creating non-UWM content with no branding requirement
</when_to_use>

<the_process>

## 1. Read the Brand Reference

Read `resources/brand-reference.md` to load the complete brand spec into context: colors, fonts, heading hierarchy, logo rules, and layout guidelines.

## 2. Select the Closest Template

Read the matching template from `resources/`:
- **Presentations**: `template-presentation.html`
- **Documents** (memo/agenda/letterhead/job-aid): `template-document.html`
- **Marketing one-pagers**: `template-one-pager.html`
- **Spreadsheets/data reports**: `template-spreadsheet.html`
- **Other**: Read `resources/brand-system.css` and compose from scratch

Read `resources/uwm-logo.png` and embed it as a base64 data URI in the output HTML to display the actual UWM logo.

## 3. Customize Content

- Replace placeholder content with the user's actual content
- Add, remove, or rearrange slides/sections as needed
- For presentations: add or remove slides, change layouts per slide
- For documents: keep only the relevant format section, delete others
- All text must be real content — never leave template placeholders
- **Presentations: respect text capacity limits** — see "Text Capacity Per Slide Layout" in brand-reference.md. Max 5-6 bullets per content slide, ~10 words per bullet (one line). If content doesn't fit, add another slide — never shrink text below 30pt

## 4. Output Self-Contained HTML

Write the final HTML file. It must be:
- **Self-contained**: All CSS embedded in `<style>` tags (copy from template)
- **Single external dependency**: Google Fonts `@import` for Roboto only
- **All colors via CSS variables**: Use `var(--uwm-blue)`, `var(--uwm-teal)`, etc.
- **Correct font stack**: `var(--uwm-font-headline)` for headings, `var(--uwm-font-body)` for body

Save to a location appropriate for the context.

## 5. Dark Mode (Only When Explicitly Requested)

If the user explicitly asks for dark mode, dark theme, or dark variant:

1. **Warn them first:** "Dark mode is an unofficial variant — it has not been approved by UWM Marketing. The colors are adapted for accessibility on dark surfaces but are not part of the official Brand Standards 2025. OK to proceed?"
2. **Wait for confirmation** before generating dark mode content.
3. **Activate:** Add `class="uwm-dark"` to the `<html>` element. The CSS variables override automatically.
4. **Include the dark mode CSS** from brand-system.css (the `.uwm-dark` section) in the embedded styles.

Do NOT apply dark mode unless the user explicitly requests it. Default is always light mode.

</the_process>

<examples>
<example>
<scenario>User asks for a team presentation</scenario>

<code>
User: "Create a presentation about our Q1 engineering achievements"

Claude reads resources/brand-reference.md and resources/template-presentation.html.
Customizes slides with engineering content.
Outputs: q1-engineering-review.html with embedded UWM branding.

Key checks:
- Slide titles are ALL CAPS
- Colors use var(--uwm-*) variables
- Orange emphasis on key metrics
- Footer on every slide with confidentiality notice
</code>
</example>

<example>
<scenario>User asks for a document but Claude hardcodes colors</scenario>

<code>
WRONG:
<h1 style="color: #005F9E;">OVERVIEW</h1>
<div style="background: #00A39D;">...</div>

CORRECT:
<h1>OVERVIEW</h1>
<!-- h1 already styled via brand-system.css: color: var(--uwm-blue) -->
<div class="uwm-bg-teal">...</div>
</code>

<why_it_fails>
Hardcoded hex values bypass the CSS variable system. If brand colors change, hardcoded values won't update. Always use var(--uwm-*) or utility classes.
</why_it_fails>
</example>

<example>
<scenario>User needs a format not covered by templates</scenario>

<code>
User: "Create a branded newsletter"

Claude reads resources/brand-reference.md and resources/brand-system.css.
Composes new layout following brand rules:
- Embeds brand-system.css inline
- Uses heading hierarchy (h1=Blue, h2=Teal, h3=Green, h4=Orange)
- Body text in var(--uwm-dark-gray)
- UWM text logo in header
- All colors via CSS variables
</code>
</example>
</examples>

<critical_rules>
## Rules That Have No Exceptions

1. **All colors via CSS variables** — Never hardcode hex values. Use `var(--uwm-blue)`, utility classes like `.uwm-bg-teal`, etc.
2. **Self-contained HTML** — Embed all CSS inline. Only external dependency is Google Fonts CDN.
3. **No lorem ipsum** — All placeholder content must be realistic and UWM-relevant.
4. **Font fallbacks required** — Futura PT is local-only. Always use the full stack: `var(--uwm-font-headline)` which falls back to Roboto.
5. **Headings in ALL CAPS** — Document and slide headings use `text-transform: uppercase`.
6. **Accessibility** — Green and Orange fail WCAG AA for body text on light backgrounds. Use them only for headings or decorative elements. (Both pass AA on dark mode surfaces.)
7. **Presentation text must be 30pt+ (2.5rem)** — All audience-facing text on slides must use `var(--uwm-slide-*)` sizes. Body text and subtitles are 2.5rem (30pt) minimum. Card layouts are a noted exception. Footers are exempt.
8. **Contrast at distance** — Projected presentations lose contrast. Use only Dark Gray and Blue for slide text. Orange for short emphasis spans only (1-3 words). Never use Green or Teal as primary text color on slides. The color-coded heading hierarchy is for documents only, not presentations.
9. **Read brand-reference.md first** — Always load the brand spec before creating content.
10. **Dark mode requires explicit request and confirmation** — Never apply `.uwm-dark` by default. Always warn the user that it is an unofficial variant not approved by UWM Marketing before generating.
</critical_rules>

<resources>
**Brand specification:** `resources/brand-reference.md` — Complete color palette (hex, RGB, CMYK, Pantone), fonts, logo rules, heading hierarchy, slide layouts, document formats

**CSS brand system:** `resources/brand-system.css` — CSS custom properties, font imports, typography scale, utility classes, slide system, print styles

**Templates:**
- `resources/template-presentation.html` — 6-slide deck (title, content, sidebar, three-card, split, closing)
- `resources/template-document.html` — 4 formats (memo, agenda, letterhead, job-aid)
- `resources/template-one-pager.html` — Marketing one-pager (hero, stats, content, CTA)
- `resources/template-spreadsheet.html` — Branded data table/report (header, data rows, summary)
</resources>
