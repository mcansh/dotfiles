#!/bin/bash
# generate-audio.sh - Generate audio segments from DEMO-RECORDING-SCRIPT.json
# Uses macOS 'say' command to produce AIFF files for each narration step.
# Measures durations and updates the JSON with audio metadata.
#
# Usage: ./generate-audio.sh <path-to-DEMO-RECORDING-SCRIPT.json>
#
# Exit codes:
#   0 - All audio generated successfully
#   1 - Error (invalid JSON, say failure, etc.)

set -euo pipefail

SCRIPT_JSON="${1:-}"

# --- Validation ---

if [ -z "$SCRIPT_JSON" ]; then
  echo "ERROR: No recording script path provided." >&2
  echo "Usage: generate-audio.sh <path-to-DEMO-RECORDING-SCRIPT.json>" >&2
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

# --- Extract config from JSON ---

MODE=$(jq -r '.mode // "general"' "$SCRIPT_JSON")
DEMO_DIR=$(dirname "$SCRIPT_JSON")
# Go up one level if we're in recording/
if [ "$(basename "$DEMO_DIR")" = "recording" ]; then
  AUDIO_DIR="${DEMO_DIR}/audio"
else
  AUDIO_DIR="${DEMO_DIR}/recording/audio"
fi

# Rate per mode (can be overridden by rate field in JSON)
JSON_RATE=$(jq -r '.rate // ""' "$SCRIPT_JSON")
if [ -n "$JSON_RATE" ]; then
  RATE="$JSON_RATE"
elif [ "$MODE" = "csuite" ]; then
  RATE=180
else
  RATE=160
fi

echo "=== Audio Generation ===" >&2
echo "  Voice: system default (no -v flag)" >&2
echo "  Mode: ${MODE}" >&2
echo "  Rate: ${RATE} wpm" >&2
echo "" >&2

# --- Verify say command works ---

SAY_TEST=$(mktemp /tmp/say-test-XXXXXX.aiff)
if ! say -o "$SAY_TEST" "test" 2>/dev/null; then
  rm -f "$SAY_TEST"
  echo "ERROR: macOS 'say' command is not functional." >&2
  exit 1
fi
rm -f "$SAY_TEST"

# --- Prepare audio directory ---

mkdir -p "$AUDIO_DIR"

# Clear previous audio files
if ls "$AUDIO_DIR"/step-*.aiff >/dev/null 2>&1; then
  echo "  Removing previous audio files..." >&2
  rm -f "$AUDIO_DIR"/step-*.aiff
fi

# --- Duration measurement ---

get_duration() {
  local file="$1"
  local duration=""

  # Try afinfo first (macOS native)
  if command -v afinfo >/dev/null 2>&1; then
    duration=$(afinfo "$file" 2>/dev/null | grep "estimated duration" | awk '{print $3}')
  fi

  # Fall back to ffprobe
  if [ -z "$duration" ] && command -v ffprobe >/dev/null 2>&1; then
    duration=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$file" 2>/dev/null)
  fi

  # Validate we got a number
  if [ -z "$duration" ] || ! echo "$duration" | grep -qE '^[0-9]+\.?[0-9]*$'; then
    echo "0"
    return
  fi

  echo "$duration"
}

# --- Generate audio for steps ---

