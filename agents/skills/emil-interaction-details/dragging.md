# Dragging

Everything a hand-built drag needs, in the order a gesture happens: deciding whether to start, tracking, going past the edge, letting go. The numbers come from Vaul (drawers), Sonner and Base UI (toasts), Lapse (a draggable panel full of buttons), and dnd-kit and React Aria (reordering).

Before building any of this, check whether the gesture already exists in a library the project has. A bottom sheet is Vaul, a swipeable toast is Sonner. Asked to build one from scratch, use them. Asked to fix a hand-written one, fix it in place with the rules below, and mention the library in your report instead of migrating unasked.

## 1. Starting: should this pointerdown become a drag?

Walk these checks in order on `pointerdown`/the first `pointermove`. Any "no" means the browser keeps the gesture: scroll, select, click.

```
Is it the primary button? (e.button === 0)
└── No → not a drag. Right-click opens the context menu, not a swipe.
Did it start on a child with a gesture of its own (input, textarea, select, slider, contenteditable, [data-no-drag])?
└── Yes → not a drag. The child owns the pointer.
    Buttons and links are not on this list: they can start a drag past the threshold below, and their click is swallowed if it became one (section 5).
Is text selected? (getSelection().toString().length > 0)
└── Yes → not a drag. The user is selecting, and a drag would throw the selection away.
Only for a container with scrollable content inside (a sheet, a drawer), when the pointer went down on that content:
│   Did it open less than 500ms ago?
│   └── Yes → not a drag. It's still animating in, and the finger is probably mid-scroll.
│   Is any scrollable ancestor between the pointer and the sheet scrolled away from its start?
│   └── Yes → not a drag. They're scrolling the content, not moving the container.
│   Did the content hit its top less than 100ms ago?
│   └── Yes → not a drag. A fast scroll that overshoots the top must not turn into a close.
│   Is it moving toward the open direction (up, on a bottom sheet) over content that can still scroll that way?
│   └── Yes → not a drag. The list scrolls. Only when nothing can scroll does the sheet take it, with tension (section 3).
│   (A handle, a slider, a card, a floating panel skip these four: they have no content to scroll, and they stay grabbable even mid-animation.)
Has the pointer moved past the start threshold on the drag axis?
├── Not yet → wait. Under 10px on touch, 2px with a mouse, 6px with a mouse on a draggable full of buttons (Lapse's panel), so a slightly shaky click stays a click.
├── Moved further on the other axis → drop the gesture. A horizontal swipe inside a sheet is a carousel, not a close.
└── Yes → it's a drag. From here it stays a drag until release.
```

Why each one exists:

- **The 100ms scroll lock** is from Vaul. People scroll fast on phones, so a flick that scrolls a sheet's content to the top keeps going and lands on the sheet itself, often fast enough to pass the velocity check and close it. Ignoring drags for 100ms after the content reaches the top separates "I was scrolling" from "now I'm dragging".
- **The start threshold** stops a tap from becoming a 1px drag and stops a button inside a draggable panel from losing its click. Touch gets more slack (10px) than a mouse (2px) because fingers wobble.
- **Once allowed, always allowed.** Never re-run the checks mid-gesture. A drag that stops halfway because some check flipped feels broken.
- **Lock the axis once** it's decided, by whichever delta was larger past the threshold. From then on only that axis moves.
- **Anchor the drag where it crossed the threshold,** not where the pointer went down, so the element starts moving from rest instead of jumping 10px to catch up.

## 2. Tracking: the element is the pointer

