---
name: emil-typography
description: "Deep, prescriptive guidance for text on the web — font files and formats, variable-font axes and OpenType features, type scales, leading and tracking, line length, wrapping and truncation, underlines, selection, form text and WCAG floors, plus a CSS-to-Tailwind lookup. Use when selecting or pairing typefaces, wiring up a variable font, building a type scale, fixing text that wraps or truncates badly, styling links, underlines, text selection, placeholder or caret behavior, or auditing frontend code for typography quality. Triggers on: typography, typeface, fonts, woff2, font formats, variable fonts, opentype, font-feature-settings, font-weight, tabular numbers, letter-spacing, tracking, line-height, leading, type scale, measure, line length, readability, text-wrap, line clamp, truncation, ellipsis, underline, text-decoration, text selection, placeholder, caret, iOS input zoom, font smoothing, antialiased, text contrast, text-box, smart punctuation, drop cap, RTL."
---

# Typography

Nearly everything an interface communicates travels through text, and browsers set text badly by default in predictable ways: lines run too long, digits jitter as they tick, underlines slice through descenders, a fake bold sneaks in when a weight file is missing. The remedies are small and mechanical once you can name them — this skill names them. Context decides which rule applies: a data cell, a hero headline, a form hint and an essay paragraph each deserve their own treatment, so never flatten them into a single recipe.

**Stay inside the project's styling idiom.** Before proposing any change, identify how the codebase expresses styles — Tailwind utilities, vanilla CSS, CSS Modules, styled-components, StyleX — and phrase every fix in that same idiom. [tailwind-map.md](tailwind-map.md) translates each declaration in this skill into its Tailwind utility for exactly this purpose. A typography fix is never a justification for bolting a second styling approach onto a codebase.

## Reference files

Open the file that matches the problem at hand:

- [typefaces-and-formats.md](typefaces-and-formats.md) — picking and pairing families, file formats, why equal font sizes look unequal
- [font-capabilities.md](font-capabilities.md) — variable axes, OpenType features, stylistic sets, small caps, numerals
- [scale-and-rhythm.md](scale-and-rhythm.md) — building a size scale, leading, tracking, cropping built-in space with `text-box`
- [line-behavior.md](line-behavior.md) — measure, wrap modes, truncation, character choice, language and direction
- [polish-and-accessibility.md](polish-and-accessibility.md) — underlines, selection, carets, decorative treatments, size and contrast floors
- [tailwind-map.md](tailwind-map.md) — every property above, translated to Tailwind

## The rules

### Files and features

**Ship `woff2` and nothing else.** It carries Brotli compression and every browser that matters accepts it. `woff` earns a place only when truly ancient browsers are a hard requirement; `ttf` and `otf` are uncompressed desktop formats that don't belong on a web server. Loading strategy — preloading, `font-display`, fallback metrics — lives in `/emil-performance`.

**Forbid synthesized styles.** Ask for a bold or italic you never loaded and the browser fabricates one by thickening or slanting the real glyphs. That's an emergency fallback, not a rendering mode you want. Declare `font-synthesis: none` so a missing file surfaces as an obvious regression instead of a quietly ugly imitation.

**Reach for the high-level property before the raw tag.** Write `font-weight: 620`, never `font-variation-settings: "wght" 620`; `font-optical-sizing: auto`, never a hand-set `"opsz"`; `font-variant-numeric: tabular-nums`, never `font-feature-settings: "tnum" 1`. High-level properties still do something sensible when a fallback font renders; the low-level ones silently stop working. The escape hatches exist solely for what has no property of its own — a custom axis like Fraunces' `"WONK" 1`, or a numbered stylistic set like `"ss03" 1`.

**Fixed-width digits on anything that updates.** Most fonts draw a narrow 1 and a wide 4, so a live timer, price or counter nudges its neighbors on every tick. `font-variant-numeric: tabular-nums` gives all digits one width and the jitter disappears.

### Hierarchy

**Two typefaces cover most products; treat three as the ceiling.** Marketing surfaces can afford more voice than product UI, but every added face, weight and size dilutes hierarchy instead of strengthening it. Pair for the surface's register before chasing contrast. In product UI and docs, start with one sans plus a mono: the sans carries every heading through size and weight, and the pairing work is fitting the mono to it by eye (`0.875em` is a starting point, not a guaranteed x-height match). Add a separate heading face only when the project's register gives a reason for it, not out of habit, and check that its optical size, weight and rendered proportions still establish clear hierarchy over the lede. Whatever you pair, never pick two lookalike sans-serifs — that reads as a version-control accident.

**Every size comes from a scale.** Define a small fixed set of sizes and treat departures from it as exceptions needing justification; scattered one-off values decay fast as a codebase grows. Solo, generic names such as `text-sm` are workable if the usage rules are written down. On a team, name steps after roles — `text-caption`, `text-body-lg` — because a role name enforces its own usage in a way a size name cannot. A ratio only seeds the scale: round each step to a whole pixel and keep the ones the page needs. Neighbors must differ at a squint — a page title sits well above its lede (about 1.75× or more) and adds weight; if a role drops weight, it needs more size to compensate.

