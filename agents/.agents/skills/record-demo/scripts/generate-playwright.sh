#!/bin/bash
# generate-playwright.sh - Generate and run a Playwright script from DEMO-RECORDING-SCRIPT.json
# Creates a self-contained Node.js script that drives the demo UI and records video.
#
# Features:
#   - Finds playwright from any install (local, npx cache, ancestor node_modules)
#   - Persistent auth via storageState (supports SSO/NTLM/Kerberos)
#   - Cross-platform (macOS, Linux, WSL)
#
# Usage: ./generate-playwright.sh <path-to-DEMO-RECORDING-SCRIPT.json> [--dry-run]
#
# Options:
#   --dry-run    Generate the script but don't run it
#
# The generated script accepts:
#   node playwright-demo.js              # normal recording
#   node playwright-demo.js --auth-only  # just sign in, no recording
#   node playwright-demo.js --headed     # record with visible browser
#
# Exit codes:
#   0 - Recording completed successfully
#   1 - Error (invalid JSON, missing audioDuration, Playwright failure)

set -euo pipefail

SCRIPT_JSON="${1:-}"
DRY_RUN=false

# Check for --dry-run flag
for arg in "$@"; do
  if [ "$arg" = "--dry-run" ]; then
    DRY_RUN=true
  fi
done

# --- Validation ---

if [ -z "$SCRIPT_JSON" ]; then
  echo "ERROR: No recording script path provided." >&2
  echo "Usage: generate-playwright.sh <path-to-DEMO-RECORDING-SCRIPT.json> [--dry-run]" >&2
  exit 1
fi

if [ ! -f "$SCRIPT_JSON" ]; then
  echo "ERROR: Recording script not found: ${SCRIPT_JSON}" >&2
  exit 1
fi

if ! jq empty "$SCRIPT_JSON" 2>/dev/null; then
  echo "ERROR: Invalid JSON in ${SCRIPT_JSON}" >&2
  exit 1
fi

# Check audioDuration fields exist
MISSING_DURATION=$(jq '[.steps[] | select(.narration != null and .narration != "" and (.audioDuration == null))] | length' "$SCRIPT_JSON" 2>/dev/null || echo "0")
if [ "$MISSING_DURATION" -gt 0 ]; then
  echo "ERROR: ${MISSING_DURATION} steps missing audioDuration. Run generate-audio.sh first." >&2
  exit 1
fi

# --- Extract config ---

DEMO_DIR=$(dirname "$SCRIPT_JSON")
if [ "$(basename "$DEMO_DIR")" = "recording" ]; then
  RECORDING_DIR="$DEMO_DIR"
else
  RECORDING_DIR="${DEMO_DIR}/recording"
fi
VIDEO_DIR="${RECORDING_DIR}/video"
PW_SCRIPT="${RECORDING_DIR}/playwright-demo.js"
APP_URL=$(jq -r '.appUrl // "http://localhost:8080"' "$SCRIPT_JSON")

# Extract authCheck selector if present, otherwise default
AUTH_CHECK_JSON=$(jq -c '.authCheck // {"role": "link", "name": "Browse Catalog"}' "$SCRIPT_JSON")

# Locate thank-you slide HTML (ships alongside this script)
SKILL_SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
THANK_YOU_HTML="${SKILL_SCRIPTS_DIR}/thank-you.html"
WELCOME_HTML="${SKILL_SCRIPTS_DIR}/welcome.html"

