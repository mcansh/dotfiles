---
name: emil-package-my-work
description: Package UI and motion work as short, high-res videos for X, newsletters and launch posts. Covers composed explainers rendered frame by frame from HTML, hover reels of live components, click-throughs of one live component with a real macOS cursor, recording pages you screen-record yourself, and adding a touch cursor to a phone recording. Use when asked to make, render, record, re-cut or shorten a video, reel, clip or demo, or to build a page to record from. Triggers on: video, make me a video, record, recording, recording page, reel, clip, mp4, 4k, render, for X, for twitter, tweet video, demo video, hover reel, cursor, touch cursor, fps, ffmpeg, frames, shorten the video, make it faster, package my work.
---

# Package My Work

These videos are watched on a phone in the X timeline: muted, small, and scrolled past. Every rule below follows from that. A viewer has to get the demo in the first second, with no sound.

## 1. Pick the mode

```
What is being asked for?
├── A composed explainer: several demos, side-by-side comparisons, easing graphs
│   → standalone index.html with window.render(t) + scripts/render.cjs        (§7a)
├── Many live items hovered one after another (cards, icons, thumbnails)
│   → temporary reel route in the app + scripts/reel.cjs                      (§7b)
├── One live component, clicked through (switcher, toggle, tabs, before/after)
│   → temporary route with #stage + scripts/click.cjs                         (§7c)
├── "Put it on a page so I can record it"
│   → a recording page in the app; nothing is rendered                         (§8)
└── The user sends a recording (.mov) and wants a touch cursor or an edit
    → scripts/touch-cursor.py on their file                                    (§9)
```

Never deliver a video you captured in real time: no screen capture, Playwright `recordVideo` or real-time playback. Playwright's webm is low-bitrate with ghost frames, and real-time capture drops frames. Every rendering mode here steps time one frame at a time. The user's own recordings (§8, §9) are the only real-time footage.

## 2. Show one look before the full render

1. Before any full render, send 2–4 stills, or for a reel or click-through a clip of one item. Wait for a go. The look takes several rounds to get right, and a full render costs minutes every round.
2. When the user asks for a change, re-send only the frames it affects.
3. Once the look is approved, apply timing-only changes and do the full render straight away, without another preview round.

## 3. Frame and format

- **Explainers:** 1080×1080 CSS at DSF 2, giving 2160×2160. 16:9 reads as too wide in the timeline. Use 1920×1080 at DSF 2 only when the content is one horizontal row.
- **Live components:** leave page background on every side: 40px around a reel card, 60px around a click-through component (40px looks cramped around a wide one). Cap the component at its real max width, never a stretched one.
- **Resolution:** pick DSF so that `min(viewport width, viewport height) × DSF ≥ 2000`. That's about DSF 8 for a 250px card and DSF 4 for an 880px component. Keep the long side at 4096px or less: larger frames break H.264 level 5.2 and play badly on X and in QuickTime.
- **Encoding:** 60fps, H.264, crf 14, yuv420p, `+faststart`. Rendered videos have no audio. The scripts already do this.
- **Theme:** use the theme of the site the component lives in. Explainers default to white.

## 4. What's on screen

- **Text that belongs to the component stays:** a card's description, menu items, control labels. Take it from current source. Remove it only when the user asks.
- **Strip the wrapper, not the component:** remove borders, shadows and rounded containers you or the page put *around* the demo, plus replay buttons and "01 Spring"-style numbering. A wrapper makes the demo read as a screenshot of a page. The component's own surfaces, like a card's background or a dropdown's panel, stay.
- **Make it big in explainers.** Scale components 2–3× (a small spinner can go to 8×) so the demo fills 60–80% of the frame. At real size a component is a speck on a phone. In reels and click-throughs the frame is already sized to the component, so never CSS-scale it there; raise DSF instead.
- **Copy the real thing from source:** the component, graph, durations, curves and colors. Grep the user's codebase for it. When the user says something looks wrong, swap in the source version instead of tweaking yours.
- **Re-read the source before every render.** Copy and descriptions change between rounds, and the next video has to use the current ones.
- **Fonts:** use the product's own sans and mono. Copy the `.woff2` files from the codebase next to `index.html` and load them with `@font-face`. Check that `document.fonts` reports them as loaded before rendering.
- **Legends:** no box and no border. Use a 14×2px line swatch and an 11px mono label, centered above the graph.
- **Comparisons:** both sides use the same scale, sit mirrored around the center and trigger on the same frame. Easing comparisons use the same duration on both sides, so only the curve differs.
- **Alignment:** check centers and left edges numerically with `getBoundingClientRect`. A 1–2px offset between labels, icons and columns is visible when the video loops. When two demos are stacked, align their content to one shared left edge.
- **Never clip a demo.** Let graphs and overshooting springs overflow their box.
- **Text inside pressed buttons:** put `will-change: transform` on anything that scales. Otherwise the text re-rasterizes every frame and visibly shifts.
- **Real content:** never edit real tweets, reviews, names or dates. Crop out what doesn't fit.

