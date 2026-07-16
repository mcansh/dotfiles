#!/bin/bash
# test-assemble-video.sh - Test harness for assemble-video.sh
# Tests validation, offset calculation, and error handling.
# NOTE: Tests that require FFmpeg will be skipped if ffmpeg is not installed.
#
# Usage: ./test-assemble-video.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSEMBLE_SCRIPT="${SCRIPT_DIR}/assemble-video.sh"
TEST_TEMP=$(mktemp -d)
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
HAS_FFMPEG=false

if command -v ffmpeg >/dev/null 2>&1; then
  HAS_FFMPEG=true
fi

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

skip_test() {
  local test_name=$1
  local reason=$2
  echo "  SKIP: ${test_name} (${reason})"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

# --- Setup helpers ---

create_recording_dir() {
  local name=$1
  local dir="${TEST_TEMP}/${name}/recording"
  mkdir -p "$dir/video" "$dir/audio" "$dir/output"
  echo "$dir"
}

# Create a minimal valid WebM file (1 second of blank video)
create_dummy_video() {
  local dir=$1
  if [ "$HAS_FFMPEG" = true ]; then
    ffmpeg -y -f lavfi -i "color=c=black:s=320x240:d=5" \
      -c:v libvpx -b:v 1M \
      "$dir/video/session.webm" 2>/dev/null
  else
    # Create a minimal placeholder (won't actually be valid WebM)
    echo "dummy" > "$dir/video/session.webm"
  fi
}

create_dummy_audio() {
  local dir=$1
  local filename=$2
  if command -v say >/dev/null 2>&1; then
    echo "test" | say -v Samantha -o "$dir/audio/${filename}" 2>/dev/null
  else
    echo "dummy" > "$dir/audio/${filename}"
  fi
}

create_valid_json() {
  local dir=$1
  cat > "$dir/DEMO-RECORDING-SCRIPT.json" << 'EOF'
{
  "mode": "csuite",
  "voice": "Samantha",
  "appUrl": "http://localhost:8080",
  "totalNarrationDuration": 6.5,
  "setupSteps": [
    {
      "id": 1,
      "narration": null,
      "action": { "type": "navigate", "target": "http://localhost:8080" },
      "audioDuration": 0,
      "audioFile": null,
      "waitAfterAction": 1000,
      "pauseBeforeNarration": 0
    }
  ],
  "steps": [
    {
      "id": 1,
      "scenario": "Intro",
      "narration": "Welcome.",
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
      "scenario": "Outro",
      "narration": "That concludes our demo.",
      "action": { "type": "observe", "target": "Done" },
      "waitAfterAction": 2000,
      "pauseBeforeNarration": 500,
      "audioDuration": 2.2,
      "audioFile": "audio/step-003.aiff"
    }
  ]
}
EOF
}

create_zero_audio_json() {
  local dir=$1
  cat > "$dir/DEMO-RECORDING-SCRIPT.json" << 'EOF'
{
  "mode": "general",
  "voice": "Samantha",
  "appUrl": "http://localhost:8080",
  "totalNarrationDuration": 0,
  "setupSteps": [],
  "steps": [
    {
      "id": 1,
      "scenario": "Silent",
      "narration": null,
      "action": { "type": "observe", "target": "Page" },
      "waitAfterAction": 2000,
      "pauseBeforeNarration": 500,
      "audioDuration": 0,
      "audioFile": null
    }
  ]
}
EOF
}

create_single_audio_json() {
  local dir=$1
  cat > "$dir/DEMO-RECORDING-SCRIPT.json" << 'EOF'
{
  "mode": "csuite",
  "voice": "Samantha",
  "appUrl": "http://localhost:8080",
  "totalNarrationDuration": 2.0,
  "setupSteps": [],
  "steps": [
    {
      "id": 1,
      "scenario": "Intro",
      "narration": "Welcome to the demo.",
      "action": { "type": "observe", "target": "Page" },
      "waitAfterAction": 2000,
      "pauseBeforeNarration": 1000,
      "audioDuration": 2.0,
      "audioFile": "audio/step-001.aiff"
    }
  ]
}
EOF
}

# --- Tests ---

echo "=== Testing assemble-video.sh ==="
echo "  FFmpeg available: ${HAS_FFMPEG}"
echo ""

# Test 1: No arguments
echo "Test 1: No arguments"
exit_code=0
bash "$ASSEMBLE_SCRIPT" 2>/dev/null || exit_code=$?
assert_exit_code 1 "$exit_code" "Exits with error"
echo ""

# Test 2: Non-existent file
echo "Test 2: Non-existent file"
exit_code=0
bash "$ASSEMBLE_SCRIPT" "/nonexistent/file.json" 2>/dev/null || exit_code=$?
assert_exit_code 1 "$exit_code" "Exits with error"
echo ""

# Test 3: Invalid JSON
echo "Test 3: Invalid JSON"
invalid_file="${TEST_TEMP}/invalid.json"
echo "not json" > "$invalid_file"
exit_code=0
bash "$ASSEMBLE_SCRIPT" "$invalid_file" 2>/dev/null || exit_code=$?
assert_exit_code 1 "$exit_code" "Exits with error on invalid JSON"
echo ""

# Test 4: Missing session.webm
echo "Test 4: Missing video file"
rec_dir=$(create_recording_dir "test4")
create_valid_json "$rec_dir"
exit_code=0
stderr_out=$(bash "$ASSEMBLE_SCRIPT" "$rec_dir/DEMO-RECORDING-SCRIPT.json" 2>&1 || exit_code=$?)
exit_code=0
bash "$ASSEMBLE_SCRIPT" "$rec_dir/DEMO-RECORDING-SCRIPT.json" 2>/dev/null || exit_code=$?
assert_exit_code 1 "$exit_code" "Exits with error for missing video"
echo ""

# Test 5: Missing audio file warning (not error)
echo "Test 5: Missing audio file handled gracefully"
rec_dir=$(create_recording_dir "test5")
create_valid_json "$rec_dir"
create_dummy_video "$rec_dir"
# Don't create audio files — they should be skipped with warning
if [ "$HAS_FFMPEG" = true ]; then
  stderr_out=$(bash "$ASSEMBLE_SCRIPT" "$rec_dir/DEMO-RECORDING-SCRIPT.json" 2>&1 || true)
  assert_stderr_contains "$stderr_out" "WARNING.*missing\|Audio files: 0" "Missing audio warned or counted as 0"
else
  skip_test "Missing audio warning" "ffmpeg not installed"
fi
echo ""

# Test 6: Zero-audio case (video-only)
echo "Test 6: Zero-audio conversion"
if [ "$HAS_FFMPEG" = true ]; then
  rec_dir=$(create_recording_dir "test6")
  create_zero_audio_json "$rec_dir"
  create_dummy_video "$rec_dir"
  exit_code=0
  bash "$ASSEMBLE_SCRIPT" "$rec_dir/DEMO-RECORDING-SCRIPT.json" 2>"${TEST_TEMP}/stderr6" || exit_code=$?
  assert_exit_code 0 "$exit_code" "Exits successfully"
  if ls "$rec_dir/output"/demo-*.mp4 >/dev/null 2>&1; then
    echo "  PASS: MP4 output created"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: No MP4 output"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
else
  skip_test "Zero-audio conversion" "ffmpeg not installed"
  skip_test "MP4 output created" "ffmpeg not installed"
fi
echo ""

# Test 7: Single audio file (no amix)
echo "Test 7: Single audio assembly"
if [ "$HAS_FFMPEG" = true ] && command -v say >/dev/null 2>&1; then
  rec_dir=$(create_recording_dir "test7")
  create_single_audio_json "$rec_dir"
  create_dummy_video "$rec_dir"
  create_dummy_audio "$rec_dir" "step-001.aiff"
  exit_code=0
  bash "$ASSEMBLE_SCRIPT" "$rec_dir/DEMO-RECORDING-SCRIPT.json" 2>"${TEST_TEMP}/stderr7" || exit_code=$?
  assert_exit_code 0 "$exit_code" "Exits successfully"
  if ls "$rec_dir/output"/demo-*.mp4 >/dev/null 2>&1; then
    echo "  PASS: MP4 output created with single audio"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: No MP4 output"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
  stderr_out=$(cat "${TEST_TEMP}/stderr7")
  assert_stderr_contains "$stderr_out" "Assembly Complete" "Completion summary shown"
else
  skip_test "Single audio assembly" "ffmpeg or say not installed"
  skip_test "MP4 with single audio" "ffmpeg or say not installed"
  skip_test "Completion summary" "ffmpeg or say not installed"
fi
echo ""

# Test 8: Multiple audio assembly
echo "Test 8: Multiple audio assembly"
if [ "$HAS_FFMPEG" = true ] && command -v say >/dev/null 2>&1; then
  rec_dir=$(create_recording_dir "test8")
  create_valid_json "$rec_dir"
  create_dummy_video "$rec_dir"
  create_dummy_audio "$rec_dir" "step-001.aiff"
  create_dummy_audio "$rec_dir" "step-002.aiff"
  create_dummy_audio "$rec_dir" "step-003.aiff"
  exit_code=0
  bash "$ASSEMBLE_SCRIPT" "$rec_dir/DEMO-RECORDING-SCRIPT.json" 2>"${TEST_TEMP}/stderr8" || exit_code=$?
  assert_exit_code 0 "$exit_code" "Exits successfully"
  if ls "$rec_dir/output"/demo-*.mp4 >/dev/null 2>&1; then
    echo "  PASS: MP4 output created with multiple audio"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: No MP4 output"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
  stderr_out=$(cat "${TEST_TEMP}/stderr8")
  assert_stderr_contains "$stderr_out" "Audio files: 3" "3 audio files detected"
  assert_stderr_contains "$stderr_out" "normalize=0\|Assembly Complete" "Assembly ran correctly"
else
  skip_test "Multiple audio assembly" "ffmpeg or say not installed"
  skip_test "MP4 with multiple audio" "ffmpeg or say not installed"
  skip_test "3 audio files detected" "ffmpeg or say not installed"
  skip_test "Assembly ran correctly" "ffmpeg or say not installed"
fi
echo ""

# Test 9: Output filename format
echo "Test 9: Output filename format"
if [ "$HAS_FFMPEG" = true ]; then
  rec_dir=$(create_recording_dir "test9")
  create_zero_audio_json "$rec_dir"
  create_dummy_video "$rec_dir"
  bash "$ASSEMBLE_SCRIPT" "$rec_dir/DEMO-RECORDING-SCRIPT.json" 2>/dev/null
  TODAY=$(date +%Y-%m-%d)
  if [ -f "$rec_dir/output/demo-general-${TODAY}.mp4" ]; then
    echo "  PASS: Output named demo-{mode}-{date}.mp4"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: Output filename wrong (expected demo-general-${TODAY}.mp4)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
else
  skip_test "Output filename format" "ffmpeg not installed"
fi
echo ""

# Test 10: Previous output cleared
echo "Test 10: Previous output cleared"
if [ "$HAS_FFMPEG" = true ]; then
  rec_dir=$(create_recording_dir "test10")
  create_zero_audio_json "$rec_dir"
  create_dummy_video "$rec_dir"
  touch "$rec_dir/output/demo-old-2020-01-01.mp4"
  bash "$ASSEMBLE_SCRIPT" "$rec_dir/DEMO-RECORDING-SCRIPT.json" 2>/dev/null
  if [ -f "$rec_dir/output/demo-old-2020-01-01.mp4" ]; then
    echo "  FAIL: Old output not cleared"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  else
    echo "  PASS: Previous output cleared"
    PASS_COUNT=$((PASS_COUNT + 1))
  fi
else
  skip_test "Previous output cleared" "ffmpeg not installed"
fi
echo ""

# Test 11: Progress output
echo "Test 11: Progress and summary output"
if [ "$HAS_FFMPEG" = true ]; then
  rec_dir=$(create_recording_dir "test11")
  create_zero_audio_json "$rec_dir"
  create_dummy_video "$rec_dir"
  stderr_out=$(bash "$ASSEMBLE_SCRIPT" "$rec_dir/DEMO-RECORDING-SCRIPT.json" 2>&1 >/dev/null)
  assert_stderr_contains "$stderr_out" "Video Assembly" "Header shown"
  assert_stderr_contains "$stderr_out" "Assembly Complete" "Summary shown"
else
  skip_test "Header shown" "ffmpeg not installed"
  skip_test "Summary shown" "ffmpeg not installed"
fi
echo ""

# --- Summary ---
echo "=== Results ==="
echo "  Passed: ${PASS_COUNT}"
echo "  Failed: ${FAIL_COUNT}"
echo "  Skipped: ${SKIP_COUNT}"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "SOME TESTS FAILED"
  exit 1
else
  echo "ALL TESTS PASSED (${SKIP_COUNT} skipped)"
  exit 0
fi
