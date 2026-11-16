---
name: emil-interaction-details
description: "The behavior between someone's input and the interface's response — delays, thresholds, tension, velocity, hover intent, and timers — so tooltips, drags, sliders, sheets, toasts, menus, selects, steppers, and buttons respond the way a hand expects. Use when building or reviewing anything people hover, drag, swipe, press, or wait on, or when an interaction works but feels off. Triggers on: interaction, interaction design, details, feel, tooltip, tooltip delay, skip delay, delayDuration, hover intent, hover, submenu, safe triangle, menu, dropdown, select, context menu, hover card, navigation menu, typeahead, click outside, dismiss, drag, draggable, swipe, flick, velocity, momentum, rubber band, rubber-banding, overscroll, tension, damping, dampening, elastic, dragElastic, past the end, past the bounds, slider, range input, sheet, drawer, bottom sheet, snap points, toast, timer, auto-dismiss, pause on hover, visibilitychange, press, active state, long press, hold to repeat, stepper, number input, double-click, wheel, trackpad, pinch, zoom, reorder, drag and drop, auto-scroll, IME, isComposing, keyboard shortcut, pointer capture, pointer events, \"feels off\", \"feels dead\", \"feels sluggish\", \"feels cheap\", \"stops dead\", \"flickers\"."
---

# Interaction Details

An interface can look finished in a screenshot and still feel wrong in the hand. The difference lives in time and distance: how long a tooltip waits, what a slider does when you keep pulling, whether a fast flick counts, whether a toast waits for you while you read it. None of it shows up in a static review, and the default an agent reaches for is the simplest behavior that technically works: no delay, a hard stop, a fixed threshold, a timer that never waits.

This skill is the behavior layer. Easing curves and durations belong to `/emil-animations`; focus, tap targets, and screen readers to `/emil-touch-and-accessibility`. When a detail here involves motion, it says what should happen and when, and the animation skill says how it moves.

## Before writing code

1. **Find the primitive.** Check what the project already uses: Radix, Base UI, React Aria, Vaul, Sonner, Motion. Most details below are a prop on a component you already have (`skipDelayDuration`, `closeThreshold`, `dragConstraints`). Use the prop instead of rebuilding it. Asked to fix hand-written code, fix it in place and name the library in your report; don't migrate unasked.
2. **Find where the library's defaults are wrong.** They exist so the component works, not so it feels right: Radix tooltips wait 700ms, shadcn's `Tooltip` gives every tooltip its own provider with no delay, a native `<input type="range">` stops dead at its end.
3. **Read the rest of the file you're in.** Match how the codebase already handles pointer events, timers, and motion values.

## The walk

Run every interactive element through these six questions, in this order. Each "yes" points at a section below. Most elements trigger two or three; an element that triggers none needs nothing from this skill.

```
1. Can it fire by accident?            (a pointer passing over, a scroll that starts on a button, a tap that wobbles)
   └── Yes → add intent: a delay or a distance it must clear first.             → Intent
2. Will people do it many times in a row? (sweeping a toolbar, arrowing a menu, holding a stepper, a shortcut)
   └── Yes → the second time skips what the first one needed.                    → Repetition
3. Can they push past the end?          (a slider at max, a sheet fully open, a list at its top)
   └── Yes → it gives with tension and comes back. Never a hard stop.           → Limits
4. Does how fast they move mean something? (a flick, a throw, a quick swipe)
   └── Yes → decide on distance OR velocity, never distance alone.              → Speed
5. Does the pointer cross gaps on the way? (toolbar buttons, a menu to its submenu, a trigger to its hover card)
   └── Yes → close the gaps, so moving between parts never counts as leaving.   → Paths
6. Can they look away or change their mind? (a toast while they read, a press they drag off, a tab switch)
   └── Yes → wait for them, and let them back out.                              → Patience
```

## Intent