## 5. Timing

Holds always end up shorter than the first draft, never longer. Start at these numbers. When the user says "shorter" without a number, cut the hold by 25–50%.

- **Explainer length:** 20–26s. Fit a lot in, then add pauses so viewers can catch up. Cut a repeat before you cut a pause.
- **Click-through length:** 6–9s.
- **The first scene is the hook.** It has to read in under a second with no explanation, like two spinners at different speeds.
- **Between scenes:** hard cuts only. A transition between examples is dead time.
- **The first action** starts 0.3–0.4s into each scene, so there's no dead opening.
- **Comparison scenes** run 5–7s each, as cycles of `[openAt, closeAt, slowdown]`: `[[0.4, 1.4, 1], [2.3, 3.3, 1], [4.2, null, 4]]`.
  - Run twice at normal speed, then once at 4× slow motion, left open until the cut.
  - When the comparison is about duration (`400ms` / `180ms`), run the third cycle at 1× (`[4.2, null, 1]`). Slowing it down hides the difference.
  - Leave 0.6–0.9s of stillness between runs, so viewers can catch up.
- **Graphs:** draw the curves once at real speed, then again 2× slower.
- **A button press before an open:** scale 1 → 0.97 over 90ms, back over 160ms, with the peak on the open frame.
- **Hover reel, per item:** rest 0.2s, glide in 0.67s, hold 0.65s, glide out 0.6s, rest 0.5s, then a hard cut. A 1.33s hold felt slow by the third item.
- **Click-through, per switch:** glide 0.55s, settle 0.15s, click, hold 0.6s. Longer holds than that make a short click-through drag.
- **Exits in motion you author** (explainers, not components copied from source): exit duration ≥ 0.8× the entrance (0.3s in, 0.275s out). A flat 250ms exit after a 500ms entrance feels abrupt.
- **Loops:** end on the same state as the first frame, so the post loops cleanly.

## 6. Cursor

- **Images:** the macOS cursors in `cursors/`, taken from `NSCursor` at 8×. A drawn cursor looks fake next to real UI, so never draw one.
  - The arrow is 28×40 with its hotspot at (5,5).
  - The hand is 32×32 with its hotspot at (12,8), plus `drop-shadow(0 1px 1px rgb(0 0 0/.45))`.
- **Which cursor:** the arrow everywhere, and the hand over anything clickable. `lib.cjs` picks it from the element under the point.
- **Path:**
  - Start and end fully off-frame, so the first and last frames show only the component.
  - Glide on a quadratic Bézier bowed 6–16% of the distance, with ease-in-out cubic.
  - Stop dead while a hover or click plays. A drifting cursor pulls the eye off the animation.
- **Rest point:** on the component, clear of the part that animates. On a labelled control, rest low and right of the label's center so the hand doesn't cover the word.
- **Variety across reel items:** seed it per item. Entry varies between the right edge and straight below, exit between bottom-right and bottom-left, and the rest point by ±3% at the same depth.
  - Cursors from the top or left, and cursors that go deep into the card, look random rather than varied. Keep the variance slight and the depth the same.

## 7. Set up the project (every rendering mode)