# Calculate estimated duration
TOTAL_DURATION_S=$(jq '
  [.setupSteps[]? | (.pauseBeforeNarration // 0) + ((.audioDuration // 0) * 1000) + (.waitAfterAction // 1000)] +
  [.steps[] | (.pauseBeforeNarration // 0) + ((.audioDuration // 0) * 1000) + (.waitAfterAction // 0)]
  | add / 1000
' "$SCRIPT_JSON" 2>/dev/null || echo "0")
TOTAL_MINUTES=$(echo "$TOTAL_DURATION_S / 60" | bc 2>/dev/null || echo "0")

echo "=== Playwright Script Generation ===" >&2
echo "  App URL: ${APP_URL}" >&2
echo "  Estimated video duration: ~${TOTAL_MINUTES} minutes (${TOTAL_DURATION_S}s)" >&2
echo "" >&2

if [ "${TOTAL_MINUTES:-0}" -gt 15 ]; then
  echo "WARNING: Estimated recording exceeds 15 minutes (${TOTAL_MINUTES}m). This is a long recording." >&2
fi

# --- Prepare directories ---

mkdir -p "$VIDEO_DIR"

# Clear previous video files
if ls "$VIDEO_DIR"/*.webm >/dev/null 2>&1 || ls "$VIDEO_DIR"/*.png >/dev/null 2>&1; then
  echo "  Removing previous video files..." >&2
  rm -f "$VIDEO_DIR"/*.webm "$VIDEO_DIR"/*.png
fi

# --- Generate Playwright script ---

echo "  Generating playwright-demo.js..." >&2

cat > "$PW_SCRIPT" << 'PLAYWRIGHT_SCRIPT'
#!/usr/bin/env node
// playwright-demo.js — Demo recording script with persistent auth
//
// Finds playwright from any install location. Authenticates via SSO with
// persistent browser profile, saves storageState for headless recording.
//
// Usage:
//   node recording/playwright-demo.js              # normal recording
//   node recording/playwright-demo.js --auth-only  # just sign in, no recording
//   node recording/playwright-demo.js --headed     # record with visible browser
//
// Cross-platform: macOS, Linux, WSL.

const fs = require('fs');
const path = require('path');
const os = require('os');

// --- Resolve playwright from wherever it's installed ---
function findPlaywright() {
  // 1. Direct require (works if in node_modules ancestor or NODE_PATH)
  try { return require('playwright'); } catch {}

  // 2. Search npx cache (~/.npm/_npx/*/node_modules/playwright)
  const npxCache = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npxCache)) {
    try {
      for (const sub of fs.readdirSync(npxCache)) {
        const candidate = path.join(npxCache, sub, 'node_modules', 'playwright');
        if (fs.existsSync(path.join(candidate, 'index.js'))) {
          return require(candidate);
        }
      }
    } catch {}
  }

  // 3. Walk up from script dir looking for node_modules/playwright
  let dir = __dirname;
  for (let i = 0; i < 8; i++) {
    dir = path.dirname(dir);
    const candidate = path.join(dir, 'node_modules', 'playwright');
    if (fs.existsSync(path.join(candidate, 'index.js'))) {
      return require(candidate);
    }
  }

  console.error('ERROR: Could not find playwright.');
  console.error('Install globally (npm i -g playwright) or in any ancestor node_modules.');
  process.exit(1);
}

const { chromium } = findPlaywright();

// --- Config ---
const RECORDING_DIR = __dirname;
const VIDEO_DIR = path.join(RECORDING_DIR, 'video');
const AUTH_CACHE_DIR = path.join(os.homedir(), '.cache', 'demo-recording-auth');
const AUTH_STATE_FILE = path.join(AUTH_CACHE_DIR, 'auth-state.json');
const AUTH_PROFILE_DIR = path.join(AUTH_CACHE_DIR, 'browser-profile');

const ARGS = process.argv.slice(2);
const AUTH_ONLY = ARGS.includes('--auth-only');
const HEADED = ARGS.includes('--headed');

PLAYWRIGHT_SCRIPT

# Embed recording data and auth check selector
echo "const RECORDING_DATA = $(jq -c '.' "$SCRIPT_JSON");" >> "$PW_SCRIPT"
echo "const AUTH_CHECK = ${AUTH_CHECK_JSON};" >> "$PW_SCRIPT"
echo "const THANK_YOU_HTML = '${THANK_YOU_HTML}';" >> "$PW_SCRIPT"
echo "const WELCOME_HTML = '${WELCOME_HTML}';" >> "$PW_SCRIPT"

cat >> "$PW_SCRIPT" << 'PLAYWRIGHT_SCRIPT_BODY'

// --- Helpers ---
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function executeAction(page, step, stepLabel) {
  const action = step.action;
  if (!action) return;

  switch (action.type) {
    case 'navigate':
      console.log(`  [${stepLabel}] Navigate: ${action.target}`);
      await page.goto(action.target, { waitUntil: 'networkidle', timeout: 30000 });
      break;
    case 'click':
      console.log(`  [${stepLabel}] Click: ${action.target}`);
      await page.locator(action.target).click({ timeout: 10000 });
      break;
    case 'type':
      console.log(`  [${stepLabel}] Type into: ${action.target}`);
      if (action.humanSpeed) {
        await page.locator(action.target).click({ timeout: 10000 });
        await page.locator(action.target).pressSequentially(action.value || '', { delay: 120 });
      } else {
        await page.locator(action.target).fill(action.value || '', { timeout: 10000 });
      }
      break;
    case 'wait':
      console.log(`  [${stepLabel}] Wait for: ${action.target}`);
      await page.waitForSelector(action.target, { timeout: 15000 });
      break;
    case 'observe':
      console.log(`  [${stepLabel}] Observe: ${action.target}`);
      // No Playwright action — narration pause only
      break;
    case 'welcome':
      console.log(`  [${stepLabel}] Welcome slide`);
      if (fs.existsSync(WELCOME_HTML)) {
        const wp = encodeURIComponent(action.product || 'Demo');
        const ws = encodeURIComponent(action.subtitle || 'Product Demo');
        const wd = encodeURIComponent(action.date || new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }));
        await page.goto(`file://${WELCOME_HTML}?product=${wp}&subtitle=${ws}&date=${wd}`, { waitUntil: 'networkidle', timeout: 10000 });
      }
      break;
    case 'thankYou':
      console.log(`  [${stepLabel}] Thank-you slide`);
      if (fs.existsSync(THANK_YOU_HTML)) {
        const tp = encodeURIComponent(action.product || 'Demo');
        const td = encodeURIComponent(action.date || new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }));
        await page.goto(`file://${THANK_YOU_HTML}?product=${tp}&date=${td}`, { waitUntil: 'networkidle', timeout: 10000 });
      }
      break;
    default:
      console.log(`  [${stepLabel}] Unknown action type: ${action.type}`);
  }
}

