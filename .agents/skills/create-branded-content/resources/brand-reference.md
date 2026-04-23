# UWM Brand Standards Reference

Source: UWM Brand Standards 2025 (Updated January 2025)
Contact: marketing@uwm.com for brand questions

## Brand Philosophy

> Consistency = familiarity. Familiarity = trust. Trust = a deeper, more meaningful relationship.

Our brands must be communicated in the same tone and manner in every communication, every time.

---

## Logo

**Full name:** UWM — United Wholesale Mortgage

**Preferred usage:** Full-color logo with "UNITED WHOLESALE MORTGAGE" text lockup.

### Logo Rules

| Rule | Detail |
|------|--------|
| Preferred format | Full-color logo |
| Gray/B&W | Requires prior approval from UWM Marketing team |
| Clear space | 1/2 the width and height of the "U" on all sides |
| Minimum size (full) | 1 inch — includes "United Wholesale Mortgage" text |
| Minimum size (mark) | 1/2 inch — "UWM" only, remove "United Wholesale Mortgage" text |
| Alterations | Never recreate, alter, or distort the logo in any way |

### Logo Asset

The actual UWM logo PNG is available at `resources/uwm-logo.png`. When generating self-contained HTML:
1. Read the logo file and convert to base64
2. Embed as `<img src="data:image/png;base64,{base64_data}" alt="UWM - United Wholesale Mortgage" class="uwm-logo">`
3. Size the logo using CSS (e.g., `height: 3rem; width: auto` for documents, `height: 2rem` for footers)
4. On dark backgrounds, apply `filter: brightness(0) invert(1)` to make the logo white
5. Never stretch or distort — always use `width: auto` with a fixed height

### Logo Variants (by size)

