# Presses, Holds, and Keys

What happens between a press and the action it causes, with a finger, a mouse, a key, or a wheel. The numbers come from React Aria (`usePress`, `useLongPress`, `useSpinButton`), Base UI, and Lapse.

## 1. The life of a press

```
pointerdown on the target       → show pressed (on touch inside a scroller, wait ~100ms first)
pointer leaves the target       → drop the pressed look; the press is still alive
pointer comes back              → pressed look returns
release over the target         → fire
release anywhere else           → nothing
an ancestor scrolls             → cancel: no pressed look, nothing fires
pointercancel                   → cancel
```

- **Sliding back on re-arms the press.** Leaving cancels the look, not the press. A thumb that slips off the edge and back still clicks on release, as native buttons do. Judge "over the target" by the finger's contact area (`pointer.width`/`height` around the point), not the single point, so a fat-finger release at the edge still counts.
- **Scrolling cancels a press.** While a press is held, listen for `scroll` on the document in the capture phase; any ancestor scrolling cancels it. Otherwise a touch that became a scroll leaves a stuck pressed state, or fires when the finger lifts.
- **On touch, a row inside scrolling content waits ~100ms before showing pressed** (Android's tap timeout; iOS delays content touches by about 150ms). Showing it on `pointerdown` lights up every row the thumb scrolls across. `:active` can't be delayed (a `transition-delay` on it does nothing useful), so drive the row's pressed look from a `data-pressed` attribute: set it from a 100ms timer started on `pointerdown`, clear it on scroll, `pointercancel`, or release, and don't style `:active` on these rows. A tap that lifts before the 100ms still sets it on release, for about 100ms, so the tap visibly registers. Buttons outside a scroller show pressed immediately, as `/emil-mobile-native` says.
- **JS hover handlers ignore touch.** `@media (hover: hover) and (pointer: fine)` gates CSS hover; a `pointerenter` handler has to check `e.pointerType === "mouse"` itself. iOS fires an emulated `pointerenter` with `pointerType: "mouse"` right after a tap, so also ignore mouse events for 50ms after any touch `pointerup` (React Aria). Media queries alone also fail on hybrid devices: a touch laptop matches `hover: hover`.
- **A control that acts on `pointerdown` ignores the `click` that follows.** A stepper or a menu trigger that already acted would act twice. Keep the `click` only when `e.detail === 0`: that click came from a keyboard or a screen reader, not the pointer.
- **Buttons inside an input never take its focus from a pointer.** A clear button, a stepper, a password reveal: `preventDefault()` on `mousedown` and act on the input. Otherwise pressing one moves focus off the input, the caret is lost, and on a phone the keyboard closes. Keyboard access is a separate question: a stepper can leave the tab order, because the arrow keys in the input do the same thing; a clear button or a password reveal has no equivalent key, so it stays focusable.

## 2. Long press

- **500ms, cancelled by more than 10px of movement.** 500ms is React Aria's and Base UI's default; the 10px tolerance is Base UI's context menu (iOS uses 500ms and 10pt). Radix's context menu waits 700ms and cancels on any movement at all, which a finger can't hold still enough for.
- **When it fires, the release doesn't also click.** Mark the press as consumed and swallow the next `click`.
- **Suppress the native callout and selection on the target**: `-webkit-touch-callout: none` and `user-select: none` while held. iOS turns selection back on as you lift, and can still start one if you restore it immediately; React Aria restores it 300ms after release.
- **Quick press acts, held press reveals.** If the control has a default, the tap does it with no extra UI; the hold shows the choices (⌘Tab switches straight to the last app; holding shows the switcher). Never make the common case wait 500ms to find out it wasn't a hold.
- **A long press always has another way in**: right-click, a visible "more" button, a keyboard shortcut. People don't discover it on their own.

## 3. Hold to repeat

- **Steppers step once on press, then repeat after 400ms, every 60ms** (React Aria, Base UI). Stop at the min or max. Agents either never repeat, so going from 1 to 40 is 39 clicks, or repeat with no initial delay, so one click steps twice.
- **On touch, a moving finger stops the repeat.** More than ~8px of movement means it's a scroll that started on the stepper, and the value must not keep changing under it (Base UI).
- **Modifier keys change the step.** Shift+arrow or PageUp/PageDown step by 10, Home/End jump to the min/max (WAI-ARIA slider pattern; Figma nudges 1 and 10). Wire only the arrow keys and moving a value by 200 takes 200 presses.
- **Key auto-repeat is for things that step, not things that toggle.** Arrow navigation and steppers accept `e.repeat`. Anything that opens, toggles, or submits ignores it: holding Enter on a menu button otherwise opens the menu, then the repeats pick an item.

## 4. Double-click

- **Read `e.detail`, don't run a timer.** `detail` counts clicks at the user's OS double-click speed; a hand-rolled 300ms timer fights their setting.
- **Never delay the single click to see if a second one comes.** Design the single click as the first half of the double: click selects, double-click opens. Waiting makes every single click lag.
- **Rapid clicks don't select text.** `onMouseDown={(e) => { if (e.detail > 1) e.preventDefault(); }}` on a stepper or a button pressed in quick succession, or double-clicking + selects the label next to it.

## 5. Keys

- **Never fire a shortcut while an IME is composing.** In Japanese, Chinese, or Korean input, Enter confirms the word being composed. Check `e.isComposing || e.keyCode === 229` before Enter-to-send or single-letter shortcuts. Safari fires `compositionend` before the keydown that ended the composition, so where it matters (Enter-to-send, Escape-to-close) also track composition with a flag cleared 5ms after `compositionend` ([menus-and-popovers.md](menus-and-popovers.md)).
- **On a Mac, Ctrl+click is a right-click.** Anything that acts on a left `pointerdown` checks `e.button === 0 && !e.ctrlKey`, or it fires along with the context menu.
- **Single-letter shortcuts don't fire while typing** in an input, a textarea, or `contenteditable`.
- **A shortcut shows the button pressed**, keyboard-driven changes don't animate: both are in the skill's Repetition section.

## 6. Wheel and trackpad

- **A trackpad swipe is one gesture, not dozens of events.** It sends a burst of `wheel` events with a long inertia tail. Treat the burst as one gesture that ends after ~150ms of silence (Lapse), pick its axis once from the first events (`|deltaX| > |deltaY|`), and normalize line-mode deltas (`deltaMode === 1`) at 16px per line. Anything discrete driven by the wheel (a carousel, a page flipper, a stepped timeline) moves one step per gesture, or one swipe skips five slides.
- **The wheel changes a number field only while it's focused.** Over a focused field it steps the value and calls `preventDefault()` so the page doesn't scroll as well; over an unfocused one it scrolls the page. Otherwise scrolling past a form silently edits it.
- **A wheel event with `ctrlKey` is a trackpad pinch** (or Ctrl+wheel). Pass it through on scrollable content; on a zoomable canvas it's the zoom.
- **Zoom around the cursor, and multiply.** Keep the point under the cursor (or the pinch's starting midpoint) fixed on screen, and scale by a factor, never by adding to the scale. Zooming around the center makes people pan back to what they were pointing at. Pinch deltas are small and a mouse-wheel notch is around 100, so clamp before scaling: `scale *= Math.exp(-clamp(e.deltaY, -10, 10) * 0.01)`.
- **Scrubbing a value by dragging uses pointer lock** (`requestPointerLock()`), so the cursor never hits the edge of the screen mid-drag, and steps once per few pixels of accumulated movement (Base UI: 2px). Skip pointer lock on touch, where there's no cursor to lose.