function getAuthLocator(page) {
  return page.getByRole(AUTH_CHECK.role, { name: AUTH_CHECK.name });
}

// --- Authenticate and save storageState ---
async function ensureAuthenticated() {
  console.log('Checking authentication...');
  fs.mkdirSync(AUTH_CACHE_DIR, { recursive: true });

  // If we have a saved auth state, verify it still works
  if (fs.existsSync(AUTH_STATE_FILE)) {
    console.log('  Found saved auth state, verifying...');
    const browser = await chromium.launch({ headless: true });
    try {
      const ctx = await browser.newContext({
        storageState: AUTH_STATE_FILE,
        viewport: { width: 1920, height: 1080 },
        ignoreHTTPSErrors: true,
      });
      const page = await ctx.newPage();
      await page.goto(RECORDING_DATA.appUrl, { waitUntil: 'networkidle', timeout: 30000 });
      const isAuthed = await getAuthLocator(page)
        .isVisible({ timeout: 5000 }).catch(() => false);
      await ctx.close();
      await browser.close();

      if (isAuthed) {
        console.log('  Authenticated (saved session valid).');
        return;
      }
      console.log('  Saved session expired.');
    } catch {
      try { await browser.close(); } catch {}
    }
  }

  // Need fresh auth — use persistent context (supports WIA/NTLM/Kerberos)
  // Launched headed so user can interact with SSO if needed
  console.log('');
  console.log('  Launching browser for sign-in...');
  console.log('  >>> If prompted, complete SSO login in the browser window. <<<');
  console.log('  The script will continue automatically once authenticated.');
  console.log('');

  const authContext = await chromium.launchPersistentContext(AUTH_PROFILE_DIR, {
    headless: false,
    viewport: { width: 1280, height: 800 },
    ignoreHTTPSErrors: true,
  });

  const authPage = authContext.pages()[0] || await authContext.newPage();
  await authPage.goto(RECORDING_DATA.appUrl, { waitUntil: 'commit', timeout: 30000 });

  console.log('  Waiting for authentication to complete...');
  await getAuthLocator(authPage).waitFor({ state: 'visible', timeout: 120000 });
  console.log('  Authenticated!');

  // Save storageState (cookies + localStorage) for headless recording
  const state = await authContext.storageState();
  fs.writeFileSync(AUTH_STATE_FILE, JSON.stringify(state, null, 2));
  console.log(`  Auth state saved to ${AUTH_STATE_FILE}`);

  await sleep(500);
  await authContext.close();
}

