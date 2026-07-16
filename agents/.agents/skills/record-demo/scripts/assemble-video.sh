#!/bin/bash
# assemble-video.sh - Merge audio segments onto video to produce final MP4
# Reads DEMO-RECORDING-SCRIPT.json for timing data, uses FFmpeg to overlay
# audio at correct timestamps, outputs playable MP4.
#
# Usage: ./assemble-video.sh <path-to-DEMO-RECORDING-SCRIPT.json>
#
# Exit codes:
#   0 - Assembly completed successfully
#   1 - Error (missing inputs, FFmpeg failure, etc.)

set -euo pipefail

SCRIPT_JSON="${1:-}"

# --- Validation ---

if [ -z "$SCRIPT_JSON" ]; then
  echo "ERROR: No recording script path provided." >&2
  echo "Usage: assemble-video.sh <path-to-DEMO-RECORDING-SCRIPT.json>" >&2
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

# --- Extract config ---

DEMO_DIR=$(dirname "$SCRIPT_JSON")
if [ "$(basename "$DEMO_DIR")" = "recording" ]; then
  RECORDING_DIR="$DEMO_DIR"
else
  RECORDING_DIR="${DEMO_DIR}/recording"
fi

VIDEO_FILE="${RECORDING_DIR}/video/session.webm"
AUDIO_DIR="${RECORDING_DIR}/audio"
OUTPUT_DIR="${RECORDING_DIR}/output"
MODE=$(jq -r '.mode // "general"' "$SCRIPT_JSON")
TODAY=$(date +%Y-%m-%d)
OUTPUT_FILE="${OUTPUT_DIR}/demo-${MODE}-${TODAY}.mp4"

# Validate video exists
if [ ! -f "$VIDEO_FILE" ]; then
  echo "ERROR: Video not found: ${VIDEO_FILE}" >&2
  echo "  Run generate-playwright.sh first." >&2
  exit 1
fi

echo "=== Video Assembly ===" >&2
echo "  Video: ${VIDEO_FILE}" >&2
echo "  Audio: ${AUDIO_DIR}/" >&2
echo "  Mode: ${MODE}" >&2
echo "  Output: ${OUTPUT_FILE}" >&2
echo "" >&2

# --- Prepare output directory ---

mkdir -p "$OUTPUT_DIR"

# Clear previous output
if ls "$OUTPUT_DIR"/demo-*.mp4 >/dev/null 2>&1; then
  echo "  Removing previous output files..." >&2
  rm -f "$OUTPUT_DIR"/demo-*.mp4
fi

# Remove any partial output from interrupted runs
rm -f "$OUTPUT_FILE"

# --- Collect audio files and calculate offsets ---

# Process setupSteps and steps in order, calculating cumulative offset
# Each step contributes: pauseBeforeNarration + (audioDuration * 1000) + waitAfterAction
# Audio starts at: cumulative_offset + pauseBeforeNarration

AUDIO_INPUTS=()       # FFmpeg -i arguments
AUDIO_OFFSETS_MS=()   # Offset in ms for each audio input
CUMULATIVE_MS=0

