#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Error: No input file specified." >&2
    echo "Usage: $0 <video_file.mp4>" >&2
    exit 1
fi

INPUT_FILE="$1"

# 1. Check whether the input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' does not exist." >&2
    exit 1
fi

# Extract file details
DIR=$(dirname "$INPUT_FILE")
FILENAME=$(basename "$INPUT_FILE")
EXT="${FILENAME##*.}"
NAME_NO_EXT="${FILENAME%.*}"

# Ensure ffmpeg and ffprobe are installed
if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null; then
    echo "Error: ffmpeg and ffprobe are required but not installed." >&2
    echo "Install them using: sudo apt install ffmpeg" >&2
    exit 1
fi

echo "Analyzing input file..."
TOTAL_SIZE=$(stat -c%s "$INPUT_FILE")
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")

# Target size: 4.0 GB in bytes (4,000,000,000 bytes) to safely stay under the 4.2 GB limit
TARGET_SIZE=4000000000
OVERLAP=30 # 30 seconds overlap

# Calculate target duration per part using awk for floating-point math
PART_DURATION=$(awk "BEGIN {print ($TARGET_SIZE * $DURATION) / $TOTAL_SIZE}")

# Simulate parts to pre-check if any output file already exists
curr=0
n=1
declare -a output_files=()

while (( $(awk "BEGIN {print ($curr < $DURATION)}") )); do
    out_file="$DIR/${NAME_NO_EXT}.part_${n}.${EXT}"
    output_files+=("$out_file")
    
    # Next start time = current start + part duration - 30s overlap
    curr=$(awk "BEGIN {print $curr + $PART_DURATION - $OVERLAP}")
    ((n++))
done

# 2. Check whether any output files already exist
for f in "${output_files[@]}"; do
    if [ -f "$f" ]; then
        echo "Error: Output file '$f' already exists. Aborting to prevent overwriting." >&2
        exit 1
    fi
done

echo "Splitting '$INPUT_FILE' into parts (~4GB each with 30s overlap)..."

# Perform the actual splitting
curr=0
n=1
while (( $(awk "BEGIN {print ($curr < $DURATION)}") )); do
    out_file="$DIR/${NAME_NO_EXT}.part_${n}.${EXT}"
    
    echo "-> Creating Part $n: $out_file (Starting at ${curr}s)"
    
    # -ss: start time, -i: input, -t: duration, -c copy: fast stream copy without re-encoding
    ffmpeg -y -ss "$curr" -i "$INPUT_FILE" -t "$PART_DURATION" -c copy "$out_file"
    
    curr=$(awk "BEGIN {print $curr + $PART_DURATION - $OVERLAP}")
    ((n++))
done

echo "Success! All parts have been created."