Create a project folder (e.g. `<name>-video/` next to the user's other projects), copy this skill's `scripts/`, `cursors/` and, for explainers, `templates/explainer.html` into it, and run `npm i playwright-core`. The scripts use the installed Google Chrome (`CHROME_PATH=` for another build) and need ffmpeg on the PATH. Run them from the project root; `out/` lands there. Never leave the source or the video only in a scratch or temp directory: it gets cleared, and the user may want to edit the design themselves.

## 7a. Explainers: `render.cjs`

- **Files:** `index.html`, the fonts and `out/` sit in the project root. Start from `templates/explainer.html`, copied to `index.html`. It has the bezier solver, `overlayState()` for open/close cycles, `pressAmount()` and one comparison scene.
- **The page:** `window.render(t)` sets every style from `t` alone.
  - No CSS transitions, animations, timers or `Date.now()`.
  - Easing goes through the JS cubic-bezier solver.
  - Scenes switch with `display`.
  - Export `window.DURATION`.
- **Commands:** `node scripts/render.cjs stills 1,4.2,9` and `node scripts/render.cjs video out/<name>-25s.mp4`. `W`, `H` and `DSF` set the canvas.

## 7b. Hover reels: `reel.cjs`

1. Build a temporary route such as `/dev-<name>-reel`. Each item is `[data-reel=i]` and only the one with `[data-on]` is visible. Every item is the same size so all frames match. Put items in the order the user gives.
   - Place the visible item with `position:fixed; left:40px; top:40px`. The script mirrors that offset as the margin, so a centered item would get a huge one.
   - Make each item a link or give it `data-clickable`, so the hand shows.
2. Send a direction check from `COUNT=1`, encoded with `node scripts/reel.cjs encode out/one out/one.mp4`.
3. Render from a git worktree with its own dev server port. A branch switch in the main checkout mid-render deletes files and kills the batches. The script retries an item after a reload and skips frames already on disk.
4. Resume only an unchanged render. After any change to the source, order, timing or resolution, render into a new, empty frames directory. Old frames would be skipped and end up in the video. The script refuses a directory whose settings differ, but it can't see source edits.
5. Split long reels into 4 parallel batches with `START`/`END`, then encode.
6. Delete the route when done.

## 7c. Click-throughs: `click.cjs`

1. Build a temporary route that renders only the component inside `#stage`, with `#stage` at a fixed height equal to its tallest state. The script exits with an error if the stage grows, because the frame is sized once and growth gets cropped.
2. Set `A` and `B` to the text of the two controls, or `css=<selector>`, and edit the ROUTE block for anything other than A ↔ B.
3. Check stills, then render: `URL=… A="Before" B="After" SCHEME=dark node scripts/click.cjs video out/<name>-7s.mp4`.
4. Delete the route when done.

Both live scripts pause Playwright's clock and step it one frame at a time, and they remove `Element.prototype.animate`. That puts Motion springs and rAF height animations on the same clock as the CSS transitions. Set `KEEP_WAAPI=1` only if the page calls `el.animate()` without a fallback. Check a mid-animation still either way.

## 8. Recording pages (the user records themselves)

- **Layout:** one item at a time, centered on a full white page with the site header hidden. Remove the container's border, shadow and radius.
- **Nothing shifts:** fix the frame to the size of the tallest item, then verify that every title and box lands on identical pixel coordinates.
- **Keys:** Space or → goes to the next item and Shift+Space or ← to the previous, wrapping at both ends. Space still types inside inputs.
- **Demos:** remount each one on arrival so autoplay starts fresh. Loop demos that would otherwise end.
- **Toggle labels** say what they toggle: "Sticky / Not sticky", not "Wrapper visible / Wrapper hidden".
- **Dev badge:** hide `nextjs-portal`, or record against a production build (`build && start`).
- **Shared demos:** editing a shared demo component also changes the live site. Say so every time.

## 9. A touch cursor on a phone recording: `touch-cursor.py`

Phone screen recordings show no finger. The cursor to add is the translucent grey disc Chrome shows in touch emulation. Needs Python 3 with numpy.

1. Run `python3 scripts/touch-cursor.py sheet in.mov sheet.png 4` and read every sheet it writes (`sheet-01.png`…, 8s each). The recording has no touch data, so work every gesture out from what happens on screen.
   - A tap lands on the frame where a press state appears, such as a highlight or a selection.
   - A scroll is a press that moves with the content and then lets go while the page keeps gliding.
   - A drag follows whatever moves under the finger.
2. Where a gesture has to follow content, decode frames with ffmpeg to numpy and track it per frame: the scroll offset from row profiles, a colored marker from a color mask. Write those positions as dense pressed keys.
3. Write `gestures.json` in points. Its format is in the script's header.
4. Run `render … --preview`, check it, then render at full size. Resolution, fps, color range and audio stay as in the source.

The default dot has a 16pt radius. Chrome's own 12.7pt reads too small at timeline size.

## 10. Verify and deliver

1. **Probe:** run `ffprobe -v error -show_entries stream=width,height,r_frame_rate -show_entries format=duration out.mp4`.
2. **Look at frames:** extract an idle frame, a mid-animation frame and the last frame from the encoded file, and make a contact sheet covering the whole video with `ffmpeg -i out.mp4 -vf "fps=30/<duration>,scale=360:-1,tile=6x5" -frames:v 1 sheet.png`. Check the cursor type over each target, alignment, and that nothing is clipped.
3. **Naming:** put the length in the file name (`<name>-9s.mp4`). Keep the previous render until the new one is approved.
4. **Report:**
   - Show the video inline if your environment can (for example, markdown image syntax with its absolute path); otherwise give the absolute path. A path alone means the user has to go find the file.
   - Give the resolution, fps, length and size, and say which frames you checked.
   - Offer one concrete next cut with its saving (for example, "dropping the second normal-speed run saves 3.5s"), not a menu.
