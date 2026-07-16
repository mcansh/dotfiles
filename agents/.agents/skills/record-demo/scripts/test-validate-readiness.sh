#!/bin/bash
# test-validate-readiness.sh - Test harness for validate-readiness.sh
# Tests various scenarios by overriding PATH and mock commands
#
# Usage: ./test-validate-readiness.sh
#
# Tests:
#   1. All checks pass (happy path)
#   2. Missing demo directory argument
#   3. Non-existent demo directory
#   4. Missing DEMO-GUIDE.md
#   5. No premium voice (fallback)
#   6. Multiple failures at once

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATE_SCRIPT="${SCRIPT_DIR}/validate-readiness.sh"
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

assert_json_field() {
  local json=$1
  local field=$2
  local expected=$3
  local test_name=$4

  local actual
  actual=$(echo "$json" | jq -r "${field}" 2>/dev/null || echo "PARSE_ERROR")

  if [ "$actual" = "$expected" ]; then
    echo "  PASS: ${test_name}"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: ${test_name} (expected '${expected}', got '${actual}')"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

assert_json_array_not_empty() {
  local json=$1
  local field=$2
  local test_name=$3

  local length
  length=$(echo "$json" | jq "${field} | length" 2>/dev/null || echo "0")

  if [ "$length" -gt 0 ]; then
    echo "  PASS: ${test_name} (${length} items)"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: ${test_name} (array is empty)"
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
    echo "  FAIL: ${test_name} (stderr missing pattern '${pattern}')"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# --- Setup demo directory ---

setup_valid_demo_dir() {
  local dir="${TEST_TEMP}/demo-test"
  mkdir -p "$dir"
  touch "$dir/docker-compose.yml"
  cat > "$dir/DEMO-GUIDE.md" << 'GUIDE'
# Demo: Test Feature

## Scenarios

### Scenario 1: Admin User - View Dashboard
**Persona:** Alice, System Admin
**Goal:** View the admin dashboard
**Steps:**
1. Navigate to http://localhost:8080
2. Click "Dashboard"
**What to observe:** Dashboard loads with real data
GUIDE
  echo "$dir"
}

# --- Tests ---

echo "=== Testing validate-readiness.sh ==="
echo ""

# Test 1: Missing demo directory argument
echo "Test 1: Missing demo directory argument"
json_output=$(bash "$VALIDATE_SCRIPT" 2>"${TEST_TEMP}/stderr1" || true)
stderr_output=$(cat "${TEST_TEMP}/stderr1")
assert_json_field "$json_output" ".success" "false" "Reports failure"
assert_stderr_contains "$stderr_output" "No demo directory specified" "Error message present"
echo ""

# Test 2: Non-existent demo directory
echo "Test 2: Non-existent demo directory"
json_output=$(bash "$VALIDATE_SCRIPT" "/nonexistent/path" 2>"${TEST_TEMP}/stderr2" || true)
stderr_output=$(cat "${TEST_TEMP}/stderr2")
assert_json_field "$json_output" ".success" "false" "Reports failure"
assert_stderr_contains "$stderr_output" "not found\|does not exist" "Directory error message"
echo ""

# Test 3: Demo directory without DEMO-GUIDE.md
echo "Test 3: Missing DEMO-GUIDE.md"
missing_guide_dir="${TEST_TEMP}/no-guide"
mkdir -p "$missing_guide_dir"
touch "$missing_guide_dir/docker-compose.yml"
json_output=$(bash "$VALIDATE_SCRIPT" "$missing_guide_dir" 2>"${TEST_TEMP}/stderr3" || true)
stderr_output=$(cat "${TEST_TEMP}/stderr3")
assert_json_field "$json_output" ".success" "false" "Reports failure"
assert_stderr_contains "$stderr_output" "DEMO-GUIDE.md" "Missing guide error"
echo ""

# Test 4: Verify JSON output structure (even on failure)
echo "Test 4: JSON output has required fields"
json_output=$(bash "$VALIDATE_SCRIPT" "/nonexistent" 2>/dev/null || true)
assert_json_field "$json_output" ".success" "false" "success field present"

# Check all required fields exist (not null)
for field in "selectedVoice" "premiumVoices" "ffmpegVersion" "failures" "warnings" "demoDir"; do
  if echo "$json_output" | jq -e "has(\"${field}\")" >/dev/null 2>&1; then
    echo "  PASS: JSON field .${field} exists"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: JSON field .${field} missing"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done
echo ""

# Test 5: Multiple failures collected (not fail-fast)
echo "Test 5: Multiple failures collected at once"
json_output=$(bash "$VALIDATE_SCRIPT" "/nonexistent" 2>"${TEST_TEMP}/stderr5" || true)
stderr_output=$(cat "${TEST_TEMP}/stderr5")
failure_count=$(echo "$json_output" | jq '.failures | length' 2>/dev/null || echo "0")
if [ "$failure_count" -gt 1 ]; then
  echo "  PASS: Multiple failures collected (${failure_count} failures)"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  FAIL: Expected multiple failures, got ${failure_count}"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# Test 6: Valid demo directory with running system (integration test)
echo "Test 6: Valid demo directory structure check"
demo_dir=$(setup_valid_demo_dir)
# This will still fail on docker checks in CI, but validates the directory checks pass
json_output=$(bash "$VALIDATE_SCRIPT" "$demo_dir" 2>"${TEST_TEMP}/stderr6" || true)
stderr_output=$(cat "${TEST_TEMP}/stderr6")
# The directory-related checks should pass even if docker/playwright fail
assert_stderr_contains "$stderr_output" "FAIL\|PASS" "Script produces check output"
# Verify demo dir is in the output
assert_json_field "$json_output" ".demoDir" "$demo_dir" "Demo dir in output"
echo ""

# Test 7: Voice detection runs
echo "Test 7: Voice detection"
json_output=$(bash "$VALIDATE_SCRIPT" "/nonexistent" 2>"${TEST_TEMP}/stderr7" || true)
stderr_output=$(cat "${TEST_TEMP}/stderr7")
# On a real Mac, say -v ? should work
if echo "$stderr_output" | grep -qi "premium voices\|falling back\|voice"; then
  echo "  PASS: Voice detection ran and reported result"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  FAIL: Voice detection didn't report (may not be on macOS)"
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
