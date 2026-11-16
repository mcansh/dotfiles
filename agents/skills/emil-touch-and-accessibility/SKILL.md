---
name: emil-touch-and-accessibility
description: "Rules for making interfaces work on touch devices and for keyboard and screen-reader users — tap targets, hover vs touch, focus management, aria labels, reduced motion, iOS Safari quirks. Use when building or reviewing any interactive UI (buttons, modals, tooltips, menus, video, timers) or fixing mobile behavior. Triggers on: touch, mobile, tap target, hit area, hover, hover state, iOS, Safari, iPhone, iPad, keyboard navigation, tab order, tabbing, focus, focus trap, aria, aria-label, accessibility, a11y, screen reader, prefers-reduced-motion, reduced motion, inert, touch-action, double-tap zoom, pinch zoom, playsinline, autoplay video, tooltip delay, submenu, dropdown, dialog, modal, Cmd, Ctrl, keyboard shortcut."
---

# Touch & Accessibility

A large share of users will experience your interface through a thumb, a keyboard, or a screen reader — never a mouse. UI that only works with a fine pointer and perfect vision is broken UI, no matter how polished it looks. The rules below are not enhancements to add later; they are the baseline. Hover should enhance, never enable: if functionality is only reachable via hover, it is unreachable on touch.

All CSS below is written as plain CSS for clarity. When implementing, match the project's existing styling system (Tailwind, CSS Modules, styled-components, vanilla-extract, etc.) rather than imposing a new one.

## Core Principles

### 1. Gate hover effects behind capability queries

Touch devices fire `:hover` on tap, causing stuck or false-positive hover states. Only apply hover styles on devices that actually support hovering:

```css
@media (hover: hover) and (pointer: fine) {
  .element:hover {
    transform: scale(1.05);
  }
}
```

Never rely on hover for the UI to function — hover reveals and embellishes, it must not be the only way to reach an action.

### 2. Tap targets are at least 44px

Visual size can stay small; the hit area cannot. Expand it with a pseudo-element:

```css
.icon-button {
  /* Visual size can be smaller */
  width: 24px;
  height: 24px;
  position: relative;
}

.icon-button::before {
  content: '';
  position: absolute;
  inset: -10px; /* 24px + 2*10px = 44px hit area */
}
```

Or with sizing directly:

```css
.small-button {
  min-width: 44px;
  min-height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
}
```

### 3. Control `touch-action`

Prevent double-tap zoom on interactive controls:

```css
button, a, input {
  touch-action: manipulation;
}
```

For custom components that implement their own gestures, hand the browser back every axis you don't use, so they don't fight yours. The value names what the *browser* may still do:

```css
.custom-slider {
  touch-action: pan-y; /* the slider owns horizontal; the page still scrolls vertically over it */
}

.custom-canvas {
  touch-action: none; /* a canvas or drawing surface owns every axis */
}
```

### 4. `muted` + `playsinline` for autoplaying video

Without both attributes, iOS either refuses to autoplay or opens fullscreen:

```html
<!-- no autoplay attribute: start it from script after the reduced-motion check (§8 below) -->
<video muted playsinline loop>
  <source src="video.mp4" type="video/mp4" />
</video>
```

### 5. Every icon-only button gets an `aria-label`

```html
<button type="button" aria-label="Close dialog">
  <CloseIcon />
</button>

<button type="button" aria-label="Search">
  <SearchIcon />
</button>
```

Illustrations built out of divs/CSS follow the same split as images. A decorative one is hidden from screen readers; one that carries meaning gets a role and a label that says what it shows:

```jsx
{/* Decorative: nothing to announce */}
<div aria-hidden="true" className="decorative-illustration" />

{/* Meaningful: announced like an image */}
<div role="img" aria-label="Upload progress: 3 of 5 files" className="progress-illustration" />
```

### 6. Tab order only includes visible elements

Users must never tab into something they can't see. Hide inactive panels from the tab order with `visibility: hidden` or the `inert` attribute:

```css
.hidden-panel {
  visibility: hidden;
}
```

```jsx
<div inert={!isVisible}>...</div>
```

And keyboard focus must never land off-screen or under sticky chrome. The browser already scrolls a focused element into view; reserve the space a sticky header covers so it lands clear of it:

```css
html {
  scroll-padding-top: 64px; /* the sticky header's height */
}
```

### 7. Manage focus across modal boundaries

When a modal or dialog opens, move focus into it (first interactive element, or the dialog itself). When it closes, return focus to the element that triggered it. Never leave focus stranded on a removed node.

### 8. Respect `prefers-reduced-motion` everywhere

Every animation needs a reduced-motion path. For video, that means offering a play button instead of autoplaying:

```jsx
const videoRef = useRef(null);
const [showControls, setShowControls] = useState(false);

// matchMedia only exists in the browser, so read it after mount, not during render
useEffect(() => {
  const query = window.matchMedia('(prefers-reduced-motion: reduce)');
  const sync = () => {
    if (query.matches) {
      videoRef.current?.pause();
      setShowControls(true);
    } else {
      // Autoplay can still be refused (Low Power Mode, data saver): give them a way to start it
      videoRef.current?.play().catch(() => setShowControls(true));
    }
  };
  sync();
  query.addEventListener('change', sync);
  return () => query.removeEventListener('change', sync);
}, []);

<video
  ref={videoRef}
  controls={showControls}
  muted
  loop
  playsInline
/>
```

### 9. Freeze time-limited actions when the tab is hidden

A countdown that keeps running in a background tab punishes the user for switching away. Pause on `visibilitychange` and window `blur`, alongside hover, press, and focus. Those reasons overlap, so a plain pause/resume pair miscounts the remaining time; the reason-tracking timer is in `/emil-interaction-details` (hover-and-timers.md). A real deadline (session expiry, a reservation hold) never pauses; it recomputes what's left from its absolute end time when the tab comes back.

### 10. Show shortcuts for the user's OS

Display `Cmd` on macOS, `Ctrl` elsewhere — and bind the matching key:

```js
// Browser only: read it in an effect, not during an SSR render.
// navigator.platform is deprecated; userAgentData is Chromium-only, so fall back to the UA string.
const platform = navigator.userAgentData?.platform ?? navigator.userAgent;
const isMac = /mac|iphone|ipad/i.test(platform);
const modKey = isMac ? 'Cmd' : 'Ctrl';

// Display: "Save (Cmd+S)" on Mac, "Save (Ctrl+S)" on Windows
```

## Tooltips & Menus

**Delay the first, skip the rest.** The first tooltip waits 500ms so incidental mouse travel doesn't fire it; once one is open, neighbors open instantly with no animation until 300ms after the last one closes. The provider setup (Radix, Base UI, and the shadcn per-tooltip provider that breaks it) is in `/emil-interaction-details`.

**Submenu safe area.** Users move the cursor diagonally from a parent item toward its submenu. Without a safe zone, that diagonal path crosses the next item and the submenu closes. Radix and Base UI menus handle this; a hand-built menu needs a safe triangle that tracks the pointer, which is in `/emil-interaction-details` (menus-and-popovers.md). A static `clip-path` triangle doesn't follow the pointer, so don't ship one.

## Feedback

Feedback components (errors, confirmations, status) must be visible directly on the page. Never hide feedback behind hover states or inside modals — if the user has to hunt for it, it failed.

## Review Checklist

- [ ] Hover styles wrapped in `@media (hover: hover) and (pointer: fine)`
- [ ] No functionality reachable only via hover
- [ ] Every tap target ≥ 44px (visual size may be smaller; hit area may not)
- [ ] `touch-action: manipulation` on buttons, links, inputs
- [ ] Custom gesture surfaces hand back the axes they don't own (`pan-y` on a horizontal slider; `none` only when every axis is theirs)
- [ ] Autoplaying videos have `muted` and `playsinline`
- [ ] Icon-only buttons have `aria-label`; decorative code-built illustrations have `aria-hidden="true"`, meaningful ones `role="img"` + `aria-label`
- [ ] Tab order skips hidden content (`visibility: hidden` or `inert`)
- [ ] Focus lands clear of sticky chrome (`scroll-padding-top`); modals move and restore focus
- [ ] Every animation and autoplaying video respects `prefers-reduced-motion`
- [ ] Timers pause on `visibilitychange`
- [ ] Shortcut hints show Cmd/Ctrl per OS

## Common Mistakes

- **Stuck hover states on mobile** — hover styles applied unconditionally, so a tap leaves the element "hovered" until the next tap elsewhere.
- **24px icon buttons with 24px hit areas** — visually fine, physically un-tappable.
- **Videos that open fullscreen on iPhone** — missing `playsinline`.
- **Tabbing into closed drawers and off-screen carousels** — hidden with `opacity: 0` or `transform` instead of `visibility: hidden`/`inert`, which keeps them focusable.
- **Focus lost when a dialog closes** — focus falls back to `<body>`, forcing keyboard users to re-tab from the top.
- **Tooltips with no delay** — flicker on across the page as the cursor passes; or with a delay on every tooltip in a row, making toolbars feel sluggish (see Tooltips & Menus and `/emil-interaction-details`).
- **Submenus that close mid-flight** — no diagonal safe area.
