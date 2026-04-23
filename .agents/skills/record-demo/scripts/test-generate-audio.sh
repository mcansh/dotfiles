#!/bin/bash
# test-generate-audio.sh - Test harness for generate-audio.sh
#
# Usage: ./test-generate-audio.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATE_SCRIPT="${SCRIPT_DIR}/generate-audio.sh"
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
    echo "  FAIL: ${test_name} (file not found: ${file})"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_json_field() {
  local file=$1
  local field=$2
  local expected=$3
  local test_name=$4
  local actual
  actual=$(jq -r "${field}" "$file" 2>/dev/null || echo "PARSE_ERROR")
  if [ "$actual" = "$expected" ]; then
    echo "  PASS: ${test_name}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: ${test_name} (expected '${expected}', got '${actual}')"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_json_gt() {
  local file=$1
  local field=$2
  local min=$3
  local test_name=$4
  local actual
  actual=$(jq -r "${field}" "$file" 2>/dev/null || echo "0")
  if echo "$actual > $min" | bc -l 2>/dev/null | grep -q "1"; then
    echo "  PASS: ${test_name} (${actual} > ${min})"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: ${test_name} (${actual} not > ${min})"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# --- Setup sample recording scripts ---

create_basic_script() {
  local dir="${TEST_TEMP}/$1"
  mkdir -p "$dir/recording"
  cat > "$dir/recording/DEMO-RECORDING-SCRIPT.json" << 'JSONEOF'
{
  "mode": "general",
  "voice": "Samantha",
  "appUrl": "http://localhost:8080",
  "generatedAt": "2026-03-05T14:30:00Z",
  "setupSteps": [
    {
      "id": 1,
      "narration": null,
      "action": { "type": "navigate", "target": "http://localhost:8080" }
    }
  ],
  "steps": [
    {
      "id": 1,
      "scenario": "Intro",
      "narration": "Welcome to the demonstration. Today we will see the new checkout flow in action.",
      "action": { "type": "observe", "target": "Landing page visible" },
      "waitAfterAction": 2000,
      "pauseBeforeNarration": 1000
    },
    {
      "id": 2,
      "scenario": "Customer Purchase",
      "narration": "The customer navigates to the product catalog to find items.",
      "action": { "type": "click", "target": "a:has-text('Products')" },
      "waitAfterAction": 1500,
      "pauseBeforeNarration": 500
    }
  ]
}
JSONEOF
  echo "$dir/recording/DEMO-RECORDING-SCRIPT.json"
}

create_special_chars_script() {
  local dir="${TEST_TEMP}/$1"
  mkdir -p "$dir/recording"
  cat > "$dir/recording/DEMO-RECORDING-SCRIPT.json" << 'JSONEOF'
{
  "mode": "csuite",
  "voice": "Samantha",
  "appUrl": "http://localhost:8080",
  "generatedAt": "2026-03-05T14:30:00Z",
  "setupSteps": [],
  "steps": [
    {
      "id": 1,
      "scenario": "Test Special Chars",
      "narration": "Here we'll see the customer's dashboard -- it's quite impressive. The \"key metrics\" show a $500 increase.",
      "action": { "type": "observe", "target": "Dashboard" },
      "waitAfterAction": 1000,
      "pauseBeforeNarration": 500
    }
  ]
}
JSONEOF
  echo "$dir/recording/DEMO-RECORDING-SCRIPT.json"
}

create_empty_narration_script() {
  local dir="${TEST_TEMP}/$1"
  mkdir -p "$dir/recording"
  cat > "$dir/recording/DEMO-RECORDING-SCRIPT.json" << 'JSONEOF'
{
  "mode": "general",
  "voice": "Samantha",
  "appUrl": "http://localhost:8080",
  "generatedAt": "2026-03-05T14:30:00Z",
  "setupSteps": [
    {
      "id": 1,
      "narration": null,
      "action": { "type": "navigate", "target": "http://localhost:8080" }
    }
  ],
  "steps": [
    {
      "id": 1,
      "scenario": "Silent Step",
      "narration": "",
      "action": { "type": "click", "target": "#btn" },
      "waitAfterAction": 1000,
      "pauseBeforeNarration": 500
    },
    {
      "id": 2,
      "scenario": "Narrated Step",
      "narration": "This step has narration.",
      "action": { "type": "observe", "target": "Result" },
      "waitAfterAction": 1000,
      "pauseBeforeNarration": 500
    }
  ]
}
JSONEOF
  echo "$dir/recording/DEMO-RECORDING-SCRIPT.json"
}

# --- Tests ---

echo "=== Testing generate-audio.sh ==="
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
bash "$GENERATE_SCRIPT" "/nonexistent/file.json" 2>/dev/null || exit_code=$?
assert_exit_code 1 "$exit_code" "Exits with error"
echo ""

# Test 3: Invalid JSON
echo "Test 3: Invalid JSON"
invalid_file="${TEST_TEMP}/invalid.json"
echo "not json" > "$invalid_file"
exit_code=0
bash "$GENERATE_SCRIPT" "$invalid_file" 2>/dev/null || exit_code=$?
assert_exit_code 1 "$exit_code" "Exits with error on invalid JSON"
echo ""

# Test 4: Basic audio generation
echo "Test 4: Basic audio generation (2 narrated steps)"
script_file=$(create_basic_script "test4")
exit_code=0
bash "$GENERATE_SCRIPT" "$script_file" 2>"${TEST_TEMP}/stderr4" || exit_code=$?
assert_exit_code 0 "$exit_code" "Exits successfully"
assert_file_exists "$(dirname "$script_file")/audio/step-001.aiff" "Step 1 audio created"
assert_file_exists "$(dirname "$script_file")/audio/step-002.aiff" "Step 2 audio created"
# Verify JSON was updated
assert_json_gt "$script_file" ".steps[0].audioDuration" "0" "Step 1 has duration > 0"
assert_json_gt "$script_file" ".steps[1].audioDuration" "0" "Step 2 has duration > 0"
assert_json_gt "$script_file" ".totalNarrationDuration" "0" "Total duration > 0"
# Setup step with null narration should have audioDuration=0
assert_json_field "$script_file" ".setupSteps[0].audioDuration" "0" "Setup step has 0 duration"
assert_json_field "$script_file" ".setupSteps[0].audioFile" "null" "Setup step has null audioFile"
echo ""

# Test 5: Special characters in narration
echo "Test 5: Special characters (quotes, apostrophes, dollar signs, dashes)"
script_file=$(create_special_chars_script "test5")
exit_code=0
bash "$GENERATE_SCRIPT" "$script_file" 2>"${TEST_TEMP}/stderr5" || exit_code=$?
assert_exit_code 0 "$exit_code" "Handles special chars without error"
assert_file_exists "$(dirname "$script_file")/audio/step-001.aiff" "Audio file created"
assert_json_gt "$script_file" ".steps[0].audioDuration" "0" "Has valid duration"
echo ""

# Test 6: Empty/null narration handling
echo "Test 6: Empty and null narration skipped"
script_file=$(create_empty_narration_script "test6")
exit_code=0
bash "$GENERATE_SCRIPT" "$script_file" 2>"${TEST_TEMP}/stderr6" || exit_code=$?
assert_exit_code 0 "$exit_code" "Exits successfully"
# Only step 2 should have audio
if [ -f "$(dirname "$script_file")/audio/step-001.aiff" ]; then
  echo "  FAIL: Step 1 audio should NOT exist (empty narration)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  echo "  PASS: Step 1 audio correctly skipped (empty narration)"
  PASS_COUNT=$((PASS_COUNT + 1))
fi
assert_file_exists "$(dirname "$script_file")/audio/step-002.aiff" "Step 2 audio created (has narration)"
assert_json_field "$script_file" ".steps[0].audioDuration" "0" "Empty narration step has 0 duration"
assert_json_gt "$script_file" ".steps[1].audioDuration" "0" "Narrated step has duration > 0"
echo ""

# Test 7: Progress output
echo "Test 7: Progress output on stderr"
script_file=$(create_basic_script "test7")
stderr_output=$(bash "$GENERATE_SCRIPT" "$script_file" 2>&1 >/dev/null)
if echo "$stderr_output" | grep -q "Generating audio"; then
  echo "  PASS: Progress messages shown"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  FAIL: No progress messages on stderr"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
if echo "$stderr_output" | grep -q "Audio Generation Complete"; then
  echo "  PASS: Completion summary shown"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  FAIL: No completion summary"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# Test 8: Re-run clears previous audio
echo "Test 8: Re-run clears previous audio"
script_file=$(create_basic_script "test8")
bash "$GENERATE_SCRIPT" "$script_file" 2>/dev/null
# Create a stale file
touch "$(dirname "$script_file")/audio/step-999.aiff"
bash "$GENERATE_SCRIPT" "$script_file" 2>"${TEST_TEMP}/stderr8"
if [ -f "$(dirname "$script_file")/audio/step-999.aiff" ]; then
  echo "  FAIL: Stale audio file should have been removed"
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  echo "  PASS: Previous audio files cleared on re-run"
  PASS_COUNT=$((PASS_COUNT + 1))
fi
echo ""

# Test 9: Csuite mode rate
echo "Test 9: C-suite mode uses faster rate"
script_file=$(create_special_chars_script "test9")  # mode=csuite
stderr_output=$(bash "$GENERATE_SCRIPT" "$script_file" 2>&1 >/dev/null)
if echo "$stderr_output" | grep -q "Rate: 180"; then
  echo "  PASS: C-suite mode uses rate 180"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  FAIL: C-suite mode should use rate 180"
  FAIL_COUNT=$((FAIL_COUNT + 1))
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