**Leading shrinks as size grows.** Body copy reads best between `1.5` and `1.6`, a lede or 20–24px subhead around `1.35`–`1.5`, a 28–40px page title around `1.15`–`1.2`, and only true display type (48px and up) as tight as `1.05`–`1.1`. Faces with long descenders want the upper end. Always write line-height unitless so it tracks the font size — a hard-coded `24px` line-height breaks the moment the size changes.

**Tracking follows size.** Sans headings tighten as they grow: about `-0.01em` at 24px, `-0.02em` at 32px, `-0.03em` from 48px up; serifs need less. Small uppercase labels open up by `0.04`–`0.08em` and drop to `11`–`12px`, below every other text on the page: capitals fill the whole cap height and tracking widens them further, so a 13px uppercase label reads as large as 15px body text and outshouts the content it labels. Body text at reading sizes gets neither.

**Space by relationship, never evenly.** Tight heading leading removes air, so give it back as margin, and size each gap by how closely the two elements belong together: an eyebrow sits close to its heading (about 8px), the heading a little further from its lede (about 16px), and the biggest gap closes the intro before the content starts (24px or more). Equal gaps melt a header into one undifferentiated block.

### Lines and breaking

**Cap the measure.** The eye loses its return path on long lines. Hold reading columns to roughly 45–75 characters, with about 65 as the sweet spot — `max-width: 65ch` states that directly, and Tailwind's `max-w-prose` is defined as exactly `65ch`. A rem-based cap works too; what matters is that the cap exists and the rendered line count lands in range.

**Pick a wrap mode per role.** Headings get `text-wrap: balance`, which evens out the lines. Standfirsts and card descriptions get `text-wrap: pretty`, which stops a lone word from stranding on the last line. Body paragraphs get `pretty` at most, never `balance` — `balance` gives up after a handful of lines anyway, and balancing a full paragraph burns horizontal space for no reading benefit.

**Guard against overflow.** Anywhere a URL, token or user-supplied word could punch out of its box, add `overflow-wrap: break-word`. Anywhere a mid-label break would read as a bug — badges, buttons, key-value labels — pin it with `white-space: nowrap`.

**Truncation must leave a path to the full text.** One line: `white-space: nowrap`, `overflow: hidden`, `text-overflow: ellipsis`. Several lines: `display: -webkit-box`, `-webkit-box-orient: vertical`, `-webkit-line-clamp: N`, `overflow: hidden` (Tailwind's `line-clamp-N` emits exactly this; the unprefixed `line-clamp` isn't dependable yet). Either way you're hiding content, so when the hidden part carries meaning, expose it through a tooltip, a details view, or an expand affordance.

### Copy and characters

**Casing is presentation, not data.** Keep strings in natural sentence case and let `text-transform` shout or capitalize them. Copy typed in caps has to be rewritten at the next redesign; a transformed string just gets a new class.

**Type real punctuation.** Curly quotes in prose (code keeps straight ones), an en dash for spans like `Mon–Fri` or `1998–2004`, an em dash for asides, the single `…` character instead of three periods. Glue units to their values with `&nbsp;` (`42&nbsp;GB`), and mark legal break points inside long words with `&shy;`.

### Finish

**Thicken the underline.** The default underline, and most fonts' own metrics, come out as a 1px hairline that looks thin next to body text. Set it by hand: about `1.5px` thick (`text-decoration-thickness: 0.09em`), dropped clear of the baseline with `text-underline-offset: 0.2em`, `text-decoration-skip-ink: auto`, and a muted color that darkens to the text color on hover, so the link reads as a link without the line shouting. A dotted line (`text-decoration-style: dotted`) is the established cue for "hover for more" — abbreviations, defined terms. And if the underline animates in any way beyond a color fade, draw it as its own element; color is the only piece of a native underline that animates dependably.

**Treat selection as a design surface.** A tinted `::selection` quietly carries the brand into reading — keep the pairing legible. Put `user-select: none` on control labels, where selection reads as a glitch, and check that select-all captures only genuine content. On the web it stays on control chrome and never goes on `body`; desktop app shells (Electron, Tauri) are the one place selection is off by default, with copy-worthy content opted back in.

**Smooth once, at the root.** macOS lays ink on thick. Set `-webkit-font-smoothing: antialiased` and `-moz-osx-font-smoothing: grayscale` — Tailwind's `antialiased` covers both — a single time on the root layout and let inheritance do the rest.

**Write direction-neutral CSS.** Use logical properties wherever a physical one exists: `margin-inline-start` over `margin-left`, `text-align: start` over `left`. Declare `lang` so hyphenation dictionaries and quote styles resolve correctly, and put `dir="rtl"` on right-to-left content.

### Accessibility floors

