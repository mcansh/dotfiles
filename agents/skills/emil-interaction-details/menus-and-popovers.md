# Menus, Selects, and Popovers

Everything that opens from a trigger and holds a list or a card: dropdown menus, selects, context menus, submenus, navigation menus, hover cards. The numbers come from Radix, Base UI, and React Aria. Where they disagree, this file picks one and says why.

All three libraries already do most of this. Before hand-building a menu, check for one; asked to fix a hand-built one, walk it through the sections below.

## 1. Opening

```
How did the press arrive?
├── Mouse, primary button, no Ctrl → open on pointerdown.
│   Press-drag-release then picks an item in one motion, the way native menus work.
├── Touch or pen → open on click.
│   A scroll that starts on the trigger never fires a click, so it never opens the menu.
└── Keyboard (Enter, Space, ArrowDown) → open with an item highlighted (below).
```

This is Radix Select's pattern. Radix DropdownMenu opens on `pointerdown` for every pointer type, so a Radix dropdown in a scrolling list on touch doesn't follow it; mention that in your report instead of patching the library.

What's highlighted on open depends on what the list is:

- **An action menu** opened by the keyboard highlights its first item (ArrowUp: its last). Opened by a pointer, it highlights nothing: a highlight under a pointer that hasn't moved makes Enter do something the user never chose.
- **A select** opens on its current value, however it was opened, scrolled so that value sits under the trigger. With no value, it falls back to the first enabled option.

- **The release from the opening press doesn't pick anything unless the pointer travelled.** A select lines its current item up under the trigger, so the `pointerup` of a plain click lands on an item. Ignore that `pointerup` if the pointer moved 10px or less since `pointerdown` (Radix). Base UI uses time instead: no pick for 200ms after opening, 400ms for the item lined up under the trigger. Use one or the other: with neither, every click on a select re-picks the current value and closes it.
- **Press, drag, release outside the menu closes it.** The trigger gets ~2px of slack so a trembling click doesn't count as leaving. The user dragged out on purpose: they've abandoned the menu.
- **The trigger is not "outside".** A press on the trigger of an open menu closes it once. If the outside-press handler counts the trigger as outside, it closes the menu and the trigger's own handler opens it again.
- **On a Mac, Ctrl+click is a right-click.** A left-click handler that opens on `pointerdown` checks `e.button === 0 && !e.ctrlKey`, or the dropdown and the context menu open together.

```tsx
// Radix Select's pattern. pointerdown handles the mouse; click handles touch, pen,
// and the click a keyboard or screen reader fires (detail === 0).
// openList(via) applies the highlight rules below: a select always opens on its
// value; an action menu highlights "first"/"last" only when opened by keyboard.
const pointerType = useRef("touch");

<button
  type="button" // inside a form, a bare <button> submits it
  onPointerDown={(e) => {
    pointerType.current = e.pointerType;
    if (e.pointerType === "mouse" && e.button === 0 && !e.ctrlKey) {
      // Stops the trigger from taking focus back from the list that just opened,
      // and from starting a text selection.
      e.preventDefault();
      open ? close() : openList("pointer");
    }
  }}
  onClick={(e) => {
    if (e.detail === 0) openList("first"); // Enter or Space
    else if (pointerType.current !== "mouse") open ? close() : openList("pointer");
  }}
  onKeyDown={(e) => {
    if (e.key === "ArrowDown" || e.key === "ArrowUp") {
      e.preventDefault();
      openList(e.key === "ArrowDown" ? "first" : "last");
    }
  }}
/>
```

### Context menus

- **Right-click opens on `contextmenu`, and the release decides.** Released over an item, at any time, it picks that item (press-drag-release). Released anywhere else: within 500ms the menu stays open for a normal pick; later, it closes, because the user held, looked, and let go. Either way, the press that opened the menu can't also dismiss it as an outside press (Base UI holds outside-press dismissal for 500ms after a context menu opens, which also covers the release of a touch long press).
- **On touch, it's a long press**: 500ms, cancelled by more than 10px of movement (the long-press rules in [presses-and-keys.md](presses-and-keys.md)).

## 2. Highlighting

- **Highlight on `pointermove`, not `pointerenter`, and only for `pointerType === "mouse"`.** Arrowing through a list scrolls items under a pointer that isn't moving; `pointerenter` fires on them and steals the keyboard's highlight. With `pointermove`, the highlight only follows the pointer when the hand actually moves, and a small wiggle after arrowing hands it back to the item under the cursor, as native menus do. `pointerleave` clears it.
- **The pointer never scrolls the list; the keyboard does.** A hover highlight focuses with `focus({ preventScroll: true })`. Otherwise hovering a half-visible last item scrolls the list, a new item slides under the cursor, gets hovered, scrolls again, and the list runs away. The keyboard highlight calls `scrollIntoView({ block: "nearest" })`, so it moves only as far as needed and never re-centers.
- **The highlight is instant.** No transition on its background (see Repetition in the skill).

## 3. Typeahead

Menus, selects, listboxes, and trees jump to an item when the user types its name.

- **The typed characters accumulate into one search, reset 1000ms after the last key** (Radix and React Aria; Base UI uses 500ms, which cuts off slower typists mid-word).
- **Typing the same letter again cycles** through the items starting with it: `b`, `b`, `b` steps through Banana, Blueberry, Brie.
- **A single letter searches from the item after the current one; a longer search starts at the current one.** Both wrap. Matching from the top every time would never get past the first match, and skipping the current item on "ba" would jump off a Bacon that still matches.
- **Space is part of the search while the buffer isn't empty.** Typing "new y" otherwise selects the item highlighted at "new ".

