# Hover, Tooltips, and Timers

The details that depend on where the pointer is and how long it has been there.

## Tooltips

Three numbers, one rule each:

| | Value | Why |
| --- | --- | --- |
| First tooltip in a group | 500ms delay, then a 125ms fade + `scale(0.97)` from the trigger side | A pointer crossing the page shouldn't light up every label it passes. The delay is the cost of asking for the first one. |
| Every tooltip after it | 0ms delay, no animation | The user is now reading labels. Making them wait 500ms on each button turns a sweep across a toolbar into a stop-and-wait. |
| Warm window | 300ms after the last tooltip closes | Long enough to cross the gap to the next trigger, short enough that coming back later feels like a fresh request. |

The rules around them:

- **One provider around the whole group.** The skip-delay only works between tooltips that share a provider. Mount one at the app root first (Radix throws for a `Tooltip` with no provider above it), and none inside individual tooltips. A toolbar that needs different delays can nest its own.
  - Radix: `<Tooltip.Provider delayDuration={500} skipDelayDuration={300}>`. Its defaults are 700 and 300.
  - Base UI: `<Tooltip.Provider delay={500} timeout={300}>`. Its defaults are 600 and 400.
  - **shadcn/ui's `Tooltip` wraps every tooltip in its own `TooltipProvider` with `delayDuration = 0`.** Every tooltip is its own group, so nothing is ever warm, and with the 0 default every label flashes on as the pointer passes. Mount one `TooltipProvider` with the delays above at the app root, then remove the per-tooltip provider from `components/ui/tooltip.tsx`. Drop its slide-in too: the entrance is the fade and `scale(0.97)` above.
- **Kill the animation when instant, not only the delay.** A tooltip that skips its delay but still fades in for 125ms looks like it lags behind the pointer. Both libraries mark it: style `[data-instant]` (Base UI) or `[data-state="instant-open"]` (Radix) with `transition-duration: 0ms` / `animation: none`. The tooltip being replaced closes instantly too, so the two never overlap mid-sweep.
- **Close faster than you open** (about 100ms), and never put the hover-intent delay on closing. The delay is about a pointer arriving; on the way out it only holds a stale label on screen. This is for tooltips: hover cards and nav menus hold content the pointer moves into, and they get a close delay ([menus-and-popovers.md](menus-and-popovers.md)).
- **A click on the trigger closes its tooltip, and it stays closed until the pointer leaves and comes back.** The user has moved from reading the label to using the button, and the tooltip would cover what the click changed. For the same reason, focus that a pointer press caused doesn't open it (only keyboard focus does), and any scroll closes it.
- **A tooltip that answers a keypress opens immediately.** Focus via Tab, or a readout for a shortcut that was just pressed, gets 0 delay: the user asked for it.
- **Contiguous hover areas in a group.** Space toolbar buttons with padding inside the hit area, not margins between them. A dead strip between two buttons closes the tooltip mid-sweep, and the next one reopens: a flicker on every crossing.
- **Tooltips label, they don't hold.** Nothing clickable inside a tooltip, and nothing only a tooltip says. Touch users never see it.

## Hover intent for everything else

- **Hover comes from a pointer that moved.** Scrolling slides content under a still cursor and fires `pointerenter` on it: every card in a scrolled grid lifts and tooltips pop up along the way. Start hover UI from `pointermove`, or ignore enters that arrive while the page is scrolling.
- **Decorative hover effects wait ~100ms.** An illustration, a card that lifts, an icon that plays: start only after the pointer has been there 100ms, and only run the hover-end animation if the hover-start ran. Otherwise a cursor crossing the page leaves a trail of half-played animations.
- **Menus and lists that respond to hover highlight instantly.** No transition on the highlight background. Anything animated trails the cursor one step behind, and in a menu the pointer moves fast.
- **Submenus get a safe triangle.** The pointer heading diagonally toward a submenu crosses the next item in the parent menu. Without a grace area the submenu closes under it. Radix and Base UI menus do this for you; a hand-built menu needs the triangle described in [menus-and-popovers.md](menus-and-popovers.md), which only engages while the pointer heads toward the submenu, so ordinary movement in the parent never waits.
- **Hover reveals also reveal on focus.** Anything that appears on `:hover` also appears on `:focus-visible` (or `:focus-within` for a container), or keyboard users can't find it.
- **Hover effects don't run on touch.** Wrap them in `@media (hover: hover) and (pointer: fine)`. A tap fires `:hover` and leaves it stuck. Hover in JavaScript checks `e.pointerType === "mouse"` itself, and ignores mouse events for 50ms after a touch ([presses-and-keys.md](presses-and-keys.md)).

## Gaps the pointer crosses

When hover keeps something open (an expanded toast stack, a hover card, a mega-menu), every gap between its parts is a place where the pointer is suddenly "outside" and the thing collapses. Fill them:

```css
/* Each expanded toast fills the gap above it. +1px covers subpixel seams. */
.toast[data-expanded="true"]::after {
  content: "";
  position: absolute;
  left: 0;
  bottom: 100%;
  width: 100%;
  height: calc(var(--gap) + 1px);
}
```

- **A trigger and its hover card are one hover area.** Bridge the offset between them with a pseudo-element on the content, or use the library's grace area.
- **Something leaving keeps its hit area until it's gone.** A toast animating out of an expanded stack still owns the space under the cursor; if it doesn't, the stack thinks the pointer left and collapses mid-exit.
- **Don't collapse on `pointerleave` while the pointer is down.** A swipe that drifts outside the stack is still the same interaction.

## Timers

Anything that disappears on its own (toasts, auto-advancing slides, "Copied!" states that revert) runs on a timer the user didn't start. They must never miss it because of something they did.

These are presentation timers. A real deadline (a session expiry, a reservation hold, an auction) never pauses: it keeps its absolute end time, and the display recomputes what's left from that when the tab comes back.

- **Pause while hovered, while pressed, while focus is inside, and while the tab is hidden or the window is in the background.** Hover or focus means they're reading or about to act. A hidden tab means they can't see it at all: a toast fired while they were in another tab would otherwise expire unseen. `visibilitychange` doesn't fire when they switch to another app with the browser still on screen, so listen for the window's `blur` and `focus` too (Radix).
- **Resume from what was left, not from the start.** A 4000ms toast hovered at 3500ms has 500ms left when the pointer leaves. Restarting the full timer makes toasts linger every time someone brushes past.
- **Never `setTimeout(fn, Infinity)`.** It fires immediately (the delay overflows to 0). A toast that should stay ("loading", a promise in flight, `duration: Infinity`) gets no timer at all.
- **Pause the whole stack together.** Hovering one toast holds all of them, so none expire behind the one being read.
- **Re-check after removals.** When a toast is removed while it holds focus, no reliable `focusout` follows; re-check `stack.contains(document.activeElement)` after every removal, or the stack stays paused forever.
- **Defaults:** 4000ms for a toast that only informs, 6000ms when it carries an action like Undo (the user has to read it and decide). Loading toasts never auto-close; when one resolves, its result starts a fresh timer.
- **The same toast fired twice updates the one on screen** instead of stacking a copy. Give it a stable `id` (Sonner replaces a toast with the same id) and restart its timer, so three saves in a row show one "Saved", not three.
- **Loading indicators have a minimum, both ways.** Wait ~150ms before showing one, so fast responses never flash it; once it's shown, keep it up at least ~300ms, so a response at 170ms doesn't produce a spinner that blinks for 20ms. Both are glitches; the second one looks like the screen flickered. Only the visible indicator waits: the button disables and guards against a double submit the moment the request starts (`/emil-forms-and-inputs`).

Hover, press, and focus overlap all the time, so track *why* it's paused, and only move between running and paused when the first reason arrives or the last one leaves. A plain `pause()`/`resume()` pair subtracts the elapsed time twice when two reasons overlap, and the toast expires early.

```ts
type Hold = "hover" | "press" | "focus" | "hidden" | "blurred";

function createTimer(duration: number, onExpire: () => void) {
  const holds = new Set<Hold>();
  let remaining = duration;
  let startedAt = 0;
  let timer: ReturnType<typeof setTimeout> | undefined;
  let done = false;

  const run = () => {
    if (done || remaining === Infinity) return; // Infinity: stays until dismissed
    startedAt = Date.now();
    timer = setTimeout(() => {
      timer = undefined;
      done = true;
      onExpire();
    }, remaining);
  };
  const stop = () => {
    clearTimeout(timer);
    timer = undefined;
    remaining -= Date.now() - startedAt;
  };

  if (typeof document !== "undefined") {
    if (document.hidden) holds.add("hidden");
    if (!document.hasFocus()) holds.add("blurred");
  }
  if (holds.size === 0) run();

  return {
    hold(reason: Hold) {
      if (holds.has(reason)) return;
      holds.add(reason);
      if (holds.size === 1 && timer !== undefined) stop(); // running → paused
    },
    release(reason: Hold) {
      if (!holds.delete(reason)) return;
      if (holds.size === 0) run(); // paused → running
    },
    clear() {
      done = true;
      clearTimeout(timer);
    },
  };
}
```

Wire `hold`/`release` to `pointerenter`/`pointerleave` (`"hover"`) and `focusin`/`focusout` (`"focus"`) on the stack, `pointerdown` on the stack with `pointerup`/`pointercancel` on the document (`"press"`, so a press released outside the stack still lets go), `visibilitychange` (`"hidden"`) on the document, and `blur`/`focus` (`"blurred"`) on the window.