**Inputs never dip below 16px on touch devices.** Mobile Safari auto-zooms the page into any focused field set smaller than `16px`. Size input text at `16px` and shrink only where the primary pointer is fine (`text-base pointer-fine:text-sm` in Tailwind v4.1+, `@media (pointer: coarse)` in plain CSS). Never gate it on a width breakpoint like `md:text-sm`: an iPad is wide and still zooms. Never patch this with `maximum-scale=1` in the viewport meta — Safari disregards it for pinch zoom while other browsers obey it and lock zooming out entirely, a WCAG failure.

**Respect the minimums.** Body copy sits at `16px`, the web's default for a reason. Dense UI text may drop to `14px` (controls, menus — though inputs keep `16px` on touch devices per the rule above), `13px` for captions, and almost never below `12px` (small uppercase labels at `11px` are the one exception). Contrast under WCAG AA: regular text needs `4.5:1` against its background; text at `24px` and up, or `18.66px` (14pt) and up in bold, may drop to `3:1`. Also assume readers will zoom, bump the root font size, or override line spacing — nothing should shatter when they do.

## Auditing existing code

When asked to review or fix typography in a codebase:

1. Detect the styling system first and phrase every fix in it.
2. Sweep the checklist below against the real text roles on screen — body, headings, labels, live numbers, inputs — not just the stylesheet.
3. Report findings grouped by file. Each finding is one bullet: where it is, what's wrong, the corrected declaration in the project's idiom, and which rule it serves.
4. Stay silent on rules the code already follows; a short list of true issues beats an exhaustive tour.
5. Fix with the smallest possible diff. Typography work should not restructure markup unless an animated underline or an expandable truncation genuinely requires an extra element.

## Fast diagnoses

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Layout twitches as a number ticks | Proportional figures | `font-variant-numeric: tabular-nums` |
| Bold looks smudged or too black | Weight file never loaded, browser faked it | Load the weight; set `font-synthesis: none` |
| Tapping a field on iPhone zooms the page | Input text under `16px` | `16px` unless the pointer is fine (`text-base pointer-fine:text-sm`) |
| Headline breaks seven words / one word | Default greedy wrapping | `text-wrap: balance` |
| Paragraph ends on a stranded single word | No orphan control | `text-wrap: pretty` |
| Underline slices through g, y, p | Skip-ink or position off | `text-decoration-skip-ink: auto`, `text-underline-offset: 0.2em` |
| Link underline looks thread-thin | Default 1px thickness | `text-decoration-thickness: 0.09em` (about `1.5px`) |
| Long URL blows out a card | No break opportunity | `overflow-wrap: break-word` |
| Weight change does nothing on some machines | Weight set via `"wght"` raw tag | `font-weight` |
| Text feels cramped in one component, airy in another | One-off sizes and line-heights | Route everything through the scale |
| Reading a paragraph feels like work | Measure far beyond 75 characters | Cap the column near `65ch` |
| ALL-CAPS strings scattered through JSX | Casing baked into copy | Sentence case + `text-transform: uppercase` |
| Ellipsis with no way to see the rest | Truncation without an escape hatch | Tooltip, title attribute, or expand control |
| Layout mirrored wrong in Arabic/Hebrew | Physical margin/padding/text-align | Logical properties, `text-align: start` |
| Faint gray text failing audits | Contrast under `4.5:1` | Darken until AA passes (`3:1` allowed ≥ `24px`, or ≥ `18.66px` bold) |

## Checklist

- [ ] Font binaries are `woff2`
- [ ] `font-synthesis: none` present; nothing renders a fabricated bold or italic
- [ ] Weights and features go through `font-weight` / `font-variant-*`; raw tags reserved for custom axes and numbered sets
- [ ] Every `font-size` traces back to the scale
- [ ] Line-height unitless and graded by size: `1.05`–`1.1` only for 48px+ display, `1.15`–`1.2` for page titles, `1.5`–`1.6` for body
- [ ] Header gaps graded by relationship (label close to heading, wider gap before content), never equal
- [ ] Tracking: slightly negative on display sizes, slightly positive on small uppercase, absent on body
- [ ] Reading columns capped near `65ch` (45–75 characters)
- [ ] `text-wrap: balance` on headings, `pretty` on short descriptive blocks
- [ ] Live or changing numbers use `tabular-nums`
- [ ] Every truncation offers a route to the full string
- [ ] Source strings keep human casing; any shouting is done by CSS
- [ ] Underlines thickened to about `1.5px` (`0.09em`), offset `0.2em`, skip-ink on, muted color that darkens on hover
- [ ] Inputs at `16px` or larger wherever the pointer is coarse (never a width breakpoint); no `maximum-scale=1`
- [ ] Sizes at or above the floors; contrast meets `4.5:1` / `3:1`
- [ ] Smoothing declared once at the root
- [ ] Logical properties plus `lang`/`dir` wherever direction can vary
- [ ] Any `::selection` override stays readable
