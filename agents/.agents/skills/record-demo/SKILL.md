---
name: record-demo
description: Use after generate-demo has created a DEMO-GUIDE.md — records a narrated screen-captured MP4 video of the demo being performed. Drives the UI with Playwright, generates narration audio with macOS say (system default voice), and assembles the final video with FFmpeg. Supports two modes - a 5-minute C-suite pitch and a longer general audience demo.
model: sonnet
---

<skill_overview>
This skill creates narrated video recordings of demos produced by generate-demo. It transforms a DEMO-GUIDE.md into a structured recording script, generates audio narration using macOS `say` (system default voice — set Siri Voice 2 for best quality), drives the application UI via Playwright (recording the session), and assembles the final MP4 using FFmpeg. Two output modes: C-suite pitch (~5 min, top scenarios, outcome-focused) and General (all scenarios, educational pace).
</skill_overview>

<rigidity_level>
MEDIUM - The 5-phase pipeline sequence is fixed (validate -> script -> audio -> record -> assemble). Content adapts to the specific demo being recorded. The validate-readiness phase MUST run first and MUST pass before any other phase begins.
</rigidity_level>

<quick_reference>
| Phase | Action | Output |
|-------|--------|--------|
| 0. Validate Readiness | Run pre-flight checks | Confirmed prerequisites |
| 1. Generate Script | Parse DEMO-GUIDE.md, confirm C-suite scenarios | `recording/DEMO-RECORDING-SCRIPT.json` |
| 2. Generate Audio | `say -o` for each narration segment | `recording/audio/step-NNN.aiff` |
| 3. Record Video | Playwright drives UI with timed waits | `recording/video/session.webm` |
| 4. Assemble | FFmpeg merges audio onto video | `recording/output/demo-{mode}.mp4` |

**Key:** Audio is pre-generated so durations are known before video recording. Playwright waits match audio durations for precise sync.
</quick_reference>

<when_to_use>
Use when:
- generate-demo has already produced a DEMO-GUIDE.md with docker-compose environment
- You want a narrated video recording of the demo
- Preparing a C-suite pitch or stakeholder presentation
- You want a repeatable, automated demo recording

Do NOT use when:
- No DEMO-GUIDE.md exists yet (run generate-demo first)
- Demo environment is not running (start docker compose first)
- You want a live, unscripted demo (just follow DEMO-GUIDE.md manually)
- You need to edit or trim the video (use a video editor after recording)
</when_to_use>

<the_process>

## Announce

```
"I'm using record-demo to create a narrated video recording of the demo."
```

---

## Phase 0: Validate Readiness

**This phase MUST pass before any other phase begins.**

Run the pre-flight validation script:

```bash
./plugins/completed-work-demo/skills/record-demo/scripts/validate-readiness.sh <demo-directory>
```

Where `<demo-directory>` is the path to the demo folder (e.g., `./demo/2026-03-05-checkout-flow`).

The script checks:
1. **ffmpeg** - Installed and functional (`ffmpeg -version`)
2. **ffprobe** - Available (ships with ffmpeg)
3. **ffmpeg codecs** - libx264 and aac codecs present
4. **macOS say** - `say` command functional (uses system default voice — Siri Voice 2 recommended)
5. **Playwright** - Installed (`npx --no-install playwright --version`) AND Chromium browser downloaded
6. **Docker** - Running (`docker info`)
7. **Demo environment** - Directory exists, has docker-compose.yml and DEMO-GUIDE.md, containers are running and healthy

**If any check fails:** The script outputs all failures with install instructions. STOP and tell the user to fix the issues before proceeding.

**If all checks pass:** The script outputs JSON with detected versions and demo directory.

**Validate-readiness output (JSON on stdout):**
```json
{
  "success": true,
  "voice": "system default",
  "ffmpegVersion": "6.1.1",
  "playwrightVersion": "1.40.0",
  "failures": [],
  "warnings": [],
  "demoDir": "./demo/2026-03-05-checkout-flow"
}
```