process_steps() {
  local array_path="$1"
  local prefix="$2"
  local count
  count=$(jq "${array_path} | length" "$SCRIPT_JSON" 2>/dev/null || echo "0")

  for ((i = 0; i < count; i++)); do
    local audio_file
    audio_file=$(jq -r "${array_path}[$i].audioFile // \"\"" "$SCRIPT_JSON")
    local pause_before
    pause_before=$(jq -r "${array_path}[$i].pauseBeforeNarration // 0" "$SCRIPT_JSON")
    local audio_duration
    audio_duration=$(jq -r "${array_path}[$i].audioDuration // 0" "$SCRIPT_JSON")
    local wait_after
    wait_after=$(jq -r "${array_path}[$i].waitAfterAction // 0" "$SCRIPT_JSON")

    # Convert audioDuration (seconds float) to integer ms
    local audio_duration_ms
    audio_duration_ms=$(echo "$audio_duration * 1000" | bc 2>/dev/null | cut -d. -f1 || echo "0")
    audio_duration_ms=${audio_duration_ms:-0}

    # Convert pause/wait to integer
    pause_before=${pause_before%%.*}
    pause_before=${pause_before:-0}
    wait_after=${wait_after%%.*}
    wait_after=${wait_after:-0}

    # Audio starts at cumulative + pauseBeforeNarration
    local audio_start_ms=$((CUMULATIVE_MS + pause_before))

    # If this step has audio, collect it
    if [ -n "$audio_file" ] && [ "$audio_file" != "null" ]; then
      local full_audio_path="${RECORDING_DIR}/${audio_file}"
      if [ -f "$full_audio_path" ]; then
        AUDIO_INPUTS+=("$full_audio_path")
        AUDIO_OFFSETS_MS+=("$audio_start_ms")
      else
        echo "  WARNING: Audio file missing, skipping: ${full_audio_path}" >&2
      fi
    fi

    # Accumulate total time for this step
    # Minimum wait for observe with no audio: 2000ms (matches Playwright timing)
    local step_total_ms
    local action_type
    action_type=$(jq -r "${array_path}[$i].action.type // \"\"" "$SCRIPT_JSON")
    if [ "$action_type" = "observe" ] && [ "$audio_duration_ms" -eq 0 ]; then
      local min_wait=2000
      step_total_ms=$((pause_before + (wait_after > min_wait ? wait_after : min_wait)))
    else
      step_total_ms=$((pause_before + audio_duration_ms + wait_after))
    fi

    CUMULATIVE_MS=$((CUMULATIVE_MS + step_total_ms))
  done
}

echo "  Calculating audio offsets..." >&2
process_steps ".setupSteps" "setup"
process_steps ".steps" "step"