// --- Main recording ---
async function record() {
  console.log('');
  console.log('=== Demo Recording ===');
  console.log(`App URL: ${RECORDING_DATA.appUrl}`);
  console.log(`Headed: ${HEADED}`);
  console.log('');

  fs.mkdirSync(VIDEO_DIR, { recursive: true });
  // Clear previous video/error files
  for (const f of fs.readdirSync(VIDEO_DIR)) {
    fs.unlinkSync(path.join(VIDEO_DIR, f));
  }

  // Launch browser with saved auth state and video recording
  const browser = await chromium.launch({ headless: !HEADED });
  const context = await browser.newContext({
    storageState: AUTH_STATE_FILE,
    viewport: { width: 1920, height: 1080 },
    recordVideo: { dir: VIDEO_DIR, size: { width: 1920, height: 1080 } },
    ignoreHTTPSErrors: true,
  });

  const page = await context.newPage();
  const failedSteps = [];

  try {
    // Guaranteed white-screen buffer for post-recording trim detection.
    // The auto-trim step detects the first non-white frame and removes
    // everything before it, so we need at least some white frames.
    await sleep(500);

    // In headed mode, additional pause for user to position/size the window
    if (HEADED) {
      console.log('');
      console.log('  Browser is open. Position the window now — recording starts in 2 seconds.');
      await sleep(2000);
      console.log('  Recording...');
      console.log('');
    }

    // Setup steps
    const setupSteps = RECORDING_DATA.setupSteps || [];
    if (setupSteps.length > 0) {
      console.log('Running setup steps...');
      for (const step of setupSteps) {
        const label = `setup-${String(step.id).padStart(3, '0')}`;
        try {
          await executeAction(page, step, label);
          await sleep(step.waitAfterAction || 1000);
        } catch (err) {
          console.error(`  ERROR in ${label}: ${err.message}`);
          try { await page.screenshot({ path: path.join(VIDEO_DIR, `error-${label}.png`) }); } catch {}
          failedSteps.push(label);
        }
      }

      // Confirm auth cookies worked after navigation
      console.log('  Waiting for app to load...');
      try {
        await getAuthLocator(page).waitFor({ state: 'visible', timeout: 15000 });
        console.log('  App loaded.');
      } catch {
        console.error('  ERROR: App did not load. Auth state may be invalid.');
        console.error(`  Delete ${AUTH_STATE_FILE} and re-run to re-authenticate.`);
        await context.close();
        await browser.close();
        process.exit(1);
      }
      console.log('');
    }

    // Main steps
    const steps = RECORDING_DATA.steps || [];
    console.log(`Running ${steps.length} demo steps...`);
    console.log('');

    for (let i = 0; i < steps.length; i++) {
      const step = steps[i];
      const label = `step-${String(step.id).padStart(3, '0')}`;
      const narrationPreview = (step.narration || '(no narration)').substring(0, 60);
      console.log(`[${i + 1}/${steps.length}] ${step.scenario}: ${narrationPreview}...`);

      try {
        await sleep(step.pauseBeforeNarration || 500);
        await executeAction(page, step, label);

        const audioDurationMs = (step.audioDuration || 0) * 1000;
        const waitAfter = step.waitAfterAction || 0;
        const totalWait = step.action?.type === 'observe' && audioDurationMs === 0
          ? Math.max(2000, waitAfter)
          : audioDurationMs + waitAfter;

        if (totalWait > 0) await sleep(totalWait);
      } catch (err) {
        console.error(`  ERROR in ${label}: ${err.message}`);
        try { await page.screenshot({ path: path.join(VIDEO_DIR, `error-${label}.png`) }); } catch {}
        failedSteps.push(label);

        // Still wait expected time so audio sync stays aligned
        const fallbackWait = (step.audioDuration || 0) * 1000 + (step.waitAfterAction || 0);
        if (fallbackWait > 0) await sleep(fallbackWait);
      }
    }

  } finally {
    console.log('');
    console.log('Closing browser and saving video...');

    let videoPath;
    try { videoPath = await page.video()?.path(); } catch {}

    await context.close();
    await browser.close();

    if (videoPath && fs.existsSync(videoPath)) {
      const dest = path.join(VIDEO_DIR, 'session.webm');
      fs.renameSync(videoPath, dest);
      console.log(`Video saved: ${dest}`);
    } else {
      console.error('WARNING: Video file not found after recording.');
    }
  }

  // Summary
  console.log('');
  console.log('=== Recording Complete ===');
  if (failedSteps.length > 0) {
    console.log(`WARNING: ${failedSteps.length} step(s) failed: ${failedSteps.join(', ')}`);
    console.log('Check error screenshots in video/ directory.');
    process.exit(2); // Partial success
  } else {
    console.log('All steps completed successfully.');
  }
}

