# Building Tonal Scales & Palettes

## Step naming

Design systems label a hue's tonal steps numerically, lightest to darkest: 50, 100, 200 … 900, 950. The full eleven-step ramp is what Tailwind ships; leaner systems keep the shape but drop stops — a nine-step version omits 400 and 600, and a minimal five-step version keeps just 100/300/500/700/900. Whatever the count, 50 is always the near-white tint and 950 the near-black shade.

## Constructing a ramp

A good oklch ramp comes from three decisions, applied per step:

**1. Anchor the lightness endpoints, then space evenly.** Put step 50 around L 0.97 and step 950 around L 0.22, and interpolate linearly between them. Even L spacing is the point of using oklch — every adjacent pair of steps will look equally far apart. Don't run all the way to L 0 or L 1: at the poles chroma collapses to zero and the endpoints stop reading as members of the hue.

**2. Shape chroma as a curve, not a constant.** Real-world ramps are most vivid in the middle and gentle at both ends. Express each step's chroma as a fraction of that step's sRGB ceiling — e.g. ~30% at the extremes rising to ~85% around the 400–500 range — so the tints stay airy, the shades stay rich, and nothing leaves the gamut.

**3. Clamp against the gamut per step.** The ceiling `maxC(L, H)` differs at every lightness, so compute (or look up) it for each step before applying the fraction. A base color that is highly saturated will necessarily lose absolute chroma toward both ends of the ramp — that's the geometry of the gamut, not an error.

Hue stays fixed for all eleven steps.

Applied to a magenta-pink brand hue (H = 330):

```css
:root {
  --berry-50:  oklch(0.97 0.007 330);
  --berry-100: oklch(0.895 0.042 330);
  --berry-200: oklch(0.82 0.103 330);
  --berry-300: oklch(0.745 0.189 330);
  --berry-400: oklch(0.67 0.251 330);
  --berry-500: oklch(0.595 0.231 330);
  --berry-600: oklch(0.52 0.195 330);
  --berry-700: oklch(0.445 0.151 330);
  --berry-800: oklch(0.37 0.105 330);
  --berry-900: oklch(0.295 0.063 330);
  --berry-950: oklch(0.22 0.03 330);
}
```

Note the absolute chroma peaking near 400 rather than 500 — at this hue the sRGB gamut is widest around L 0.67, and the clamp reflects that.

## Families of hues

To make several hues feel like one system (the classic "brand + success + warning" trio), equalize two things across them:

- **The same L per step number** — every `-500` sits at the same lightness, so rows of the palette look equally bright.
- **The same fraction of each hue's own ceiling** — *not* the same absolute C. Ceilings differ wildly between hues, so a shared absolute value over-saturates the roomy hues and flattens the cramped ones.

```css
:root {
  /* all at L 0.65, each at 70% of its own sRGB ceiling */
  --teal-500:   oklch(0.65 0.08 185);   /* ceiling here ≈ 0.115 */
  --amber-500:  oklch(0.65 0.096 75);   /* ceiling here ≈ 0.137 */
  --violet-500: oklch(0.65 0.155 300);  /* ceiling here ≈ 0.221 */
}
```

Three different absolute chromas, one perceived intensity.

## Dark mode

Never hand-pick a second palette by eye. Keep the hue, and derive each dark-mode value from the role it plays and the surface it sits on.

**Neutrals mirror.** Surfaces, ink, borders, and muted text swap with their mirror steps — 50 ↔ 950, 200 ↔ 800, 300 ↔ 700. Because oklch lightness is close to perceptually even, a pair separated by ΔL reads about as distinct after the flip; still check each text pair.

```css
:root              { --surface: var(--gray-50);  --ink: var(--gray-950); }
[data-theme="dark"] { --surface: var(--gray-950); --ink: var(--gray-50); }
```

**Accents don't mirror.** Mapping brand text 600 → 300 and its tint 50 → 950 is the tempting shortcut, and it fails twice. The light end of a ramp is deliberately low in chroma so tints stay airy, so brand text pulled from there turns pastel. The dark end was tuned to be text in light mode, so as a tint background it sits barely lighter than the surface and reads as a dark stain. Re-pick each accent role on the same H instead:

| Role | Dark-mode value | Why |
| --- | --- | --- |
| Brand text: links, active tabs, chip labels | The lowest L that clears the contrast target with a little margin (about 6:1), at the brand's own C, capped at ~95% of the ceiling at that L | Every step of L above what contrast needs costs chroma at hues with a low ceiling (blue and violet lose about 0.03 C per 0.05 L) and buys nothing |
| Tint behind brand text (badge, selected row) | ~0.07 L above the surface, C around 0.09, or what the ceiling allows there (cyan and teal top out near 0.05) | It has to read as the hue, not as a dark blob. Its text can reuse the brand-text value if it still passes on the tint |
| Fills: meters, progress, dots | L ~0.6, the brand's C, capped by the ceiling | Non-text marks only need 3:1 against the surface, so they can stay deep and vivid |
| Solid button with a white label | The brand, with L moved until white clears 4.5:1 and the button separates from the surface. For most brands that's a nudge up of up to 0.05 L | The light-mode brand often sits under 3:1 against a dark surface, so the button sinks into it |

Capping at the brand's C matters for roomy hues: magenta's ceiling at L 0.72 is about 0.29, and filling it turns the brand neon.

Don't build dark-mode chip tints out of the brand at low opacity. Composited over a dark surface, 15% of a vivid indigo lands near C 0.05, a gray-violet, and its value shifts with whatever is behind it.

Worked through for the berry brand above (step 600, `oklch(0.52 0.195 330)`) on a dark surface at L 0.215:

```css
:root {
  --brand-text: var(--berry-600);        /* 6.1:1 on white */
  --brand-tint: var(--berry-50);
  --brand-tint-text: var(--berry-700);
  --brand-fill: var(--berry-600);
  --brand-button: var(--berry-600);
}

[data-theme="dark"] {
  --brand-text: oklch(0.72 0.195 330);      /* 6.4:1 on the surface */
  --brand-tint: oklch(0.29 0.09 330);
  --brand-tint-text: oklch(0.76 0.195 330); /* 6.3:1 on the tint */
  --brand-fill: oklch(0.62 0.195 330);
  --brand-button: oklch(0.57 0.195 330);    /* white on it 5.0:1; 3.5:1 against the surface */
}
```

The mirror of `--brand-tint`, berry-950, is the same lightness as the surface: the badge disappears. On a blue or violet brand the text goes wrong too. Indigo's mirrored 300 sits near `oklch(0.78 0.09 277)`, 8.6:1 when 6:1 would do, and too pale to read as the brand.

Brand-colored text on dark is also where APCA and WCAG 2 disagree most. APCA's Lc 60 lands around L 0.77, where blue and violet hues have only about 0.11 C left, so the brand goes pastel however carefully you pick it. Keep brand color to short labels (links, tabs, chips), hold those to WCAG AA with margin (about 6:1, roughly L 0.66–0.72 on a near-black surface), and set paragraphs in neutral ink, where APCA's body-text targets apply. This is a deliberate tradeoff, covered in [contrast.md](contrast.md).

## The case against HSL ramps

Two structural defects make HSL unusable for scale generation:

**The hue lies as lightness moves.** Take an HSL blue ramp at a fixed hue of 240: `hsl(240 65% 25%)` lands at oklch hue ≈ 272.6, `hsl(240 65% 55%)` at ≈ 274.3, but the pale `hsl(240 65% 88%)` tint lands at ≈ 285.2 — a ~13° slide toward violet that users see as the light steps "going purple." An oklch ramp pins H and the slide disappears.

**The lightness number is decorative.** `hsl(55 100% 50%)` (a yellow) and `hsl(255 100% 50%)` (a blue-violet) claim identical lightness; on screen one is nearly white-bright and the other is dark. Any ramp spacing computed from HSL's L channel inherits this distortion. OKLCH's L is the actual perceived brightness, so spacing computed from it is real.

## Auditing an inherited scale for drift

1. Convert every step of the existing scale to oklch.
2. Read off the H values and find the spread between the minimum and maximum.
3. Over ~10° of spread is visible drift: keep the scale's mid-tone hue, then regenerate the ramp with the procedure above.
