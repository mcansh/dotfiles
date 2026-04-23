#!/bin/bash
# test-generate-playwright.sh - Test harness for generate-playwright.sh
# Tests script generation (dry-run only — no actual Playwright execution)
#
# Usage: ./test-generate-playwright.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATE_SCRIPT="${SCRIPT_DIR}/generate-playwright.sh"
TEST_TEMP=$(mktemp -d)
PASS_COUNT=0
FAIL_COUNT=0

cleanup() {
  rm -rf "$TEST_TEMP"
}
trap cleanup EXIT

# --- Test helpers ---

assert_exit_code() {
  local expected=$1
  local actual=$2
  local test_name=$3
  if [ "$actual" -eq "$expected" ]; then
    echo "  PASS: ${test_name} (exit code ${actual})"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: ${test_name} (expected exit ${expected}, got ${actual})"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_file_exists() {
  local file=$1
  local test_name=$2
  if [ -f "$file" ]; then
    echo "  PASS: ${test_name}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: ${test_name} (file not found)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_file_contains() {
  local file=$1
  local pattern=$2
  local test_name=$3
  if grep -q "$pattern" "$file" 2>/dev/null; then
    echo "  PASS: ${test_name}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: ${test_name} (pattern '${pattern}' not found)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_stderr_contains() {
  local stderr=$1
  local pattern=$2
  local test_name=$3
  if echo "$stderr" | grep -q "$pattern"; then
    echo "  PASS: ${test_name}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: ${test_name} (stderr missing '${pattern}')"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# --- Setup helpers ---

create_valid_script() {
  local dir="${TEST_TEMP}/$1/recording"
  mkdir -p "$dir"
  cat > "$dir/DEMO-RECORDING-SCRIPT.json" << 'EOF'
{
  "mode": "csuite",
  "voice": "Samantha",
  "appUrl": "http://localhost:8080",
  "generatedAt": "2026-03-05T14:30:00Z",
  "totalNarrationDuration": 8.5,
  "setupSteps": [
    {
      "id": 1,
      "narration": null,
      "action": { "type": "navigate", "target": "http://localhost:8080" },
      "audioDuration": 0,
      "audioFile": null
    }
  ],
  "steps": [
    {
      "id": 1,
      "scenario": "Intro",
      "narration": "Welcome to the demo.",
      "action": { "type": "observe", "target": "Landing page" },
      "waitAfterAction": 2000,
      "pauseBeforeNarration": 1000,
      "audioDuration": 2.5,
      "audioFile": "audio/step-001.aiff"
    },
    {
      "id": 2,
      "scenario": "Customer",
      "narration": "Click products.",
      "action": { "type": "click", "target": "a:has-text('Products')" },
      "waitAfterAction": 1500,
      "pauseBeforeNarration": 500,
      "audioDuration": 1.8,
      "audioFile": "audio/step-002.aiff"
    },
    {
      "id": 3,
      "scenario": "Customer",
      "narration": "Type to search.",
      "action": { "type": "type", "target": "#search", "value": "laptop" },
      "waitAfterAction": 1000,
      "pauseBeforeNarration": 500,
      "audioDuration": 1.5,
      "audioFile": "audio/step-003.aiff"
    }
  ]
}
EOF
  echo "$dir/DEMO-RECORDING-SCRIPT.json"
}

create_missing_duration_script() {
  local dir="${TEST_TEMP}/$1/recording"
  mkdir -p "$dir"
  cat > "$dir/DEMO-RECORDING-SCRIPT.json" << 'EOF'
{
  "mode": "general",
  "voice": "Samantha",
  "appUrl": "http://localhost:8080",
  "setupSteps": [],
  "steps": [
    {
      "id": 1,
      "scenario": "Test",
      "narration": "This step has no audioDuration field.",
      "action": { "type": "observe", "target": "Page" },
      "waitAfterAction": 1000,
      "pauseBeforeNarration": 500
    }
  ]
}
EOF
  echo "$dir/DEMO-RECORDING-SCRIPT.json"
}

create_special_selectors_script() {
  local dir="${TEST_TEMP}/$1/recording"
  mkdir -p "$dir"
  cat > "$dir/DEMO-RECORDING-SCRIPT.json" << 'EOF'
{
  "mode": "general",
  "voice": "Samantha",
  "appUrl": "http://localhost:8080",
  "setupSteps": [],
  "steps": [
    {
      "id": 1,
      "scenario": "Special Chars",
      "narration": "Testing selector with quotes and special chars.",
      "action": { "type": "click", "target": "button:has-text(\"Submit Order\")" },
      "waitAfterAction": 1000,
      "pauseBeforeNarration": 500,
      "audioDuration": 2.0,
      "audioFile": "audio/step-001.aiff"
    },
    {
      "id": 2,
      "scenario": "Special Chars",
      "narration": "Testing data-testid selector.",
      "action": { "type": "click", "target": "[data-testid='checkout-btn']" },
      "waitAfterAction": 1000,
      "pauseBeforeNarration": 500,
      "audioDuration": 1.5,
      "audioFile": "audio/step-002.aiff"
    }
  ]
}
EOF
  echo "$dir/DEMO-RECORDING-SCRIPT.json"
}

# --- Tests ---

echo "=== Testing generate-playwright.sh ==="
echo ""

# Test 1: No arguments
echo "Test 1: No arguments"
exit_code=0
bash "$GENERATE_SCRIPT" 2>/dev/null || exit_code=$?
assert_exit_code 1 "$exit_code" "Exits with error"
echo ""

# Test 2: Non-existent file
echo "Test 2: Non-existent file"
exit_code=0
bash "$GENERATE_SCRIPT" "/nonexistent/file.json" --dry-run 2>/dev/null || exit_code=$?
assert_exit_code 1 "$exit_code" "Exits with error"
echo ""

# Test 3: Missing audioDuration
echo "Test 3: Missing audioDuration fields"
script_file=$(create_missing_duration_script "test3")
exit_code=0
stderr_out=$(bash "$GENERATE_SCRIPT" "$script_file" --dry-run 2>&1 || exit_code=$?)
# Capture exit code properly
exit_code=0
bash "$GENERATE_SCRIPT" "$script_file" --dry-run 2>/dev/null || exit_code=$?
assert_exit_code 1 "$exit_code" "Exits with error for missing audioDuration"
echo ""

# Test 4: Valid script generates playwright-demo.js
echo "Test 4: Valid script (dry-run)"
script_file=$(create_valid_script "test4")
exit_code=0
bash "$GENERATE_SCRIPT" "$script_file" --dry-run 2>"${TEST_TEMP}/stderr4" || exit_code=$?
assert_exit_code 0 "$exit_code" "Exits successfully"
pw_file="$(dirname "$script_file")/playwright-demo.js"
assert_file_exists "$pw_file" "playwright-demo.js created"
echo ""

# Test 5: Generated script has valid JS syntax
echo "Test 5: Generated JS syntax"
script_file=$(create_valid_script "test5")
bash "$GENERATE_SCRIPT" "$script_file" --dry-run 2>/dev/null
pw_file="$(dirname "$script_file")/playwright-demo.js"
if node --check "$pw_file" 2>/dev/null; then
  echo "  PASS: Valid JavaScript syntax"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  FAIL: JavaScript syntax error"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# Test 6: Generated script contains key elements
echo "Test 6: Generated script content"
script_file=$(create_valid_script "test6")
bash "$GENERATE_SCRIPT" "$script_file" --dry-run 2>/dev/null
pw_file="$(dirname "$script_file")/playwright-demo.js"
assert_file_contains "$pw_file" "chromium" "Imports chromium"
assert_file_contains "$pw_file" "recordVideo" "Has recordVideo config"
assert_file_contains "$pw_file" "1920" "1920 resolution"
assert_file_contains "$pw_file" "1080" "1080 resolution"
assert_file_contains "$pw_file" "headless.*true" "Headless mode"
assert_file_contains "$pw_file" "ignoreHTTPSErrors" "HTTPS errors ignored"
assert_file_contains "$pw_file" "session.webm" "Renames to session.webm"
assert_file_contains "$pw_file" "networkidle" "Waits for networkidle"
assert_file_contains "$pw_file" "try" "Has try/catch"
assert_file_contains "$pw_file" "screenshot" "Takes screenshots on error"
echo ""

# Test 7: Special selectors handled
echo "Test 7: Special selectors in generated JS"
script_file=$(create_special_selectors_script "test7")
bash "$GENERATE_SCRIPT" "$script_file" --dry-run 2>/dev/null
pw_file="$(dirname "$script_file")/playwright-demo.js"
if node --check "$pw_file" 2>/dev/null; then
  echo "  PASS: Special selector chars don't break JS syntax"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  FAIL: Special selectors broke JS syntax"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# Test 8: Video directory created
echo "Test 8: Video directory created"
script_file=$(create_valid_script "test8")
bash "$GENERATE_SCRIPT" "$script_file" --dry-run 2>/dev/null
video_dir="$(dirname "$script_file")/video"
if [ -d "$video_dir" ]; then
  echo "  PASS: Video directory created"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  FAIL: Video directory not created"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# Test 9: Progress output
echo "Test 9: Progress output on stderr"
script_file=$(create_valid_script "test9")
stderr_output=$(bash "$GENERATE_SCRIPT" "$script_file" --dry-run 2>&1 >/dev/null)
assert_stderr_contains "$stderr_output" "Playwright Script Generation" "Header shown"
assert_stderr_contains "$stderr_output" "Syntax check: OK" "Syntax check reported"
assert_stderr_contains "$stderr_output" "Dry run" "Dry run message"
echo ""

# Test 10: Previous video files cleared
echo "Test 10: Previous video files cleared"
script_file=$(create_valid_script "test10")
video_dir="$(dirname "$script_file")/video"
mkdir -p "$video_dir"
touch "$video_dir/old-session.webm"
touch "$video_dir/old-error.png"
bash "$GENERATE_SCRIPT" "$script_file" --dry-run 2>/dev/null
if [ -f "$video_dir/old-session.webm" ]; then
  echo "  FAIL: Old WebM not cleared"
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  echo "  PASS: Old video files cleared"
  PASS_COUNT=$((PASS_COUNT + 1))
fi
echo ""

# --- Summary ---
echo "=== Results ==="
echo "  Passed: ${PASS_COUNT}"
echo "  Failed: ${FAIL_COUNT}"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "SOME TESTS FAILED"
  exit 1
else
  echo "ALL TESTS PASSED"
  exit 0
fi