// --- Entry point ---
async function main() {
  await ensureAuthenticated();

  if (AUTH_ONLY) {
    console.log('Auth-only mode complete. Exiting.');
    return;
  }

  await record();
}

main().catch(err => {
  console.error('FATAL:', err.message);
  process.exit(1);
});
PLAYWRIGHT_SCRIPT_BODY

echo "  Generated: ${PW_SCRIPT}" >&2
echo "" >&2

# --- Validate generated script syntax ---

if ! node --check "$PW_SCRIPT" 2>/dev/null; then
  echo "ERROR: Generated script has syntax errors." >&2
  exit 1
fi

echo "  Syntax check: OK" >&2

# --- Run the script (unless --dry-run) ---

if [ "$DRY_RUN" = true ]; then
  echo "  Dry run — skipping execution." >&2
  echo "" >&2
  echo "To run manually:" >&2
  echo "  node ${PW_SCRIPT}" >&2
  echo "" >&2
  echo "Options:" >&2
  echo "  node ${PW_SCRIPT} --auth-only   # Sign in only, no recording" >&2
  echo "  node ${PW_SCRIPT} --headed      # Record with visible browser" >&2
  exit 0
fi

echo "  Starting Playwright recording..." >&2
echo "" >&2

if node "$PW_SCRIPT" --headed; then
  true  # Success
elif [ $? -eq 2 ]; then
  echo "  Some steps failed — check error screenshots." >&2
else
  echo "" >&2
  echo "ERROR: Playwright recording failed." >&2
  exit 1
fi

# --- Auto-trim white screen from start of recording ---
# The recording always starts with a white-screen buffer (about:blank).
# Detect the first non-white frame and trim everything before it.

SESSION_WEBM="${VIDEO_DIR}/session.webm"
if [ -f "$SESSION_WEBM" ] && command -v ffprobe >/dev/null 2>&1; then
  echo "" >&2
  echo "  Detecting white-screen duration..." >&2

  # Fast detection: scale each frame to 1x1 grayscale pixel at 10fps for first 10 seconds.
  # Each byte = average brightness. White (about:blank) = 0xf0+ (240+), content = lower.
  SAMPLE_FPS=10
  TRIM_FRAME=$(ffmpeg -t 10 -i "$SESSION_WEBM" -vf "fps=${SAMPLE_FPS},scale=1:1,format=gray" \
    -f rawvideo -pix_fmt gray - 2>/dev/null \
    | od -A n -t u1 | tr -s ' ' '\n' | grep -v '^$' \
    | awk '{ if ($1 + 0 < 240) { print NR - 1; exit } }')

  # Convert frame number to timestamp
  if [ -n "$TRIM_FRAME" ] && [ "$TRIM_FRAME" -gt 0 ]; then
    TRIM_TIME=$(echo "scale=2; ${TRIM_FRAME} / ${SAMPLE_FPS}" | bc 2>/dev/null)
  else
    TRIM_TIME=""
  fi

  if [ -n "$TRIM_TIME" ] && [ "$(echo "$TRIM_TIME > 0.1" | bc 2>/dev/null)" = "1" ]; then
    echo "  White screen detected: ${TRIM_TIME}s — trimming..." >&2
    TRIMMED_WEBM="${VIDEO_DIR}/session-trimmed.webm"
    if ffmpeg -y -ss "$TRIM_TIME" -i "$SESSION_WEBM" -c:v libvpx -b:v 500k -r 25 "$TRIMMED_WEBM" 2>/dev/null; then
      mv "$TRIMMED_WEBM" "$SESSION_WEBM"
      echo "  Trimmed ${TRIM_TIME}s from start." >&2
    else
      echo "  WARNING: Trim failed, using untrimmed video." >&2
    fi
  else
    echo "  No white screen detected (or < 0.1s) — no trim needed." >&2
  fi
fi

echo "" >&2
echo "=== Video Recording Complete ===" >&2
echo "  Video: ${SESSION_WEBM}" >&2
exit 0