Things that react to the pointer just passing by feel jumpy. Things that react to everything feel broken: a scroll that turns into a close, a tap that turns into a drag.

- **Tooltips wait 500ms the first time.** Less and every label flashes as the pointer crosses the page; more and asking for one feels like a stall.
- **Decorative hover effects wait ~100ms**, and their hover-out only runs if their hover-in did. A cursor crossing the page shouldn't leave half-played animations behind it.
- **A drag starts after the pointer clears a threshold on the drag axis**: 10px on touch, 2px with a mouse, ~6px on a surface full of buttons. Below it, it's still a tap, so buttons inside a draggable keep their clicks.
- **A drag never starts from a text selection or from a child with a gesture of its own** (an input, a slider). Buttons can start one; their click is swallowed if it became a drag. A sheet with scrolling content also refuses one while that content is scrolled, or within 100ms of it reaching the top, so a fast scroll can't close it. The full order of checks is in [dragging.md](dragging.md).
- **Show the press on `pointerdown`, act on release.** The press state (`:active`, see `/emil-animations` for the scale) answers the touch immediately; the action waits for `click`, because pressing, then sliding off, is how people cancel. Menus and selects are the exception: with a mouse they open on `pointerdown`, so press-drag-release picks an item in one motion. That needs guards (the opening press's release picks nothing, touch opens on `click`), all in [menus-and-popovers.md](menus-and-popovers.md).
- **A scroll cancels a press.** Anything pressed inside a scroller drops its pressed state and doesn't fire once the scroller moves. On touch, rows in a scrolling list wait ~100ms before showing pressed, so a thumb scrolling the list doesn't light up every row it crosses ([presses-and-keys.md](presses-and-keys.md)).
- **Whatever opens on hover waits for as long as an accidental open would cost**: submenu 100ms, navigation menu 200ms, tooltip 500ms, hover card 600ms with the pointer at rest. The reasons, and the close delays, are in [menus-and-popovers.md](menus-and-popovers.md).
- **Hover comes from a mouse that moved.** CSS hover sits behind `@media (hover: hover) and (pointer: fine)`. A hover handler in JavaScript checks `e.pointerType === "mouse"` and ignores mouse events for 50ms after a touch `pointerup`: iOS fires an emulated `pointerenter` with `pointerType: "mouse"` after every tap, so the type check alone doesn't catch it. And content scrolled under a still cursor doesn't open hover UI: a scrolled grid shouldn't lift every card it passes.
- **A long press is 500ms and survives 10px of wobble.** When it fires, the release doesn't also click. A quick press still does the default action at once ([presses-and-keys.md](presses-and-keys.md)).
- **On touch, a surface can scroll or take a gesture, not both.** A canvas, a map, a playground of draggable things inside a scrolling page: the first tap engages it and locks page scroll; tapping outside releases it. Otherwise every scroll that starts on it becomes a drag.

## Repetition

The first time costs a delay; the second time shouldn't. And anything people do hundreds of times a day can't make them wait for its animation.

- **Once one tooltip in a group is open, the rest open instantly, with no animation**, until 300ms after the last one closes. This needs one shared provider around the group: see [hover-and-timers.md](hover-and-timers.md) for Radix, Base UI, and the shadcn trap that breaks it.
- **Keyboard-driven changes don't animate.** A command menu opened with ⌘K, a highlight moving with the arrow keys, a list reordered by shortcut: show the result on the next frame. The user's hands are already ahead of the animation.
- **Hover highlights in menus and lists are instant.** A background that eases in trails the cursor one item behind.
- **Frequency decides how a write confirms.** In a tool used all day, update optimistically: a pending state on every change is friction. On a rare, consequential write (a contact form, a payment, a settings save), show the pending state so the user trusts it went through: the button disables at once, and the spinner appears after 150ms and stays at least 300ms, so it never blinks.
- **Holding means "again".** A stepper held down steps once, waits 400ms, then repeats every 60ms; Shift+arrow steps by 10. Key auto-repeat (`e.repeat`) drives things that step and is ignored by things that open, toggle, or submit. Double-clicks and trackpad swipes are repetition too: [presses-and-keys.md](presses-and-keys.md).
- **Typing jumps to an item.** Menus, selects, and lists match typed characters as one search that resets 1000ms after the last key; the same letter typed again cycles through the items that start with it ([menus-and-popovers.md](menus-and-popovers.md)).
- **A shortcut that triggers a button also shows the button pressed.** A keyboard shortcut never puts the button it triggers into `:active` (only Space held on a focused button does), so set a `data-pressed` attribute for ~150ms (the length of the press transition). Use an attribute, not a class: a React re-render rewrites `className` and wipes it a frame in.

## Limits

When a drag reaches the end of what it can do, the element keeps following the pointer, each pixel a little less than the last, and springs back on release. Things in the real world don't stop dead, they slow down first. A hard stop also breaks the one rule of a drag: the element is the pointer. With a hard stop the cursor carries on and leaves the thing it was holding behind.

```
Is the direction allowed at all?
├── No (a toast swiped up, a sheet pulled above its top)
│   → capped tension: it gives, but never more than ~20px.
└── Yes, it's the end of the range (a slider at 100%, a list at its first item)
    → iOS rubber band: follows at 0.55 at first, less with every pixel.
```

```ts
// iOS rubber band. `dimension` is the size of what's being dragged.
// Works in both directions: `over` is negative past the start.
const rubberBand = (over: number, dimension: number) =>
  Math.sign(over) *
  (1 - 1 / ((Math.abs(over) * 0.55) / dimension + 1)) *
  dimension;

// Capped (Sonner): 10px → 5, 50px → 12.5, never past `limit`.
const capped = (delta: number, limit = 20) =>
  delta / (1.5 + Math.abs(delta) / limit);
```

- **Motion's `dragElastic` is not tension.** It's a constant ratio: 0.2 moves the element 20% of every pixel, forever. For tension, apply a curve above in the drag handler.
- **A slider stretches.** Past 100% the track grows along the drag (iOS rubber band, with the track's width as the dimension) and thins across it, `scaleY = 1 - 0.3 * min(1, stretch / 40px)`, then springs back on release. The value stays at 100%.
- **A stretch never opens a gap.** A sheet pulled up shows the page under its bottom edge: extend its background with a `::after` 200% past the edge.
- **The return is a spring,** ~500ms with no bounce, the way iOS settles a rubber band. Clamp anything derived from the stretch at 0, so the track never ends up thicker than at rest.
- **Dragging toward the edge of a scroller scrolls it.** A reorder or a selection that reaches the outer 20% of its container scrolls, faster the closer it gets to the edge. A drag that can't reach past what's visible has a limit the user can't see.

## Speed

Distance alone ignores how people actually dismiss things: a quick, short flick. A sheet that only closes past 50% of its height makes them drag further than they meant to, then snaps back anyway.

- **Release decides on distance OR velocity**, and checks the direction is allowed before velocity counts.

| Dragged | Distance | Velocity |
| --- | --- | --- |
| Toast | 45px | 0.11 px/ms, gesture average (Sonner) |
| Sheet / drawer | 25% of its height | 0.4 px/ms gesture average (Vaul), or 500 px/s release velocity (Motion's `info.velocity`) |

- **A threshold only works with the method it was tuned on.** Sonner and Vaul divide total distance by total time; Motion's `info.velocity` is the speed at release, several times higher for the same flick. Never pair a release velocity with a gesture-average number. Snap points have their own rules in [dragging.md](dragging.md).
- **A pointer that sat still for ~90ms before release placed it; it didn't throw it.** Skip the velocity check and decide on distance.
- **The finish is a spring seeded with the release velocity,** so the element leaves at the speed it was moving, from where the finger left it. Where the throw lands in view (a sheet thrown to a snap point, a panel thrown to a corner, a dragged card settling back into its slot), a subtle bounce (≤ 0.2) shows the force the drag put in; the same element moved by a button gets none.
- **A snap-back is fast**: ~300ms, no bounce. A slow one reads as the UI arguing.
- **Changing their mind cancels the throw.** A swipe pulled back 10px from the furthest point it reached returns to rest, even past the distance threshold.
- **Motion's `dragMomentum` is on by default** and coasts to 0.8 × the release velocity. Anything that should land somewhere specific (a corner, a slot, a snap point) turns it off and picks the target itself.

Full release tree, throw projection, and the pointer lifecycle around it in [dragging.md](dragging.md).

## Paths

The pointer travels between parts of one interaction. If any point on that path counts as "outside", the interaction collapses halfway.

- **The hover target never moves.** If hovering a card lifts or scales it, the card slides out from under the pointer, hover ends, it drops back, hover starts: a flicker. Listen for hover on a parent that stays put, and animate a child.
- **Toolbar hit areas touch.** Space buttons with padding inside the hit area, not margins between them, or every crossing closes and reopens the tooltip.
- **Submenus keep a safe triangle** between the pointer and the submenu, so the diagonal route there doesn't cross into another item and close it. It engages only while the pointer heads toward the submenu; a flat grace timer makes every ordinary move in the parent menu lag.
- **Content the pointer moves into gets a close delay; a label doesn't.** A hover card waits ~300ms on leave so the trip across the gap doesn't close it. A tooltip closes at once.
- **Hover-held groups fill their gaps.** A stack of toasts, a trigger and its hover card: pseudo-elements cover the space between parts. An item animating out keeps its hit area until it's gone.

## Patience

The user's attention is elsewhere more often than the UI assumes. Anything on a timer waits for them, and any action in progress can be abandoned.

- **Presentation timers pause on hover, on press, on focus inside, and when the tab is hidden,** then resume from what was left, not from the start. A toast that expires while they read it, or in a tab they weren't looking at, was never seen. Track the reasons, since they overlap ([hover-and-timers.md](hover-and-timers.md)). Real deadlines, like a session expiry, never pause.
- **Pressing and dragging off a button cancels it; dragging back on re-arms it.** That's why buttons act on `click`, not `pointerdown`. Releasing back over the button still fires, as native buttons do.
- **A press that started inside never dismisses, wherever it ends.** Selecting text in a popover and letting go past its edge doesn't close it. On touch, an outside press dismisses on `click`, not `pointerdown`: a scroll that starts outside fires no click.
- **Hold-to-confirm is slow to commit, fast to let go.** The hold fills over ~2s on `linear` (it's showing time passing); releasing early drains it in ~200ms on `ease-out`. Mirror timing makes backing out feel like a second commitment.
- **Dismiss one layer at a time.** Escape or a click outside closes the topmost layer only. A select open inside a modal closes the select and leaves the modal: portalled popovers sit outside the modal in the DOM, so the modal's outside-click handler fires unless the library treats them as nested layers (Radix and Base UI do; hand-built ones need it).
- **Commit when the cost of a mistake allows it.** Something light (a peek, a search field pulled down) can commit mid-gesture once past its threshold, and reversing the gesture undoes it. Something destructive commits only on release and stays reversible until then.
- **Grabbing something mid-animation takes it over.** Stop the animation and hand the position to the pointer. This rules out CSS keyframes for anything a gesture can touch: they restart from zero.
- **A drag that ends on a button doesn't click it**: ignore clicks for ~300ms after a drag ends. **A flick that ends over an input doesn't focus it**: ignore focus for ~200ms after a fast release.

## Numbers worth memorizing

| | |
| --- | --- |
| First tooltip delay / skip window | 500ms / 300ms |
| Hover open: submenu / nav menu / hover card | 100ms / 200ms / 600ms at rest |
| Drag start threshold | 10px touch, 2px mouse |
| Tension | iOS: follows at 0.55, approaches the dimension; capped: ≤ 20px |
| Velocity, gesture average: toast / sheet | 0.11 / 0.4 px/ms |
| Velocity at release (Motion): sheet | 500 px/s |
| Distance: toast / sheet | 45px / 25% |
| Long press | 500ms, cancelled past 10px |
| Hold to repeat | first step at once, then 400ms, then every 60ms |
| Typeahead reset | 1000ms after the last key |
| Toast lifetime | 4000ms (6000ms with an action), paused while hovered, pressed, focused, or out of view |

The rest live next to the rule they belong to, in the section above or the reference file.

## Failure modes to catch

- Each tooltip waits its own delay as the pointer sweeps a toolbar → one provider, skip delay 300ms.
- Tooltips flash on as the cursor passes (shadcn's per-tooltip provider at `delayDuration = 0`) → one provider at 500ms.
- An instant tooltip still fades in → `[data-instant]` / `[data-state="instant-open"]` gets `transition-duration: 0ms`.
- A slider or sheet stops dead at its limit and the cursor carries on without it → tension past the end, spring back on release.
- `dragElastic={0.2}` as the "rubber band" → a constant ratio, not tension; use a curve.
- A sheet that only closes past a distance → add the velocity check.
- A scroll inside a sheet that overshoots the top and closes the sheet → scroll lock and the scrolled-ancestor check.
- A toast that keeps counting down while hovered, or in a background tab, or restarts from 4000ms on every leave → pause, then resume from what was left.
- A dead strip between toolbar buttons that closes the tooltip mid-sweep → hit areas that touch.
- A ⌘K menu that animates open → no animation for keyboard-triggered UI.
- Dragging a panel by its button also clicks the button → swallow the click after a drag.
- A card that lifts on hover flickers at its edge → hover on a parent that stays put, animate a child.
- Clicking outside a select inside a modal closes both → dismiss the topmost layer only.
- A plain click on a select re-picks the value under the cursor and closes it, or a page scroll on touch opens it → the opening guards in menus-and-popovers.md.
- Moving down a menu feels laggy, or submenus flash open on the way past → a 100ms open delay and a direction-aware safe area, not a grace timer.
- Arrowing through a list, the item under the idle cursor steals the highlight, or hovering the last item scrolls the list away → highlight on `pointermove`, focus with `preventScroll`.
- Every row lights up as the thumb scrolls a list → delay the touch press look, cancel the press on scroll.
- Enter in a Japanese IME sends the message mid-word → skip while composing (presses-and-keys.md).
- One trackpad swipe skips five carousel slides → one step per wheel gesture.
- A panel let go with Motion drag glides past its target → `dragMomentum={false}`, pick the target on release.

## Reporting

When you finish, list each interaction you changed with the question from the walk that caught it, what it did before, and what it does now, with the number that decides it ("Toolbar tooltips · Repetition · each waited 500ms → first waits 500ms, the rest open instantly within 300ms"). Then list what you checked and left alone, so the reader knows it was considered. If a detail needs a real device to judge (touch thresholds, flick velocity), say so instead of calling it done.

## Going deeper

- [dragging.md](dragging.md) — when a pointerdown becomes a drag, tracking, tension curves, the release tree, velocity, and the pointer lifecycle after
- [hover-and-timers.md](hover-and-timers.md) — tooltip groups in Radix, Base UI, and shadcn, hover intent, gap filling, and timers that pause and resume
- [menus-and-popovers.md](menus-and-popovers.md) — opening and picking in menus and selects, context menus, highlighting, typeahead, submenus and the safe triangle, hover-opened surfaces, dismissing
- [presses-and-keys.md](presses-and-keys.md) — the life of a press, long press, hold to repeat, double-click, IME and key repeat, wheel, trackpad, and pinch