- Move it 1:1 with the pointer. No transition, no easing, no spring during the drag. Set `transition: none` on the element (and anything linked to it) when the drag starts, and restore it on release.
- Write `transform` on the element itself. Not React state per `pointermove`, and not a CSS variable on a parent: every write recalculates styles for all its descendants (it made Vaul lag with ~20 list items inside).
- **1:1 is for things being moved, not things reacting.** A sheet, a slider, a card being dragged follow the pointer exactly. Decorative things that react to the pointer (a tilt, a glow that follows the cursor, a parallax layer) go through a spring, because nothing in the real world snaps to a new position instantly. If it carries information (a chart's crosshair, a value readout), it's 1:1 again.
- Drive linked values (overlay opacity, the background's scale, a radius) from the same drag progress, so they can't drift: `opacity = 1 - progress`.
- **Ignore every pointer after the first** until release. A second finger otherwise makes the element jump to it.
- **Once the drag passes its threshold,** set `user-select: none` on the element and clear any selection the first pixels started (`getSelection()?.removeAllRanges()`). Not before: a press that never becomes a drag should still be able to select text.
- **Pointer capture:**
  - The draggable has no buttons inside (a sheet, a toast): capture on `pointerdown`, so the drag survives the pointer leaving the element.
  - The draggable is full of buttons (a toolbar, a panel): capture only once the drag passes its threshold. Capturing at `pointerdown` retargets the buttons' clicks to the panel.
- During the drag, `preventDefault()` `dragstart` and `selectstart`. Links and images under the pointer otherwise start a native drag-and-drop, and Chrome cancels the pointer stream.
- **End the drag exactly once, and know whether it was committed or cancelled.**
  - `pointerup` commits: run the release decision in section 4.
  - `pointercancel`, `lostpointercapture` without a `pointerup`, and `contextmenu` cancel: the browser or the OS took the pointer, so the user never let go on purpose. Stop tracking and return to rest; never let a cancel dismiss on velocity.
  - **Escape cancels too.** It returns the element to where the drag started, with nothing committed (native drag and drop and dnd-kit do this; hand-built drags almost never do).
  - Guard the end with a flag, since `lostpointercapture` also fires after a normal `pointerup`. (Not `pointerout`: it bubbles, and fires every time the pointer crosses into a child.)

## 3. Past the edge: tension, not a wall

When the drag reaches a limit (a sheet fully open, a slider at 100%, a list's first item), the element keeps following the pointer, but each extra pixel moves it less. Nothing in the real world stops dead; it slows down first. A hard stop also makes the element detach from the pointer: the cursor keeps going and leaves the thing it was holding behind.

Pick the curve by what the element is allowed to do:

```
Can the element legitimately move further in this direction?
├── No, the direction is wrong (a toast swiped up, a sheet pulled above its top)
│   → capped: it gives a little and never more than ~20px.
└── Yes, but this is the end of its range (a slider at max, a list at its end)
    → iOS rubber band: follows at 0.55 at first, less and less after.
```

```ts
// Capped (Sonner). 10px → 5, 50px → 12.5, 100px → 15.4, never past 20.
function capped(delta: number, limit = 20) {
  return delta / (1.5 + Math.abs(delta) / limit);
}

// iOS rubber band. `dimension` is the size of the thing being dragged
// (the track's width, the sheet's height): bigger things stretch further.
function rubberBand(overshoot: number, dimension: number, c = 0.55) {
  const sign = Math.sign(overshoot);
  const x = Math.abs(overshoot);
  return sign * (1 - 1 / ((x * c) / dimension + 1)) * dimension;
}
```

Rules that go with it:

- **Motion's `dragElastic` is linear**: 0.2 moves the element 20% of every pixel, forever. That's a weaker drag, not tension. For tension, set `dragElastic={0}` and apply one of the curves above in `onDrag`, or drive the position from a motion value yourself.
- **Fill the gap the stretch opens.** A sheet that rubber-bands upward shows the page under its bottom edge. Extend its background past the edge: `::after { content: ""; position: absolute; top: 100%; left: 0; right: 0; height: 200%; background: inherit; }`.
- **A stretched control can change shape.** A slider track pulled past its end grows along the drag and thins across it, `scaleY = 1 - 0.3 * Math.min(1, stretch / 40)`, the way iOS volume sliders do. It reads as material being pulled. The value stays at its limit.
- **Release always returns to the limit** on a spring, about 500ms with no bounce, the way iOS settles a rubber band. Keep any value derived from the stretch clamped at 0, so a spring that overshoots never makes the track thicker than at rest or the value dip under its limit.
- A dampened direction can still produce a fast flick. Check the direction is allowed before letting velocity dismiss anything.

## 4. Letting go: distance OR velocity

A release decides between "go" and "come back". Distance alone ignores flicks: a fast, short swipe snaps back, and the user has to drag further than they meant to. Always check both:

```
On release:
├── Ended back at or past the rest position, or moving toward it at release → return to it.
├── Pulled back 10px or more from the furthest point it reached → return to it, even past the distance threshold.
│   They went far, changed their mind, and started bringing it back (Base UI's toast).
├── Velocity over the threshold, in an allowed direction → go (dismiss, next snap point).
├── Distance over the threshold → go.
└── Otherwise → come back, fast.
```

**A velocity threshold only means something with the method it was tuned on.** There are two, and their numbers are not interchangeable:

- **Gesture average**: total distance ÷ time since `pointerdown`. What Sonner and Vaul compute. It includes the slow start, so it reads far lower than the speed at release.
- **Release velocity**: speed over the last ~100ms of movement. What Motion's `onDragEnd` gives you as `info.velocity` (in px/s). It reads several times higher for the same flick.

| What's dragged | Distance | Gesture average | Release velocity |
| --- | --- | --- | --- |
| Toast swipe-to-dismiss | 45px | 0.11 px/ms (Sonner) | |
| Sheet / drawer close | 25% of its height | 0.4 px/ms (Vaul) | 500 px/s |
| Snap points: move one | dragged < 40% of the viewport | > 0.4 px/ms: exactly one point in the drag direction (Vaul) | |
| Snap points: skip | | > 2 px/ms: jump to the last point, or close (Vaul) | |

Light, small things dismiss on a gentler flick than big ones. Pick the column that matches how your code measures, and never pair a release velocity with a gesture-average number: at 110 px/s measured at release, almost any toast still moving gets dismissed.

**A pointer that sat still for ~90ms before release placed the element; it didn't throw it.** Whatever the method, skip the velocity check and decide on distance alone.

Throwing to one of several targets (a panel to a corner): take the release velocity, project the release ~140ms ahead (capped at ~400px), and pick the nearest target to the projected point. Above ~0.55 px/ms, direction beats distance: pick the target best aligned with the throw.

**Motion's `dragMomentum` is on by default, and it glides far.** On release it coasts to 0.8 × the release velocity (a 1000 px/s release travels 800px) over a 750ms time constant. That suits a free-floating canvas object. Anything that lands on a target (a panel, a card back in its slot, a snap point) gets `dragMomentum={false}`, and the release decision above picks where it goes.

After release:

- **Finish on a spring seeded with the release velocity,** so the element leaves at the speed it was moving. A fixed-duration ease makes every throw land the same way. Where the throw lands in view (a sheet thrown to a snap point, a panel thrown to a corner, a dragged card settling back into its slot), a subtle bounce (≤ 0.2) shows the force the drag put in; the same element moved by a button gets none. Something thrown off-screen gets no bounce: it would happen where no one sees it.
- **The exit starts where the finger left it** and continues in the swipe's direction. A toast swiped right leaves to the right from where it was, not from its resting spot.
- **Coming back is fast**: a spring around 300ms with no bounce. A slow snap-back reads as the UI arguing with the user.
- **A grab mid-animation takes over.** Stop the running animation and hand the position to the pointer. Springs and transitions allow it; CSS keyframes restart from zero and can't be caught.

## 5. After the drag

- **Swallow the click that ends a drag** started on a button: ignore clicks for ~300ms after a drag ends. Otherwise dragging a panel by its button also presses the button.
- **Don't let a released flick focus an input.** After a fast release, ignore focus for ~200ms. The finger lifting over an input wasn't a tap on it.
- On the handle of a sheet: a 250ms long-press cancels the tap action (they were about to drag), and a second tap within 120ms cancels the first (a double tap isn't two taps).
- A sheet's handle is a thin bar; its hit area isn't: `width: max(100%, 44px); height: max(100%, 44px)` on an invisible child.
- **While anything is being dragged, nothing else reacts to hover.** Buttons the dragged element passes over don't light up and tooltips don't open (Motion does this for its own gestures). The pointer is busy.

## 6. Reordering and dropping

- **On touch, a reorder without a handle starts on a hold**, not on distance: ~250ms with ~5px of tolerance (dnd-kit's documented setting). With only a distance threshold, every vertical scroll that starts on a row becomes a drag. With a handle, the handle gets `touch-action: none` and drags at once.
- **Dragging near the edge of a scroll container scrolls it.** In the outer 20% of the container (dnd-kit), speed grows the closer the pointer gets to the edge. Without it you can't move an item past what's visible.
- **Hovering a dragged item over a closed target opens it after ~800ms** (React Aria; macOS spring-loaded folders): a collapsed tree row expands, a tab switches. The user's hands are full, and this is the only way to reach a target they can't click.
- **The dragged item leaves a gap where it would land,** and the other items move out of its way on a spring. The pointer is busy, so the gap is the only answer to "where will this go?".

## 7. CSS for the surface

```css
/* The sheet is a gesture surface: the browser shouldn't pan it. */
.sheet { touch-action: none; }
/* touch-action only applies up to the nearest scroll container, so a list
   inside the sheet still scrolls natively. Keep its scroll from chaining
   to the page. */
.sheet .list { touch-action: pan-y; overscroll-behavior: contain; }
/* A horizontal carousel keeps vertical page scroll. */
.carousel { touch-action: pan-y; }
```

When the list is at its top and the pull is downward, the drag handler takes over from native scroll by calling `preventDefault()` in a non-passive `touchmove` listener on the list. This is the one place that listener is right (`/emil-mobile-native` rules it out for scroll chaining, which `overscroll-behavior` handles): only on the list, only at its top, only while pulling down. Check this one on a real iPhone: it's where hand-built sheets most often fail.