generate_step_audio() {
  local json_array_path="$1"  # ".setupSteps" or ".steps"
  local prefix="$2"           # "setup" or "step"
  local count
  count=$(jq "${json_array_path} | length" "$SCRIPT_JSON")

  local generated=0
  local total_duration=0

  for ((i = 0; i < count; i++)); do
    local narration
    narration=$(jq -r "${json_array_path}[$i].narration // \"\"" "$SCRIPT_JSON")

    # Skip null or empty narration
    if [ -z "$narration" ] || [ "$narration" = "null" ]; then
      continue
    fi

    local step_id
    step_id=$(jq -r "${json_array_path}[$i].id // $((i + 1))" "$SCRIPT_JSON")
    local audio_file="${AUDIO_DIR}/${prefix}-$(printf '%03d' "$step_id").aiff"

    echo "  Generating audio: ${prefix}-$(printf '%03d' "$step_id") ($((i + 1))/${count})..." >&2

    # CRITICAL: Pipe narration through stdin to avoid shell quoting issues
    # No -v flag: uses system default voice (Siri Voice 2 if configured)
    if ! printf '%s' "$narration" | say -r "$RATE" -o "$audio_file"; then
      echo "ERROR: 'say' command failed on ${prefix} step ${step_id}." >&2
      echo "  Narration: ${narration:0:80}..." >&2
      exit 1
    fi

    # Verify file was created
    if [ ! -f "$audio_file" ]; then
      echo "ERROR: Audio file not created: ${audio_file}" >&2
      exit 1
    fi

    # Measure duration
    local duration
    duration=$(get_duration "$audio_file")

    # Warn if unusually long
    local dur_int=${duration%%.*}
    if [ "${dur_int:-0}" -gt 30 ]; then
      echo "  WARNING: Step ${step_id} audio is ${duration}s (>30s). Consider shortening narration." >&2
    fi

    # Accumulate
    total_duration=$(echo "$total_duration + $duration" | bc 2>/dev/null || echo "$total_duration")
    generated=$((generated + 1))

    # Store results for JSON update (use temp file to collect)
    echo "${json_array_path}|${i}|${audio_file}|${duration}" >> "$RESULTS_FILE"
  done

  echo "$generated|$total_duration"
}

# --- Main execution ---

RESULTS_FILE=$(mktemp)
trap 'rm -f "$RESULTS_FILE"' EXIT

echo "Processing setupSteps..." >&2
setup_result=$(generate_step_audio ".setupSteps" "setup")
setup_count=${setup_result%%|*}
setup_duration=${setup_result##*|}

echo "Processing steps..." >&2
steps_result=$(generate_step_audio ".steps" "step")
steps_count=${steps_result%%|*}
steps_duration=${steps_result##*|}

total_count=$((setup_count + steps_count))
total_duration=$(echo "${setup_duration:-0} + ${steps_duration:-0}" | bc 2>/dev/null || echo "0")

echo "" >&2

# --- Update JSON with audio metadata ---

echo "Updating recording script with audio metadata..." >&2

# Build jq update expression from results
TEMP_JSON=$(mktemp)
cp "$SCRIPT_JSON" "$TEMP_JSON"

while IFS='|' read -r array_path index audio_file duration; do
  # Make audio_file relative to the recording directory
  local_audio_file=$(basename "$audio_file")
  TEMP_JSON2=$(mktemp)
  jq "${array_path}[${index}].audioFile = \"audio/${local_audio_file}\" | ${array_path}[${index}].audioDuration = ${duration}" "$TEMP_JSON" > "$TEMP_JSON2"
  mv "$TEMP_JSON2" "$TEMP_JSON"
done < "$RESULTS_FILE"

# Also set audioDuration=0 for steps without narration
for array_path in ".setupSteps" ".steps"; do
  count=$(jq "${array_path} | length" "$TEMP_JSON")
  for ((i = 0; i < count; i++)); do
    has_audio=$(jq -r "${array_path}[$i].audioFile // \"\"" "$TEMP_JSON")
    if [ -z "$has_audio" ]; then
      TEMP_JSON2=$(mktemp)
      jq "${array_path}[${i}].audioFile = null | ${array_path}[${i}].audioDuration = 0" "$TEMP_JSON" > "$TEMP_JSON2"
      mv "$TEMP_JSON2" "$TEMP_JSON"
    fi
  done
done

# Add totalNarrationDuration to top level
TEMP_JSON2=$(mktemp)
jq ".totalNarrationDuration = ${total_duration}" "$TEMP_JSON" > "$TEMP_JSON2"
mv "$TEMP_JSON2" "$TEMP_JSON"

# Atomic move to final location
mv "$TEMP_JSON" "$SCRIPT_JSON"

# --- Summary ---

# Format duration as M:SS
total_minutes=$(echo "$total_duration / 60" | bc 2>/dev/null || echo "0")
total_seconds=$(echo "$total_duration - ($total_minutes * 60)" | bc 2>/dev/null | cut -d. -f1 || echo "0")
formatted_duration=$(printf "%d:%02d" "${total_minutes:-0}" "${total_seconds:-0}")

echo "=== Audio Generation Complete ===" >&2
echo "  Generated: ${total_count} audio files" >&2
echo "  Total narration: ${formatted_duration} (${total_duration}s)" >&2
echo "  Output: ${AUDIO_DIR}/" >&2
echo "  Updated: ${SCRIPT_JSON}" >&2

exit 0
