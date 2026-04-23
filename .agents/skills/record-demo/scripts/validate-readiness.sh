#!/bin/bash
# validate-readiness.sh - Pre-flight check for demo recording pipeline
# Checks all prerequisites and reports ALL failures with install instructions.
# Usage: ./validate-readiness.sh <demo-directory>
#
# Exit codes:
#   0 - All checks passed
#   1 - One or more checks failed
#
# Output:
#   JSON object with check results on stdout
#   Human-readable status on stderr

set -euo pipefail

DEMO_DIR="${1:-}"
FAILURES=()
WARNINGS=()
DETECTED_VOICE=""
FFMPEG_VERSION=""
FFPROBE_VERSION=""
PLAYWRIGHT_VERSION=""

# --- Helper functions ---

add_failure() {
  FAILURES+=("$1")
}

add_warning() {
  WARNINGS+=("$1")
}

# --- Check functions ---

check_ffmpeg() {
  if output=$(ffmpeg -version 2>&1); then
    FFMPEG_VERSION=$(echo "$output" | head -1 | sed 's/ffmpeg version //' | awk '{print $1}')
    echo "  [PASS] ffmpeg ${FFMPEG_VERSION}" >&2
  else
    add_failure "ffmpeg not found or not functional. Install: brew install ffmpeg"
    echo "  [FAIL] ffmpeg not installed" >&2
    return
  fi
}

check_ffprobe() {
  if output=$(ffprobe -version 2>&1); then
    echo "  [PASS] ffprobe available" >&2
  else
    add_failure "ffprobe not found. It ships with ffmpeg. Install: brew install ffmpeg"
    echo "  [FAIL] ffprobe not installed" >&2
  fi
}