AUDIO_COUNT=${#AUDIO_INPUTS[@]}
echo "  Audio files: ${AUDIO_COUNT}" >&2
echo "  Timeline: ${CUMULATIVE_MS}ms (~$((CUMULATIVE_MS / 1000))s)" >&2
echo "" >&2

# --- Build and run FFmpeg command ---

if [ "$AUDIO_COUNT" -eq 0 ]; then
  # No audio — just convert WebM to MP4
  echo "  No audio files — converting video only..." >&2
  if ! ffmpeg -y -i "$VIDEO_FILE" -c:v libx264 -preset fast -an "$OUTPUT_FILE" 2>&1 | tail -5 >&2; then
    echo "ERROR: FFmpeg conversion failed." >&2
    rm -f "$OUTPUT_FILE"
    exit 1
  fi

elif [ "$AUDIO_COUNT" -eq 1 ]; then
  # Single audio file — adelay + direct map, no amix needed
  local_offset="${AUDIO_OFFSETS_MS[0]}"
  echo "  Single audio at offset ${local_offset}ms..." >&2

  if ! ffmpeg -y -i "$VIDEO_FILE" -i "${AUDIO_INPUTS[0]}" \
    -filter_complex "[1:a]adelay=${local_offset}|${local_offset}[aout]" \
    -map 0:v -map "[aout]" \
    -c:v libx264 -preset fast -c:a aac \
    "$OUTPUT_FILE" 2>&1 | tail -5 >&2; then
    echo "ERROR: FFmpeg assembly failed." >&2
    rm -f "$OUTPUT_FILE"
    exit 1
  fi

else
  # Multiple audio files — build filter_complex with adelay + amix

  # Build FFmpeg input arguments
  FFMPEG_INPUTS=(-y -i "$VIDEO_FILE")
  for audio_file in "${AUDIO_INPUTS[@]}"; do
    FFMPEG_INPUTS+=(-i "$audio_file")
  done

  # Build filter_complex string
  FILTER_PARTS=()
  AMIX_INPUTS=""
  for ((i = 0; i < AUDIO_COUNT; i++)); do
    local_offset="${AUDIO_OFFSETS_MS[$i]}"
    input_idx=$((i + 1))  # 0 is video
    label="a${i}"
    FILTER_PARTS+=("[${input_idx}:a]adelay=${local_offset}|${local_offset}[${label}]")
    AMIX_INPUTS+="[${label}]"
  done

  # amix with normalize=0 to prevent volume reduction
  FILTER_PARTS+=("${AMIX_INPUTS}amix=inputs=${AUDIO_COUNT}:normalize=0[aout]")

  FILTER_COMPLEX=$(IFS=';'; echo "${FILTER_PARTS[*]}")

  echo "  Assembling ${AUDIO_COUNT} audio segments..." >&2

  # For 50+ files, use filter_complex_script to avoid command-line length issues
  if [ "$AUDIO_COUNT" -ge 50 ]; then
    FILTER_SCRIPT=$(mktemp)
    echo "$FILTER_COMPLEX" > "$FILTER_SCRIPT"
    echo "  Using filter_complex_script (${AUDIO_COUNT} files)..." >&2

    if ! ffmpeg "${FFMPEG_INPUTS[@]}" \
      -filter_complex_script "$FILTER_SCRIPT" \
      -map 0:v -map "[aout]" \
      -c:v libx264 -preset fast -c:a aac \
      "$OUTPUT_FILE" 2>&1 | tail -5 >&2; then
      echo "ERROR: FFmpeg assembly failed." >&2
      rm -f "$OUTPUT_FILE" "$FILTER_SCRIPT"
      exit 1
    fi
    rm -f "$FILTER_SCRIPT"
  else
    if ! ffmpeg "${FFMPEG_INPUTS[@]}" \
      -filter_complex "$FILTER_COMPLEX" \
      -map 0:v -map "[aout]" \
      -c:v libx264 -preset fast -c:a aac \
      "$OUTPUT_FILE" 2>&1 | tail -5 >&2; then
      echo "ERROR: FFmpeg assembly failed." >&2
      rm -f "$OUTPUT_FILE"
      exit 1
    fi
  fi
fi

# --- Verify output ---

echo "" >&2

if [ ! -f "$OUTPUT_FILE" ]; then
  echo "ERROR: Output file was not created." >&2
  exit 1
fi

FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
FILE_SIZE_BYTES=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')

if [ "$FILE_SIZE_BYTES" -eq 0 ]; then
  echo "ERROR: Output file is empty." >&2
  rm -f "$OUTPUT_FILE"
  exit 1
fi

# Get duration and stream info via ffprobe
DURATION=""
VIDEO_CODEC=""
AUDIO_CODEC=""

if command -v ffprobe >/dev/null 2>&1; then
  DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$OUTPUT_FILE" 2>/dev/null || echo "unknown")
  VIDEO_CODEC=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$OUTPUT_FILE" 2>/dev/null || echo "unknown")
  AUDIO_CODEC=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$OUTPUT_FILE" 2>/dev/null || echo "none")
fi

# Format duration
if [ -n "$DURATION" ] && [ "$DURATION" != "unknown" ]; then
  DUR_INT=${DURATION%%.*}
  DUR_MIN=$((DUR_INT / 60))
  DUR_SEC=$((DUR_INT % 60))
  FORMATTED_DUR=$(printf "%d:%02d" "$DUR_MIN" "$DUR_SEC")
else
  FORMATTED_DUR="unknown"
fi

echo "=== Assembly Complete ===" >&2
echo "  Output: ${OUTPUT_FILE}" >&2
echo "  Size: ${FILE_SIZE}" >&2
echo "  Duration: ${FORMATTED_DUR}" >&2
echo "  Video: ${VIDEO_CODEC}" >&2
echo "  Audio: ${AUDIO_CODEC}" >&2

if [ "$AUDIO_COUNT" -gt 0 ] && [ "$AUDIO_CODEC" = "none" ]; then
  echo "  WARNING: Expected audio track but none found in output." >&2
fi

echo "" >&2
echo "Demo video ready: ${OUTPUT_FILE}" >&2

exit 0