---

## Phase 1: Generate Recording Script

Transform DEMO-GUIDE.md into a structured DEMO-RECORDING-SCRIPT.json. This phase is Claude-driven because narration generation and Playwright selector inference require LLM intelligence.

**Step 1a: Read and parse DEMO-GUIDE.md**

Read the DEMO-GUIDE.md from the demo directory. Extract:

1. **App URL** — Find in the `## Setup` section. Look for URLs matching `http[s]://localhost[:port][/path]` or similar. If multiple URLs, use the Web UI URL (not API).

2. **Scenarios** — Find all `### Scenario` headers. For each scenario, extract:
   - Title (from the header, after `### Scenario N:`)
   - Persona name and role (from `**Persona:**` line)
   - Goal (from `**Goal:**` line)
   - Context (from `**Context:**` line)
   - Numbered steps (from `**Steps:**` section — each line starting with a number)
   - What to observe (from `**What to observe:**` line)

**Parse flexibly:** Look for `### Scenario` headers and `**Steps:**` markers. Do not rely on rigid line offsets. Handle minor format variations (e.g., `###Scenario` vs `### Scenario`, `**Step:**` vs `**Steps:**`).

**If no scenarios found:** STOP. Tell the user: "No scenarios found in DEMO-GUIDE.md. The file may not match the expected format."

**Skip empty scenarios** (header exists but no numbered steps) with a warning.

**Step 1b: Determine recording mode**

Ask the user which mode to record:

```
AskUserQuestion:
  question: "Which recording mode?"
  header: "Mode"
  options:
    - label: "C-suite pitch (Recommended)"
      description: "~5 minutes. Top 2-3 most impactful scenarios. Outcome-focused narration. Brisk pacing."
    - label: "General audience"
      description: "Full length. All scenarios. Educational narration. Measured pacing."
    - label: "Both"
      description: "Generate two recording scripts. Record both versions."
```

**Step 1c: C-suite scenario selection (if csuite or both mode)**

If C-suite mode was selected, present the list of scenarios for the user to confirm:

1. Recommend the top 2-3 most impactful scenarios based on:
   - Business value described in Context
   - Visual impact (scenarios with clear UI changes are better on video)
   - Uniqueness of the functionality being demonstrated
2. Present all scenarios using AskUserQuestion with multiSelect, marking recommended ones
3. If user deselects all scenarios, offer: "No scenarios selected. Switch to general mode instead?"

**Step 1d: Generate setupSteps**

Check if the demo requires login or navigation to a starting state:

1. If DEMO-GUIDE.md references login, authentication, SSO, or credentials in Setup or Prerequisites:
   - Add a single `navigate` step to the app URL (auth is handled automatically by the recording script's `ensureAuthenticated` flow — it launches a headed persistent context for SSO/NTLM/Kerberos)
   - Do NOT add `type` steps for username/password — SSO is handled interactively in the pre-auth step
2. If no auth required, add a single `navigate` step to the app URL

**Step 1d-2: Set authCheck selector**

Set the `authCheck` field in the JSON root. This selector tells the recording script how to verify the app loaded successfully after authentication. Pick a UI element that:
- Is **unique on the page** (use Playwright role selectors to avoid strict-mode violations)
- Is **visible only when authenticated** (e.g., a sidebar navigation link, a user menu, a dashboard header)
- Appears **after the app finishes loading** (not a loading spinner)

Format: `{ "role": "<role>", "name": "<accessible name>" }` — maps to `page.getByRole(role, { name })`.

Examples:
- `{ "role": "link", "name": "Dashboard" }` — sidebar nav link
- `{ "role": "banner", "name": "Welcome" }` — header banner
- `{ "role": "navigation", "name": "Main" }` — main navigation

If the app has no auth, still set `authCheck` to an element that confirms the page loaded.

**Step 1e: Generate steps with narration and actions**

For each selected scenario, for each numbered step, generate:

1. **narration** — Transform the DEMO-GUIDE.md step text into spoken narration:
   - **C-suite mode:** Outcome-focused. "Now we see the real-time qualification results..." not "Click the submit button."
   - **General mode:** Educational. "Next, we'll click Submit to trigger the qualification engine. Notice how the results appear in real-time..."
   - Keep to 1-3 sentences per step
   - Soft limit: Flag any narration exceeding 50 words (review and shorten)
   - **NEVER read credentials aloud.** Say "using the demo credentials" not "entering password demo123"
   - Include "What to observe" content in the final step's narration for each scenario

2. **action** — Determine the Playwright action from the step text:
   - `navigate` — Step says "Navigate to", "Go to", "Open" + URL
     - target: the URL (resolve relative URLs against appUrl)
   - `click` — Step says "Click", "Select", "Press", "Toggle", "Expand"
     - target: Playwright selector (e.g., `button:has-text("Submit")`, `a:has-text("Dashboard")`, `#element-id`, `[data-testid="xyz"]`)
   - `type` — Step says "Enter", "Type", "Input", "Fill in"
     - target: Playwright selector for the input field
     - value: the text to type
     - humanSpeed: (optional, boolean) if true, types character-by-character at 120ms delay using `pressSequentially` instead of instant `fill()`. Use for visible typing in demos.
   - `wait` — Step says "Wait for", "Until"
     - target: Playwright selector to wait for
   - `observe` — Step says "Observe", "Notice", "See", "Look at", "Verify" with no UI interaction
     - target: description of what to observe (for logging only)
     - No Playwright action is performed — this is a narration-only pause
   - `welcome` — Opening slide (use as the first step with intro narration)
     - product: Product name (e.g., "Meridian")
     - subtitle: Subtitle text (e.g., "Business Capability Manager")
     - date: Date string (e.g., "March 2026")
     - Loads a branded UWM HTML slide via `file://` protocol
   - `thankYou` — Closing slide (use as the last step with "Thank you for watching" narration)
     - product: Product name with tagline
     - date: Date string
     - Loads a branded UWM HTML slide via `file://` protocol

3. **selectorStrategy** — Brief note explaining how to find the element:
   - "Button text match" / "Link text in nav" / "Form input by name" / "Data-testid attribute"
   - Aids debugging when selectors don't match at runtime

4. **Timing:**
   - `waitAfterAction`: Time to wait after the Playwright action completes (ms)
     - C-suite: 1000-2000ms (brisk)
     - General: 2000-3000ms (measured)
   - `pauseBeforeNarration`: Pause before narration starts (ms)
     - 500ms default (brief pause for visual context)
     - 1500ms for first step of a new scenario (let the page settle)

**Step 1f: Add transition narration between scenarios**

Between scenarios, add an `observe` step with transition narration:
- C-suite: "Now let's look at [next scenario goal]..."
- General: "Moving on to our next scenario. [Persona name], a [role], needs to [goal]..."

**Step 1g: Add intro and outro steps**

**Intro** (first step, before all scenarios):
- `welcome` action with intro narration: "Welcome to [product name]. [Brief summary of what's being demonstrated]."
- Set `product`, `subtitle`, and `date` fields on the action
- C-suite: Keep intro to 1-2 sentences
- General: Can expand to 3-4 sentences with context
- The welcome slide displays a branded UWM title card while the intro narration plays
- Follow with a silent `navigate` step to the app URL (the app loads after the welcome slide, avoiding white screen flicker)

**Outro** (last two steps, after all scenarios):
- `observe` step with closing narration: "That concludes our demonstration of [feature]. [1 sentence summary of what was shown]."
- `thankYou` step with narration "Thank you for watching." — displays a branded UWM closing card with product name and date

**Step 1h: Write DEMO-RECORDING-SCRIPT.json**

Create `recording/` directory if it doesn't exist:
```bash
mkdir -p <demo-dir>/recording
```

If a previous `DEMO-RECORDING-SCRIPT.json` exists, warn: "Replacing existing recording script."

Write the JSON file:

```json
{
  "mode": "csuite",
  "voice": "system default",
  "appUrl": "http://localhost:8080",
  "generatedAt": "2026-03-05T14:30:00Z",
  "authCheck": {
    "role": "link",
    "name": "Dashboard"
  },
  "setupSteps": [
    {
      "id": 1,
      "narration": null,
      "action": {
        "type": "navigate",
        "target": "http://localhost:8080",
        "selectorStrategy": "Direct URL navigation"
      }
    }
  ],
  "steps": [
    {
      "id": 1,
      "scenario": "Intro",
      "narration": "Welcome to the demonstration of our new checkout flow. Today we'll see how the streamlined process reduces cart abandonment.",
      "action": {
        "type": "observe",
        "target": "Landing page visible"
      },
      "waitAfterAction": 2000,
      "pauseBeforeNarration": 1000
    },
    {
      "id": 2,
      "scenario": "Customer — Complete Purchase",
      "narration": "Sarah, a returning customer, navigates to the product catalog.",
      "action": {
        "type": "click",
        "target": "a:has-text('Products')",
        "selectorStrategy": "Navigation link text match"
      },
      "waitAfterAction": 1500,
      "pauseBeforeNarration": 500
    }
  ]
}
```

**Step 1i: Validate the output**

```bash
jq . <demo-dir>/recording/DEMO-RECORDING-SCRIPT.json > /dev/null
```

If jq validation fails, fix the JSON and re-validate.

Confirm to the user:
```
Recording script generated:
  Mode: [csuite/general]
  Voice: system default
  Scenarios: [N] selected
  Steps: [N] total (including intro/outro/transitions)
  Estimated narration: ~[N] words ([estimated minutes] at 150 wpm)

File: <demo-dir>/recording/DEMO-RECORDING-SCRIPT.json
```

---

## Phase 2: Generate Audio Segments

Generate audio files for each narration step using macOS `say` command.

Run the audio generation script:

```bash
./plugins/completed-work-demo/skills/record-demo/scripts/generate-audio.sh <demo-dir>/recording/DEMO-RECORDING-SCRIPT.json
```

The script will:
1. **Validate** the recording script JSON
2. **Verify** the `say` command is functional
3. **Clear** any previous audio files in `recording/audio/`
4. **Generate** one AIFF file per step with non-null narration using `say -r <rate> -o <file>` (no `-v` flag — uses system default voice)
   - Narration is piped through stdin to avoid shell quoting issues with special characters
   - Rate is 180 wpm for C-suite mode (brisk) or 160 wpm for General mode (measured)
   - For best quality, set system default voice to Siri Voice 2 in System Settings > Accessibility > Spoken Content
5. **Measure** duration of each audio file using `afinfo` (with `ffprobe` fallback)
6. **Update** DEMO-RECORDING-SCRIPT.json with `audioFile` and `audioDuration` fields per step
7. **Add** `totalNarrationDuration` to the top-level JSON
8. **Report** progress and summary

**After the script completes, verify:**
- Audio files exist in `recording/audio/`
- JSON has been updated with duration data
- Total narration time is reasonable for the mode (~3-5 min for csuite, longer for general)

```bash
jq '.totalNarrationDuration' <demo-dir>/recording/DEMO-RECORDING-SCRIPT.json
ls -la <demo-dir>/recording/audio/
```

**If total duration is too long for C-suite mode (>6 minutes):** Consider shortening narration text in the recording script and re-running this phase.

---

## Phase 3: Record Video with Playwright

Generate and run a Playwright script that drives the demo UI while recording video.

**Step 3a: Generate the Playwright script**

```bash
./plugins/completed-work-demo/skills/record-demo/scripts/generate-playwright.sh <demo-dir>/recording/DEMO-RECORDING-SCRIPT.json --dry-run
```

The `--dry-run` flag generates the script without running it. This lets you review the generated `playwright-demo.js` before recording.

The script:
1. **Validates** that `audioDuration` fields exist (errors if generate-audio.sh wasn't run)
2. **Calculates** estimated video duration and warns if >15 minutes
3. **Generates** `recording/playwright-demo.js` — a self-contained Node.js script (no playwright.config.ts needed)
4. **Validates** the generated JS with `node --check`
5. **Clears** previous video files in `recording/video/`

**Step 3b: Review the generated script (optional)**

Check that selectors and actions look reasonable:

```bash
cat <demo-dir>/recording/playwright-demo.js
```

Key characteristics of the generated script:
- **Finds playwright automatically** — searches `require('playwright')`, npx cache (`~/.npm/_npx/`), and ancestor `node_modules/` directories. No per-directory install needed.
- **Persistent auth** — runs `ensureAuthenticated()` before recording. On first run, launches a headed persistent context (supports SSO/NTLM/Kerberos WIA) and saves `storageState` to `~/.cache/demo-recording-auth/auth-state.json`. Subsequent runs reuse the saved session.
- **Always records in headed mode** — headless Chromium skips CSS animations, producing slideshow-like video. The script always passes `--headed`.
- Uses `chromium.launch()` directly (not the test framework)
- 2-second positioning pause in headed mode — user can size/position the browser window before recording starts
- **Auto-trims white screen** — detects and removes the `about:blank` white frames from the start of the recording using 1x1 pixel brightness detection + VP8 re-encode
- 1920x1080 viewport and video resolution
- `ignoreHTTPSErrors: true` (demo may use self-signed certs)
- Per-step try/catch — selector failures take a screenshot but don't kill the recording
- Wait times match `pauseBeforeNarration + audioDuration*1000 + waitAfterAction`
- Supports `welcome` and `thankYou` action types for branded UWM slides via `file://`
- Supports `humanSpeed: true` on `type` actions for character-by-character typing
- Video file renamed from Playwright's random UUID to `session.webm`
- Cross-platform: macOS, Linux, WSL

**Step 3c: Pre-authenticate (if needed)**

If this is the first recording or the session expired, authenticate first:

```bash
node <demo-dir>/recording/playwright-demo.js --auth-only
```

This launches a headed browser, navigates to the app URL, and waits for SSO to complete. Once authenticated, cookies are saved for future headless recordings.

**Step 3d: Run the recording**

```bash
./plugins/completed-work-demo/skills/record-demo/scripts/generate-playwright.sh <demo-dir>/recording/DEMO-RECORDING-SCRIPT.json
```

Without `--dry-run`, the script generates AND runs the Playwright recording.

**After recording completes, verify:**

```bash
ls -la <demo-dir>/recording/video/session.webm
```

If any steps failed, check error screenshots:

```bash
ls <demo-dir>/recording/video/error-*.png
```

**If selectors are wrong:** Edit DEMO-RECORDING-SCRIPT.json to fix the selector `target` values, re-run generate-audio.sh (if narration changed), then re-run this phase.

---

## Phase 4: Assemble Final MP4

Merge audio segments onto the video at correct timestamps to produce the final MP4.

```bash
./plugins/completed-work-demo/skills/record-demo/scripts/assemble-video.sh <demo-dir>/recording/DEMO-RECORDING-SCRIPT.json
```

The script will:
1. **Validate** that `session.webm` exists and verify each referenced audio file
2. **Calculate** timestamp offsets for each audio segment using integer milliseconds:
   - Processes setupSteps first, then main steps, in timeline order
   - Each step's audio starts at: cumulative prior time + pauseBeforeNarration
   - Accumulates: pauseBeforeNarration + audioDuration*1000 + waitAfterAction per step
3. **Build** FFmpeg filter graph:
   - `adelay` filter places each audio at its calculated timestamp
   - `amix` with `normalize=0` merges all audio without volume reduction
   - Video re-encoded from VP8/VP9 to H.264 (`-c:v libx264`)
   - Audio encoded as AAC (`-c:a aac`)
4. **Handle** edge cases:
   - Zero audio files: converts video to MP4 without audio track
   - Single audio file: uses adelay without amix
   - 50+ audio files: uses `-filter_complex_script` to avoid command-line length limits
5. **Verify** output with ffprobe (video stream, audio stream, duration)
6. **Report** output path, size, duration, and codec info

Output: `recording/output/demo-{mode}-{date}.mp4`

**After assembly, verify the output is playable:**

```bash
ls -la <demo-dir>/recording/output/demo-*.mp4
ffprobe <demo-dir>/recording/output/demo-*.mp4 2>&1 | head -20
```

**If audio is out of sync:** The timing depends on the Playwright recording matching the calculated offsets. If sync is off, check that audioDuration values in the JSON match actual audio file lengths.

---

## Complete Pipeline Summary

To record a demo end-to-end:

```bash
# Phase 0: Validate prerequisites
./plugins/completed-work-demo/skills/record-demo/scripts/validate-readiness.sh <demo-dir>

# Phase 1: Generate recording script (Claude-driven — see SKILL.md Phase 1)
# Produces: <demo-dir>/recording/DEMO-RECORDING-SCRIPT.json

# Phase 2: Generate audio
./plugins/completed-work-demo/skills/record-demo/scripts/generate-audio.sh <demo-dir>/recording/DEMO-RECORDING-SCRIPT.json

# Phase 3: Record video
./plugins/completed-work-demo/skills/record-demo/scripts/generate-playwright.sh <demo-dir>/recording/DEMO-RECORDING-SCRIPT.json

# Phase 4: Assemble final MP4
./plugins/completed-work-demo/skills/record-demo/scripts/assemble-video.sh <demo-dir>/recording/DEMO-RECORDING-SCRIPT.json
```

Final output: `<demo-dir>/recording/output/demo-{mode}-{date}.mp4`

</the_process>

<anti_patterns>
- NO skipping validate-readiness — missing tools cause cryptic errors downstream; the pre-flight check exists to catch problems early with clear instructions
- NO live audio playback during recording — pre-generate audio for precise timing control; live playback requires audio loopback hardware and introduces sync issues
- NO hardcoded Playwright selectors in the skill — selectors must be generated from DEMO-GUIDE.md steps, not baked into this file
- NO modifying the existing generate-demo skill — record-demo consumes generate-demo output (DEMO-GUIDE.md) without changing how it's produced
- NO requiring paid services or API keys — macOS say is free, ffmpeg is free, Playwright is free
- NO single monolithic script — separate concerns into pipeline stages (validate, script-gen, audio, video, assembly)
</anti_patterns>

<critical_rules>
1. Validate-readiness MUST pass before any recording work begins — no exceptions, no overrides
2. All failures are collected and shown at once — never fail-fast on the first issue
3. Audio uses system default voice (no `-v` flag) — for best quality, set Siri Voice 2 as system default
4. The demo directory must have both docker-compose.yml and DEMO-GUIDE.md — both are required inputs
5. Docker containers must be running AND healthy — "present but exited" is a failure
6. The validate script outputs JSON on stdout for programmatic use and human-readable text on stderr
7. Narration NEVER reads credentials aloud — say "demo credentials" not the actual values
8. Playwright selectors are generated per-demo from DEMO-GUIDE.md steps — never hardcoded in this skill
9. C-suite scenario selection MUST be confirmed by the user before generating the script
10. Recording script JSON MUST be validated with jq before proceeding to Phase 2
11. Parse DEMO-GUIDE.md flexibly — look for markers like `### Scenario` and `**Steps:**`, not rigid line offsets
</critical_rules>

<verification_checklist>
**Phase 0 (Validate Readiness):**
- [ ] Script runs without errors when all prerequisites are met
- [ ] Script detects missing ffmpeg and provides install command
- [ ] Script detects missing ffprobe and provides install command
- [ ] Script detects missing codecs and provides reinstall command
- [ ] Script verifies macOS say command works
- [ ] Script detects missing Playwright and provides install command
- [ ] Script detects missing Chromium browser specifically
- [ ] Script detects Docker not running and provides start instructions
- [ ] Script validates demo directory exists
- [ ] Script checks for docker-compose.yml and DEMO-GUIDE.md
- [ ] Script checks container health status (not just presence)
- [ ] All failures collected and shown together (not fail-fast)
- [ ] JSON output includes voice field

**Phase 1 (Generate Script):**
- [ ] DEMO-GUIDE.md parsed using flexible markers (not rigid offsets)
- [ ] App URL extracted from Setup section
- [ ] All scenarios extracted with persona, goal, context, steps, what-to-observe
- [ ] User asked for recording mode (csuite/general/both)
- [ ] C-suite scenario selection confirmed by user via AskUserQuestion
- [ ] Empty scenarios skipped with warning
- [ ] Each step has narration (1-3 sentences, <50 words soft limit)
- [ ] Narration never reads credentials aloud
- [ ] Each step has Playwright action with type and selector
- [ ] Each action has selectorStrategy for debugging
- [ ] observe action type used for non-interactive steps
- [ ] setupSteps handles login if DEMO-GUIDE.md references auth
- [ ] Intro and outro steps included
- [ ] Transition narration between scenarios
- [ ] Timing values set per mode (csuite=brisk, general=measured)
- [ ] Output JSON validated with jq
- [ ] Previous script overwritten with warning
- [ ] Summary shown to user (mode, scenario count, step count, estimated time)

**Phase 2 (Generate Audio):**
- [ ] Audio file generated for each step with non-null narration
- [ ] Narration piped through stdin (not shell argument)
- [ ] Audio files are valid AIFF format
- [ ] Duration measured for each file (afinfo with ffprobe fallback)
- [ ] JSON updated atomically (temp file + mv)
- [ ] audioFile and audioDuration added to each step
- [ ] totalNarrationDuration added to top-level JSON
- [ ] Steps with null/empty narration have audioDuration=0
- [ ] Speech rate matches mode (csuite=180, general=160)
- [ ] Previous audio cleared before regeneration
- [ ] say command verified before generating (no -v flag, uses system default)
- [ ] Progress counter shown during generation
- [ ] Special characters handled (quotes, apostrophes, dollar signs)

**Phase 3 (Record Video):**
- [ ] Playwright script generated from DEMO-RECORDING-SCRIPT.json
- [ ] audioDuration fields validated before generation
- [ ] Self-contained script (no playwright.config.ts)
- [ ] Headless mode for clean recording
- [ ] 1920x1080 viewport and video resolution
- [ ] All action types handled (navigate, click, type, wait, observe)
- [ ] Wait times match audioDuration + padding
- [ ] Per-step try/catch (failures don't kill recording)
- [ ] Error screenshots taken on step failure
- [ ] Video renamed from UUID to session.webm
- [ ] Previous video files cleared
- [ ] Estimated duration calculated and warned if >15 min
- [ ] Generated JS passes syntax check (node --check)

**Phase 4 (Assemble Video):**
- [ ] Audio segments placed at correct timestamps via adelay
- [ ] Timestamps use integer milliseconds (no float accumulation)
- [ ] setupSteps included in timeline before main steps
- [ ] amix uses normalize=0 (volume not reduced)
- [ ] Video re-encoded from VP8/VP9 to H.264
- [ ] Output is playable MP4 (H.264 + AAC)
- [ ] Output named demo-{mode}-{date}.mp4
- [ ] Zero-audio case produces video-only MP4
- [ ] Single-audio case works without amix
- [ ] Missing audio files skipped with warning
- [ ] Output verified with ffprobe
- [ ] Previous output cleared before assembly
- [ ] File size and duration reported
</verification_checklist>

<integration>
Called by: using-hyper (when user asks to record a demo, create a demo video, or prepare a video presentation)
Precondition: generate-demo must have already produced DEMO-GUIDE.md and docker-compose.yml in a demo directory. Docker environment must be running.
Reads: DEMO-GUIDE.md (for narration and action steps), docker-compose.yml (to verify environment)
Writes: recording/ subdirectory within the demo folder (scripts, audio, video, final MP4)
Never writes to: DEMO-GUIDE.md (input is read-only), generate-demo skill files
Related skills: generate-demo (produces the input this skill consumes)
</integration>

<edge_cases>

## Edge Case: Low quality voice output
- Signal: Generated audio sounds robotic or synthetic
- Action: Recommend setting Siri Voice 2 as system default: System Settings > Accessibility > Spoken Content > System Voice. The `say` command uses the system default when no `-v` flag is passed. Siri voices produce natural speech but cannot be selected via `-v` (they don't appear in `say -v '?'` output).

## Edge Case: Docker daemon starting but not ready
- Signal: `docker info` succeeds but `docker compose ps` shows containers in non-running state
- Action: Report unhealthy containers with their states. Suggest waiting or restarting.

## Edge Case: Demo directory has compose file but no DEMO-GUIDE.md
- Signal: docker-compose.yml exists but DEMO-GUIDE.md does not
- Action: Fail with message to run generate-demo first.

## Edge Case: say command hangs
- Signal: `say -v ?` does not return within 5 seconds
- Action: Timeout and report failure. Suggest checking Speech Synthesis in System Settings.

## Edge Case: Playwright installed but no browser
- Signal: `npx --no-install playwright --version` succeeds but Chromium directory missing
- Action: Fail with specific install command: `npx playwright install chromium`

## Edge Case: ffmpeg present but missing codecs
- Signal: `ffmpeg -codecs` output lacks libx264 or aac
- Action: Fail with reinstall command: `brew install ffmpeg`

## Edge Case: DEMO-GUIDE.md has no Scenarios section
- Signal: No `### Scenario` headers found after parsing
- Action: STOP. Tell user: "No scenarios found in DEMO-GUIDE.md. The file may not match the expected format from generate-demo."

## Edge Case: Step text is observation-only (no UI action)
- Signal: Step says "Observe", "Notice", "Verify", "See" with no clickable/typeable action
- Action: Use `observe` action type. Playwright does nothing; narration plays over the current screen state.

## Edge Case: Step references API endpoint instead of UI
- Signal: Step mentions curl, API call, or endpoint without a UI equivalent
- Action: Skip for video recording. Add narration: "Behind the scenes, the API handles [X]." Use `observe` action type.

## Edge Case: DEMO-GUIDE.md references login credentials
- Signal: Setup or Prerequisites section mentions username/password, login, or authentication
- Action: Generate setupSteps for login. Narration says "using demo credentials" — never reads actual credential values aloud.

## Edge Case: User deselects all C-suite scenarios
- Signal: AskUserQuestion returns with no scenarios selected
- Action: Offer to switch to general mode. If user declines, STOP.

## Edge Case: Very long narration generated (>50 words for a step)
- Signal: Word count of generated narration exceeds 50
- Action: Flag to user: "Step N narration is [X] words (recommended: <50). Shorten?" Continue if user approves.

## Edge Case: Multiple app URLs in Setup section
- Signal: DEMO-GUIDE.md lists both Web UI and API URLs
- Action: Use the Web UI URL as appUrl. Note API URL in a comment in the JSON but don't navigate to it.

</edge_cases>