check_ffmpeg_codecs() {
  if [ -z "$FFMPEG_VERSION" ]; then
    # ffmpeg itself failed, skip codec check
    return
  fi

  local missing_codecs=()

  local codec_output
  codec_output=$(ffmpeg -codecs 2>/dev/null || true)

  if ! echo "$codec_output" | grep -q "libx264"; then
    missing_codecs+=("libx264")
  fi

  if ! echo "$codec_output" | grep -q "aac"; then
    missing_codecs+=("aac")
  fi

  if [ ${#missing_codecs[@]} -gt 0 ]; then
    add_failure "ffmpeg missing required codecs: ${missing_codecs[*]}. Reinstall: brew install ffmpeg"
    echo "  [FAIL] ffmpeg missing codecs: ${missing_codecs[*]}" >&2
  else
    echo "  [PASS] ffmpeg codecs (libx264, aac)" >&2
  fi
}

check_say() {
  # Verify macOS say command works. We use the system default voice (no -v flag)
  # which uses whatever is set in System Settings > Accessibility > Spoken Content.
  # For best quality, set the system default to Siri Voice 2.
  # Timeout protection against hung speech daemon (5 seconds)
  # macOS doesn't have `timeout` command, use perl one-liner
  local say_test
  say_test=$(mktemp /tmp/say-test-XXXXXX.aiff)
  if ! perl -e 'alarm 5; exec @ARGV' say -o "$say_test" "test" 2>&1 >/dev/null; then
    rm -f "$say_test"
    add_failure "macOS 'say' command failed or timed out. Ensure Speech Synthesis is functional in System Settings."
    echo "  [FAIL] say command failed" >&2
    return
  fi

  rm -f "$say_test"
  DETECTED_VOICE="system default"
  echo "  [PASS] macOS say command (using system default voice)" >&2
  echo "  [INFO] For best quality, set Siri Voice 2 in System Settings > Accessibility > Spoken Content" >&2
}

check_playwright() {
  # Use --no-install to prevent npx from auto-installing
  if output=$(npx --no-install playwright --version 2>&1); then
    PLAYWRIGHT_VERSION="$output"
    echo "  [PASS] Playwright ${PLAYWRIGHT_VERSION}" >&2
  else
    add_failure "Playwright not installed. Install: npm install -D @playwright/test && npx playwright install chromium"
    echo "  [FAIL] Playwright not installed" >&2
    return
  fi

  # Check that Chromium browser is actually installed
  # Playwright stores browsers in a known location
  local browser_path
  browser_path=$(npx --no-install playwright install --dry-run chromium 2>&1 || true)

  # Alternative: try to launch and see if it fails
  # Check the browsers directory
  local pw_browsers_path="${PLAYWRIGHT_BROWSERS_PATH:-${HOME}/Library/Caches/ms-playwright}"
  if [ -d "$pw_browsers_path" ]; then
    if ls "$pw_browsers_path"/chromium-* >/dev/null 2>&1; then
      echo "  [PASS] Chromium browser installed" >&2
    else
      add_failure "Playwright Chromium browser not installed. Install: npx playwright install chromium"
      echo "  [FAIL] Chromium browser not found in ${pw_browsers_path}" >&2
    fi
  else
    add_failure "Playwright browser directory not found at ${pw_browsers_path}. Install: npx playwright install chromium"
    echo "  [FAIL] Playwright browser directory missing" >&2
  fi
}

check_docker() {
  if docker info >/dev/null 2>&1; then
    echo "  [PASS] Docker running" >&2
  else
    add_failure "Docker is not running. Start Docker Desktop before recording."
    echo "  [FAIL] Docker not running" >&2
  fi
}

check_demo_environment() {
  if [ -z "$DEMO_DIR" ]; then
    add_failure "No demo directory specified. Usage: validate-readiness.sh <demo-directory>"
    echo "  [FAIL] No demo directory specified" >&2
    return
  fi

  if [ ! -d "$DEMO_DIR" ]; then
    add_failure "Demo directory does not exist: ${DEMO_DIR}"
    echo "  [FAIL] Demo directory not found: ${DEMO_DIR}" >&2
    return
  fi

  if [ ! -f "${DEMO_DIR}/docker-compose.yml" ] && [ ! -f "${DEMO_DIR}/docker-compose.yaml" ] && [ ! -f "${DEMO_DIR}/compose.yml" ] && [ ! -f "${DEMO_DIR}/compose.yaml" ]; then
    add_failure "No docker-compose file found in ${DEMO_DIR}. Run generate-demo first."
    echo "  [FAIL] No docker-compose file in ${DEMO_DIR}" >&2
    return
  fi

  if [ ! -f "${DEMO_DIR}/DEMO-GUIDE.md" ]; then
    add_failure "No DEMO-GUIDE.md found in ${DEMO_DIR}. Run generate-demo first."
    echo "  [FAIL] No DEMO-GUIDE.md in ${DEMO_DIR}" >&2
    return
  fi

  # Check if containers are running and healthy
  local compose_output
  if ! compose_output=$(cd "$DEMO_DIR" && docker compose ps --format json 2>&1); then
    add_failure "Failed to check demo containers. Run: cd ${DEMO_DIR} && docker compose up -d"
    echo "  [FAIL] docker compose ps failed in ${DEMO_DIR}" >&2
    return
  fi

  if [ -z "$compose_output" ]; then
    add_failure "No containers running in ${DEMO_DIR}. Run: cd ${DEMO_DIR} && docker compose up -d"
    echo "  [FAIL] No containers running" >&2
    return
  fi

  # Check for unhealthy or exited containers
  local unhealthy=()
  while IFS= read -r line; do
    if [ -z "$line" ]; then continue; fi
    local name state health
    name=$(echo "$line" | jq -r '.Name // .Service // "unknown"' 2>/dev/null || echo "unknown")
    state=$(echo "$line" | jq -r '.State // "unknown"' 2>/dev/null || echo "unknown")
    health=$(echo "$line" | jq -r '.Health // "none"' 2>/dev/null || echo "none")

    if [ "$state" != "running" ]; then
      unhealthy+=("${name} (state: ${state})")
    elif [ "$health" != "none" ] && [ "$health" != "healthy" ] && [ "$health" != "" ]; then
      unhealthy+=("${name} (health: ${health})")
    fi
  done <<< "$compose_output"

  if [ ${#unhealthy[@]} -gt 0 ]; then
    add_failure "Unhealthy containers in ${DEMO_DIR}: ${unhealthy[*]}. Check: cd ${DEMO_DIR} && docker compose ps"
    echo "  [FAIL] Unhealthy containers: ${unhealthy[*]}" >&2
  else
    echo "  [PASS] Demo environment healthy" >&2
  fi
}

# --- Main ---

echo "=== Demo Recording Pre-flight Check ===" >&2
echo "" >&2

check_ffmpeg
check_ffprobe
check_ffmpeg_codecs
check_say
check_playwright
check_docker
check_demo_environment

echo "" >&2

# --- Output results ---

if [ ${#FAILURES[@]} -gt 0 ]; then
  echo "=== FAILED: ${#FAILURES[@]} check(s) failed ===" >&2
  echo "" >&2
  for i in "${!FAILURES[@]}"; do
    echo "  $(( i + 1 )). ${FAILURES[$i]}" >&2
  done
  echo "" >&2
  echo "Fix all issues above and re-run." >&2
fi

if [ ${#WARNINGS[@]} -gt 0 ]; then
  echo "=== WARNINGS ===" >&2
  for warning in "${WARNINGS[@]}"; do
    echo "  - ${warning}" >&2
  done
  echo "" >&2
fi

# JSON output on stdout for programmatic consumption
# Escape quotes in strings for JSON safety
json_failures="["
for i in "${!FAILURES[@]}"; do
  [ "$i" -gt 0 ] && json_failures+=","
  # Simple escaping for common characters
  escaped=$(echo "${FAILURES[$i]}" | sed 's/"/\\"/g')
  json_failures+="\"${escaped}\""
done
json_failures+="]"

json_warnings="["
for i in "${!WARNINGS[@]}"; do
  [ "$i" -gt 0 ] && json_warnings+=","
  escaped=$(echo "${WARNINGS[$i]}" | sed 's/"/\\"/g')
  json_warnings+="\"${escaped}\""
done
json_warnings+="]"

cat <<EOF
{
  "success": $([ ${#FAILURES[@]} -eq 0 ] && echo "true" || echo "false"),
  "voice": "${DETECTED_VOICE}",
  "ffmpegVersion": "${FFMPEG_VERSION}",
  "playwrightVersion": "${PLAYWRIGHT_VERSION}",
  "failures": ${json_failures},
  "warnings": ${json_warnings},
  "demoDir": "${DEMO_DIR}"
}
EOF

# Exit with appropriate code
if [ ${#FAILURES[@]} -gt 0 ]; then
  exit 1
fi

exit 0
