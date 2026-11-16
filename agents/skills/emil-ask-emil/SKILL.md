---
name: emil-ask-emil
description: "A router over the design engineering skills. Ask which one fits the situation in front of you, and which order to run them in. Use when you don't know which skill covers a problem, when two of them seem to overlap, when you want the sequence for building or fixing a whole screen, or when you're not sure a skill applies at all. Triggers on: which skill, what skill should I use, ask emil, which one covers, do you have a skill for, what's the right skill, skill for this, list the skills, what skills do I have, where does this belong, which order."
disable-model-invocation: true
---

# Ask Emil

You don't remember which skill covers what, so ask.

Answer with **one or two skills, not five**. Name them, say in one line why, then run them. Loading four skills at once spreads the agent's attention across four craft bars and it applies none of them properly — the same reason a skill covers one aspect of the interface instead of everything.

## Route in two questions

**1. What phase are you in?** This picks the group. Every skill belongs to exactly one moment in the work, and reaching for the wrong moment is the most common mis-route — polishing something whose layout is still wrong wastes the pass, because the polish gets thrown away with the layout.

| Phase | You're saying | Go to |
| --- | --- | --- |
| Undecided | "try a few", "not sure which", "show me options", "I'm stuck" | [Decide](#decide) |
| Foundation | "build this screen", "lay this out" | [Start here](#start-here) |
| Pieces | "build this card / form / component / landing page" | [Build](#build) |
| It works, it feels off | "make it feel finished", "this is janky", "on mobile it's broken" | [Refine](#refine) |
| It's done | "does this look right", "review before I ship", "we launch Thursday" | [Check](#check) |
| The words, not the work | "what's it called when…", "this sounds like AI" | [Underneath](#underneath) |

**2. What is the thing?** Inside the group, the skill is named after the material — type, color, surfaces, motion, forms, components. If two of them both look right, the answer is in [Overlaps](#overlaps), not in reading both.

## Decide

- **`/emil-prototype`** — build 3–5 genuinely different versions behind a live picker, with every uncertain number on a control, then write down what got picked and what got rejected. Reach for it the moment a decision hasn't been made yet. **Never run it after the decision is made** — a picker holding three answers to a settled question wastes the run. If the user already knows what they want, skip straight to the building skill.
- **`/emil-get-creative`** — for creative visual work when the user holds only a vibe, mood words, or "something like…" instead of a spec: research the visual language until it has names, compress it into rules, then build a seeded generator with knobs and a save button. Reach for it when they say "I'm stuck" or "I need inspiration", or have rejected a round of prompted variants. `/emil-prototype` compares a few directions for a known component; this one finds a direction when there isn't one yet.

## Start here

The foundation. Most screens need these two before anything else, and running them after the pieces are built means redoing the pieces.

- **`/emil-typography`** — font files, variable axes, type scales, line length, wrapping, truncation. Anything where the *text itself* is the problem.
- **`/emil-color`** — OKLCH palettes, tonal scales, dark mode derivation, contrast that actually passes APCA/WCAG. Any time a color value gets invented rather than chosen.

## Build

The pieces that sit on the foundation.

- **`/emil-surfaces`** — shadows, borders, gradients, elevation, and the dark-mode versions of all four. Cards, modals, dropdowns, images.
- **`/emil-component-design`** — the *props API* of a component other people will reuse: composition over configuration, compound components, controlled/uncontrolled. Not how it looks.
- **`/emil-forms-and-inputs`** — forms, inputs, buttons, validation timing, loading and disabled states, submit behavior. Anything a user types into or presses.

## Refine

The screen works. Now it has to feel built.

- **`/emil-animations`** — whether to animate at all, then easing, duration, springs, enter/exit. Motion that looks *wrong*.
- **`/emil-ui-polish`** — the invisible pass: font rendering, tabular numbers, layout shift, hover/focus/pressed states, hit areas, truncation, stacking. A static screen that looks *unfinished*; motion belongs to `/emil-animations`.
- **`/emil-interaction-details`** — the behavior between input and response: tooltip delays and skip groups, tension past a drag's limit, velocity on release, hover intent, gaps the pointer crosses, timers that wait. Reach for it when something works but doesn't feel right *in the hand* — a toolbar that makes you wait on every tooltip, a slider that stops dead, a sheet you have to drag halfway to close.
- **`/emil-performance`** — virtualization, preloading, GPU compositing, layout stability. Anything measured in frames, milliseconds, or scroll jank.
- **`/emil-touch-and-accessibility`** — tap targets, hover vs touch, focus management, aria, reduced motion, iOS Safari quirks. This is a floor, not a refinement — if it fails here it ships broken for someone, so run it even when the screen already looks finished.
- **`/emil-mobile-native`** — the platform layer on a phone: sticky hover, the tap flash, `100vh`, inputs that zoom, safe areas, the software keyboard, overscroll, `theme-color`. Reach for it when the complaint is "it works in Chrome but feels like a website on my phone". Most of those reports aren't animation problems, so try this before `/emil-animations`.

## Check

- **`/emil-ui-review`** — point it at a diff, a generated component, or a PR and get findings ranked by how much they hurt. It **reports, it doesn't fix**. Reach for it after an agent builds UI, which is the case it exists for: models produce interfaces that look right in a screenshot and fall apart under a real cursor.
- **`/emil-prep-for-prod`** — sweep the **whole app** before a launch, a release, or a demo: accessibility, performance, mobile, forms, loading/empty/error states, motion, dark mode, leftover debug output and dev tools, metadata. It **fixes what a diff can fix**, then lists what needs a phone or a person and ends with Ship or Not yet. It's the one exception to "one or two skills": it crosses every other skill on purpose, an inch deep, and names the owning skill when a finding needs more than a one-line fix. Run it last, and **never while the screen is still being designed** — it fixes defects, not taste.
- **`/emil-unslop-design`** — strip the visual tells that mark a screen as AI-generated (indigo gradients, glassmorphism, emoji feature grids, the centered-hero sameness), then put a point of view back in. Reach for it when a screen "looks vibe-coded" or generic, or as a pass after generating any marketing page, dashboard, or app screen.

## Underneath

Run beneath the others. Reach for them when the **words**, not the work, are the problem.

- **`/emil-design-vocabulary`** — name a *visual* concept from a loose description ("the space between two specific letters" → kerning). Also settles near-synonyms: badge vs tag, tooltip vs popover.
- **`/emil-engineering-vocabulary`** — name a *behavior* from a loose description ("the UI updates before the server confirms" → optimistic update).
- Both exist because a vague prompt gets a vague interface. Getting the term right before asking for the thing is the cheapest quality win available.
- **`/emil-unslop-writing`** — strip the tells that mark prose as AI-written, then put a human voice back in. Reach for it when drafting or reviewing any text a person will read (READMEs, docs, release notes, commit messages, marketing copy, UI microcopy), or when it "sounds like AI".

## Standalone

Off the flow entirely.

- **`/emil-ask-lapse`** — Lapse, the animation inspector: installing it, driving the panel, takes, named moments, diffs, jank reports, the MCP and Playwright integrations. Reach for it when you need to *see* what an animation is doing frame by frame. `/emil-animations` decides what the motion should be; `/emil-ask-lapse` is how you look at what it currently is. They pair: inspect with Lapse, fix with `/emil-animations`.
- **`/emil-writing-skills`** — write skill files that actually change what an agent does. Reach for it when the user is packaging their own taste, or when a skill they wrote is being ignored.
- **`/emil-learn-taste`** — turn the design corrections from a session (said out loud, silent edits to files the agent wrote, repeated nudges, reverts) into rules with reasons in DESIGN.md, or a lint check when one would catch it. Reach for it at the end of a session where the user corrected the agent more than once. It records the user's taste; `/emil-design-system-docs` documents the components and tokens that exist.
- **`/emil-borrow-a-brain`** — turn a person's or company's published work into a skill that answers the way they would: collect the whole corpus, extract sourced claims, cluster them into references, write the skill, test it. Reach for it when the user says "make a skill out of X's essays / talks / blog". `/emil-writing-skills` packages the user's own taste; this one packages someone else's published thinking.
- **`/emil-product-thinking`** — interview the user about a product or feature idea, one question at a time, against twenty principles, and end with a verdict. Reach for it when the user says "should I build this", "grill me on this idea", or asks whether something is worth building. It is about the idea, not the interface; once the idea holds, hand off to the building skills.
- **`/emil-build-a-tool`** — when prompting for an artifact directly keeps landing on "closer, but not quite", stop iterating on the output: diagnose why the direct path fails, build the small tool that closes that gap with the taste decisions on live controls, and export exactly what the project needs. Reach for it after a round or two of re-prompting the same artifact, or when the user says "build me a tool for this".
- **`/emil-design-system-docs`** — write a DESIGN.md or docs folder an agent can follow: which component, which variant, which tokens, generated from the code that exists. Reach for it when an agent keeps hardcoding colors, inventing variants, or picking the wrong component.
- **`/emil-package-my-work`** — package UI and motion work as short, high-res videos for X, newsletters, and launch posts: composed explainers, hover reels, cursor click-throughs, recording pages. Reach for it when asked to make, record, render, or re-cut a video or clip.

## Overlaps

The routes that get confused. Each pair is one question, not two skills to read.

| If you're torn between | Ask | Then |
| --- | --- | --- |
| `emil-ui-polish` / `emil-ui-review` | Do you want it fixed, or told what's wrong? | Fixed → polish. Told → review. |
| `emil-animations` / `emil-interaction-details` | Is it how it moves, or when and whether it responds? | Curve, duration, spring → animations. Delay, threshold, tension, velocity, timer → interaction-details. |
| `emil-animations` / `emil-performance` | Does it look wrong, or does it drop frames? | Looks wrong → animations. Drops frames → performance. |
| `emil-animations` / `emil-ask-lapse` | Do you know what the motion is doing? | No → Lapse first. Yes → animations. |
| `emil-color` / `emil-surfaces` | Is it the value, or what's built from it? | Palette, contrast, dark-mode values → color. Shadow, border, gradient, elevation → surfaces. |
| `emil-component-design` / everything visual | Is the problem the props, or the pixels? | Props → component-design. Pixels → the matching visual skill. |
| `emil-touch-and-accessibility` / `emil-ui-polish` | Is it broken for someone, or merely unpolished? | Broken → touch-and-accessibility, and it's blocking. |
| `emil-ui-review` / `emil-prep-for-prod` | One diff, or the whole app? Told, or fixed? | A diff you want judged → review. The app, the week it ships → prep-for-prod. |
| `emil-touch-and-accessibility` / `emil-mobile-native` | Is someone locked out, or does it just feel like a website? | Keyboard, screen reader, tap targets, focus → touch-and-accessibility. Viewport, browser chrome, scroll, keyboard, tap feel on a phone → mobile-native. |
| `emil-mobile-native` / `emil-animations` | Does it feel wrong only on the phone? | Yes → mobile-native first. A tap delay or a stuck hover reads as bad motion and isn't. |
| `emil-prototype` / any building skill | Has the decision been made? | No → prototype. Yes → build the one thing. |
| `emil-design-vocabulary` / `emil-engineering-vocabulary` | Can you see it, or does it happen? | See → design. Happens → engineering. |

## Stacking

Real work runs two or three in sequence, never in parallel.

- **New screen** → the material skill for whatever it's made of, then `/emil-ui-review` before it ships.
- **New component** → `/emil-prototype` if undecided → build → `/emil-animations` if it moves → `/emil-touch-and-accessibility`.
- **"Feels cheap"** → `/emil-ui-polish` first. It's the highest hit rate on that complaint.
- **"Feels off" when you use it, but fine in a screenshot** → `/emil-interaction-details`, then `/emil-animations` if what's left is the motion itself.
- **"Feels slow"** → `/emil-performance`, not `/emil-animations`. Slowness is measured; motion taste is judged.
- **"Feels off on my phone"** → `/emil-mobile-native`. Only move on to `/emil-animations` or `/emil-performance` once the platform tells are gone and it still feels wrong.
- **Launch week** → `/emil-prep-for-prod`, once, on the whole app. Whatever it puts on its human list comes back to the owning skill after launch.

## When nothing fits

Say so. These skills cover the interface — layout, type, color, surfaces, motion, components, forms, accessibility, performance. They do not cover backend logic, data fetching, state management, build tooling, or testing. Stretching `/emil-ui-polish` over a database question produces confident nonsense, and the user can't tell it apart from a real answer. Answer normally instead, and say no skill applies.
