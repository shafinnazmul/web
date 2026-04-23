#!/bin/bash

# =============================================================================
# Bash script: strip_prefix_chars.sh
# 
# Removes the first N characters from the beginning of EVERY regular file
# in the CURRENT directory (non-recursive).
# 
# N is provided as a command-line argument.
# 
# IMPORTANT: The script will NEVER rename ITSELF (even if it has a prefix).
# 
# Example usage:
#   ./strip_prefix_chars.sh 3
# 
# This would turn:
#   01_fileA.txt           →  fileA.txt
#   02_fileB.txt           →  fileB.txt
#   03_10_document.pdf     →  10_document.pdf
#   01_strip_prefix_chars.sh  (skipped - script protects itself)
# 
# Safely skips files that are too short, checks for name collisions,
# and handles filenames with spaces/special characters.
# =============================================================================

if [ $# -ne 1 ]; then
    echo "Usage: $0 <number_of_characters_to_remove>"
    echo "Example: $0 3"
    exit 1
fi

n="$1"

# Validate: must be a positive integer
if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -eq 0 ]; then
    echo "ERROR: n must be a positive integer (greater than 0)" >&2
    exit 1
fi

# Get the exact basename of this script so we can protect it from renaming
script_name="${0##*/}"

count=0

echo "Removing first $n character(s) from all files in current directory..."
echo "(Skipping this script itself: $script_name)"

for file in *; do
    # Only process regular files
    [[ -f "$file" ]] || continue

    # SKIP OURSELVES - never rename the running script
    [[ "$file" == "$script_name" ]] && continue

    # Get original length
    len="${#file}"

    # Skip if file is too short
    if [ "$len" -le "$n" ]; then
        echo "Skipping '$file' (length $len ≤ $n)" >&2
        continue
    fi

    # Remove first n characters (bash substring syntax)
    new_name="${file:$n}"

    # Safety check: if target name already exists
    if [[ -e "$new_name" && "$new_name" != "$file" ]]; then
        echo "WARNING: Cannot rename '$file' → '$new_name' (target already exists)" >&2
        continue
    fi

    # Perform the rename
    mv -- "$file" "$new_name"
    echo "✓ Stripped $n chars: '$file' → '$new_name'"

    ((count++))
done

echo "Done! Processed $count file(s). (This script was protected and left unchanged)"