1. **Large (1"+ wide):** Full lockup — UWM + UNITED WHOLESALE MORTGAGE
2. **Medium (1/2"–1"):** Mark only — UWM (no tagline text)
3. **Below 1/2":** Do not use

---

## Color Palette

### Primary & Accent Colors

| Name | Hex | RGB | CMYK | Pantone | Usage |
|------|-----|-----|------|---------|-------|
| **Blue** | #005F9E | 0, 95, 158 | 100/53/2/16 | 2945 C | Primary brand color, H1 headings, links |
| **Teal** | #00A39D | 0, 163, 157 | 83/0/40/11 | 7716 C | H2 headings, secondary accent |
| **Green** | #A1CE57 | 161, 206, 87 | 41/0/85/0 | 2292 C | H3 headings, decorative elements |
| **Orange** | #F68A33 | 246, 138, 51 | 0/56/90/0 | 1505 C | H4 headings, emphasis, CTAs |
| **Gray** | #B2B5B6 | 178, 181, 182 | 12/8/9/23 | Cool Gray 4 | Borders, decorative, subtle backgrounds |

### Extended Colors (derived from templates)

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Dark Gray** | #575757 | 87, 87, 87 | Body text, slide titles, primary text color |
| **White** | #FFFFFF | 255, 255, 255 | Backgrounds, text on dark surfaces |

### Accessibility — Color Contrast on White (#FFFFFF)

| Color | Contrast Ratio | WCAG AA (normal text) | WCAG AA (large text) | Safe For |
|-------|---------------|----------------------|---------------------|----------|
| Blue #005F9E | 5.53:1 | Pass | Pass | Body text, headings, links |
| Teal #00A39D | 3.48:1 | Fail | Pass | Headings and large text only |
| Green #A1CE57 | 2.35:1 | Fail | Fail | Decorative elements, icons, large headings with caution |
| Orange #F68A33 | 2.79:1 | Fail | Fail | Decorative elements, icons, large headings with caution |
| Dark Gray #575757 | 5.92:1 | Pass | Pass | Body text, primary content |
| Gray #B2B5B6 | 1.99:1 | Fail | Fail | Decorative only — never for text |

**Rule:** Body text must use Dark Gray #575757 or Blue #005F9E on white backgrounds. Green, Orange, and Gray are for decorative/large-text use only.

### Dark Mode Palette (UNOFFICIAL VARIANT)

> **WARNING:** This dark mode palette is NOT approved by UWM Marketing. It is a proposed variant for internal tools, developer dashboards, or contexts where dark mode is strongly preferred. Any external-facing use requires approval from marketing@uwm.com.

Activate by adding `class="uwm-dark"` to `<html>` or `<body>`. The CSS variables are overridden automatically.

| Role | Light Mode | Dark Mode | Why Changed |
|------|-----------|-----------|-------------|
| **Blue (accents, H1, links)** | #005F9E | #4DA3D4 | Original fails contrast on dark surfaces (2.34:1). Lightened to 5.61:1 |
| **Teal (H2)** | #00A39D | #00A39D (unchanged) | Already passes at 5.03:1 on dark |
| **Green (H3)** | #A1CE57 | #A1CE57 (unchanged) | Already passes at 8.58:1 on dark |
| **Orange (H4, emphasis)** | #F68A33 | #F68A33 (unchanged) | Already passes at 6.43:1 on dark |
| **Gray (borders)** | #B2B5B6 | #4A5568 | Darkened for subtle borders on dark surfaces |
| **Dark Gray (body text)** | #575757 | #D8DEE9 | Reversed to light text. 11.62:1 contrast |
| **White (backgrounds)** | #FFFFFF | #1C2333 | Dark navy surface |
| **Off-White (alt backgrounds)** | #F7F7F7 | #252D3F | Slightly lighter dark surface for cards/rows |

**Dark Mode Contrast on #1C2333:**

| Color | Contrast Ratio | WCAG AA | Safe For |
|-------|---------------|---------|----------|
| Blue #4DA3D4 | 5.61:1 | Pass | Body text, headings, links |
| Teal #00A39D | 5.03:1 | Pass | Headings, accents |
| Green #A1CE57 | 8.58:1 | Pass | Headings, body text, decorative |
| Orange #F68A33 | 6.43:1 | Pass | Headings, emphasis, CTAs |
| Body Text #D8DEE9 | 11.62:1 | Pass | All text |

**Key improvement:** Green and Orange, which fail WCAG AA on white, both pass AA on dark surfaces. Dark mode has better overall accessibility for the UWM color palette.

---

## Typography

### Font Families

| Role | Font | Web Fallback | System Fallback Stack |
|------|------|-------------|----------------------|
| **Headlines** | Futura PT | Roboto (Google Fonts) | 'Futura PT', 'Roboto', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif |
| **Body Copy** | Helvetica Neue LT Pro | System sans-serif | 'Helvetica Neue LT Pro', 'Helvetica Neue', Helvetica, Arial, sans-serif |
| **Web** | Roboto | — | 'Roboto', sans-serif |

### Futura PT Weights

| Weight | CSS font-weight | Usage |
|--------|----------------|-------|
| Light (+ Oblique) | 300 | Subtle labels, captions |
| Book (+ Oblique) | 400 | Body text, slide content, bullets |
| Medium | 500 | Subtitles, sub-headings |
| Demi (+ Oblique) | 600 | Semi-bold emphasis |
| Bold (+ Oblique) | 700 | Titles, primary headings |
| Heavy / Extra Bold (+ Oblique) | 800–900 | Impact text, hero sections |

### Helvetica Neue LT Pro Weights

| Weight | CSS font-weight | Usage |
|--------|----------------|-------|
| 45 Light | 300 | Light body text |
| 55 Roman | 400 | Standard body text |
| 56 Italic | 400 italic | Emphasis in body |
| 75 Bold | 700 | Bold body text |
| 85 Heavy | 800 | Heavy emphasis |

### Roboto Weights (Web Fallback via Google Fonts)

Load: 300 (Light), 400 (Regular), 500 (Medium), 700 (Bold)

---

## Document Heading Hierarchy

Derived from the UWM Training/Job Aid template. Use for documents, memos, training materials, and job aids.

| Level | Text Style | Font | Size (print) | Size (HTML) | Color |
|-------|-----------|------|-------------|------------|-------|
| H1 | ALL CAPS | Futura PT Book | 15pt | 2rem | Blue #005F9E |
| H2 | ALL CAPS | Futura PT Book | 13pt | 1.5rem | Teal #00A39D |
| H3 | ALL CAPS | Futura PT Book | 13pt | 1.25rem | Green #A1CE57 |
| H4 | ALL CAPS | Futura PT Book | 13pt | 1.125rem | Orange #F68A33 |
| Body | Normal case | Futura PT Book | 12pt | 1rem | Dark Gray #575757 |
| Small/Caption | Normal case | Futura PT Book | 10pt | 0.875rem | Dark Gray #575757 |

**Note:** Print pt sizes are too small for screen. HTML sizes use a proportional scale optimized for readability.

---

## Presentation Standards

Derived from UWM Presentation Template 2026.

### Dimensions

- **Aspect ratio:** 16:9 widescreen
- **Physical size:** 13.33 x 7.50 inches
- **CSS dimensions:** 1280 x 720 pixels (or scale proportionally)

### Typography for Slides

| Element | Font | Style | Size (CSS) | Approx pt | Color |
|---------|------|-------|-----------|----------|-------|
| Slide title (hero) | Futura PT Bold | ALL CAPS | var(--uwm-slide-title-hero-size) = 4rem | 48pt | Dark Gray #575757 |
| Slide title | Futura PT Bold | ALL CAPS | var(--uwm-slide-title-size) = 3rem | 36pt | Dark Gray #575757 |
| Slide subtitle | Futura PT Medium | ALL CAPS | var(--uwm-slide-subtitle-size) = 2.5rem | 30pt | Dark Gray #575757 |
| Body text / bullets | Futura PT Book | Normal case | var(--uwm-slide-body-size) = 2.5rem | 30pt | Dark Gray #575757 |
| Card title | Futura PT Bold | ALL CAPS | var(--uwm-slide-card-title-size) = 2rem | 24pt | Dark Gray #575757 |
| Card text | Futura PT Book | Normal case | var(--uwm-slide-card-text-size) = 1.5rem | 18pt | Dark Gray #575757 |
| Emphasis text | Futura PT Book Bold | Normal case | (inherits context) | — | Orange #F68A33 |
| Footer | Futura PT Book | Normal case | var(--uwm-text-xs) = 0.75rem | 9pt | Dark Gray #575757 |

### Large-Screen Readability Rules

**The 30pt rule:** All text the audience needs to read must be 30pt (2.5rem / 40px) or larger. Text below this threshold is unreadable when projected on a large screen from typical seating distance.

| Element | Minimum Size | Meets 30pt? | Notes |
|---------|-------------|-------------|-------|
| Slide title | 3rem (36pt) | Yes | Hero title even larger at 4rem (48pt) |
| Subtitle | 2.5rem (30pt) | Yes | Exactly at threshold |
| Body / bullets | 2.5rem (30pt) | Yes | Keep bullets to 6 words or fewer |
| Card title | 2rem (24pt) | Exception | Dense layouts; keep text very short |
| Card body | 1.5rem (18pt) | Exception | Dense layouts; minimize text |
| Footer / slide number | 0.75rem (9pt) | Exempt | Not audience-facing content |

**Contrast at distance:** Low-contrast text that may be readable on a monitor becomes illegible when projected. Colors perform differently at distance:

| Color | Contrast on White | Projection Readability |
|-------|------------------|----------------------|
| Blue #005F9E | 6.71:1 | Good — readable at distance |
| Dark Gray #575757 | 7.23:1 | Excellent — primary slide text color |
| Teal #00A39D | 3.12:1 | Marginal — avoid for projected body text |
| Green #A1CE57 | 1.83:1 | Poor — unreadable at distance, decorative only |
| Orange #F68A33 | 2.44:1 | Poor — use sparingly for short emphasis words only |

**Implications for presentations:**
- Use **Dark Gray** for all slide titles and body text (already the default)
- Use **Blue** for links or secondary headings where high contrast is needed
- Use **Orange** only for short emphasis spans (1-3 words), never full sentences
- **Never** use Green or Teal as the primary color for projected text
- The color-coded heading hierarchy (H1=Blue, H2=Teal, H3=Green, H4=Orange) is for **documents only** — do not use it in presentations

### Text Capacity Per Slide Layout

At 30pt (2.5rem) body text on a 1280x720 slide, each layout has strict content limits. Exceeding these limits causes text to be cut off or visually cramped.

| Layout | Max Bullets/Lines | Words Per Line | Total Words | Notes |
|--------|------------------|---------------|-------------|-------|
| **Content slide** | 5-6 bullets | ~10 words (59 chars at 30pt on 1137px) | ~50-60 | Full-width body area, generous horizontal space |
| **Sidebar slide** | 4 bullets | ~8 words | ~32 | Sidebar eats ~5rem of width |
| **Split slide (40/60)** | 3-4 short paragraphs | ~8 words (60% width content area) | ~40 | Image 40%, content 60% |
| **Three-card slide** | 2-3 lines per card | ~6 words per card line | ~20 per card | Uses smaller 24pt titles and 18pt body (dense exception) |
| **Title slide** | Title + subtitle only | — | ~12 | No body text area |
| **Closing slide** | 1-2 sentences | — | ~20 | Centered, max-width constrained |

**Key rule:** If your content doesn't fit, you need another slide — not smaller text. Split content across multiple slides rather than reducing font size below 30pt.

### Layout Rules

- Keep bullet text to one line — approximately 8-10 words at 30pt on a full-width slide
- Keep content at least 2 inches from the bottom of the slide
- Footer format: `SLIDE: [#]  |  PROPRIETARY AND CONFIDENTIAL TO UWM - FOR USE BY UWM TEAM MEMBERS ONLY`
- Orange #F68A33 for emphasis and call-to-action text — short spans only
- If content overflows a slide, split into two slides — never shrink text below 30pt

### Slide Layouts (5 Primary)

#### 1. Title Slide
Full-width slide with centered title and subtitle. UWM logo positioned above title area. Used as the opening slide.

#### 2. Content Slide
Title bar at top (ALL CAPS, Dark Gray), optional subtitle below, body content area with generous padding. Standard layout for most content.

#### 3. Sidebar Content
Colored vertical bar on the left side (~1.5 inches wide, uses a brand accent color). Title and body content positioned to the right of the sidebar. Use for section breaks or visual variety.

#### 4. Three-Card Layout
Three equal-width columns, each containing: image placeholder at top, colored accent line, title, subtitle, and description text. Use for comparisons, feature highlights, or team introductions.

#### 5. Image + Text Split
Full-color background. Image on the left half, text content on the right half. Title above body text. Use for case studies, testimonials, or visual storytelling.

---

## Document Templates

### Memo
- Header: "MEMO" in Futura PT Book, 16pt, ALL CAPS
- Body: Helvetica Neue LT Pro 55 Roman, Bold, 10pt, Gray
- Table for TO/FROM/DATE/RE fields

### Agenda
- Header: "AGENDA" in Futura PT Book, 16pt, ALL CAPS
- Date and location line in Helvetica Neue LT Pro 55 Roman, 10pt
- Table for agenda items with time/topic columns
- Body text: Helvetica Neue LT Pro 55 Roman, 10pt

### Letterhead
- Header: Futura PT Book for date, name, title, address
- Body: Helvetica Neue LT Pro 55 Roman, 10pt
- UWM branding in header area

### Training / Job Aid
- Uses the full heading hierarchy (H1=Blue, H2=Teal, H3=Green, H4=Orange)
- Body: Futura PT Book, 12pt, Gray #575757
- Bullet indent: 0.25 inches
- Tables for structured information

### Spreadsheet / Data Report
- Header: UWM logo with report title
- Data table: Blue header row, alternating white/off-white rows
- Summary/totals row at bottom
- Footer: Confidentiality notice

---

## Key Brand Rules Summary

1. **Always use the full-color logo** — gray/B&W requires Marketing approval
2. **Never alter the logo** — no stretching, recoloring, or removing elements
3. **Maintain clear space** — 1/2 the width of the "U" on all sides
4. **Use brand colors consistently** — reference the palette above, use CSS variables
5. **Use Futura PT for headlines** — fall back to Roboto for web
6. **Use Helvetica Neue for body copy** — fall back to system sans-serif for web
7. **ALL CAPS for headings** — document headings and slide titles use uppercase
8. **Accessibility first** — only use high-contrast colors for body text (Dark Gray, Blue)
9. **Consistency above all** — same look, tone, and manner in every communication