```ts
const search = useRef("");
const timer = useRef<number | undefined>(undefined);

// Call first in the list's keydown handler. null: not a typeahead key, let the
// list handle it. A number: the key went into the search, so preventDefault()
// and highlight that index (unchanged if nothing matched), and skip the list's
// own Space activation, on keyup too. `current` is -1 when nothing is highlighted.
function onTypeahead(e: KeyboardEvent, labels: string[], current: number): number | null {
  if (e.key.length !== 1 || e.metaKey || e.ctrlKey || e.altKey) return null;
  if (e.key === " " && search.current === "") return null; // Space selects

  search.current += e.key.toLowerCase();
  clearTimeout(timer.current);
  timer.current = window.setTimeout(() => (search.current = ""), 1000);

  // "bbb" is one letter repeated: cycle on that letter.
  const s = search.current;
  const query = [...s].every((c) => c === s[0]) ? s[0] : s;

  // One letter moves on from the current item; a longer query starts at it,
  // so "b" → Bacon, then "ba" stays on Bacon instead of jumping to Bagel.
  const start = query.length === 1 ? current + 1 : Math.max(current, 0);
  for (let i = 0; i < labels.length; i++) {
    const index = (start + i) % labels.length;
    if (labels[index].toLowerCase().startsWith(query)) return index;
  }
  return current;
}
```

## 4. Submenus

- **A submenu opens after ~100ms of hover** (Radix, Base UI). Opening on `pointerenter` flashes every submenu the pointer crosses on its way down the parent. Longer, and it reads as broken. The arrow pointing toward the submenu opens it at once and highlights its first item; the one pointing back closes it and returns to the parent item. In a right-to-left layout those are ArrowLeft and ArrowRight respectively: resolve them from the writing direction, not hard-coded.
- **A safe area that reads the pointer's direction, not a timer, keeps it open.** On its way to the submenu the pointer crosses other parent items diagonally. A flat grace timer makes every ordinary up/down move in the parent feel laggy. React Aria's version is the simplest to hand-build:
  - On each `pointermove` (throttled to 50ms), take the angle of the move from the previous position. It's heading for the submenu if it points between the submenu's near top and near bottom corners, with that cone widened by 15° on each side.
  - While it's heading there, the parent's items ignore the pointer: `pointer-events: none` on the parent menu.
  - A move in any other direction hands the pointer straight back, and the item under it takes the hover as usual. Moving up and down the parent never waits.
  - A pointer that stops on its way gets 1000ms, then the item under it wins. Generous enough for someone with a tremor, short enough that a pause isn't a trap.
  - Drop it once the pointer lands in the submenu, and skip it entirely for touch and pen.

  Radix and Base UI draw a polygon from the point where the pointer left the item (Radix offsets it 5px back) to the submenu's near edge instead, and Base UI also gives up when the pointer slows below 0.1px/ms inside it. Same behavior; pick one approach.

## 5. Opening on hover

Different surfaces wait for different lengths of time before opening, because they cost different amounts when they open by accident:

| Surface | Open | Close | Why |
| --- | --- | --- | --- |
| Submenu | 100ms | when the safe triangle gives up | Small, attached to where the pointer already is |
| Navigation menu | 200ms, then instant for 300ms after one closes | 150ms | The pointer heading for the page crosses the nav bar; once one is open the user is browsing (Radix's numbers) |
| Tooltip | 500ms, then instant for 300ms | at once (~100ms fade) | [hover-and-timers.md](hover-and-timers.md) |
| Hover card / preview | pointer at rest for 600ms | 300ms | Covers content, so it needs real intent; holds rich content the pointer moves into |

- **"At rest" means the timer restarts on every movement.** Moves smaller than about 1.4px (`movementX² + movementY² < 2`, Base UI) are hand tremor and don't restart it. A card that opens 600ms after the pointer arrived, even though it kept moving, opens on everything the pointer drifts across.
- **Content the pointer moves into gets a close delay; a label doesn't.** A tooltip closes at once because nothing inside it is reachable. A hover card or nav panel waits ~150–300ms on `pointerleave`, so the trip across the gap from the trigger doesn't close it.
- **A hover-opened popover ignores a click on its trigger for 500ms** ("patient click", Base UI). The user was already clicking when hover opened it, and without this the click toggles it straight shut.
- **A hover card stays open while text inside it is selected, or while the pointer is down inside it.** Someone selecting a line in it drags out of its bounds; that's not leaving.
- **Hover-opened surfaces need a non-hover way in.** Focus opens them too, and on touch the trigger's tap is its own action (follow the link), so the card never shows. Nothing that's only in a hover card.

## 6. Dismissing

- **A press that started inside never dismisses, wherever it ends.** Selecting text in a popover and releasing outside it, or dragging a slider out of its bounds, is still using the popover. Remember where the `pointerdown` landed and ignore the release if it was inside.
- **A press that starts outside dismisses on `pointerdown` with a mouse, on the outside `click` on touch.** A scroll that starts outside fires `pointerdown` and no `click`, so on touch the popover survives a scroll.
- **Topmost layer only.** Escape and outside presses close the top layer; a select inside a modal closes the select and leaves the modal (see Patience in the skill).
- **Escape while an IME is composing doesn't close anything.** It cancels the composition. Track it yourself: set a flag on `compositionstart` and clear it on `compositionend`, after 5ms on Safari (Base UI; 0–1ms isn't enough), because Safari fires `compositionend` before the Escape `keydown` that ended it. Checking `e.isComposing` alone misses that keydown on Safari.
- **Where focus goes in a menu or popover depends on how it closed.** Escape, or picking an item, returns focus to the trigger. Closing by clicking elsewhere leaves focus where the click put it; pulling it back to the trigger would undo what the user just did. Modal dialogs always return focus (`/emil-touch-and-accessibility`).
